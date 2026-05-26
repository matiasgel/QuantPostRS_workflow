# Análisis del corpus — QuantPostRS
**Fecha:** 26 de mayo de 2026  
**Actualizado por:** Mary (BMad Analyst) — enriquecido con datos de la sesión fundacional ChatGPT (`6a15fe56`)

---

## Tabla de contenidos

1. [Estado actual del corpus](#1-estado-actual-del-corpus)
2. [Estado de las fases del workflow](#2-estado-de-las-fases-del-workflow)
3. [Mapa de preguntas abiertas](#3-mapa-de-preguntas-abiertas)
4. [Pasos a seguir (roadmap)](#4-pasos-a-seguir-roadmap)
5. [Grafo de dependencias](#5-grafo-de-dependencias)
6. [Guía de terminología y arquitectura para ingenieros de software](#6-guía-de-terminología-y-arquitectura-para-ingenieros-de-software)
7. [Arquitectura original y modelo de episodios](#7-arquitectura-original-y-modelo-de-episodios)

---

## 1. Estado actual del corpus

### Artefactos existentes

| ID | Tipo | Título | Estado |
|----|------|--------|--------|
| DECISION-0001 | Decisión | Corpus distribuido en carpetas de primer nivel | `ACTIVE` |
| Q-0001 | Pregunta abierta | Simetría restringida versus simetría off-shell | `OPEN` |
| Q-0002 | Pregunta abierta | Espectro cuántico y positividad | `OPEN` |
| Q-0003 | Pregunta abierta | Matching con el sector libre (q→0) | `OPEN` |
| Q-0004 | Pregunta abierta | Causalidad en fondos electromagnéticos | `OPEN` |
| Q-0005 | Pregunta abierta | Base de operadores no minimales | `OPEN` |
| Q-0006 | Pregunta abierta | Coeficientes no minimales requeridos dinámicamente | `OPEN` |
| Q-0007 | Pregunta abierta | Renormalizabilidad del modelo minimal | `OPEN` |
| Q-0008 | Pregunta abierta | Estabilidad radiativa y anomalías BRST | `OPEN` |
| Q-0009 | Pregunta abierta | Interpretación UV o EFT | `OPEN` |
| CLAIM-0001 | Claim | Invariancia Stueckelberg de W_μ | **`TESTED_PASS`** |
| SCRIPT-CADABRA-0001 | Script | Prueba formal abstracta de CLAIM-0001 | `EXECUTABLE` |
| SCRIPT-SAGE-0001 | Script | Prueba matricial 4×4 de CLAIM-0001 | `EXECUTABLE` |
| REPORT-0001 | Reporte | Residuo = [0,0,0,0] en ambos verificadores | `PASSING` |
| EVAL-0001 | Evaluación | Clasificación final de CLAIM-0001 | `TESTED_PASS` |

### Lo que está ausente (gaps críticos)

- **Ningún CLAIM más allá del 0001.** Las invariancias de H_{μν}, de la acción cargada, y de la covarianza electromagnética no tienen claims formales todavía.
- **Sin mutation tests** en CLAIM-0001 (flagueado como warning en EVAL-0001).
- **Sin interpretaciones físicas** (`interpretations/` solo tiene el template).
- **`FISICO.md` y `master_agent.md` sin activar en el corpus operativo** — ambos documentos existen en `docs/coordinacion_agentica_propuesta/` (junto con el PDF de documentación y copias de todos los docs de referencia), pero fueron escritos para un modelo basado en **Codex CLI + ramas Git** y no han sido adaptados al sistema 100% agéntico actual (BMad + Copilot). La jerarquía `FISICO.md → master_agent.md → agente ejecutor` está diseñada correctamente, pero las instrucciones de `master_agent.md` aún referencian `git checkout`, `git status` y `git diff` como herramientas de auditoría.
- **Sin mutation tests** en CLAIM-0001 (flagueado como warning en EVAL-0001).
- **Sin interpretaciones físicas** (`interpretations/` solo tiene el template).
- **Sin criterios formales de cierre en el corpus operativo** — los cuatro resultados finales posibles (`FUNDAMENTAL_FIELD_CANDIDATE`, `EFFECTIVE_FIELD_THEORY`, `FAILED_PROGRAM`, `HUMAN_DECISION_REQUIRED`) están definidos en `docs/coordinacion_agentica_propuesta/FISICO.md` pero no en ningún artefacto del corpus activo (`decisions/`).
https://chatgpt.com/share/6a15fe56-428c-83e9-84e2-269d5e7c05aa
---

## 2. Estado de las fases del workflow

Según `FORMAL_METHODS_GUIDE.md`, el ciclo tiene 6 fases (0 a 5):

| Fase | Nombre | Estado | Evidencia |
|------|--------|--------|-----------|
| **0** | Congelar convenciones | ✅ **Completa** | `AGENTS.md`, `DECISION-0001`, `FORMAL_METHODS_GUIDE.md` |
| **1** | Reproducir lo establecido | ⚠️ **Parcial** | Solo W_μ verificada; H_{μν}, acción cargada y invariancia de contacto sin claim formal |
| **2** | Mapear preguntas abiertas | ✅ **Completa** | Q-0001 a Q-0009 creadas con sección en `Problema.tex` |
| **3** | Generar claims mínimos | ⚠️ **Muy parcial** | 1 claim de N necesarios (~10 estimados para cubrir Fase 1) |
| **4** | Auditoría formal | ⚠️ **Muy parcial** | Solo CLAIM-0001 auditado; falta mutation test |
| **5** | Interpretación controlada | ❌ **No iniciada** | Requiere cadena de TESTED_PASS que no existe aún |

---

## 3. Mapa de preguntas abiertas

### Dependencias entre preguntas

```
Q-0001 (BRST off-shell)
  └──► Q-0002 (espectro cuántico)
         └──► Q-0007 (renormalizabilidad)
         └──► Q-0009 (UV/EFT)
  └──► Q-0003 (matching libre) ← sanidad temprana, independiente de Q-0002

Q-0002 + Q-0004 ──► Q-0009

Q-0004 (causalidad EM) ──► Q-0006 (coef. no-minimales)

Q-0005 (base operadores) ──► Q-0006 ──► Q-0007 ──► Q-0008 ──► Q-0009
```

### Descripción resumida de cada pregunta

| Q | Pregunta | Prioridad | Herramientas | Depende de |
|---|----------|-----------|--------------|------------|
| Q-0001 | ¿Cómo tratar la simetría Stueckelberg restringida `∂̸ξ=0`? ¿BRST con ghost restringido o campos auxiliares? | **Alta** | Cadabra2 + Sage | — |
| Q-0002 | ¿El espectro cuántico contiene solo spin-3/2 masivo con norma positiva? | **Alta** | Cadabra2 + Sage | Q-0001 |
| Q-0003 | En `q→0`, ¿se reproduce spin-3/2 libre puro sin modos espurios? | **Alta (sanidad)** | Sage | Q-0001, Q-0002 |
| Q-0004 | ¿La propagación en fondos EM es causal? ¿Hay mecanismo Velo-Zwanziger? | **Media** | Cadabra2 + Sage | Q-0001, Q-0002 |
| Q-0005 | ¿Cuál es la base completa de operadores locales compatibles con las 3 simetrías? | **Media** | Cadabra2 | — |
| Q-0006 | ¿Causalidad/hiperbolicidad fija coeficientes no-minimales? | **Media** | Sage + Cadabra2 | Q-0004, Q-0005 |
| Q-0007 | ¿El modelo minimal es renormalizable o es una EFT? | **Media** | Cadabra2 + Sage | Q-0002, Q-0005 |
| Q-0008 | ¿Los loops preservan BRST? ¿Generan operadores fuera del ansatz? | **Media** | Cadabra2 + Sage | Q-0001, Q-0005, Q-0007 |
| Q-0009 | ¿Hay completación UV? Si no, ¿cuál es la escala de corte de la EFT? | **Baja** | Ambos | Q-0002, Q-0004, Q-0007, Q-0008 |

---

## 4. Pasos a seguir (roadmap)

### Bloque A — Completar Fase 1: reproducir invariancias establecidas

Estas invariancias están **algebraicamente demostradas en `Problema.tex`** pero aún sin claim formal ni scripts verificados. Son las que le dan sustento al programa BRST.

---

#### CLAIM-0002 (sugerido) — Invariancia Stueckelberg del tensor H_{μν}

**Enunciado:** El tensor `H_{μν} = D_μ W_ν - D_ν W_μ` satisface `δ_S H_{μν} = 0`.

**Residuo a probar:**
```
δ_S(D_μ Ψ_ν - D_ν Ψ_μ) + δ_S(iq b F_{μν} χ) = 0
```
Explícitamente:
```
-iq b F_{μν} ξ  +  iq b F_{μν} ξ  = 0
```

**Evidencia en Problema.tex:** sección `subsec:el-tensor-mejorado`, demostración analítica completa.

**Depende de:** CLAIM-0001 (ya PASS).

**Herramienta:** Cadabra2 (algebraico) + SageMath (matricial).

---

#### CLAIM-0003 (sugerido) — Covariancia electromagnética de W_μ y H_{μν}

**Enunciado:** Bajo `U(1)_em`, ambos bloques transforman como `e^{iqλ}(·)`.

**Residuo a probar:**
```
δ_EM(W_μ) - iq λ W_μ = 0
δ_EM(H_{μν}) - iq λ H_{μν} = 0
```

**Evidencia en Problema.tex:** secciones `subsec:el-bloque-stueckelberg-invariante` y `subsec:el-tensor-mejorado`.

---

#### CLAIM-0004 (sugerido) — Invariancia de contacto de la acción cargada

**Enunciado:** La acción escrita en términos de W_μ es invariante bajo `δ_C Ψ_μ = γ_μ ε`.

**Residuo a probar:**
```
δ_C [ Ā_{Ψ} Λ^{μν}_{-1/2}(D) Ψ_ν + ... ] = 0
```

**Evidencia en Problema.tex:** sección `subsec:el-limite-a-1-2-y-la-invariancia-de-contacto` (propiedad `Λ^{μν}_{-1/2} γ_ν = 0`).

---

### Bloque B — Test de sanidad temprana (Q-0003)

Q-0003 está diseñado como **test de sanidad físico** que puede ejecutarse antes de atacar el espectro completo (Q-0002) o el BRST completo (Q-0001).

#### CLAIM-0005 (sugerido) — Descomposición en sectores de spin en q=0

**Enunciado:** En `q=0`, `A_μ=0`, el operador cuadrático del Lagrangiano de la tesis se descompone en sectores de spin independientes y el sector spin-3/2 reproduce la ecuación `(i∂̸ - m)Ψ_μ = 0` con `∂_μ Ψ^μ = 0`.

**Herramienta:** SageMath en representación `4×4` con `p_μ` genérico.

**Prioridad:** Alta — es la única pregunta que no depende de completar Q-0001.

---

### Bloque C — Formalizar BRST mínimo (Q-0001)

#### CLAIM-0006 (sugerido) — Nilpotencia `s² = 0` sobre campo y ghost de Stueckelberg

**Enunciado:**
```
s χ = η
s Ψ_μ = b D_μ η
s η = 0   (η = ghost Stueckelberg)
```
Entonces `s²χ = 0`, `s²Ψ_μ = 0`, `s²η = 0`.

**Residuo:** Calcular `s(sX)` para cada campo y verificar que es idénticamente cero bajo las convenciones fijas.

**Depende de:** CLAIM-0001, CLAIM-0002.

---

### Bloque D — Mutation tests (deuda técnica)

**EVAL-0001 tiene un warning explícito:** CLAIM-0001 no fue sometido a mutation tests. Antes de usar CLAIM-0001 como premisa para interpretaciones físicas, se deben:

1. Modificar el coeficiente `b` en el script (cambiar `1/m √(2/3)` por otro valor) y verificar que el residuo **no** es cero.
2. Cambiar el signo de `δ_S Ψ_μ` y verificar que el residuo **no** es cero.
3. Documentar en un nuevo `REPORT-0001-mutation.md` o equivalente.

---

### Priorización ejecutiva

| Prioridad | Acción | Tipo |
|-----------|--------|—----|
| 🔴 **0** | Adaptar `master_agent.md` de `docs/coordinacion_agentica_propuesta/` al modelo agéntico: reemplazar instrucciones Git/Codex por instrucciones BMad/Copilot y moverlo a la raíz operativa del repo | Infraestructura de gobierno |
| 🔴 **0b** | Formalizar los criterios de cierre (`FUNDAMENTAL_FIELD_CANDIDATE`, `EFT`, `FAILED_PROGRAM`, `HUMAN_DECISION_REQUIRED`) en `decisions/DECISION-0002_criterios_de_cierre.md` | Infraestructura de gobierno |
| 🔴 **1** | Mutation tests de CLAIM-0001 | Deuda técnica |
| 🔴 **2** | CLAIM-0002 (H_{μν} Stueckelberg) | Fase 1 |
| 🔴 **3** | CLAIM-0003 (covariancia EM) | Fase 1 |
| 🟡 **4** | CLAIM-0005 (sanidad q=0) | Q-0003 early test |
| 🟡 **5** | CLAIM-0004 (invariancia de contacto) | Fase 1 |
| 🟢 **6** | CLAIM-0006 (nilpotencia BRST) | Q-0001 |
| ⚪ **7+** | Q-0002, Q-0004, Q-0005, Q-0006, Q-0007, Q-0008, Q-0009 | Fases 3-5 |

---

## 5. Grafo de dependencias

```
CONVENCIONES (AGENTS.md, DECISION-0001) — fijas, no modificar
         │
         ▼
Problema.tex — fuente de verdad, no modificar
         │
         ├──── CLAIM-0001 [TESTED_PASS] ─────────────────────────────────────┐
         │       Invariancia de W_μ bajo Stueckelberg                         │
         │              │                                                      │
         │         [mutation tests pendientes]                                 │
         │              │                                                      │
         ├──── CLAIM-0002 (depende de 0001)                                   │
         │       Invariancia de H_{μν} bajo Stueckelberg                      │
         │              │                                                      │
         ├──── CLAIM-0003 (depende de 0001, 0002)                             │
         │       Covariancia EM de W_μ y H_{μν}                               │
         │              │                                                      │
         ├──── CLAIM-0004 (depende de 0001, 0002, 0003)                       │
         │       Invariancia de contacto de acción cargada                     │
         │              │                                                      │
         ├──── CLAIM-0005 (independiente, vía q=0)                            │
         │       Sanidad: sector libre reproduce spin-3/2 puro                 │
         │                                                                     │
         ├──── CLAIM-0006 (depende de 0001, 0002) ◄────────────────────────── ┘
         │       Nilpotencia BRST s²=0 en sector mínimo
         │              │
         │       ┌──────┴──────────────────────────────────────┐
         │       ▼                                              ▼
         │   Q-0002 (espectro, propagadores)            Q-0005 (base operadores)
         │       │                                              │
         │       ▼                                              ▼
         │   Q-0003 (matching libre)                    Q-0006 (coef. no-min.)
         │       │                                              │
         │   Q-0004 (causalidad EM) ◄─────────────────────────-┘
         │       │
         │       └──► Q-0007 (renormalizabilidad)
         │                    │
         │                    ▼
         │              Q-0008 (anomalías BRST)
         │                    │
         │                    ▼
         └────────────► Q-0009 (UV/EFT, conclusión final)
```

---

## 6. Guía de terminología y arquitectura para ingenieros de software

Esta sección traduce los conceptos del proyecto al lenguaje de un ingeniero de software con poca formación en física teórica.

---

### 6.1 El proyecto en una oración

> Este repositorio implementa un **pipeline de verificación formal asistido por computadora** de un modelo matemático de física teórica. El "código" es álgebra simbólica. El "test suite" son scripts Cadabra2 y SageMath. Los "PRs" son claims. El "CI" es el workflow BMad + revisión manual.

---

### 6.2 Analogías entre física y software

| Concepto de física | Analogía en software |
|--------------------|----------------------|
| `Problema.tex` | Spec document / source of truth (inmutable como una RFC aprobada) |
| Convenciones fijas | Interfaces / contratos de tipos (cambiarlos rompe todo) |
| Campo `Ψ_μ` | Objeto de dominio principal con índices (como un tensor 4D) |
| Simetría gauge | Invariante de representación: múltiples representaciones del mismo objeto físico |
| Claim | Test unitario con nombre, hipótesis y residuo esperado = 0 |
| Residuo | Valor de retorno del test. Si es 0 → PASS. Si no → FAIL |
| Cadabra2 | Motor de álgebra simbólica abstracta (como un type checker sofisticado) |
| SageMath | Motor de verificación en representación concreta (como integration tests con matrices reales) |
| `TESTED_PASS` | Test verde con cobertura de dos verificadores independientes |
| `TESTED_PARTIAL` | Test amarillo: corre pero quedan casos sin cubrir |
| `TESTED_FAIL` | Test rojo: residuo ≠ 0 |
| Ghost fields (`c`, `η`, `ρ`) | Variables internas del verificador formal; no observables físicos |
| Interpretación física | Conclusión de dominio derivada de tests verdes (como una decisión de negocio basada en métricas confiables) |
| Corpus inmutable | Append-only log / event sourcing: nunca se edita, solo se añaden nuevos artefactos |
| `supersedes` / `refutes` | Git annotate + deprecation notice referenciando el artefacto anterior |

---

### 6.3 Arquitectura del repositorio

```
QuantPostRS_workflow/
│
├── Problema.tex              ← SOURCE OF TRUTH. Nunca modificar.
│                                Equivalente a la RFC/spec principal del proyecto.
│
├── AGENTS.md                 ← Reglas de negocio del pipeline. Equivalente a
│                                un CONTRIBUTING.md muy estricto con reglas de QA.
│
├── FORMAL_METHODS_GUIDE.md   ← Manual de desarrollo. Explica el ciclo de trabajo,
│                                tipos de claims, fases del workflow.
│
├── open_questions/           ← Backlog de tareas. Cada Q-XXXX.md es un ticket
│   ├── Q-0001.md                con contexto, dependencias y claims sugeridos.
│   ├── Q-0002.md
│   └── ...
│
├── claims/                   ← Unit tests declarados. Cada CLAIM-XXXX.md describe
│   └── CLAIM-0001.md            QUÉ se debe verificar (hypothesis + expected residue).
│
├── scripts/                  ← Implementación de los tests.
│   ├── cadabra/                 Cadabra2 = tests abstractos/tipados
│   │   └── SCRIPT-CADABRA-0001.cdb
│   └── sage/                    SageMath = integration tests con matrices 4×4
│       └── SCRIPT-SAGE-0001.sage
│
├── reports/                  ← CI output logs. Cada REPORT-XXXX.md registra
│   └── REPORT-0001.md           la salida de ejecución y los residuos obtenidos.
│
├── evaluations/              ← Test results con clasificación. EVAL-XXXX.md
│   └── EVAL-0001.md             asigna el status final al claim (PASS/FAIL/etc.)
│
├── interpretations/          ← Business conclusions. Solo se crean cuando hay
│   └── (vacío)                  suficientes TESTED_PASS encadenados.
│
├── decisions/                ← Architecture Decision Records (ADRs).
│   └── DECISION-0001.md         Cambios de convenciones o reglas del proceso.
│
└── bmad_out/                 ← Salidas del workflow BMad (planning, artifacts).
    ├── analisis.md   ← ESTE ARCHIVO
    ├── planning-artifacts/
    └── implementation-artifacts/
```

---

### 6.4 Herramientas: Cadabra2 y SageMath

#### Cadabra2 — el verificador abstracto

Cadabra2 es un sistema de álgebra de computadora especializado en **tensores y matrices gamma** (matrices 4×4 que satisfacen relaciones de anticonmutación). Piensen en él como un **type checker dependiente** que:

- Conoce las reglas de álgebra de matrices gamma: `{γ^μ, γ^ν} = 2η^{μν}𝟙`
- Puede simplificar expresiones tensoriales con índices libres y contratados
- Declara "residuo = 0" cuando una identidad algebraica es verdadera en abstracto

**Limitación:** no trabaja con números concretos. Verifica que las reglas de tipo/álgebra se satisfacen, pero no construye representaciones explícitas.

**Análogo en software:** un compilador de tipos dependientes como Coq o Lean que verifica proposiciones matemáticas.

#### SageMath — el verificador concreto

SageMath es un sistema de álgebra computacional de propósito general (basado en Python). En este proyecto se usa para:

- Construir las matrices gamma en representación concreta `4×4` (números complejos)
- Evaluar el residuo de un claim como una **matriz numérica**
- Confirmar que la matriz = 0 (todos los elementos son cero)

**Ventaja clave:** detecta errores de signo o coeficientes que Cadabra2 podría pasar por alto al simplificar simbólicamente.

**Análogo en software:** integration tests con datos reales que complementan los unit tests abstractos.

#### Regla de aprobación dual

> **Un claim se considera TESTED_PASS solo cuando AMBOS verificadores producen residuo = 0.**

Si Cadabra2 da PASS pero SageMath da FAIL → el claim tiene un error de convención.
Si SageMath da PASS pero Cadabra2 da PARTIAL → la formalización abstracta está incompleta.

---

### 6.5 Anatomía de un claim

Un claim es el artefacto central del pipeline. Equivale a un **test unitario con contexto extendido**.

```yaml
# CLAIM-XXXX.md — estructura

id: CLAIM-0001
type: claim
title: "Invariancia Stueckelberg de W_μ"
status: TESTED_PASS

# Hipótesis (preconditions)
assumptions:
  - métrica η = diag(+1,-1,-1,-1)
  - D_μ = ∂_μ - iq A_μ
  - δ_S A_μ = 0

# Enunciado (lo que se afirma)
statement: |
  W_μ = Ψ_μ - b D_μ χ  satisface  δ_S W_μ = 0

# Residuo esperado (valor que deben producir los scripts)
expected_residue: "0 en todos los índices μ"

# Scripts que ejecutan el test
uses_scripts:
  - SCRIPT-CADABRA-0001
  - SCRIPT-SAGE-0001

# Resultado
tested_by: EVAL-0001
```

**Pasos del ciclo de un claim:**

```
1. PROPOSED     → se formula el enunciado
2. FORMALIZED   → se escriben los scripts
3. (ejecutar)   → se corren Cadabra2 y SageMath
4a. TESTED_PASS   → residuo = 0 en ambos
4b. TESTED_FAIL   → residuo ≠ 0 (se crea nuevo claim que refuta)
4c. TESTED_PARTIAL → un verificador pasa, el otro no
```

---

### 6.6 El concepto de "simetría" en este contexto

Una **simetría** en física clásica equivale a una **invariante de transformación** en software: es una propiedad que se preserva cuando se aplica una operación.

Hay tres simetrías clave en este proyecto:

#### Simetría electromagnética U(1)_em

Equivale a un **cambio global de fase compleja** de todos los campos cargados:
```
Ψ_μ → e^{iqλ(x)} Ψ_μ
```
Es análoga a una transformación de coordenadas en un sistema de referencia: el campo cambia de representación pero la física no cambia. El potencial `A_μ` "absorbe" este cambio para que las ecuaciones sigan siendo las mismas.

#### Simetría Stueckelberg

Equivale a una **redundancia de representación** del campo `χ`. El campo `χ` es un campo auxiliar (como un parámetro de normalización): diferentes valores de `χ` describen el mismo estado físico si se transforma conjuntamente con `Ψ_μ`. El bloque `W_μ = Ψ_μ - b D_μ χ` es la **representación canónica** que elimina esta redundancia (como un canonical form o forma normal).

#### Invariancia de contacto

Una simetría especial del operador cinético singular `Λ^{μν}_{-1/2}`. Se puede agregar `γ_μ ε` a `Ψ_μ` sin cambiar la acción, porque el operador tiene `Λ^{μν} γ_ν = 0` (nulidad en ese subespacio). Equivale a que ciertas componentes del campo están en el **kernel del operador** y son físicamente irrelevantes.

---

### 6.7 El formalismo BRST — el framework de testing gauge-invariante

**BRST** (Becchi-Rouet-Stora-Tyutin) es el método estándar para cuantizar teorías con simetrías gauge. En términos de software:

> BRST es un **framework de testing de invariantes** que amplía el espacio de campos con variables auxiliares (llamadas *ghosts*) para manejar las redundancias formalmente.

**Estructura:**

| Objeto BRST | Rol en software |
|-------------|-----------------|
| `s` (operador BRST) | Operador que actúa como "diferencial": si `s(X) = Y`, entonces `Y` es "BRST-exacto" |
| `s² = 0` (nilpotencia) | Condición de consistencia del framework: aplicar `s` dos veces da siempre cero |
| Ghost `c` (U(1)_em) | Variable interna para rastrear la invariancia EM |
| Ghost `η` (Stueckelberg) | Variable interna para rastrear la redundancia de `χ` |
| Ghost `ρ` (contacto) | Variable interna para rastrear la redundancia de contacto |
| Cohomología BRST | El conjunto de estados físicos = objetos cerrados (`sX=0`) módulo exactos (`X=sY`) |
| Espacio físico | `ker(s) / im(s)` — equivalente a un quotient type |

**Por qué importa `s²=0`:** si el operador BRST no fuera nilpotente, la cohomología no estaría bien definida y no se podría separar lo físico de lo no-físico. Es el análogo de que un compilador de tipos sea **sound**: si el sistema de tipos no es consistente, los theorems no valen nada.

---

### 6.8 Los campos y sus roles

| Campo | Símbolo | Tipo | Descripción en términos de software |
|-------|---------|------|--------------------------------------|
| Campo Post-RS cargado | `Ψ_μ` | Vector-espinor (4 índices Lorentz × 4 componentes espinoriales) | Objeto de dominio principal. Array de matrices complejas con índice de Lorentz |
| Espinor auxiliar | `χ` | Espinor de Dirac (4 componentes) | Grado de libertad de gauge: redundante, se puede fijar en `χ=0` |
| Bloque invariante | `W_μ` | Vector-espinor | Forma canónica que elimina la redundancia de `χ` |
| Tensor de campo | `H_{μν}` | Tensor antisimétrico de espinores | Análogo al tensor de fuerza `F_{μν}` del electromagnetismo; construido a partir de `W_μ` |
| Potencial EM | `A_μ` | 4-vector real | Campo externo (no dinámico en la teoría principal) |
| Tensor EM | `F_{μν}` | Tensor antisimétrico | `∂_μ A_ν - ∂_ν A_μ`; la "curvatura" del potencial |
| Ghost EM | `c` | Campo escalar fermiònico | Variable interna BRST para U(1)_em |
| Ghost Stueckelberg | `η` | Espinor fermiònico | Variable interna BRST para la redundancia de `χ` |
| Ghost de contacto | `ρ` | Espinor fermiònico | Variable interna BRST para la invariancia de contacto |

---

### 6.9 Las matrices gamma y el álgebra de Clifford

Las **matrices gamma** `γ^μ` son 4 matrices complejas `4×4` que satisfacen:
```
{γ^μ, γ^ν} = γ^μ γ^ν + γ^ν γ^μ = 2 η^{μν} 𝟙
```

Son el **corazón del álgebra** que usan los campos espinoriales. En términos de software son como un **tipo algebraico base** con una relación de reescritura:

```
γ^0 γ^0 = +𝟙
γ^i γ^i = -𝟙  (i = 1,2,3)
γ^μ γ^ν = -γ^ν γ^μ  si μ ≠ ν
```

SageMath construye estas matrices explícitamente con números complejos. Cadabra2 trabaja con ellas como símbolos abstractos con reglas de reescritura.

La convención fija de este proyecto es `η = diag(+1,-1,-1,-1)`, que determina los signos de todas las relaciones. Cambiar esta convención sin actualizar todos los scripts rompería todos los tests.

---

### 6.10 La métrica Lorentziana y la notación de índices

**Notación de Einstein (convención de suma):** un índice repetido arriba y abajo implica suma:
```
γ^μ D_μ = γ^0 D_0 + γ^1 D_1 + γ^2 D_2 + γ^3 D_3
```

Esto se escribe como `D̸` (D-slash). En código Python sería:
```python
slashed_D = sum(gamma[mu] * D[mu] for mu in range(4))
```

**Subida y bajada de índices:** la métrica `η^{μν}` actúa como un operador de conversión entre representaciones contravariante (índice arriba) y covariante (índice abajo):
```
X^μ = η^{μν} X_ν   ←→   X_μ = η_{μν} X^ν
```

Con `η = diag(+1,-1,-1,-1)`:
```
X^0 = +X_0,   X^1 = -X_1,   X^2 = -X_2,   X^3 = -X_3
```

---

### 6.11 La derivada covariante y el acoplamiento mínimo

La **derivada covariante** `D_μ = ∂_μ - iq A_μ` es el operador que reemplaza a la derivada ordinaria cuando los campos tienen carga eléctrica `q`.

**Analogía en software:** es como un proxy que inyecta un término de corrección dependiente del campo externo `A_μ`:

```python
def D(mu, X, q, A):
    return partial(mu, X) - 1j * q * A[mu] * X
```

Su propiedad clave es que el conmutador de dos derivadas covariantes no es cero:
```
[D_μ, D_ν] X = -iq F_{μν} X
```

Esto es equivalente a decir que la derivada covariante tiene **curvatura no trivial** (como una conexión en un fibrado con holonomía). Esta curvatura es exactamente lo que hace que la sustitución ingenua `∂ → D` en todas partes rompa la invariancia Stueckelberg, y motiva la construcción de los bloques `W_μ` y `H_{μν}`.

---

### 6.12 Por qué la "sustitución minimal ingenua" falla

Un campo libre `Ψ_μ` con simetría Stueckelberg `δ_S Ψ_μ = (1/m)√(2/3) ∂_μ ξ` parece sugerir que, para acoplarlo a EM, basta con reemplazar `∂ → D`. Pero:

```
δ_S(D_μ Ψ_ν - D_ν Ψ_μ) = b [D_μ, D_ν] ξ = -iq b F_{μν} ξ  ≠ 0
```

La derivada covariante "siente" el potencial EM y produce un residuo proporcional a `F_{μν}`. Es como si una función que era pura con derivadas ordinarias dejara de serlo al inyectar dependencias externas.

**La solución:** el término `H_{μν} = D_μ Ψ_ν - D_ν Ψ_μ + iq b F_{μν} χ` fue diseñado para que el residuo se cancele exactamente. Este es el contenido de CLAIM-0002.

---

### 6.13 El concepto de "espectro" y por qué importa

El **espectro** de la teoría es el conjunto de partículas que esta describe: sus masas, spins y multiplicidades. Verificar que el espectro es "limpio" equivale a verificar que:

1. **No hay modos espurios:** el operador cuadrático (la "matriz de masas" del sistema) no tiene eigenvalores en sectores no físicos.
2. **Norma positiva:** los estados físicos tienen probabilidades positivas (no hay "probabilidades negativas" que indicarían estados fantasma no físicos).
3. **Matching con el límite libre:** al apagar el acoplamiento `q→0`, se recupera exactamente la teoría de un solo campo spin-3/2 masivo, sin contribuciones de `χ` o los ghosts.

Este es el objetivo de Q-0002, Q-0003.

---

### 6.14 Reglas del corpus (anti-drift)

El corpus tiene reglas estrictas equivalentes a las de un sistema de event sourcing:

1. **Inmutabilidad:** los artefactos en `claims/`, `reports/`, `evaluations/`, `interpretations/`, `decisions/`, `open_questions/` son **append-only**. Nunca se editan.
2. **Trazabilidad:** cada artefacto declara sus dependencias (`depends_on`, `uses_scripts`, `tested_by`).
3. **No se salta el CI:** ningún claim puede pasar a `INCORPORATED` sin `TESTED_PASS`.
4. **No mutación encubierta:** ajustar coeficientes para que el residuo desaparezca sin documentarlo es equivalente a hacer trampa en el CI.
5. **Sage PASS es soberano para identidades matriciales:** si SageMath da PASS, un PARTIAL de Cadabra2 no puede sobrescribirlo.

---

### 6.15 Cómo usar BMad en este proyecto

BMad es un framework de gestión de workflows de investigación/desarrollo. En este proyecto cumple los roles de:

- **Sprint planning:** identificar el próximo claim a formalizar
- **Story creation:** crear los archivos CLAIM-XXXX.md con contexto completo
- **Dev story:** implementar los scripts Cadabra2/SageMath
- **Code review:** verificar que los scripts siguen las convenciones
- **Sprint status:** reportar el estado del corpus

Los módulos relevantes son:
- `bmad-create-story` → crear un nuevo CLAIM-XXXX.md
- `bmad-dev-story` → implementar los scripts de un claim
- `bmad-sprint-status` → ver estado actual del corpus
- `bmad-code-review` → revisar scripts antes de registrar el REPORT

---

## 7. Arquitectura original y modelo de episodios

> Esta sección documenta el diseño original del workflow, tal como fue diseñado en la sesión fundacional del proyecto (ChatGPT, conversación `6a15fe56-428c-83e9-84e2-269d5e7c05aa`). Sirve como contexto para reconstruir los artefactos de gobierno que actualmente faltan.

---

### 7.1 Origen del proyecto

El repositorio fue diseñado a partir de una sesión interactiva con ChatGPT en la que el usuario (matidani/Daniel) cargó el documento `Problema.tex` para:

1. Generar una versión "agent-friendly" del `.tex` con macros normalizadas, labels explícitos y comentarios para agentes.
2. Identificar ambigüedades de convención que podrían confundir a agentes automáticos.
3. Diseñar el sistema de agentes para usar con **Codex CLI**, Cadabra2 y SageMath en Linux.

La sesión produjo los siguientes documentos fundacionales que **actualmente no están en el repositorio**:

| Documento | Propósito | Estado en repo |
|-----------|-----------|----------------|
| `FISICO.md` | Supervisor científico: decide qué episodio lanzar | ❌ Ausente |
| `master_agent.md` | Coordinador/referee: gestiona episodios, ramas y auditoría técnica | ❌ Ausente |
| `README.md` del proyecto | Orientado a GitHub Copilot para auditar e implementar el sistema | ❓ Reemplazado por `AGENTS.md` |
| `QuantPostRS_workflow__Documentacion.pdf` | PDF completo de documentación del proyecto | ❌ No incorporado en `docs/` |
| Reporte de ambigüedades del `.tex` | Lista de macros, símbolos y estados que fueron normalizados | ❌ No incorporado |

---

### 7.2 La jerarquía de gobernanza original

La arquitectura diseñada tiene tres capas:

```
FISICO.md
  │  Supervisor científico
  │  Decide: qué episodio lanzar, cuándo detener, cuál es el resultado final
  │
  ▼
master_agent.md
  │  Coordinador/referee/release manager
  │  Coordina: ramas Git, asigna trabajo a Codex CLI, audita lo producido,
  │  decide si itera, rechaza, mergea o detiene el episodio
  │
  ▼
Codex CLI  (actualmente reemplazado por GitHub Copilot / BMad)
     Produce: claims, scripts, reportes y evaluaciones
     Trabaja en ramas Git aisladas
```

**Responsabilidades del FÍSICO (capa de gobernanza científica):**
- Evalúa la calidad científica de cada episodio completado
- Decide el siguiente episodio a lanzar basándose en el estado del corpus
- Define la condición de terminación de la investigación
- Clasifica el resultado final de la investigación

**Responsabilidades del AGENTE MAESTRO (capa de coordinación técnica):**
- No es un investigador físico — es un **coordinador de laboratorio formal**
- Su unidad de trabajo es el episodio completo: asignar trabajo al agente ejecutor → auditar lo producido → decidir si acepta, itera o rechaza
- Verifica que los artefactos producidos respetan las convenciones de `AGENTS.md` antes de considerarlos parte del corpus
- Aplica criterios de aceptación, iteración o rechazo de forma autónoma

---

### 7.3 El modelo de episodios

Un **episodio** es la unidad atómica del workflow de investigación. El sistema es **100% agéntico y autónomo**: no requiere intervención humana salvo en las decisiones de gobernanza científica que corresponden al Físico. Cada episodio sigue el ciclo:

```
1. El Físico decide el próximo episodio (ej: "formalizar CLAIM-0002")
         │
         ▼
2. master_agent formula el prompt específico y lo delega al agente ejecutor
         │
         ▼
3. Agente ejecutor (Copilot + BMad) produce los artefactos de forma autónoma:
   - CLAIM-XXXX.md (formulación)
   - SCRIPT-CADABRA-XXXX.cdb (test abstracto)
   - SCRIPT-SAGE-XXXX.sage (test matricial)
   - Ejecuta Cadabra2 y SageMath en la máquina local
   - Captura los residuos y produce REPORT-XXXX.md
         │
         ▼
4. master_agent audita los artefactos producidos de forma autónoma:
   - ¿Los artefactos siguen las convenciones de AGENTS.md?
   - ¿Los scripts usan las definiciones correctas?
   - ¿No se modificaron artefactos inmutables?
         │
         ├── ACEPTA → el agente crea EVAL-XXXX.md y cierra el episodio
         ├── ITERA  → el agente reformula el prompt y reintenta de forma autónoma
         └── RECHAZA → el agente crea DECISION explicando por qué
         │
         ▼
5. El Físico evalúa el resultado del episodio y lanza el siguiente
```

**Principio clave:** la intervención humana del Físico es exclusivamente científica (decidir qué investigar y evaluar el resultado). Todo el trabajo de producción, ejecución, auditoría y registro de artefactos es ejecutado por agentes de forma autónoma.

---

### 7.4 Modelo de auditoría en el sistema agéntico

El sistema no delega la integridad del corpus a Git (sin ramas por episodio, sin merges manuales). La auditoría es **responsabilidad del agente** y se garantiza mediante las reglas del corpus:

| Mecanismo | Cómo funciona |
|-----------|---------------|
| **Inmutabilidad de artefactos** | Las reglas de `AGENTS.md` prohíben editar o borrar artefactos del corpus; el agente las cumple por instrucción |
| **Trazabilidad por campos YAML** | Cada artefacto declara `depends_on`, `uses_scripts`, `tested_by` — el agente los completa al crear el artefacto |
| **Verificación de convenciones** | Antes de registrar cualquier REPORT, el agente verifica que los scripts usan `η = diag(+1,-1,-1,-1)` y `D_μ = ∂_μ - iq A_μ` |
| **Mutation tests** | El agente debe introducir mutaciones deliberadas y verificar que el residuo deja de ser cero — esto no requiere ramas, solo ejecución local |
| **Audit trail** | El historial de artefactos en el corpus (append-only) es el audit trail; no se requiere `git log` para rastrearlo |

> Git está presente como respaldo del repositorio, pero **no es parte del workflow agéntico**. Los agentes no crean ramas ni merges — escriben directamente en el corpus siguiendo las reglas de inmutabilidad.

---

### 7.5 Los tres resultados finales posibles de la investigación

Esta es la información más crítica ausente del corpus: **la investigación tiene criterios de terminación explícitos**. El Físico clasifica el resultado final en una de tres categorías:

| Resultado | Criterio | Significado físico |
|-----------|----------|--------------------|
| **Campo Fundamental** | Las tres simetrías son consistentes, el espectro es limpio (solo spin-3/2 masivo con norma positiva), Q-0001 a Q-0004 con `TESTED_PASS` | El modelo describe un campo genuinamente fundamental que puede acoplarse a EM sin inconsistencias |
| **Campo Efectivo (EFT)** | El espectro tiene inconsistencias en alta energía, Q-0007 o Q-0009 confirman escala de corte | El modelo es una Teoría Efectiva de Campos válida a baja energía, con escala de corte explícita |
| **Investigación Fallida** | Residuos no reducibles, inconsistencias irresolubles, violación de causalidad sin remedio | El ansatz del modelo no puede formalizarse consistentemente |
| **Decisión Humana Requerida** | Los datos son ambiguos o contradictorios entre preguntas abiertas | Requiere juicio experto humano para redefinir la dirección |

> Estos criterios de cierre deben formalizarse en un artefacto del corpus (sugerido: `decisions/DECISION-0002_criterios_de_cierre.md`) para que cualquier agente pueda evaluar si la investigación ha concluido.

---

### 7.6 Correspondencia con el workflow BMad actual

El workflow BMad (instalado el 2026-05-26) implementa la arquitectura agéntica autónoma como sistema de producción:

| Capa original | Implementación actual | Estado |
|---------------|----------------------|--------|
| `FISICO.md` | Usuario humano (matidani) actúa como Físico | La definición formal existe en `docs/coordinacion_agentica_propuesta/FISICO.md`; los criterios de cierre deben migrar a `decisions/` |
| `master_agent.md` | `AGENTS.md` + `AGENTS_review_monitor.md` + reglas BMad | Existe en `docs/coordinacion_agentica_propuesta/master_agent.md` pero con instrucciones Git/Codex; necesita adaptación al modelo agéntico |
| Codex CLI | GitHub Copilot + BMad skills (100% agéntico) | Reemplazado completamente; el modelo de episodios corre de forma autónoma |
| Ramas por episodio | **No aplica** — diseño intencional | Los agentes escriben directamente en el corpus siguiendo reglas de inmutabilidad |
| `docs/` como `project_knowledge` | `docs/coordinacion_agentica_propuesta/` con 8 archivos | Contenido presente; los agentes BMad deben apuntar a esta subcarpeta como fuente de contexto adicional |

---

*Archivo actualizado el 26-05-2026. Fuentes: corpus completo del repositorio + sesión fundacional ChatGPT `6a15fe56-428c-83e9-84e2-269d5e7c05aa`.*
