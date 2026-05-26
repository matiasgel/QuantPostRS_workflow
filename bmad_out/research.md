---
id: RESEARCH-INPUT-0001
type: research_input
title: Documento de entrada — Estado del corpus y hoja de ruta QuantPostRS
status: active
created: 2026-05-26
author: GitHub Copilot
purpose: >
  Documento de entrada consolidado para agentes. Resume el problema físico, las
  convenciones fijas, el estado actual del corpus, el grafo de dependencias de las 9
  preguntas abiertas, los próximos claims a formalizar y la estrategia de ejecución
  en paralelo. Cargar este archivo en contexto antes de cualquier tarea de
  investigación o implementación.
source_of_truth: Problema.tex
corpus_folders:
  - claims/
  - scripts/
  - reports/
  - evaluations/
  - interpretations/
  - decisions/
  - open_questions/
---

# research.md — Entrada de investigación QuantPostRS

## 0. Cómo usar este documento

Este archivo es el **punto de entrada** para cualquier agente que trabaje en el
repositorio. Contiene toda la información necesaria para entender el problema físico,
las reglas del corpus y las tareas pendientes **sin necesidad de leer el corpus
completo**. Para detalles matemáticos completos, consultar `Problema.tex`.

---

## 1. Problema físico — descripción ejecutiva

**Objetivo:** construir y verificar formalmente una teoría de campo para un
vector-espinor cargado masivo $\Psi_\mu$ (campo de Rarita-Schwinger Post-RS, spin
3/2) acoplado a electromagnetismo, libre de inconsistencias de Velo-Zwanziger
(propagación superlumínica y modos fantasma).

**Dificultad central:** los campos de spin alto (s ≥ 1) acoplados a gauge producen
en general modos no físicos y violaciones de causalidad al encender el campo de fondo
$F_{\mu\nu}$. La tesis (Capítulo 8 de `Problema.tex`) propone una solución mediante:
1. Simetría tipo Stueckelberg para desacoplar el modo escalar $\chi$.
2. Bloques invariantes $\mathcal{W}_\mu$ y $\mathcal{H}_{\mu\nu}$ que absorben la
   dependencia de calibre.
3. Un Lagrangiano con coeficiente fijo $\alpha = \sqrt{2/3}$ que elimina las
   inconsistencias conocidas.

**Estado actual:** la teoría está formulada pero los verificadores formales han
completado solo una prueba trivial (CLAIM-0001). Las 9 preguntas abiertas que
constituyen el programa de investigación siguen sin demostrar.

---

## 2. Convenciones fijas — INMUTABLES

> Ningún script, claim o decisión puede contradecir estas convenciones sin crear
> una entrada en `decisions/` con justificación explícita.

| Símbolo | Definición |
|---------|-----------|
| Métrica | $\eta = \mathrm{diag}(+1,-1,-1,-1)$ |
| Álgebra de Clifford | $\{\gamma^\mu, \gamma^\nu\} = 2\,\eta^{\mu\nu}\,\mathbb{1}$ |
| Derivada covariante | $D_\mu = \partial_\mu - \mathrm{i}\,q\,A_\mu$ |
| Conmutador covariante | $[D_\mu, D_\nu]\,X = -\mathrm{i}\,q\,F_{\mu\nu}\,X$ |
| Constancia de gammas | $D_\mu\gamma^\nu = 0$ |
| Slash | $\slashed{D} = \gamma^\mu D_\mu$ |
| Subida/bajada | $X^\mu = \eta^{\mu\nu}X_\nu$, $X_\mu = \eta_{\mu\nu}X^\nu$ |
| Coeficiente b | $b = \tfrac{1}{m}\sqrt{\tfrac{2}{3}}$ |

**Coeficientes que conmutan con matrices gamma:** $D_\mu$, $m$, $q$, $b$ y
cualquier escalar, salvo indicación explícita contraria.

---

## 3. Bloques fundamentales — definiciones de `Problema.tex`

### 3.1 Campo de Stueckelberg $\mathcal{W}_\mu$

$$\mathcal{W}_\mu = \Psi_\mu - b\,D_\mu\chi$$

Transformación Stueckelberg (parámetro local $\xi$, sin restricción en la teoría
cargada):
$$\delta_S\chi = \xi, \qquad \delta_S\Psi_\mu = b\,D_\mu\xi, \qquad \delta_S A_\mu = 0$$

Invariancia: $\delta_S\mathcal{W}_\mu = 0$ ← **CLAIM-0001** (TESTED_PASS, trivial).

### 3.2 Tensor de campo $\mathcal{H}_{\mu\nu}$

$$\mathcal{H}_{\mu\nu} = D_\mu\mathcal{W}_\nu - D_\nu\mathcal{W}_\mu$$

Equivalente a: $\mathcal{H}_{\mu\nu} = D_\mu\Psi_\nu - D_\nu\Psi_\mu - \mathrm{i}\,q\,b\,F_{\mu\nu}\,\chi$

Invariancia esperada bajo Stueckelberg: usa $[D_\mu, D_\nu] = -\mathrm{i}qF_{\mu\nu}$
de forma no trivial ← **CLAIM-0002** (pendiente, first non-trivial claim).

### 3.3 Lagrangiano de la tesis (acción minimal)

$$\mathcal{L} = \bar{\mathcal{W}}^\mu\bigl[\ldots\bigr]\mathcal{W}_\mu + \ldots$$

con $\alpha = \sqrt{2/3}$ fijado por consistencia (ver `Problema.tex` ec. 8.x).

### 3.4 Operador $\Lambda^{\mu\nu}_{-1/2}$ (invariancia de contacto)

$$\Lambda^{\mu\nu}_{-1/2} = g^{\mu\nu} - \tfrac{1}{4}\gamma^\mu\gamma^\nu$$

Propiedad clave: $\Lambda\,\gamma_\nu = 0$, que garantiza que el acoplamiento sea
insensible a transformaciones $\delta_C\Psi_\mu = \gamma_\mu\epsilon$.

---

## 4. Estado actual del corpus

### 4.1 Artefactos existentes

| Artefacto | Tipo | Estado |
|-----------|------|--------|
| `CLAIM-0001` | Claim | `TESTED_PASS` ⚠️ trivial |
| `SCRIPT-CADABRA-0001` | Script | `b·X - b·X = 0` — tautología |
| `SCRIPT-SAGE-0001` | Script | `b·Dxi[mu] - b·Dxi[mu]` — tautología |
| `REPORT-0001` | Report | residuo `[0,0,0,0]` — por tautología |
| `EVAL-0001` | Eval | `TESTED_PASS` ⚠️ sin mutation tests |
| `DECISION-0001` | Decision | corpus distribuido, artefactos inmutables |
| `Q-0001` ... `Q-0009` | Questions | todas `OPEN` |

### 4.2 Advertencia sobre CLAIM-0001

Los scripts actuales verifican la identidad `b·X - b·X = 0` por construcción
algebraica directa, sin usar el conmutador covariante ni ninguna identidad no trivial.
El `TESTED_PASS` es formalmente correcto pero no audita ninguna física real.
La invariancia de $\mathcal{W}_\mu$ es trivial dado que se definió para ser invariante.
El primer claim no trivial es **CLAIM-0002** (invariancia de $\mathcal{H}_{\mu\nu}$).

---

## 5. Las 9 preguntas abiertas

### 5.1 Tabla de preguntas y dependencias

| ID | Título | Deps | Prioridad | Tools |
|----|--------|------|-----------|-------|
| **Q-0001** | Simetría restringida vs. off-shell | — | 🔴 Alta | Cadabra2 + SageMath |
| **Q-0002** | Espectro cuántico y positividad | Q-0001 | 🔴 Alta | SageMath + Cadabra2 |
| **Q-0003** | Matching con sector libre (sanidad q→0) | Q-0001, Q-0002 | 🔴 Alta (sanidad temprana) | SageMath |
| **Q-0004** | Causalidad en fondos EM | Q-0001, Q-0002 | 🔴 Alta | SageMath + Cadabra2 |
| **Q-0005** | Base de operadores no minimales | — | 🟡 Media | Cadabra2 |
| **Q-0006** | Coeficientes no minimales (dinámicos) | Q-0004, Q-0005 | 🟡 Media | SageMath + Cadabra2 |
| **Q-0007** | Renormalizabilidad del modelo minimal | Q-0002, Q-0005 | 🟡 Media | Cadabra2 + SageMath |
| **Q-0008** | Estabilidad radiativa y anomalías BRST | Q-0001, Q-0005, Q-0007 | 🟡 Media | Cadabra2 + SageMath |
| **Q-0009** | Interpretación UV o EFT | Q-0002, Q-0004, Q-0007, Q-0008 | 🟢 Baja | Cadabra2 + SageMath |

### 5.2 Grafo de dependencias

```
Q-0005 (independiente)
  │
  ├──► Q-0006 ◄── Q-0004 ◄──┐
  │                           │
  └──► Q-0007 ◄── Q-0002 ◄──┤
         │                   │
         └──► Q-0008 ◄── Q-0001 (raíz del árbol principal)
                   │         │
                   └──► Q-0009 ◄── Q-0004, Q-0007
                             │
                         (síntesis final)

Q-0001 ──► Q-0002 ──► Q-0003 (sanidad)
      │
      └──► Q-0004 ──► Q-0006 ──► (coeficientes no minimales)
```

### 5.3 Descripción física por pregunta

**Q-0001 — Simetría restringida vs. off-shell** (líneas 1141–1153 de `Problema.tex`)
- La tesis formula la simetría Stueckelberg con restricción `∂̸ξ = 0` (sector libre).
- En la teoría cargada no está claro si la restricción persiste o si se levanta
  con campos auxiliares → ¿BRST con ghost restringido o simetría off-shell limpia?
- **Esta pregunta es el cuello de botella del 80% del pipeline.**

**Q-0002 — Espectro cuántico y positividad** (líneas 1155–1159)
- El espacio físico debe contener exactamente 4 polarizaciones (partícula de spin 3/2
  masiva) con norma positiva.
- Los modos de spin 1/2 ($\chi$, $\gamma\cdot\mathcal{W}$) y los ghosts deben ser
  BRST-exactos (no aparecen como polos físicos independientes).

**Q-0003 — Matching con sector libre** (líneas 1161–1165) — sanidad temprana
- En el límite $q \to 0$, $A_\mu \to 0$: la teoría debe reducirse a una partícula
  masiva de spin 3/2 pura (Rarita-Schwinger libre).
- **Independiente de la solución completa de Q-0001** si se verifica solo el límite.
- Candidato a ejecutarse en Track A paralelo (SageMath únicamente).

**Q-0004 — Causalidad en fondos EM** (líneas 1167–1171)
- Mecanismo Velo-Zwanziger: campos de spin alto en fondos EM pueden propagarse
  fuera del cono de luz → la teoría es acausal.
- El Lagrangiano de la tesis (con α=√(2/3)) debe eliminar este problema.
- Análisis del símbolo principal bajo $D_\mu \to n_\mu$.

**Q-0005 — Base de operadores no minimales** (líneas 1173–1177) — independiente
- Construir lista exhaustiva de operadores de baja dimensión compatibles con:
  U(1)_em + simetría Stueckelberg + invariancia de contacto.
- Bloques constructivos: $\mathcal{W}_\mu$, $\mathcal{H}_{\mu\nu}$, $F_{\mu\nu}$, $D_\mu$.
- **Candidato a Track B paralelo (Cadabra2 únicamente).**

**Q-0006 — Coeficientes no minimales** (líneas 1179–1182)
- ¿La dinámica (causalidad, positividad, UV) fija los coeficientes de los operadores de Q-0005?

**Q-0007 — Renormalizabilidad** (líneas 1184–1187)
- ¿La acción minimal es cerrada bajo renormalización o es una EFT?
- Requiere propagadores gauge-fijados y comportamiento UV.

**Q-0008 — Anomalías BRST** (líneas 1189–1192)
- ¿La simetría BRST es libre de anomalías a nivel de loops?
- ¿Los loops generan operadores compatibles pero ausentes del ansatz minimal?

**Q-0009 — Interpretación UV/EFT** (líneas 1194–1197)
- Síntesis final: ¿completación UV o EFT con escala de corte?

---

## 6. Próximos claims a formalizar

Los claims están ordenados por dependencias y valor formal decreciente.

### CLAIM-0002 — Invariancia Stueckelberg de $\mathcal{H}_{\mu\nu}$

**Claim:** $\delta_S\mathcal{H}_{\mu\nu} = 0$ bajo transformación Stueckelberg con $\delta_S A_\mu = 0$.

**Residuo esperado:** (primer claim no trivial)
$$\delta_S\mathcal{H}_{\mu\nu}
= \underbrace{-\mathrm{i}q\,b\,F_{\mu\nu}\,\xi}_{\text{de } [D_\mu, D_\nu]\xi}
+ \underbrace{\mathrm{i}q\,b\,F_{\mu\nu}\,\xi}_{\text{de } \delta_S(-\mathrm{i}qb\,F_{\mu\nu}\chi)}
= 0$$

**Por qué es no trivial:** usa explícitamente el conmutador $[D_\mu, D_\nu] = -\mathrm{i}qF_{\mu\nu}$.
Sin esta identidad el residuo no es cero. Cadabra2 debe formalizarla.

**Dependencias para TESTED_PASS:** CLAIM-0001 (base), convenciones AGENTS.md.

**Scripts necesarios:**
- `SCRIPT-CADABRA-0002`: definir $\mathcal{H}_{\mu\nu}$, aplicar $\delta_S$, usar regla del conmutador, verificar residuo = 0.
- `SCRIPT-SAGE-0002`: matrices gamma 4×4, F_{μν} simbólico, verificar residuo matricial = 0.
- `SCRIPT-SAGE-WEYL-0002` (opcional): cross-check con representación de Weyl.

**Mutation tests requeridos:** mutar el signo de $F_{\mu\nu}$, mutar el coeficiente $b$, omitir el término $-\mathrm{i}qb\chi$ en la definición de $\mathcal{H}$. Cada mutación debe producir residuo ≠ 0.

---

### CLAIM-0003 — Covariancia EM de $\mathcal{W}_\mu$ y $\mathcal{H}_{\mu\nu}$

**Claim:** bajo transformación U(1)_em $\delta_{U(1)}\Psi_\mu = \mathrm{i}q\alpha_x\Psi_\mu$,
$\delta_{U(1)}\chi = \mathrm{i}q\alpha_x\chi$, $\delta_{U(1)}A_\mu = \partial_\mu\alpha_x$:

$$\delta_{U(1)}\mathcal{W}_\mu = \mathrm{i}q\alpha_x\,\mathcal{W}_\mu, \qquad
\delta_{U(1)}\mathcal{H}_{\mu\nu} = \mathrm{i}q\alpha_x\,\mathcal{H}_{\mu\nu}$$

**Dependencias:** CLAIM-0002.

---

### CLAIM-0004 — Invariancia de contacto ($\Lambda$-invariancia)

**Claim:** la acción es invariante bajo $\delta_C\Psi_\mu = \gamma_\mu\epsilon$ por la
propiedad $\Lambda^{\mu\nu}_{-1/2}\gamma_\nu = 0$.

**Residuo esperado:**
$$\delta_C\mathcal{L} \propto \bar{\mathcal{W}}^\mu\Lambda_{\mu\nu}\,\gamma^\nu\epsilon + \text{c.c.} = 0$$

**Dependencias:** CLAIM-0001, CLAIM-0003.

---

### CLAIM-0005 — Sanidad $q\to0$: sector libre spin 3/2 (Track A independiente)

**Claim:** en el límite $q=0$, $A_\mu=0$, las ecuaciones de movimiento de la acción
minimal se reducen a las de Rarita-Schwinger libre:
$$(i\slashed{\partial} - m)\Psi_\mu = 0, \qquad \partial^\mu\Psi_\mu = 0, \qquad \gamma^\mu\Psi_\mu = 0$$

**Por qué es ejecutable ahora:** NO depende de Q-0001. Es un test de sanidad
puro sobre la acción.

**Tool:** SageMath únicamente.

**Mutation tests:** mutar $\alpha$ (usar valor ≠ √(2/3)), mutar $m$. El match con Rarita-Schwinger debe romperse.

---

### CLAIM-0006 — Nilpotencia BRST $Q^2 = 0$ (Track C, desbloqueado por CLAIM-0002)

**Claim:** el operador BRST $Q$ satisface $Q^2 = 0$ sobre el espacio de campos
$({\Psi_\mu, \chi, c, \bar{c}, B})$ con las transformaciones definidas en `Problema.tex`.

**Dependencias:** CLAIM-0001, CLAIM-0002, CLAIM-0003, CLAIM-0004.

---

### CLAIM-0007 — Operador Pauli respeta las 3 simetrías (Track B independiente)

**Claim:** el término $\mathrm{i}q\kappa F_{\mu\nu}\bar{\mathcal{W}}^\mu\mathcal{W}^\nu$
es invariante bajo U(1)_em, Stueckelberg e invariancia de contacto.

**Tool:** Cadabra2 únicamente.

**Dependencias:** CLAIM-0002, CLAIM-0003.

---

## 7. Estrategia de ejecución paralela

```
ESTADO ACTUAL
    │
    ├── EJECUTABLE AHORA (sin dependencias pendientes):
    │     ├── TRACK A: CLAIM-0005 (sanidad q=0, SageMath, ~1-2 días)
    │     └── TRACK B: CLAIM-0007 (operador Pauli, Cadabra2, ~3-5 días)
    │
    └── TRACK C (secuencial, cadena principal BRST):
          CLAIM-0002 → CLAIM-0003 → CLAIM-0004 → CLAIM-0006
          (~semanas, desbloquea Q-0002)
          
DESBLOQUEOS:
  CLAIM-0005 PASS → evidencia para Q-0003 (sanidad)
  CLAIM-0006 PASS + CLAIM-0005 PASS → Q-0002 (espectro)
  CLAIM-0007 PASS → contribución a Q-0005 (base de operadores)
```

**Regla clave de paralelismo:** un agente puede comenzar cualquier CLAIM cuyos
`depends_on` estén todos en estado `TESTED_PASS`. Los Tracks A y B están libres
ahora mismo.

---

## 8. Reglas de corpus — resumen operacional

1. **Artefactos inmutables:** nada en `claims/`, `evaluations/`, `reports/`,
   `interpretations/`, `decisions/`, `open_questions/` puede editarse ni borrarse.
   Solo se crean artefactos nuevos (con `supersedes:` si corresponde).

2. **`Problema.tex` nunca cambia.** Es la especificación autorizada.

3. **TESTED_PASS requiere:** residuo = 0 en Cadabra2 **Y** en SageMath **Y**
   mutation tests documentados (campo `mutation_tests_report:` no vacío en EVAL).

4. **Solo TESTED_PASS puede usarse como premisa** para claims subsiguientes.

5. **Prohibido:** ajustar scripts para eliminar el residuo cambiando definiciones
   originales. Los mutation tests deben detectar artificios.

6. **Numeración de artefactos:** CLAIM-XXXX, SCRIPT-CADABRA-XXXX, SCRIPT-SAGE-XXXX,
   REPORT-XXXX, EVAL-XXXX, INTERP-XXXX, con XXXX = número de 4 dígitos en secuencia.

---

## 9. Comandos de ejecución (verificados)

```bash
# Ejecutar script Cadabra2
env MPLCONFIGDIR=/tmp/mpl-cadabra cadabra2 scripts/cadabra/SCRIPT-CADABRA-XXXX.cdb

# Ejecutar script SageMath
env DOT_SAGE=/tmp/sage-dot sage scripts/sage/SCRIPT-SAGE-XXXX.sage
```

---

## 10. Referencias al corpus completo

| Documento | Uso |
|-----------|-----|
| `Problema.tex` | Fuente de verdad. Convenciones, Lagrangiano, 9 problemas abiertos (líneas 1135–1197). |
| `AGENTS.md` | Reglas del corpus, flujo de trabajo, acciones prohibidas. |
| `FORMAL_METHODS_GUIDE.md` | 7 pasos del ciclo de investigación, tipos de claim, mutation tests obligatorios. |
| `claims/CLAIM_TEMPLATE.md` | Template para nuevos claims (YAML frontmatter + campos required). |
| `evaluations/EVAL_TEMPLATE.md` | Template para nuevas evaluaciones. |
| `reports/REPORT_TEMPLATE.md` | Template para nuevos reportes. |
| `bmad_out/analisis.md` | Análisis completo del corpus + guía para ingenieros de software. |
| `bmad_out/planning-artifacts/tech-research-agentic-architecture.md` | Stack tecnológico propuesto y arquitectura agéntica. |

---

*Este documento se actualiza manualmente cuando el estado del corpus cambia
significativamente (nuevos TESTED_PASS, nuevas preguntas abiertas, cambios de
estrategia). No es parte del corpus lógico y puede modificarse.*
