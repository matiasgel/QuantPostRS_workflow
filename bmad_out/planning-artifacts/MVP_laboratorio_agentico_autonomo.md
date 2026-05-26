# MVP — Laboratorio Agéntico Autónomo para QuantPostRS
**Fecha:** 26 de mayo de 2026  
**Estado:** DRAFT — diseño de MVP  
**Autores:** Carson (Brainstorm) + Mary (Análisis estratégico)  
**Origen:** Sesión de brainstorming sobre conversión de live coding a sistema agéntico autónomo con guardas de intervención humana

---

## Tabla de contenidos

1. [Visión del sistema](#1-visión-del-sistema)
2. [Componente A — Daemon Orchestrator](#2-componente-a--daemon-orchestrator)
3. [Componente B — Telegram Bot (interfaz del Físico)](#3-componente-b--telegram-bot-interfaz-del-físico)
4. [Componente C — Arquitectura completa del MVP](#4-componente-c--arquitectura-completa-del-mvp)
5. [Modernización con MCP, A2A y optimización de costos](#5-modernización-con-mcp-a2a-y-optimización-de-costos)
6. [Guardas de intervención humana — especificación completa](#6-guardas-de-intervención-humana--especificación-completa)
7. [Preguntas abiertas para el ingeniero de software](#7-preguntas-abiertas-para-el-ingeniero-de-software)
8. [Preguntas abiertas para el físico](#8-preguntas-abiertas-para-el-físico)
9. [Plan de implementación por fases](#9-plan-de-implementación-por-fases)

---

## 1. Visión del sistema

### 1.1 El problema a resolver

El proyecto QuantPostRS es actualmente un sistema de "live coding asistido": el Físico (matidani) inicia cada sesión, decide qué hacer, lo hace junto con el agente LLM, y cierra la sesión. El corpus crece solo cuando el Físico está activo.

El objetivo es convertirlo en un **laboratorio autónomo** con las siguientes propiedades:

- El laboratorio trabaja de forma continua, incluso cuando el Físico no está presente
- El Físico puede darle una instrucción al comienzo de la semana y recibir resultados al final
- El sistema interrumpe al Físico **solo cuando hay algo que exclusivamente él puede decidir**
- La interrupción llega al celular (Telegram) con la información suficiente para tomar una decisión en 30 segundos
- El corpus permanece append-only, trazable y auditble en todo momento

### 1.2 La separación de roles

```
FÍSICO (matidani)
  │  Decide: dirección científica, desbloquea guardas, evalúa resultados
  │  Interfaz: Telegram desde el celular
  │  Tiempo requerido: 5-15 minutos por día (solo cuando hay guardas activas)
  │
  ▼
DAEMON ORCHESTRATOR (Python, corre localmente)
  │  Decide: qué episodio ejecutar, en qué orden, cuándo escalar al Físico
  │  Lee el corpus → construye el estado → selecciona episodio → ejecuta
  │  Escribe artefactos al corpus directamente
  │
  ▼
AGENTE EJECUTOR (LLM: Claude/GPT vía API)
  │  Produce: CLAIM, SCRIPT-CADABRA, SCRIPT-SAGE, REPORT, EVAL
  │  Ejecuta: Cadabra2 y SageMath via subprocess local
  │  Respeta: AGENTS.md, FORMAL_METHODS_GUIDE.md, convenciones fijas
  │
  ▼
CORPUS (filesystem local)
     claims/ scripts/ reports/ evaluations/ interpretations/ decisions/
     → append-only, nunca editar artefactos existentes
```

### 1.3 Principio rector

> El daemon no "hace física". Lee el estado del corpus, determina el próximo paso seguro según las reglas ya definidas en `AGENTS.md` y `FORMAL_METHODS_GUIDE.md`, y lo ejecuta. Cuando el próximo paso requiere juicio científico, se detiene y llama al Físico.

---

## 2. Componente A — Daemon Orchestrator

### 2.1 El loop principal

El daemon es un proceso Python que corre continuamente (o en modo batch nocturno). Su ciclo es:

```
┌─────────────────────────────────────────────────────────┐
│                    CICLO DEL DAEMON                     │
│                                                         │
│  1. LEER CORPUS          leer_corpus()                  │
│     └─ parsea todos los artefactos YAML del corpus      │
│     └─ construye el estado actual (claims, deps, etc.)  │
│                                                         │
│  2. DETECTAR TRIGGERS    detectar_triggers(estado)      │
│     └─ ¿hay condiciones que requieren al Físico?        │
│     └─ si hay → notifica Telegram → espera respuesta    │
│                                                         │
│  3. SELECCIONAR EPISODIO seleccionar_episodio(estado)   │
│     └─ topological sort del grafo de dependencias       │
│     └─ primer claim con todas las deps en TESTED_PASS   │
│     └─ si ninguno → notifica "corpus estable" → pausa   │
│                                                         │
│  4. EJECUTAR EPISODIO    ejecutar_episodio(episodio)    │
│     └─ construye el prompt para el LLM                  │
│     └─ llama a la API con herramientas de filesystem    │
│     └─ el LLM crea claim + scripts + ejecuta + reporta  │
│                                                         │
│  5. AUDITAR RESULTADO    auditar(resultado)             │
│     └─ verifica convenciones en los scripts             │
│     └─ verifica que no se tocaron artefactos inmutables │
│     └─ ACEPTA → escribe EVAL / ITERA → reformula        │
│                                                         │
│  6. REGISTRAR Y ESPERAR  dormir(INTERVALO)              │
│     └─ registra en working/daemon_log_YYYYMMDD.md       │
│     └─ espera antes del próximo ciclo                   │
└─────────────────────────────────────────────────────────┘
```

### 2.2 El state machine explícito del daemon

El daemon tiene estados internos bien definidos. Esto evita ambigüedad sobre qué está haciendo en cada momento:

```
IDLE
  │  (corpus leído, sin episodio seleccionado)
  ▼
PLANNING
  │  (evaluando grafo de dependencias, seleccionando episodio)
  ▼
EXECUTING
  │  (agente LLM activo, produciendo artefactos)
  ▼
AUDITING
  │  (verificando artefactos producidos)
  ├─► EXECUTING  (itera si auditoría falla, hasta MAX_REINTENTOS)
  ▼
WRITING
  │  (escribe EVAL al corpus, cierra episodio)
  ▼
WAITING_HUMAN
  │  (trigger activo, esperando respuesta del Físico por Telegram)
  ▼
IDLE  (vuelve al inicio)
```

**Transiciones de error:**
- `EXECUTING` → `WAITING_HUMAN`: si el LLM declara que necesita decisión del Físico
- `AUDITING` → `WAITING_HUMAN`: si supera MAX_REINTENTOS sin convergencia
- Cualquier estado → `WAITING_HUMAN`: si se detecta un trigger crítico

### 2.3 Módulo: `corpus_reader.py`

Este módulo es el más crítico. Transforma el filesystem en una estructura de datos que el daemon puede razonar.

```python
# Estructura de datos del estado del corpus
@dataclass
class CorpusState:
    claims: dict[str, Claim]           # id → Claim con status, deps, scripts
    evaluations: dict[str, Evaluation] # id → Evaluation
    open_questions: dict[str, Question]
    decisions: list[Decision]
    daemon_flags: DaemonFlags          # flags de estado global

@dataclass
class Claim:
    id: str                            # CLAIM-0001
    title: str
    status: str                        # TESTED_PASS, PROPOSED, etc.
    depends_on: list[str]              # [CLAIM-0001, ...]
    uses_scripts: list[str]            # [SCRIPT-CADABRA-0001, ...]
    tested_by: str | None              # EVAL-0001
    is_foundational: bool              # True si es Fase 1

@dataclass
class DaemonFlags:
    paused: bool = False               # Físico pausó el sistema
    aggressive_mode: bool = False      # ejecutar en paralelo
    current_episode: str | None = None
    consecutive_failures: int = 0
```

**Regla de parsing:** el daemon lee el YAML frontmatter de cada artefacto `.md`. Los templates (archivos que contienen `CLAIM_TEMPLATE`, `EVAL_TEMPLATE`, etc.) se ignoran — no son artefactos reales.

**La función de grafo ejecutable:**
```python
def get_executable_claims(state: CorpusState) -> list[Claim]:
    """
    Retorna los claims que pueden ejecutarse ahora:
    todos sus depends_on tienen status TESTED_PASS.
    """
    passed = {id for id, c in state.claims.items()
              if c.status == "TESTED_PASS"}
    return [
        c for c in state.claims.values()
        if c.status == "PROPOSED"
        and all(dep in passed for dep in c.depends_on)
    ]
```

### 2.4 Módulo: `episode_runner.py`

El episode runner construye el prompt para el LLM y orquesta la ejecución. Es la capa que traduce el estado del corpus en instrucciones concretas.

**Estructura del prompt del sistema (invariante):**
```
Eres el agente ejecutor del laboratorio QuantPostRS.
Tu rol: producir artefactos formales verificables para el corpus.

REGLAS ABSOLUTAS (de AGENTS.md):
- Signatura: η = diag(+1,-1,-1,-1)
- Derivada covariante: D_μ = ∂_μ - iq A_μ
- Conmutador covariante: [D_μ, D_ν]X = -iq F_{μν} X
- El corpus es append-only: NO edites artefactos existentes
- Un claim NO puede ser TESTED_PASS sin residuo explícitamente cero
  en AMBOS verificadores (Cadabra2 Y SageMath)
- Los mutation tests son OBLIGATORIOS antes de TESTED_PASS

HERRAMIENTAS DISPONIBLES:
- create_file(path, content)
- read_file(path)
- run_cadabra2(script_path) → retorna stdout + exit_code
- run_sagemath(script_path) → retorna stdout + exit_code
- list_corpus() → lista artefactos existentes
- report_decision_needed(reason, options) → escala al Físico
```

**Estructura del prompt del episodio (variable por claim):**
```
CONTEXTO DEL CORPUS (estado al momento de ejecución):
Claims usables como premisas (TESTED_PASS):
  - CLAIM-0001: Invariancia Stueckelberg de W_μ
    Enunciado: W_μ = Ψ_μ - b D_μ χ satisface δ_S W_μ = 0
    [contenido completo del claim]

EPISODIO ACTUAL:
ID: CLAIM-0002
Título: Invariancia Stueckelberg del tensor H_{μν}
Enunciado: H_{μν} = D_μ W_ν - D_ν W_μ satisface δ_S H_{μν} = 0
Residuo esperado: -iq b F_{μν} ξ + iq b F_{μν} ξ = 0
Evidencia en Problema.tex: subsec:el-tensor-mejorado
Dependencias verificadas: [CLAIM-0001]

SECUENCIA OBLIGATORIA:
1. Crea claims/CLAIM-0002_stueckelberg_H.md con YAML frontmatter correcto
2. Crea scripts/cadabra/SCRIPT-CADABRA-0002_stueckelberg_H.cdb
3. Ejecuta: run_cadabra2("scripts/cadabra/SCRIPT-CADABRA-0002_stueckelberg_H.cdb")
4. Reporta el residuo de Cadabra2
5. Crea scripts/sage/SCRIPT-SAGE-0002_stueckelberg_H.sage
6. Ejecuta: run_sagemath("scripts/sage/SCRIPT-SAGE-0002_stueckelberg_H.sage")
7. Reporta el residuo de SageMath
8. MUTATION TESTS (OBLIGATORIO):
   8a. Modifica b en el script Sage a un valor incorrecto
   8b. Ejecuta y verifica que el residuo NO es cero
   8c. Restaura el valor correcto
9. Si AMBOS residuos son 0 Y mutation tests pasan:
   - Crea reports/REPORT-0002_stueckelberg_H.md con status PASSING
   - Crea evaluations/EVAL-0002_stueckelberg_H.md con status TESTED_PASS
10. Si algún residuo NO es 0:
    - Crea REPORT con los residuos obtenidos
    - Crea EVAL con status TESTED_FAIL o CONVENTION_MISMATCH
    - NO declares TESTED_PASS bajo ninguna circunstancia
```

### 2.5 Módulo: `auditor.py`

Antes de aceptar los artefactos producidos por el LLM, el auditor verifica mecánicamente:

```python
class Auditor:
    def auditar(self, artefactos_producidos: list[str]) -> AuditResult:
        errores = []

        for path in artefactos_producidos:
            # 1. Verificar que son NUEVOS artefactos
            if self.es_artefacto_existente(path):
                errores.append(f"VIOLACIÓN: se intentó editar {path}")

            # 2. Verificar YAML frontmatter válido
            if not self.tiene_yaml_valido(path):
                errores.append(f"YAML inválido en {path}")

            # 3. Verificar que los scripts usan las convenciones correctas
            if path.endswith('.cdb') or path.endswith('.sage'):
                if not self.usa_convencion_metrica(path):
                    errores.append(f"CONVENTION_MISMATCH en {path}")

            # 4. Verificar que EVAL con TESTED_PASS tiene mutation_tests: true
            if 'EVAL' in path:
                eval_data = self.leer_yaml(path)
                if eval_data.get('status') == 'TESTED_PASS':
                    if not eval_data.get('mutation_tests_passed', False):
                        errores.append(f"TESTED_PASS sin mutation tests en {path}")

        return AuditResult(ok=len(errores) == 0, errores=errores)
```

### 2.6 Módulo: `episodios_config.yaml`

El roadmap como datos, no como documento. El daemon lee esto para saber el orden de ejecución:

```yaml
# Configuración de episodios del laboratorio QuantPostRS
# Formato: id, tipo, prioridad, desbloqueado_por, herramientas, notas

version: "1.0"
max_reintentos_por_episodio: 3
intervalo_ciclo_segundos: 300   # 5 minutos entre ciclos en modo normal
intervalo_nocturno_segundos: 60  # 1 minuto en modo agresivo

episodios:
  # BLOQUE 0 — Deuda técnica (sin dependencias, siempre disponible)
  - id: MUTATION-CLAIM-0001
    tipo: mutation_test
    titulo: "Mutation tests para CLAIM-0001"
    prioridad: 0
    desbloqueado_por: []
    herramientas: [sagemath]
    notas: >
      Modificar el coeficiente b en SCRIPT-SAGE-0001 y verificar
      que el residuo deja de ser cero. Documentar en REPORT-0001-mutation.md

  # BLOQUE 1 — Fase 1: invariancias foundational
  - id: CLAIM-0002
    tipo: nuevo_claim
    titulo: "Invariancia Stueckelberg del tensor H_{μν}"
    prioridad: 1
    desbloqueado_por: [CLAIM-0001, MUTATION-CLAIM-0001]
    herramientas: [cadabra2, sagemath]
    enunciado: "H_{μν} = D_μ W_ν - D_ν W_μ satisface δ_S H_{μν} = 0"
    referencia_tex: "subsec:el-tensor-mejorado"

  - id: CLAIM-0005
    tipo: nuevo_claim
    titulo: "Sanidad q=0: reproducción de spin-3/2 libre"
    prioridad: 2
    desbloqueado_por: []             # INDEPENDIENTE — paralelizable con CLAIM-0002
    herramientas: [sagemath]
    enunciado: >
      En q=0, A_μ=0, el operador cuadrático se descompone en sectores
      de spin independientes y el sector spin-3/2 reproduce (i∂̸-m)Ψ_μ=0
    referencia_tex: "sec:limite-libre"

  - id: CLAIM-0003
    tipo: nuevo_claim
    titulo: "Covariancia electromagnética de W_μ y H_{μν}"
    prioridad: 3
    desbloqueado_por: [CLAIM-0001, CLAIM-0002]
    herramientas: [cadabra2, sagemath]
    enunciado: "Bajo U(1)_em, W_μ y H_{μν} transforman como e^{iqλ}(·)"

  - id: CLAIM-0004
    tipo: nuevo_claim
    titulo: "Invariancia de contacto de la acción cargada"
    prioridad: 4
    desbloqueado_por: [CLAIM-0001, CLAIM-0002, CLAIM-0003]
    herramientas: [cadabra2, sagemath]
    enunciado: "La acción en términos de W_μ es invariante bajo δ_C Ψ_μ = γ_μ ε"

  - id: CLAIM-0006
    tipo: nuevo_claim
    titulo: "Nilpotencia BRST s²=0 en sector mínimo"
    prioridad: 5
    desbloqueado_por: [CLAIM-0001, CLAIM-0002]
    herramientas: [cadabra2, sagemath]
    enunciado: "s²χ = 0, s²Ψ_μ = 0, s²η = 0 bajo las transformaciones BRST mínimas"
    requiere_decision_humana: true
    motivo_decision: >
      Elegir entre formulación BRST con ghost restringido (∂̸η=0)
      o con campos auxiliares (Q-0001 abierta)
```

### 2.7 Ejecución de herramientas formales vía subprocess

El daemon ejecuta Cadabra2 y SageMath directamente en la máquina local:

```python
import subprocess
import re

def run_cadabra2(script_path: str, timeout: int = 120) -> ToolResult:
    result = subprocess.run(
        ["cadabra2", "--noninteractive", script_path],
        capture_output=True,
        text=True,
        timeout=timeout
    )
    residuo = parsear_residuo_cadabra(result.stdout)
    return ToolResult(
        stdout=result.stdout,
        stderr=result.stderr,
        exit_code=result.returncode,
        residuo=residuo,
        es_cero=(residuo == "0" or residuo == "[]")
    )

def run_sagemath(script_path: str, timeout: int = 120) -> ToolResult:
    result = subprocess.run(
        ["sage", script_path],
        capture_output=True,
        text=True,
        timeout=timeout
    )
    residuo = parsear_residuo_sage(result.stdout)
    return ToolResult(
        stdout=result.stdout,
        stderr=result.stderr,
        exit_code=result.returncode,
        residuo=residuo,
        es_cero=es_matriz_cero(residuo)
    )

def parsear_residuo_sage(stdout: str) -> list:
    """
    Busca el patrón de salida de los scripts Sage del proyecto:
    Residuo: [0, 0, 0, 0]
    """
    match = re.search(r"Residuo[:\s]+(\[.*?\])", stdout)
    if match:
        return eval(match.group(1))  # lista de valores
    return None
```

### 2.8 El log del daemon

Cada ciclo del daemon se registra en `working/daemon_log_YYYYMMDD.md`. No es corpus primario — es un scratchpad de operaciones:

```markdown
# Daemon Log — 2026-05-27

## 03:14:22 CICLO #47
Estado: PLANNING
Claims ejecutables detectados: [CLAIM-0002, CLAIM-0005]
Episodio seleccionado: CLAIM-0002 (prioridad más alta)
Motivo: CLAIM-0001 y MUTATION-CLAIM-0001 en TESTED_PASS

## 03:14:23 CICLO #47 → EXECUTING
Episodio: CLAIM-0002
Prompt enviado a Claude API (1847 tokens)

## 03:18:41 CICLO #47 → AUDITING
Artefactos producidos:
  - claims/CLAIM-0002_stueckelberg_H.md ✅
  - scripts/cadabra/SCRIPT-CADABRA-0002_stueckelberg_H.cdb ✅
  - scripts/sage/SCRIPT-SAGE-0002_stueckelberg_H.sage ✅
  - reports/REPORT-0002_stueckelberg_H.md ✅
  - evaluations/EVAL-0002_stueckelberg_H.md ✅
Auditoría: OK
Residuo Cadabra2: 0
Residuo SageMath: [0, 0, 0, 0]
Mutation test: PASS (residuo≠0 con b alterado)
Status final: TESTED_PASS

## 03:18:42 CICLO #47 → IDLE
Telegram: notificado ✅
```

---

## 3. Componente B — Telegram Bot (interfaz del Físico)

### 3.1 Por qué Telegram

- **Cero fricción**: sin workspace corporativo, desde el celular, funciona con `python-telegram-bot`
- **Markdown nativo**: los mensajes del bot pueden formatear código, tablas y listas
- **Bidireccional**: el bot recibe comandos y responde, sin necesidad de abrir la computadora
- **Privado**: un bot de Telegram es una cuenta privada, sin exposición externa
- **Persistente**: si no hay conexión, los mensajes se encolan y se entregan cuando el Físico vuelve

### 3.2 Comandos del Físico

| Comando | Descripción | Respuesta del bot |
|---------|-------------|-------------------|
| `/estado` | Estado completo del corpus y del daemon | Tabla con claims activos, bloqueos, siguiente episodio disponible |
| `/siguiente` | Lanza el próximo episodio según la priorización | Confirmación de qué episodio se lanzó |
| `/pausa` | Congela el daemon hasta `/reanudar` | "Laboratorio pausado" |
| `/reanudar` | Reanuda el daemon | "Laboratorio reanudado, próximo episodio: CLAIM-0002" |
| `/resultado A` | Responde la opción A a una decisión pendiente | Desbloquea el episodio con la elección A |
| `/episodio CLAIM-0002` | Fuerza un episodio específico | Lanza ese episodio saltando la cola |
| `/alarmas` | Lista todas las anomalías detectadas | Claims FAIL, PARTIAL, warnings sin resolver |
| `/log` | Últimas 10 entradas del daemon log | Resumen de actividad reciente |
| `/modo agresivo` | Activa paralelización de claims independientes | "Modo agresivo activado" |
| `/modo normal` | Vuelve al modo secuencial | "Modo normal activado" |
| `/dryrun CLAIM-0002` | Simula el episodio sin escribir al corpus | Muestra el plan de ejecución |

### 3.3 Notificaciones del bot al Físico

El bot nunca interrumpe sin motivo. Solo notifica en estos casos:

#### Notificación tipo INFO (no bloquea)
```
🔬 QuantPostRS Lab

✅ Episodio completado: CLAIM-0002

Título: Invariancia Stueckelberg de H_{μν}
Status: TESTED_PASS

Residuo Cadabra2: 0
Residuo SageMath: [0, 0, 0, 0]
Mutation test: PASS

Próximo episodio en cola: CLAIM-0005
[Ver detalles]  [Pausar]
```

#### Notificación tipo ALERTA (no bloquea, requiere revisión)
```
⚠️ QuantPostRS Lab — ATENCIÓN

CLAIM-0003 completado con TESTED_PARTIAL

Cadabra2: PASS (residuo = 0)
SageMath: PARTIAL (residuo ≠ 0 en componente μ=0)

El daemon pausó automáticamente los episodios dependientes.

Posibles causas:
  [A] Error de signos en la representación Sage
  [B] Covarianza EM requiere término adicional no contemplado
  [C] Bug en el script Sage

¿Qué hacemos?
  /resultado A — Revisar signos en Sage (reintenta automáticamente)
  /resultado B — Escalar a decisión científica mayor
  /resultado C — Revisar script manualmente
```

#### Notificación tipo CRITICO (bloquea todo)
```
🚨 QuantPostRS Lab — DECISIÓN REQUERIDA

CLAIM-0006 requiere elección científica antes de proceder.

La formalización de la nilpotencia BRST s²=0 tiene DOS formulaciones
equivalentes algebraicamente pero inequivalentes físicamente:

[A] Ghost restringido: η con condición ∂̸η = 0
    → más cercano a la formulación original de la tesis
    → requiere formalizar la restricción en el formalismo BRST

[B] Campos auxiliares: introducir campo B para imponer la restricción
    → más estándar en literatura BRST moderna
    → cambia la estructura del espacio de Hilbert de ghosts

Esta decisión no puede revertirse sin crear un nuevo claim que refute el actual.

El laboratorio está pausado hasta tu respuesta.
/resultado A  o  /resultado B
```

#### Notificación tipo MILESTONE (informativa, no bloquea)
```
🏆 QuantPostRS Lab — MILESTONE

Fase 1 completa: todas las invariancias foundational verificadas.

Claims TESTED_PASS en Fase 1:
  ✅ CLAIM-0001: Invariancia Stueckelberg de W_μ
  ✅ CLAIM-0002: Invariancia Stueckelberg de H_{μν}
  ✅ CLAIM-0003: Covariancia EM de W_μ y H_{μν}
  ✅ CLAIM-0004: Invariancia de contacto

Estado científico global: FOUNDATIONAL_ALGEBRA_IN_PROGRESS → FREE_LIMIT_UNDER_TEST

Próxima fase disponible: Q-0003 (test de sanidad q→0)
¿Lanzar próximo episodio? /siguiente  o  /pausa
```

### 3.4 Implementación técnica del bot

```python
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, ContextTypes
import asyncio

class LabTelegramBot:
    def __init__(self, token: str, chat_id: int, daemon_state: DaemonState):
        self.app = Application.builder().token(token).build()
        self.chat_id = chat_id  # ID del Físico — solo él puede controlar el lab
        self.daemon = daemon_state

        # Registrar comandos
        self.app.add_handler(CommandHandler("estado", self.cmd_estado))
        self.app.add_handler(CommandHandler("siguiente", self.cmd_siguiente))
        self.app.add_handler(CommandHandler("pausa", self.cmd_pausa))
        self.app.add_handler(CommandHandler("reanudar", self.cmd_reanudar))
        self.app.add_handler(CommandHandler("resultado", self.cmd_resultado))
        self.app.add_handler(CommandHandler("alarmas", self.cmd_alarmas))

    def verificar_identidad(self, update: Update) -> bool:
        """Solo el chat_id autorizado puede controlar el laboratorio."""
        return update.effective_chat.id == self.chat_id

    async def notificar(self, mensaje: str, nivel: str = "INFO"):
        """Envía notificación al Físico con formato según nivel."""
        iconos = {"INFO": "🔬", "ALERTA": "⚠️", "CRITICO": "🚨", "MILESTONE": "🏆"}
        await self.app.bot.send_message(
            chat_id=self.chat_id,
            text=f"{iconos[nivel]} *QuantPostRS Lab*\n\n{mensaje}",
            parse_mode="Markdown"
        )

    async def cmd_estado(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        if not self.verificar_identidad(update):
            return
        estado = self.daemon.leer_corpus()
        reporte = formatear_estado_telegram(estado)
        await update.message.reply_text(reporte, parse_mode="Markdown")

    async def esperar_resultado(self, opciones: list[str]) -> str:
        """Bloquea hasta que el Físico envíe /resultado X."""
        future = asyncio.get_event_loop().create_future()
        self.pending_decision = future
        self.valid_options = opciones
        return await future
```

### 3.5 Seguridad del bot

- El bot solo responde al `chat_id` del Físico — no hay endpoints públicos
- El token del bot se almacena en variables de entorno, nunca en el código
- Los comandos destructivos (pausa, forzar episodio) requieren confirmación antes de ejecutar
- El bot loguea todos los comandos recibidos en `working/telegram_log_YYYYMMDD.md`

---

## 4. Componente C — Arquitectura completa del MVP

### 4.1 Diagrama de componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                    MÁQUINA LOCAL (Linux)                        │
│                                                                 │
│  ┌─────────────────────┐     ┌──────────────────────────────┐  │
│  │   DAEMON (Python)   │     │   AGENTE LLM (Claude API)    │  │
│  │                     │     │                              │  │
│  │  corpus_reader.py   │────►│  System prompt + AGENTS.md   │  │
│  │  episode_runner.py  │◄────│  Produce artefactos          │  │
│  │  auditor.py         │     │  Ejecuta herramientas        │  │
│  │  trigger_detector.py│     └──────────────────────────────┘  │
│  │  telegram_bot.py    │                                        │
│  └──────┬──────────────┘                                        │
│         │  lee/escribe                    subprocess            │
│         ▼                         ┌──────────┐  ┌──────────┐   │
│  ┌─────────────────────┐          │ Cadabra2 │  │ SageMath │   │
│  │  CORPUS (filesystem)│          └──────────┘  └──────────┘   │
│  │                     │                                        │
│  │  claims/            │                                        │
│  │  scripts/           │                                        │
│  │  reports/           │                                        │
│  │  evaluations/       │                                        │
│  │  decisions/         │                                        │
│  │  open_questions/    │                                        │
│  │  working/           │ ← daemon logs, no es corpus primario   │
│  └─────────────────────┘                                        │
│                                                                 │
└────────────────────────────────┬────────────────────────────────┘
                                 │  Telegram API (HTTPS)
                                 ▼
                    ┌────────────────────────┐
                    │  FÍSICO (matidani)      │
                    │  Telegram en el celular │
                    │                         │
                    │  Recibe: notificaciones │
                    │  Envía: comandos        │
                    └────────────────────────┘
```

### 4.2 Stack tecnológico del MVP

```
RUNTIME
  Python 3.11+
  uv                        Gestor de dependencias rápido (10-100x más rápido que pip)

DEPENDENCIAS CORE
  anthropic>=0.40           SDK con soporte de prompt caching y Batch API
  mcp>=1.0                  Model Context Protocol (cliente + servidor)
  python-telegram-bot>=21   Bot de Telegram (async)
  pyyaml>=6                 Parsing de artefactos YAML
  networkx>=3               Grafo de dependencias del corpus
  pydantic>=2               Validación de schemas (CorpusState, Claim, etc.)
  pydantic-settings>=2      Configuración type-safe desde .env

DEPENDENCIAS OPCIONALES
  litellm>=1.40             Proxy multi-proveedor con cache transparente
  instructor>=1.0           Salidas estructuradas garantizadas via Pydantic
  loguru>=0.7               Logging estructurado
  tiktoken                  Conteo de tokens previo al envío (cost control)

SERVIDORES MCP (ver sección 5)
  mcp-server-filesystem     Oficial — reemplaza create_file/read_file/list_dir
  mcp-server-quantpostrs    Custom — run_cadabra2, run_sagemath, validate_yaml

HERRAMIENTAS FORMALES (ya instaladas)
  cadabra2                  Vía subprocess (dentro del MCP server custom)
  sage                      Vía subprocess (dentro del MCP server custom)

VARIABLES DE ENTORNO (gestionadas con pydantic-settings)
  ANTHROPIC_API_KEY         Clave de la API de Claude
  TELEGRAM_BOT_TOKEN        Token del bot
  TELEGRAM_CHAT_ID          Chat ID del Físico (solo él controla el lab)
  CORPUS_ROOT               Path absoluto al repositorio
  LLM_MODEL_ROUTER          Default: claude-3-5-haiku-latest (routing barato)
  LLM_MODEL_EXECUTOR        Default: claude-sonnet-4-5 (ejecución)
  LLM_MODEL_AUDITOR         Default: claude-3-5-haiku-latest (auditoría barata)
  USE_BATCH_API             Default: true (descuento 50% para episodios no urgentes)
  USE_PROMPT_CACHE          Default: true (descuento ~90% en tokens cacheados)
  DAILY_BUDGET_USD          Default: 5.00 (circuit breaker automático)
  MAX_REINTENTOS            Default: 3
  INTERVALO_CICLO           Default: 300 (segundos)
  MODO_AGRESIVO             Default: false
```

### 4.3 Estructura de archivos del orchestrator

```
orchestrator/
│
├── daemon.py                  # loop principal, state machine
├── corpus_reader.py           # parsing del filesystem → CorpusState
├── episode_runner.py          # prompt builder + llamadas LLM
├── auditor.py                 # verificación de artefactos producidos
├── trigger_detector.py        # guardas de intervención humana
├── telegram_bot.py            # notificaciones y comandos
├── tool_executor.py           # wrappers para Cadabra2 y SageMath
├── formatters.py              # formateo de mensajes Telegram
│
├── config/
│   ├── episodios_config.yaml  # roadmap como datos
│   └── prompts/
│       ├── system_prompt.md   # instrucciones base del agente
│       ├── new_claim.md       # template de prompt para claim nuevo
│       ├── mutation_test.md   # template para mutation test
│       └── brst_episode.md    # template para episodios BRST
│
├── tests/
│   ├── test_corpus_reader.py
│   ├── test_auditor.py
│   └── test_trigger_detector.py
│
└── .env.example               # template de variables de entorno
```

### 4.4 El protocolo de herramientas del LLM (vía MCP)

En lugar de implementar tools custom desde cero, el MVP usa **MCP (Model Context Protocol)** — un estándar abierto de Anthropic que define cómo los LLMs descubren y llaman herramientas externas. Esto da tres beneficios concretos para el MVP:

1. **Reuso**: el servidor MCP oficial `mcp-server-filesystem` ya implementa `read_file`, `write_file`, `list_directory` con sandbox de paths. No hay que reescribirlos.
2. **Portabilidad**: si mañana cambias de Claude a GPT-5 o a un modelo local, las herramientas no cambian — cualquier cliente MCP-compatible las consume.
3. **Inspección**: el bot Telegram puede mostrar al Físico exactamente qué tools tiene disponible el agente y con qué parámetros, leyendo la metadata MCP.

La arquitectura queda:

```
  Daemon (cliente MCP)
     ├── mcp-server-filesystem (oficial, npx)
     │     └── read_file, write_file, list_directory  — sandbox al CORPUS_ROOT
     │
     └── mcp-server-quantpostrs (custom, ~150 líneas Python)
           ├── run_cadabra2(script_path, timeout)
           ├── run_sagemath(script_path, timeout)
           ├── parse_yaml_frontmatter(path)
           ├── validate_claim_artifact(path)
           └── report_decision_needed(reason, options)
```

**Implementación del servidor MCP custom** (esqueleto):

```python
# mcp_server_quantpostrs.py
from mcp.server import Server
from mcp.types import Tool, TextContent

server = Server("quantpostrs-tools")

@server.tool()
async def run_cadabra2(script_path: str, timeout: int = 120) -> dict:
    """Ejecuta un script Cadabra2 y retorna stdout + residuo parseado.
    Solo acepta scripts dentro de scripts/cadabra/ del corpus."""
    if not script_path.startswith("scripts/cadabra/") or not script_path.endswith(".cdb"):
        return {"error": "path no permitido"}
    # ... subprocess.run con timeout ...
    return {"stdout": ..., "residuo": ..., "es_cero": ..., "exit_code": ...}

@server.tool()
async def run_sagemath(script_path: str, timeout: int = 120) -> dict:
    """Análogo a run_cadabra2 pero para SageMath."""
    ...

@server.tool()
async def report_decision_needed(reason: str, options: list[str]) -> dict:
    """Escala al Físico via Telegram bot. Bloquea hasta /resultado X."""
    ...
```

**Sandbox del filesystem MCP** (configuración crítica para seguridad):

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/matiasgel/Documentos/QuantPostRS_workflow"
      ]
    },
    "quantpostrs": {
      "command": "python",
      "args": ["orchestrator/mcp_server_quantpostrs.py"]
    }
  }
}
```

El servidor de filesystem oficial ya impone que **toda escritura esté dentro del root configurado**, eliminando la Q-SW-012 sobre path traversal (`../../etc/passwd`).

**Validación adicional del auditor** — MCP da sandbox de filesystem, pero las reglas del corpus (no editar artefactos existentes, no modificar `Problema.tex`) se imponen en el `auditor.py` después del episodio, no en el tool mismo, porque son reglas semánticas del proyecto y no de seguridad de SO.

### 4.5 Flujo de datos end-to-end: un episodio completo

```
T=0     Daemon lee corpus
        Estado: CLAIM-0001 TESTED_PASS, MUTATION-CLAIM-0001 TESTED_PASS
        Detectado: CLAIM-0002 desbloqueado (todas las deps en PASS)

T=1     Daemon construye prompt para CLAIM-0002
        System prompt (invariante) + estado del corpus + instrucciones del episodio
        ~2000 tokens

T=2     Claude API recibe el prompt
        Ejecuta secuencialmente:
          → create_file("claims/CLAIM-0002_stueckelberg_H.md", ...)
          → create_file("scripts/cadabra/SCRIPT-CADABRA-0002.cdb", ...)
          → run_cadabra2("scripts/cadabra/SCRIPT-CADABRA-0002.cdb")
             Output: "Residuo: 0\n"
          → create_file("scripts/sage/SCRIPT-SAGE-0002.sage", ...)
          → run_sagemath("scripts/sage/SCRIPT-SAGE-0002.sage")
             Output: "Residuo: [0, 0, 0, 0]\n"
          → [mutation test: modifica b, re-ejecuta]
             Output: "Residuo: [-0.047+0.031j, ...]\n"  ← no es cero: PASS
          → create_file("reports/REPORT-0002.md", ...)
          → create_file("evaluations/EVAL-0002.md", status: TESTED_PASS)

T=3     Daemon audita los artefactos producidos
        Checks: YAML válido, no se editaron artefactos existentes,
                convenciones correctas, mutation_tests_passed: true
        Resultado: OK

T=4     Daemon notifica al Físico por Telegram
        "✅ CLAIM-0002 TESTED_PASS — Residuo Cadabra2: 0, SageMath: [0,0,0,0]"

T=5     Daemon actualiza su estado interno
        Nuevo estado: CLAIM-0002 TESTED_PASS
        Próximos episodios desbloqueados: CLAIM-0003 (deps: 0001, 0002 ✅)
        Ciclo siguiente: CLAIM-0005 (paralelo, independiente)
```

### 4.6 Modo de ejecución: normal vs agresivo

```yaml
# Modo normal (default)
# → episodios secuenciales, uno a la vez, espera confirmación entre bloques
modo_normal:
  episodios_en_paralelo: 1
  confirmar_antes_de_bloque: false
  notificar_cada: "TESTED_PASS, TESTED_FAIL, HUMAN_REQUIRED, MILESTONE"

# Modo agresivo (activado por /modo agresivo)
# → claims independientes en paralelo, mínimas interrupciones
modo_agresivo:
  episodios_en_paralelo: 3   # máximo de claims independientes simultáneos
  confirmar_antes_de_bloque: false
  notificar_cada: "TESTED_FAIL, HUMAN_REQUIRED, MILESTONE"
  # no notifica cada TESTED_PASS individual — solo milestones
```

---

## 5. Modernización con MCP, A2A y optimización de costos

Esta sección explica cómo aprovechar las herramientas y protocolos lanzados durante 2024-2026 para que el MVP sea más barato, más mantenible y más fácil de migrar a otros proveedores LLM en el futuro.

### 5.1 Resumen ejecutivo de decisiones

| Decisión | Adoptar en MVP | Justificación |
|----------|----------------|---------------|
| **MCP** (Model Context Protocol) para tools | ✅ Sí | Estándar abierto; reusa filesystem oficial; portable entre LLMs |
| **Prompt caching** (Anthropic) | ✅ Sí | ~90% descuento en tokens cacheados; system prompt + corpus son cacheables |
| **Batch API** (Anthropic) | ✅ Sí (opcional por episodio) | 50% descuento; aceptable para episodios no urgentes |
| **Modelo split por rol** (Haiku/Sonnet) | ✅ Sí | Routing y auditoría con Haiku; ejecución con Sonnet |
| **LiteLLM** como proxy | 🟡 Opcional | Útil si se quiere fallback a OpenAI/local; añade complejidad |
| **A2A** (Agent-to-Agent, Google) | ❌ No para MVP | Overkill; un solo proceso daemon es suficiente |
| **LangGraph** | ❌ No para MVP | El state machine custom es ~100 líneas; LangGraph añade dependencia pesada |
| **Instructor / Pydantic AI** | ✅ Sí | Garantiza que las respuestas del LLM cumplen schemas (YAML válido) |

### 5.2 Optimización de costos — el cálculo concreto

Sin optimización, un episodio típico (CLAIM-0002) cuesta aproximadamente:

```
PROMPT
  System prompt (AGENTS.md + reglas):       ~3,000 tokens
  Corpus context (claims TESTED_PASS):      ~5,000 tokens
  Instrucciones del episodio:               ~1,500 tokens
  Total input:                              ~9,500 tokens

OUTPUT
  Claim + scripts + report + eval:          ~4,000 tokens
  Razonamiento intermedio:                  ~2,000 tokens
  Total output:                             ~6,000 tokens

COSTO con Claude Sonnet 4.5 (sin optimización):
  Input:  9,500 × $3/Mtok  = $0.0285
  Output: 6,000 × $15/Mtok = $0.0900
  ────────────────────────────────
  Por episodio:             ~$0.12
  100 episodios:            ~$12
```

**Con las optimizaciones del MVP:**

```
1. PROMPT CACHING (system + corpus = ~8,000 tokens cacheables)
   Primer episodio: cache write a $3.75/Mtok  = $0.030
   Episodios 2-100: cache read a $0.30/Mtok   = $0.0024 cada uno
   Savings sobre 100 episodios:               ~$2.50 → ~$0.27

2. BATCH API en episodios no urgentes (50% off)
   Input cacheado batch:  $0.15/Mtok
   Output batch:          $7.50/Mtok
   Si 70% de episodios van por batch:         savings ~50% adicional

3. ROUTING con Haiku ($0.80/$4 por Mtok)
   - Seleccionar próximo episodio:           Haiku
   - Auditoría de artefactos:                Haiku
   - Resúmenes para Telegram:                Haiku
   - Solo el episodio mismo usa Sonnet
   
COSTO REAL ESTIMADO con todas las optimizaciones:
  Por episodio:             ~$0.025 - $0.04
  100 episodios:             ~$2.50 - $4.00
```

**Reducción de ~75-80%** sobre la implementación naive, sin perder calidad en la ejecución (Sonnet sigue siendo el modelo de ejecución).

### 5.3 Prompt caching — qué cachear y cómo

Anthropic's prompt caching aplica un descuento de ~90% a cualquier prefijo del prompt que se marca como `cache_control`. El cache vive 5 minutos (renovable). Las partes ideales para cachear son:

```python
# Estructura del prompt con caching
messages = [
    {
        "role": "system",
        "content": [
            {
                "type": "text",
                "text": SYSTEM_PROMPT_INVARIANTE,  # AGENTS.md + reglas (~3000 tok)
                "cache_control": {"type": "ephemeral"}  # ← cachear
            },
            {
                "type": "text",
                "text": render_corpus_passed_claims(state),  # ~5000 tok
                "cache_control": {"type": "ephemeral"}  # ← cachear
            }
        ]
    },
    {
        "role": "user",
        "content": render_episode_instructions(episodio)  # ~1500 tok, no cachear
    }
]
```

**Regla operativa:** todo lo que cambia poco (system prompt, claims TESTED_PASS) va cacheado. Lo que cambia por episodio (instrucción específica) no se cachea. Si dos episodios corren dentro de 5 minutos, el segundo paga ~$0.0024 en lugar de $0.025.

### 5.4 Batch API — cuándo usarla

La Batch API procesa requests de forma asíncrona con descuento del 50%, pero con SLA de hasta 24 horas. Aplicación al MVP:

| Tipo de episodio | API a usar | Razón |
|------------------|------------|-------|
| Mutation tests batch nocturno | Batch | No urgente; corre mientras el Físico duerme |
| CLAIM nuevo con dependencias resueltas | Batch | Si está en cola, no hay urgencia |
| Auditoría retrospectiva del corpus | Batch | Tarea de mantenimiento sin urgencia |
| Episodio lanzado por `/siguiente` | **Realtime** | El Físico está esperando respuesta |
| Respuesta a guarda (`/resultado X`) | **Realtime** | El Físico desbloqueó algo, debe ejecutarse ya |

Configuración: el flag `usar_batch_api: true/false` por episodio en `episodios_config.yaml`, con default según el tipo.

### 5.5 Modelo split por rol — el routing

En lugar de usar Sonnet para todo, el daemon usa diferentes modelos según la tarea:

```python
class ModelRouter:
    """Selecciona el modelo apropiado para cada subtarea."""

    MODELS = {
        "router":    "claude-3-5-haiku-latest",    # ~5x más barato
        "auditor":   "claude-3-5-haiku-latest",    # validación estructural
        "summarizer":"claude-3-5-haiku-latest",    # resúmenes para Telegram
        "executor":  "claude-sonnet-4-5",          # ejecución del episodio
        "scientific":"claude-opus-4-1",            # razonamiento BRST/espectro
    }

    def for_task(self, task: str) -> str:
        return self.MODELS[task]
```

**Tareas que usan Haiku (barato):**
- Decidir cuál es el próximo episodio dado el estado del corpus
- Verificar que un YAML frontmatter es válido
- Resumir el log del daemon para enviar por Telegram
- Detectar si dos enunciados de claims son potencialmente contradictorios (primera pasada)

**Tareas que usan Sonnet (estándar):**
- Producir CLAIM + SCRIPT-CADABRA + SCRIPT-SAGE de un episodio
- Generar el REPORT y EVAL del episodio

**Tareas que usan Opus (caro, solo cuando hace falta):**
- Razonamiento sobre BRST con ghost restringido vs campos auxiliares
- Análisis espectral del operador cuadrático
- Argumentos analíticos para `interpretations/`

### 5.6 Salidas estructuradas con Instructor

Para que el daemon no tenga que parsear YAML producido por el LLM (frágil), se usa `instructor` que garantiza que la respuesta del LLM cumple un schema Pydantic:

```python
from instructor import patch
from pydantic import BaseModel
from anthropic import Anthropic

class ClaimArtifact(BaseModel):
    claim_id: str
    titulo: str
    enunciado: str
    depends_on: list[str]
    uses_scripts: list[str]
    yaml_frontmatter: str
    markdown_body: str

client = patch(Anthropic())

# El LLM debe retornar exactamente un ClaimArtifact válido
artifact = client.messages.create(
    model="claude-sonnet-4-5",
    response_model=ClaimArtifact,
    messages=[...]
)
# artifact es type-safe; YAML siempre válido
```

Esto elimina toda una clase de bugs (Q-SW-009 sobre YAML malformado).

### 5.7 Circuit breaker de costos

Un bug puede hacer que el daemon dispare 100 episodios en loop antes de detectarse. El circuit breaker mata el daemon cuando el costo del día supera `DAILY_BUDGET_USD`:

```python
class CostCircuitBreaker:
    def __init__(self, daily_budget_usd: float):
        self.daily_budget = daily_budget_usd
        self.spent_today = self.load_today_spend()

    def can_execute(self, estimated_cost: float) -> bool:
        if self.spent_today + estimated_cost > self.daily_budget:
            self.notify_telegram(
                f"🚨 CIRCUIT BREAKER: gasto diario ${self.spent_today:.2f} "
                f"alcanzó el límite ${self.daily_budget}. Daemon pausado."
            )
            return False
        return True

    def record(self, actual_cost: float):
        self.spent_today += actual_cost
        self.persist()
```

Estimación previa al envío usando `tiktoken` para contar tokens del prompt.

### 5.8 Por qué A2A queda fuera del MVP

**A2A (Agent-to-Agent Protocol)** es el estándar de Google para comunicación entre agentes independientes. Sería relevante si el laboratorio tuviera:
- Un agente "Físico Teórico" en una máquina
- Un agente "Auditor Cadabra2" en otra máquina  
- Un agente "Auditor Sage" en una tercera

Cada uno con su LLM, su contexto, su personalidad. En esa arquitectura, A2A define cómo se mandan mensajes, tareas y resultados entre ellos.

**Para el MVP**, el daemon es un único proceso que orquesta llamadas a un único LLM con diferentes prompts. No hay agentes distribuidos. A2A añadiría:
- Servidor HTTP por agente
- Discovery de capabilities
- Gestión de identidades y autenticación

Sin beneficio real. **Posible adopción futura:** si el sistema crece y se quiere correr el auditor de Sage en un servidor remoto (porque tiene una instalación particular), A2A es la forma estándar de hacerlo. Pero hoy, un `subprocess.run("sage", ...)` local resuelve el mismo problema con cero overhead.

### 5.9 Por qué LangGraph queda fuera del MVP

LangGraph es excelente para grafos complejos de agentes con muchos branches condicionales. Pero el state machine del daemon (sección 2.2) tiene 6 estados y ~10 transiciones \u2014 implementarlo en Python puro son ~100 líneas. LangGraph añadiría:

- ~80 MB de dependencias (langchain ecosystem)
- Curva de aprendizaje
- Acoplamiento a LangChain
- Debugger menos directo

Si el state machine crece a 20+ estados, vale la pena reconsiderar.

### 5.10 Checklist de adopción para el MVP

```
[ ] Migrar tools a servidor MCP custom (mcp_server_quantpostrs.py)
[ ] Configurar filesystem MCP server oficial via npx con sandbox al corpus
[ ] Implementar ModelRouter con Haiku/Sonnet/Opus
[ ] Activar prompt caching en system_prompt + corpus context
[ ] Implementar CostCircuitBreaker con DAILY_BUDGET_USD
[ ] Usar instructor para artefactos estructurados (claims, evals)
[ ] Flag usar_batch_api por episodio en episodios_config.yaml
[ ] Telegram /costo : muestra gasto diario y mensual
[ ] Telegram /modelos : muestra qué modelo se usa para qué tarea
```

---

### 5.11 Alternativa de costos: modelos Qwen vía API

Esta sección analiza el uso de modelos **Qwen** (Alibaba) como alternativa o complemento a los modelos de Anthropic. Los precios se obtienen de OpenRouter (estado: 26 de mayo de 2026), que expone todos los modelos Qwen con API OpenAI-compatible, lo que permite integrarlos con LiteLLM sin ningún cambio en el código del daemon.

#### Catálogo de modelos Qwen disponibles (precios reales vía OpenRouter)

| Modelo | Parámetros | Ctx | Input $/Mtok | Output $/Mtok | Caching | Rol sugerido |
|--------|-----------|-----|-------------|--------------|---------|--------------|
| **qwen/qwen3.7-max** | ~MoE | 1M | $2.50 | $7.50 | ✅ explícito | Razonamiento científico (reemplaza Opus) |
| **qwen/qwen3.6-max-preview** | ~1T MoE | 262K | $1.04 | $6.24 | — | Razonamiento avanzado (alternativa a Opus) |
| **qwen/qwen3.6-plus** | 263B MoE | 1M | $0.325 | $1.95 | — | Ejecutor de episodios (reemplaza Sonnet) |
| **qwen/qwen3.5-397b-a17b** | 397B-A17B | 262K | $0.39 | $2.34 | — | Ejecutor robusto (alternativa Sonnet) |
| **qwen/qwen3.6-flash** | MoE | 1M | $0.1875 | $1.125 | ✅ explícito | Ejecutor rápido / auditor |
| **qwen/qwen3.5-flash** | — | 1M | $0.065 | $0.26 | — | Auditor / summarizer |
| **qwen/qwen3.6-35b-a3b** | 35B-A3B | 262K | $0.15 | $1.00 | — | Auditor / routing |
| **qwen/qwen3-235b-a22b-2507** | 235B-A22B | 262K | $0.071 | $0.10 | — | Router / auditor (excepcional relación calidad/precio) |
| **qwen/qwen3.5-9b** | 9B | 262K | $0.04 | $0.15 | — | Routing simple / formato YAML |

> **Nota:** Precios vía OpenRouter (routing internacional). DashScope directo (Alibaba Cloud) puede ser más barato para alta frecuencia pero requiere cuenta china. `qwen3.7-max` y `qwen3.6-flash` soportan prompt caching explícito con pricing diferenciado.

#### Comparación de costos: Claude vs. Qwen — mismo episodio de referencia

El mismo episodio CLAIM-0002 (9,500 tokens entrada / 6,000 tokens salida):

```
╔══════════════════════════════════════════════════════════╗
║  ESCENARIO 1: Claude puro, sin optimización              ║
║  Executor: claude-sonnet-4-5                             ║
║  Input:  9,500 × $3.00/Mtok  = $0.0285                  ║
║  Output: 6,000 × $15.00/Mtok = $0.0900                  ║
║  Por episodio: $0.12  │  100 episodios: $12.00           ║
╠══════════════════════════════════════════════════════════╣
║  ESCENARIO 2: Claude optimizado (sección 5.2)            ║
║  Executor: claude-sonnet-4-5 + caching + Haiku routing   ║
║  Por episodio: $0.025-0.04  │  100 episodios: ~$3.25     ║
╠══════════════════════════════════════════════════════════╣
║  ESCENARIO 3: Qwen puro, sin optimización                ║
║  Executor: qwen3.6-plus                                  ║
║  Input:  9,500 × $0.325/Mtok = $0.0031                  ║
║  Output: 6,000 × $1.95/Mtok  = $0.0117                  ║
║  Por episodio: $0.015  │  100 episodios: $1.50           ║
╠══════════════════════════════════════════════════════════╣
║  ESCENARIO 4: Qwen optimizado (split por rol)            ║
║  Router:   qwen3-235b-a22b-2507 ($0.071/$0.10)          ║
║  Executor: qwen3.6-flash ($0.1875/$1.125) + caching      ║
║  Auditor:  qwen3-235b-a22b-2507                          ║
║  Por episodio: ~$0.007  │  100 episodios: ~$0.70         ║
╠══════════════════════════════════════════════════════════╣
║  ESCENARIO 5: Híbrido recomendado para MVP               ║
║  Router:   qwen3-235b-a22b-2507 (barato, capaz)          ║
║  Executor: claude-sonnet-4-5 + caching (calidad máx.)   ║
║  Auditor:  qwen3-235b-a22b-2507                          ║
║  Científico: qwen3.7-max (más barato que Opus)           ║
║  Por episodio: ~$0.022  │  100 episodios: ~$2.20         ║
╚══════════════════════════════════════════════════════════╝
```

#### Mapeo de roles: Claude → Qwen

| Rol | Claude (original) | Qwen (alternativa) | Ahorro aprox. |
|-----|-------------------|--------------------|---------------|
| **Routing / selección episodio** | claude-haiku-3.5 ($0.80/$4) | qwen3-235b-a22b-2507 ($0.071/$0.10) | ~90% |
| **Auditoría de artefactos** | claude-haiku-3.5 | qwen3-235b-a22b-2507 | ~90% |
| **Resúmenes para Telegram** | claude-haiku-3.5 | qwen3.5-9b ($0.04/$0.15) | ~95% |
| **Ejecución de episodios** | claude-sonnet-4-5 ($3/$15) | qwen3.6-plus ($0.325/$1.95) | ~87% |
| **Razonamiento BRST/espectro** | claude-opus-4-1 ($15/$75) | qwen3.7-max ($2.50/$7.50) | ~83% |

> **Caveat crítico sobre calidad:** Qwen3.6-Plus y Qwen3.7-Max tienen excelentes benchmarks en código y razonamiento general, pero su comportamiento específico en **álgebra de Clifford, trazas de gamma y formalismo BRST** no está validado para este proyecto. **La recomendación es comenzar con el Escenario 5 (híbrido)**: Qwen para routing y auditoría (bajo riesgo), Claude Sonnet para la ejecución del episodio hasta que se valide experimentalmente que Qwen ejecuta episodios correctamente.

#### Integración con LiteLLM (cambio mínimo de código)

```python
# ModelRouter actualizado para soporte Qwen + Claude
import litellm
from litellm import completion

class ModelRouter:
    MODELS = {
        # OpenAI-compatible via LiteLLM → OpenRouter
        "router":     "openrouter/qwen/qwen3-235b-a22b-2507",
        "auditor":    "openrouter/qwen/qwen3-235b-a22b-2507",
        "summarizer": "openrouter/qwen/qwen3.5-9b",
        # Claude para la ejecución (calidad garantizada)
        "executor":   "anthropic/claude-sonnet-4-5",
        # Qwen más barato que Opus para razonamiento avanzado
        "scientific": "openrouter/qwen/qwen3.7-max",
    }

    def call(self, role: str, messages: list, **kwargs) -> str:
        model = self.MODELS[role]
        response = completion(model=model, messages=messages, **kwargs)
        return response.choices[0].message.content

# Configuración de LiteLLM (.env)
# OPENROUTER_API_KEY=...  (una sola clave para todos los modelos Qwen)
# ANTHROPIC_API_KEY=...   (para Claude en el executor)
```

LiteLLM resuelve automáticamente la autenticación, retry, fallback y logging. Un solo `pip install litellm` da acceso a todos los modelos de la tabla.

#### Prompt caching en Qwen

`qwen3.7-max` y `qwen3.6-flash` soportan caching explícito vía OpenRouter. La sintaxis es idéntica a la de Anthropic (ambos usan el campo `cache_control`), por lo que el código de la sección 5.3 funciona sin modificaciones si se migra a estos modelos.

#### Estrategia de migración progresiva

```
Semana 1: Validar routing con qwen3-235b-a22b-2507
  → Ejecutar 5 ciclos de selección de episodio
  → Comparar con output de Haiku: ¿selecciona el mismo episodio?
  → Si OK: migrar auditor también a Qwen

Semana 2: Validar executor con qwen3.6-plus
  → Ejecutar CLAIM-0002 completo con Qwen como executor
  → Auditar los artefactos con el auditor Python (no LLM)
  → Comparar con el output de Claude Sonnet: ¿convenciones correctas?
  → Si OK: migrar executor a Qwen

Semana 3+: Validar razonamiento científico con qwen3.7-max
  → Solo para episodios BRST/espectro (alta complejidad algebraica)
  → Esta validación puede tardar semanas — no urgente para MVP
```

---

## 6. Guardas de intervención humana — especificación completa

Esta sección define exactamente qué condiciones activan una guarda, qué mensaje se envía, qué opciones tiene el Físico, y qué hace el daemon con cada respuesta.

### G-01: Claim foundational TESTED_FAIL

**Condición:** Un claim de Fase 1 (foundational) tiene status `TESTED_FAIL` o `CONVENTION_MISMATCH`  
**Severidad:** CRÍTICO  
**Bloquea:** TODO el daemon  
**Mensaje:**
```
🚨 CRÍTICO: {claim_id} FALLIDO

{claim_id} es un claim foundational de Fase 1.
Un fallo aquí puede invalidar múltiples claims dependientes.

Residuo obtenido: {residuo}
Residuo esperado: 0

Opciones:
[A] Revisar convenciones — puede ser CONVENTION_MISMATCH
[B] Reformular el claim — el enunciado puede estar incorrecto
[C] Marcar como REFUTED y crear CLAIM alternativo
[D] Revisar manualmente (pausa indefinida)
```
**Respuesta A:** daemon relanza el episodio con instrucción de verificar convenciones primero  
**Respuesta B:** daemon relanza con prompt de "reformular enunciado antes de scripts"  
**Respuesta C:** daemon crea EVAL con status REFUTED y desbloquea claims alternativos si existen  
**Respuesta D:** pausa indefinida, daemon queda en WAITING_HUMAN

---

### G-02: Contradicción entre claims TESTED_PASS

**Condición:** Dos claims con status `TESTED_PASS` tienen enunciados lógicamente contradictorios (detectado por auditoría LLM de consistencia)  
**Severidad:** CRÍTICO  
**Bloquea:** TODO el daemon  
**Mensaje:**
```
🚨 CRÍTICO: Contradicción detectada

{claim_A} y {claim_B} tienen status TESTED_PASS pero sus
enunciados son potencialmente contradictorios.

{claim_A}: {enunciado_A}
{claim_B}: {enunciado_B}

Conflicto detectado: {descripción del conflicto}

Opciones:
[A] Revisar ambos claims — puede ser error de formulación
[B] Uno de los dos tiene error de convención — revisar
[C] Contradicción genuina — investigar consecuencias físicas
```

---

### G-03: Formulaciones científicas equivalentes

**Condición:** El agente ejecutor llama a `report_decision_needed()` porque detecta dos formulaciones válidas  
**Severidad:** DECISIÓN  
**Bloquea:** El episodio actual y los dependientes  
**Ejemplo:** CLAIM-0006 (BRST con ghost restringido vs. campos auxiliares)  
**Mensaje:** Ver ejemplo en sección 3.3

---

### G-04: Stall del orchestrator (MAX_REINTENTOS superado)

**Condición:** El mismo episodio falló N veces consecutivas (default: 3)  
**Severidad:** ALERTA  
**Bloquea:** Solo el episodio en cuestión  
**Mensaje:**
```
⚠️ ATENCIÓN: {episodio_id} falló {N} veces consecutivas

El laboratorio no pudo completar este episodio de forma autónoma.

Historial de intentos:
  Intento 1: {error_1}
  Intento 2: {error_2}
  Intento 3: {error_3}

Opciones:
[A] Continuar con siguiente episodio (skip temporario)
[B] Revisar el script manualmente — te envío los artefactos producidos
[C] Cambiar el enfoque del episodio (prompt diferente)
[D] Marcar como HUMAN_DECISION_REQUIRED y documentar
```

---

### G-05: Milestone de fase completado

**Condición:** Todos los claims de una fase del roadmap tienen status `TESTED_PASS`  
**Severidad:** INFO (no bloquea)  
**Acción:** Notifica el hito y presenta el próximo bloque  
**Respuesta esperada:** `/siguiente` para continuar o `/pausa` para revisar

---

### G-06: Corpus en estado estable (sin episodios disponibles)

**Condición:** No hay claims desbloqueados disponibles para ejecutar  
**Causas posibles:**
- Todos los claims disponibles están en WAITING_HUMAN
- El siguiente bloque requiere una decisión del Físico sobre qué preguntas abiertas priorizar
- Se completaron todos los episodios configurados  
**Mensaje:**
```
🔬 Laboratorio en estado estable

No hay episodios disponibles para ejecución autónoma.

Estado actual:
  Claims TESTED_PASS: {lista}
  Bloqueados (esperando PASS): {lista con sus deps}
  En WAITING_HUMAN: {lista}

Próximas opciones disponibles:
  [A] Lanzar Q-0001 BRST (requiere decisión previa — guarda G-03)
  [B] Continuar con Q-0002 espectro (depende de Q-0001)
  [C] Agregar nuevos episodios al config manualmente
```

---

### G-07: Modificación de Problema.tex detectada

**Condición:** El daemon detecta que `Problema.tex` fue modificado (comparando hash)  
**Severidad:** CRÍTICO  
**Bloquea:** TODO el daemon  
**Mensaje:**
```
🚨 CRÍTICO: Problema.tex modificado

El documento de autoridad fue modificado.
Esto puede invalidar convenciones y claims existentes.

Hash anterior: {hash_anterior}
Hash actual: {hash_actual}

El laboratorio está pausado. Acción requerida:
[A] Modificación intencional — registrar en decisions/ y continuar
[B] Modificación accidental — restaurar versión anterior
```

---

## 7. Preguntas abiertas para el ingeniero de software

Estas preguntas deben ser respondidas antes o durante la implementación del MVP. Están ordenadas por impacto en el diseño.

---

### Arquitectura y diseño

**Q-SW-001:** ¿El daemon corre como proceso permanente (`while True: dormir(N)`) o como job batch (cron / systemd timer)? La diferencia afecta la gestión de estado entre ciclos, el recovery ante crashes, y cómo el bot Telegram mantiene la conexión.

**Q-SW-002:** ¿El daemon y el bot Telegram corren en el mismo proceso (async) o como dos procesos separados que se comunican por IPC (socket, queue, archivo de estado)? El diseño async simplifica el código pero complica el debugging; IPC lo hace más robusto pero más complejo.

**Q-SW-003:** ¿Cómo se maneja el estado del daemon entre reinicios? Si se cae durante la ejecución de un episodio, ¿cómo sabe si el LLM ya escribió artefactos parciales? Opciones: (a) detectar artefactos sin EVAL correspondiente al iniciar, (b) lockfile por episodio, (c) estado en archivo JSON separado.

**Q-SW-004:** ¿Cómo se implementa el "modo agresivo" con múltiples claims en paralelo si los tools del LLM (create_file, run_cadabra2) son operaciones sobre el mismo filesystem? ¿Es necesario un sistema de locks por archivo, o los claims independientes garantizan que no hay conflictos de escritura?

---

### LLM y prompts

**Q-SW-005:** ¿Qué modelo LLM usar para el MVP? Claude Sonnet 3.5 es un buen candidato (buen balance costo/calidad para tareas de código estructurado), pero Claude Opus puede ser necesario para el razonamiento algebraico complejo de BRST. ¿Se usa un modelo único o diferente según el tipo de episodio?

**Q-SW-006:** ¿Cómo se maneja el context window cuando el corpus crece? Con 30+ claims, el prompt puede superar los límites del modelo. Opciones: (a) incluir solo las deps directas, no todo el corpus; (b) summarización automática de claims distantes; (c) RAG (retrieval) del corpus por relevancia.

**Q-SW-007:** ¿Se mantiene un historial de conversación dentro de un episodio (multi-turn) o cada episodio es un prompt único? Multi-turn permite al LLM razonar iterativamente pero aumenta el costo; single-turn es más barato pero requiere que el LLM resuelva todo en una sola respuesta.

**Q-SW-008:** ¿Cómo se verifica que el LLM no alucinó el residuo? El agente dice "Residuo: 0" pero ¿realmente ejecutó el script? Es necesario que el tool `run_cadabra2` retorne el stdout real y que el auditor verifique consistencia entre el output del tool y lo que el LLM escribió en el REPORT.

---

### Corpus y filesystem

**Q-SW-009:** ¿Cómo parsear de forma robusta el YAML frontmatter de los artefactos `.md`? Los artefactos son archivos con YAML entre `---` seguido de contenido Markdown. Si el LLM produce YAML malformado, ¿el daemon rechaza todo el episodio o intenta recuperar lo que pueda?

**Q-SW-010:** ¿Cómo detectar si un artefacto es un template vs. un artefacto real? Los templates tienen nombre como `CLAIM_TEMPLATE.md`. ¿Es suficiente verificar si el filename contiene `TEMPLATE`, o se necesita un campo `is_template: true` en el YAML?

**Q-SW-011:** ¿Cómo manejar el versionado de los scripts? Si el daemon ejecuta `SCRIPT-CADABRA-0002.cdb` y produce `REPORT-0002.md`, pero luego se detecta un error y se crea `SCRIPT-CADABRA-0002-v2.cdb`, ¿cómo sabe el daemon qué versión del script corresponde a qué REPORT?

---

### Seguridad y robustez

**Q-SW-012:** ¿Qué pasa si el LLM intenta usar `create_file` para escribir fuera del corpus (e.g., `../../etc/passwd`)? El validador del tool debe verificar que el path esté dentro del `CORPUS_ROOT` y en una carpeta permitida. ¿Hay otras operaciones de filesystem que el LLM podría intentar que necesitan ser bloqueadas?

**Q-SW-013:** ¿Cuál es el timeout máximo para Cadabra2 y SageMath? Scripts complejos pueden tardar minutos. Si el script entra en un loop infinito (posible si el LLM genera código incorrecto), ¿cómo lo detecta el daemon y cómo lo reporta?

**Q-SW-014:** ¿Cómo se evita que el daemon genere costos de API descontrolados? Si hay un bug que hace que el daemon lance episodios en loop, la factura de Claude puede crecer rápido. ¿Se implementa un rate limiter, un budget diario, o un circuit breaker que pause ante anomalías de uso?

---

### Testing

**Q-SW-015:** ¿Cómo se testea el daemon sin gastar API credits? Opciones: (a) mock del cliente LLM que retorna respuestas predefinidas, (b) modo dry-run que imprime los prompts sin enviarlos, (c) usar el free tier de un modelo más barato para desarrollo.

**Q-SW-016:** ¿Cómo se testea el auditor? Se necesita un corpus de prueba con artefactos válidos e inválidos para verificar que el auditor detecta correctamente cada tipo de violación.

---

### MCP, A2A y optimización

**Q-SW-017:** ¿El servidor MCP custom (`mcp_server_quantpostrs.py`) corre como subproceso del daemon (lanzado por el cliente MCP de `anthropic`) o como proceso separado escuchando un socket? El SDK oficial de MCP soporta ambos modos (stdio y SSE); para el MVP, stdio es más simple porque no requiere puertos ni autenticación.

**Q-SW-018:** ¿Es aceptable depender de `npx` (Node.js) para correr el `mcp-server-filesystem` oficial? Alternativa: reimplementar las tools de filesystem dentro del servidor MCP custom (~30 líneas), eliminando la dependencia de Node.

**Q-SW-019:** Para el prompt caching de Anthropic, ¿qué hacer cuando el corpus context (claims TESTED_PASS) cambia entre un episodio y el siguiente? El cache se invalida y el siguiente request paga full price. ¿Conviene cachear solo los claims foundational (que no cambian) y mantener los recién añadidos fuera del cache?

**Q-SW-020:** ¿Cómo medir el costo real de cada episodio para alimentar el `CostCircuitBreaker`? La API de Anthropic retorna `usage.input_tokens` y `usage.output_tokens` por response, pero hay que distinguir tokens cacheados (`cache_creation_input_tokens`, `cache_read_input_tokens`) que tienen pricing distinto. ¿Hay una librería que ya hace este cálculo, o se implementa custom?

**Q-SW-021:** ¿El modelo router (Haiku) puede equivocarse al seleccionar el próximo episodio? Si Haiku elige mal, se desperdicia una llamada a Sonnet en un episodio incorrecto. ¿Conviene que el router sea determinístico (Python puro sobre el grafo de dependencias) y solo usar LLM para casos ambiguos?

**Q-SW-022:** Con Batch API, los resultados llegan asincrónicamente en hasta 24h. ¿Cómo notifica el daemon al Físico que un batch está listo? ¿Hay un poller que revisa el estado cada N minutos, o se usa webhook? ¿Qué pasa si el Físico pide `/estado` y hay episodios en batch pendientes — cómo se reportan?

**Q-SW-023:** ¿Instructor / Pydantic AI manejan bien outputs muy largos como un script Cadabra2 completo (puede ser 80+ líneas dentro de un campo string)? ¿O conviene que el LLM genere los scripts via tool calls (`write_file`) en lugar de devolverlos en el response estructurado?

**Q-SW-024:** Si en el futuro se migra a un modelo local (Llama, DeepSeek), ¿el servidor MCP custom funciona sin cambios? Los modelos open source de 2026 soportan MCP via Ollama, pero la calidad de razonamiento algebraico puede no ser suficiente. ¿Cuál es el plan de contingencia si Anthropic sube precios drasticamente?

---

## 8. Preguntas abiertas para el físico

Estas preguntas deben ser respondidas antes de que el daemon pueda operar correctamente. Algunas son prerrequisitos técnicos; otras son decisiones científicas que afectan la arquitectura del sistema.

---

### Prerrequisitos para el daemon

**Q-FIS-001:** ¿CLAIM-0006 (nilpotencia BRST) puede formularse de forma única, o requiere elegir entre ghost restringido y campos auxiliares? Esta pregunta determina si el episodio CLAIM-0006 puede ejecutarse de forma autónoma o si siempre va a requerir la guarda G-03. Si la respuesta es "siempre requiere decisión", conviene agregar un campo `requiere_decision_previa: true` en `episodios_config.yaml` para que el daemon nunca lo intente de forma autónoma.

**Q-FIS-002:** ¿Cuál es el criterio preciso para que una evaluación sea `TESTED_PASS` vs `TESTED_PARTIAL` cuando Cadabra2 retorna términos no simplificados? El script Cadabra2 a veces retorna expresiones algebraicamente equivalentes a cero pero que no se ven como `0`. ¿El agente debe intentar simplificación adicional, o `TESTED_PARTIAL` es el status correcto? Esto afecta directamente la lógica del auditor.

**Q-FIS-003:** Para los mutation tests, ¿qué mutaciones son obligatorias para cada tipo de claim? CLAIM-0001 tiene mutaciones claras (cambiar `b`). ¿Cuáles son las mutaciones mínimas para CLAIM-0002 (H_{μν}), CLAIM-0003 (covariancia EM), CLAIM-0004 (invariancia de contacto)? Sin esta lista, el agente puede generar mutation tests insuficientes.

**Q-FIS-004:** ¿La invariancia de contacto en CLAIM-0004 es verificable algebraicamente con las herramientas actuales, o requiere conocer la forma explícita del operador `Λ^{μν}_{-1/2}`? Si `Λ^{μν}_{-1/2}` no está implementado en SageMath, el claim no puede tener un script Sage válido. ¿Hay una representación matricial de `Λ^{μν}_{-1/2}` disponible en la tesis?

---

### Decisiones científicas que afectan la priorización

**Q-FIS-005:** ¿CLAIM-0005 (sanidad q=0) puede ejecutarse sin TESTED_PASS en CLAIM-0001 y CLAIM-0002? El `episodios_config.yaml` lo marca como independiente, pero ¿es realmente independiente o necesita que los bloques W_μ y H_{μν} estén verificados para que la interpretación del resultado sea válida?

**Q-FIS-006:** En el roadmap actual, CLAIM-0003 (covariancia EM) depende de CLAIM-0001 y CLAIM-0002. ¿También depende de CLAIM-0005? Si la covariancia EM de W_μ en presencia de un fondo A_μ requiere que el sector libre esté verificado, la dependencia existe aunque no esté en el grafo actual.

**Q-FIS-007:** ¿Existe un claim "CLAIM-0000" implícito — la verificación de que las convenciones fijas del proyecto (`AGENTS.md`) son consistentes entre sí? Por ejemplo: ¿las definiciones de `D_μ`, `F_{μν}` y `[D_μ, D_ν]` en `AGENTS.md` son mutuamente consistentes bajo `η = diag(+1,-1,-1,-1)`? Esto debería ser el primer script que corra el daemon al inicializarse.

---

### Criterios de terminación y cierre científico

**Q-FIS-008:** ¿Cuáles son exactamente los claims `TESTED_PASS` mínimos necesarios para que el Físico pueda declarar `FUNDAMENTAL_FIELD_CANDIDATE`? La definición en `docs/coordinacion_agentica_propuesta/FISICO.md` dice "cierre bajo renormalización o argumento fuerte de completitud" — ¿esto requiere Q-0007 y Q-0008 en `TESTED_PASS`, o es suficiente un argumento analítico documentado en `interpretations/`?

**Q-FIS-009:** ¿La clasificación `EFFECTIVE_FIELD_THEORY` puede ser un resultado científicamente satisfactorio para el proyecto, o es considerada un "fracaso parcial"? La respuesta afecta cómo el Físico usa las notificaciones de milestone — si EFT es un resultado aceptable, el daemon puede notificarlo como milestone positivo; si es un fracaso, la notificación debe ser de tipo ALERTA.

**Q-FIS-010:** ¿Hay preguntas abiertas (Q-0001 a Q-0009) que el Físico considera "no urgentes" y que pueden postergarse indefinidamente sin afectar la investigación principal? Si Q-0007 (renormalizabilidad) y Q-0008 (anomalías BRST) son opcionales en el contexto del MVP, el daemon puede ignorarlos en la primera implementación.

---

### Sobre el funcionamiento de las herramientas

**Q-FIS-011:** ¿El output de Cadabra2 para residuo cero es siempre el string `"0"`, o puede ser `"0 * (expresión)"` o expresiones simbólicamente equivalentes a cero? La función `parsear_residuo_cadabra` del daemon necesita manejar todos los casos posibles de "cero algebraico" que Cadabra2 puede producir.

**Q-FIS-012:** Para los scripts SageMath de este proyecto, ¿el output de residuo siempre tiene el formato `Residuo: [0, 0, 0, 0]`? ¿O varía según el tipo de claim? El daemon necesita un contrato de output estable para poder parsear los resultados de forma robusta. Si el formato varía, hay que definir un contrato explícito que los scripts deben cumplir.

**Q-FIS-013:** ¿Cadabra2 puede ejecutarse en modo no-interactivo con `cadabra2 --noninteractive script.cdb` en tu instalación? ¿O requiere un entorno gráfico? Si Cadabra2 necesita display, el daemon puede necesitar un servidor virtual X (Xvfb) para correr de forma autónoma sin monitor.

**Q-FIS-014:** ¿Cuánto tarda típicamente un script Cadabra2 o SageMath en este proyecto? Los timeouts del daemon (120 segundos por defecto) son razonables para los scripts actuales, pero pueden ser insuficientes para claims más complejos (espectro, BRST completo). ¿Hay una estimación de los scripts futuros?

---

### Sobre el modelo de episodios

**Q-FIS-015:** ¿Qué pasa si el daemon produce un claim con un enunciado algebraicamente correcto pero físicamente trivial o sin interés? ¿Hay un criterio de "valor físico mínimo" que el Físico pueda comunicarle al daemon como constraint en el prompt del episodio, o la evaluación de valor físico siempre requiere revisión humana?

**Q-FIS-016:** ¿El daemon puede generar claims nuevos no previstos en `episodios_config.yaml`, si detecta que una cadena de razonamiento intermedia requiere un lemma no listado? ¿O debe limitarse estrictamente a los episodios configurados? Esta decisión define si el sistema es "exploratorio" (más autónomo, más riesgo) o "ejecutor" (más controlado, más predecible).

---

## 9. Plan de implementación por fases

### Fase 0 — Fundamentos (1-2 días)
**Objetivo:** Tener el corpus legible de forma programática, MCP servers configurados, y el bot básico funcionando.

```
[ ] uv init + pyproject.toml con dependencias core
[ ] corpus_reader.py: parsear claims/, evaluations/, open_questions/ con Pydantic
[ ] test_corpus_reader.py: verificar parsing correcto con artefactos existentes
[ ] mcp_server_quantpostrs.py: stub con run_cadabra2 y run_sagemath
[ ] Configurar mcp-server-filesystem oficial via npx con sandbox al CORPUS_ROOT
[ ] Verificar que un cliente MCP de prueba puede leer/escribir al corpus
[ ] telegram_bot.py: /estado que retorna el corpus leído
[ ] .env.example + pydantic-settings para configuración
[ ] Responder Q-FIS-013 (Cadabra2 no-interactivo)
[ ] Responder Q-SW-017 y Q-SW-018 (modo MCP transport)
```

### Fase 1 — Daemon mínimo con caching (2-3 días)
**Objetivo:** El daemon puede seleccionar y ejecutar un episodio completo con supervisión humana en cada paso, ya con optimización de costos activa.

```
[ ] episodios_config.yaml: roadmap completo con flag usar_batch_api
[ ] episode_runner.py: prompt builder con cache_control para system + corpus
[ ] ModelRouter: Haiku para routing/auditor, Sonnet para executor
[ ] CostCircuitBreaker con DAILY_BUDGET_USD y persistencia en JSON
[ ] instructor + ClaimArtifact Pydantic model para outputs estructurados
[ ] auditor.py: verificaciones básicas (YAML válido, no editar existentes)
[ ] daemon.py: loop con confirmación Telegram antes de cada episodio
[ ] Telegram /costo: muestra gasto del día y proyección mensual
[ ] Responder Q-FIS-002 (criterio PARTIAL vs PASS en Cadabra2)
[ ] Responder Q-FIS-003 (mutation tests mínimas por tipo de claim)
[ ] Responder Q-SW-019 y Q-SW-020 (estrategia de cache y medición de costos)
```

### Fase 2 — Guardas completas (2-3 días)
**Objetivo:** El daemon puede operar sin supervisión en episodios rutinarios y escalar al Físico solo cuando es necesario.

```
[ ] trigger_detector.py: G-01 a G-07 implementadas
[ ] telegram_bot.py: notificaciones estructuradas por nivel
[ ] telegram_bot.py: comandos /pausa, /reanudar, /resultado
[ ] daemon.py: state machine completo
[ ] Responder Q-SW-003 (recovery ante crashes)
[ ] Responder Q-FIS-001 (CLAIM-0006 autónomo o con guarda)
```

### Fase 3 — Producción del primer episodio real (1 día)
**Objetivo:** El daemon completa MUTATION-CLAIM-0001 de forma autónoma.

```
[ ] Ejecutar el daemon en modo supervisado (confirmación antes de cada paso)
[ ] Verificar que el mutation test de CLAIM-0001 produce TESTED_PASS
[ ] Verificar que el corpus queda en estado correcto
[ ] Responder Q-FIS-011 y Q-FIS-012 (contratos de output)
```

### Fase 4 — Autonomía completa (ongoing)
**Objetivo:** El daemon corre de forma autónoma, el Físico solo interviene ante guardas.

```
[ ] Activar modo autónomo (sin confirmación por episodio)
[ ] Implementar modo agresivo para claims paralelos
[ ] Implementar working/daemon_log_YYYYMMDD.md
[ ] Dashboard de estado via /estado enriquecido
[ ] Responder Q-FIS-008 y Q-FIS-009 (criterios de cierre científico)
```

---

*Documento generado el 26-05-2026 en sesión de brainstorming con Carson (BMad CIS Brainstorming Specialist). Basado en: sesión fundacional ChatGPT `6a15fe56`, `analisis.md`, `FISICO.md`, `master_agent.md`, `AGENTS.md`, `FORMAL_METHODS_GUIDE.md`.*
