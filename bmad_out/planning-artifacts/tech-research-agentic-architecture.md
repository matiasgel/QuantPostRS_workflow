# Investigación tecnológica — Arquitectura agéntica autónoma para QuantPostRS
**Fecha:** 26 de mayo de 2026  
**Estado:** DRAFT — investigación inicial  
**Autor:** GitHub Copilot (Mary / Analista estratégica)

---

## Tabla de contenidos

1. [Problemas a resolver](#1-problemas-a-resolver)
2. [Investigación por problema — candidatos tecnológicos](#2-investigación-por-problema--candidatos-tecnológicos)
   - [P1 — Pipeline lineal bloqueado en Q-0001](#p1--pipeline-lineal-bloqueado-en-q-0001)
   - [P2 — Mutation tests sin enforcement mecánico](#p2--mutation-tests-sin-enforcement-mecánico)
   - [P3 — Sin registry de corpus — no escala a 30+ claims](#p3--sin-registry-de-corpus--no-escala-a-30-claims)
   - [P4 — Punto ciego compartido en verificación dual](#p4--punto-ciego-compartido-en-verificación-dual)
   - [P5 — Scripts demasiado simples — poca confianza en el PASS](#p5--scripts-demasiado-simples--poca-confianza-en-el-pass)
3. [Arquitectura agéntica autónoma con procesos en paralelo](#3-arquitectura-agéntica-autónoma-con-procesos-en-paralelo)
4. [Stack tecnológico recomendado](#4-stack-tecnológico-recomendado)
5. [Prioridades de implementación](#5-prioridades-de-implementación)

---

## 1. Problemas a resolver

Según el análisis adversarial (corregido) en `analisis.md`, los problemas vigentes son:

| ID | Problema | Severidad |
|----|----------|-----------|
| P1 | Q-0001 bloquea el 80% del pipeline; cadena lineal sin paralelismo | 🔴 Crítico |
| P2 | Mutation tests obligatorios en spec pero opcionales en práctica | 🔴 Crítico |
| P3 | Sin registry/index — corpus colapsará en trazabilidad a ~30 claims | 🟡 Medio |
| P4 | Verificadores comparten convención — sin árbitro independiente | 🟡 Medio |
| P5 | CLAIM-0001 verifica `b·X - b·X = 0` — los scripts son demasiado triviales | 🟢 Bajo |

---

## 2. Investigación por problema — candidatos tecnológicos

---

### P1 — Pipeline lineal bloqueado en Q-0001

**El problema:** el grafo de dependencias del corpus es un árbol con raíz en Q-0001. Si Q-0001 tarda meses, todo lo demás espera. No hay extracción de paralelismo en las ramas independientes.

#### Candidato A — **LangGraph** (LangChain)

| Aspecto | Detalle |
|---------|---------|
| Qué es | Framework de grafos de estados para agentes LLM. Cada nodo es un agente o función; las aristas son condiciones de transición. |
| Cómo resuelve P1 | Permite definir el grafo de dependencias de claims como un DAG ejecutable. Nodos independientes (Q-0003, Q-0005) se ejecutan en paralelo; nodos que dependen de Q-0001 esperan. |
| Ventaja clave | `StateGraph` con `parallel_branches` — ejecuta múltiples ramas simultáneamente y hace `join` cuando todas terminan. |
| Desventaja | Overhead de LLM en cada nodo; hay que ajustar qué decisiones son LLM vs. deterministas. |
| Fit con QuantPostRS | Alto — la lógica de "¿cuál es el próximo claim ejecutable?" es exactamente un problema de graph traversal con estado del corpus. |

```python
# Ejemplo conceptual con LangGraph
from langgraph.graph import StateGraph

workflow = StateGraph(CorpusState)
workflow.add_node("select_ready_claims", select_claims_without_pending_deps)
workflow.add_node("execute_q003", run_q003_sanity_check)   # paralelo
workflow.add_node("execute_q005", run_q005_operator_basis) # paralelo
workflow.add_node("execute_q001_brst", run_q001_brst)      # paralelo
workflow.add_edge("select_ready_claims", ["execute_q003", "execute_q005", "execute_q001_brst"])
```

---

#### Candidato B — **Prefect** / **Dagster**

| Aspecto | Detalle |
|---------|---------|
| Qué es | Frameworks de orquestación de workflows con DAG explícito, retries, observabilidad y scheduling. |
| Cómo resuelve P1 | Define las dependencias entre claims como un DAG de tareas. `@task` en Prefect o `@op` en Dagster. Las tareas sin dependencias corren en paralelo automáticamente. |
| Ventaja clave | UI de observabilidad del pipeline; retries automáticos si un script falla por timeout; logs centralizados. |
| Desventaja | Más overhead de setup; orientado a data pipelines, no a investigación simbólica. |
| Fit con QuantPostRS | Medio — muy poderoso para orquestación, pero no aporta inteligencia para decidir qué claim formular. |

```python
# Ejemplo con Prefect
from prefect import task, flow

@task
def execute_claim(claim_id: str, script_paths: list) -> ClaimResult:
    ...

@flow
def research_pipeline(corpus_state: CorpusState):
    ready = corpus_state.get_executable_claims()
    # Prefect ejecuta en paralelo automáticamente
    results = execute_claim.map(ready)
```

---

#### Candidato C — **Ray** (distributed parallel execution)

| Aspecto | Detalle |
|---------|---------|
| Qué es | Framework de computación distribuida y paralela para Python. |
| Cómo resuelve P1 | Los scripts Cadabra2 y SageMath son procesos externos (`subprocess`). Ray puede lanzarlos como `remote` tasks en paralelo, con gestión de recursos (CPU, memoria) y fault tolerance. |
| Ventaja clave | Escala a múltiples máquinas si los cálculos se vuelven pesados (e.g. análisis espectral de operadores 16×16). |
| Desventaja | Overkill para el volumen actual de scripts. |
| Fit con QuantPostRS | Bajo ahora, Alto cuando haya 50+ claims con scripts costosos. |

---

**Recomendación P1:** **LangGraph** para la lógica agéntica de selección y ejecución. **Prefect** como scheduler/orquestador si se necesita UI de observabilidad. Paralelismo inmediato: ejecutar Q-0003 y Q-0005 ahora, sin esperar Q-0001.

---

### P2 — Mutation tests sin enforcement mecánico

**El problema:** `FORMAL_METHODS_GUIDE.md` declara mutation tests obligatorios. `EVAL-0001` los omite. No hay ningún mecanismo que impida que un EVAL asigne `TESTED_PASS` sin ellos.

#### Candidato A — **pre-commit hooks** + validador de schema YAML

| Aspecto | Detalle |
|---------|---------|
| Qué es | Framework de hooks de git que se ejecutan antes de cada commit. |
| Cómo resuelve P2 | Un hook valida que cualquier archivo `EVAL-XXXX.md` con `status: TESTED_PASS` tenga campo `mutation_tests_report:` con valor no nulo. Si no, el commit es bloqueado. |
| Implementación | Script Python de ~30 líneas con `pyyaml` + `pre-commit`. |
| Ventaja clave | Enforcement en el punto de escritura, no en revisión manual. |
| Desventaja | Fácil de saltear con `git commit --no-verify`. |

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: validate-eval-mutation-tests
        name: Check mutation tests in EVAL files
        entry: python scripts/validate_eval_schema.py
        language: python
        files: ^evaluations/EVAL-.*\.md$
```

```python
# scripts/validate_eval_schema.py
import sys, yaml, re

for filepath in sys.argv[1:]:
    content = open(filepath).read()
    # Extraer YAML frontmatter
    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        continue
    meta = yaml.safe_load(match.group(1))
    if meta.get('status') == 'TESTED_PASS':
        if not meta.get('mutation_tests_report'):
            print(f"ERROR: {filepath} has TESTED_PASS but no mutation_tests_report field")
            sys.exit(1)
```

---

#### Candidato B — **Pydantic** schema validation + GitHub Actions

| Aspecto | Detalle |
|---------|---------|
| Qué es | Pydantic es la librería de validación de datos de Python más usada; GitHub Actions es CI/CD. |
| Cómo resuelve P2 | Definir un schema `EvalArtifact(BaseModel)` con `mutation_tests_report: str = Field(...)` requerido cuando `status == TESTED_PASS`. CI falla si algún EVAL viola el schema. |
| Ventaja clave | Más expresivo que YAML puro; permite validaciones condicionales. |
| Desventaja | Requiere que los archivos `.md` sean parseados como YAML frontmatter + texto. |

```python
from pydantic import BaseModel, validator
from typing import Optional, Literal

class EvalArtifact(BaseModel):
    id: str
    status: Literal["TESTED_PASS", "TESTED_PARTIAL", "TESTED_FAIL", ...]
    mutation_tests_report: Optional[str] = None

    @validator("mutation_tests_report", always=True)
    def require_mutation_tests_for_pass(cls, v, values):
        if values.get("status") == "TESTED_PASS" and not v:
            raise ValueError("TESTED_PASS requires mutation_tests_report")
        return v
```

---

#### Candidato C — **Hypothesis** (property-based testing)

| Aspecto | Detalle |
|---------|---------|
| Qué es | Librería Python de property-based testing: genera automáticamente casos de mutación a partir de propiedades declaradas. |
| Cómo resuelve P2 | Para cada claim, definir `@given(b=floats(), sign=sampled_from([+1,-1]))` y verificar que cuando `b` cambia o el signo cambia, el residuo ya **no** es cero. Esto automatiza los mutation tests. |
| Ventaja clave | Genera cientos de mutaciones automáticamente sin escribirlas manualmente. |
| Desventaja | Los scripts de Cadabra2 son procesos externos en CDB, no funciones Python puras. Requiere wrapper. |

```python
from hypothesis import given, assume
from hypothesis.strategies import floats, sampled_from
import subprocess

@given(
    b_mutated=floats(min_value=0.01, max_value=10.0),
    sign=sampled_from([-1, 1])
)
def test_claim_0001_mutation(b_mutated, sign):
    # b correcto es 1/m * sqrt(2/3) ≈ 0.816/m
    b_correct = 0.8165  # ejemplo para m=1
    assume(abs(b_mutated - b_correct) > 0.01)  # mutación real

    result = run_sage_claim(b=b_mutated, sign=sign)
    # Un b incorrecto DEBE producir residuo ≠ 0
    assert result.residue_norm > 1e-10, \
        f"Mutation with b={b_mutated} passed — script is not detecting mutations!"
```

---

**Recomendación P2:** **pre-commit + Pydantic** como gate inmediato (implementable hoy). **Hypothesis** como evolución para automation de mutation generation.

---

### P3 — Sin registry de corpus — no escala a 30+ claims

**El problema:** con 15 artefactos actuales el grafo de dependencias se mantiene mentalmente. Con 50+ artefactos — que son plausibles solo para cubrir Q-0001 a Q-0004 — se pierde trazabilidad.

#### Candidato A — **Neo4j** (grafo de dependencias)

| Aspecto | Detalle |
|---------|---------|
| Qué es | Base de datos de grafos nativa. Los nodos son artefactos (claims, scripts, reports, evals). Las aristas son relaciones (`DEPENDS_ON`, `TESTED_BY`, `USES_SCRIPT`, `SUPERSEDES`, `REFUTES`). |
| Cómo resuelve P3 | Queries como "dame todos los claims cuyas dependencias están en TESTED_PASS y que aún no tienen EVAL" son triviales en Cypher: `MATCH (c:Claim)-[:DEPENDS_ON]->(d) WHERE d.status='TESTED_PASS' AND NOT (c)-[:TESTED_BY]->(:Eval)`. |
| Ventaja clave | Visualización del grafo en Neo4j Browser. Detección automática de "ciclos" (dependencias circulares inválidas). |
| Desventaja | Infraestructura adicional (servidor Docker). Over-engineering si el corpus no supera 100 nodos. |

```cypher
// Ejemplo: ¿qué claims están listos para ejecutar ahora?
MATCH (c:Claim {status: 'PROPOSED'})
WHERE ALL(dep IN [(c)-[:DEPENDS_ON]->(d) | d] WHERE dep.status = 'TESTED_PASS')
RETURN c.id, c.title
```

---

#### Candidato B — **ChromaDB** (búsqueda semántica del corpus)

| Aspecto | Detalle |
|---------|---------|
| Qué es | Base de datos vectorial embebida (corre en proceso Python, sin servidor). Almacena documentos con embeddings para búsqueda por similitud semántica. |
| Cómo resuelve P3 | Indexa el contenido de todos los claims, preguntas abiertas y reportes. Un agente puede buscar "¿hay claims relacionados con invariancia de contacto?" y obtener los documentos más relevantes por embedding, sin recorrer el filesystem. |
| Ventaja clave | Embebido, sin servidor, API Python simple. Los agentes LLM pueden hacer RAG (Retrieval-Augmented Generation) sobre el corpus sin cargar todos los archivos en contexto. |
| Desventaja | No modela relaciones tipadas (DEPENDS_ON, etc.) — es búsqueda por similitud, no por estructura. |

```python
import chromadb

client = chromadb.Client()
corpus = client.create_collection("quantpostrs_corpus")

# Indexar todos los claims
for claim_file in Path("claims/").glob("CLAIM-*.md"):
    corpus.add(
        documents=[claim_file.read_text()],
        metadatas=[{"type": "claim", "status": get_status(claim_file)}],
        ids=[claim_file.stem]
    )

# Buscar claims relacionados con "invariancia de contacto"
results = corpus.query(
    query_texts=["invariancia de contacto acción cargada"],
    n_results=5
)
```

---

#### Candidato C — **DuckDB** + YAML frontmatter parsing

| Aspecto | Detalle |
|---------|---------|
| Qué es | Base de datos SQL embebida, analítica, extremadamente rápida para queries sobre archivos. |
| Cómo resuelve P3 | Un script Python parsea el frontmatter YAML de todos los artefactos y los carga en tablas DuckDB en memoria. Permite queries SQL complejos sobre el corpus sin infraestructura adicional. |
| Ventaja clave | Sin servidor, sin dependencias externas pesadas. Ideal para CI que genera un reporte de estado del corpus. |
| Desventaja | No modela grafos nativamente — hay que simular relaciones con JOINs. |

```python
import duckdb, yaml

# Parsear todos los claims
claims = []
for f in Path("claims/").glob("*.md"):
    meta = extract_yaml_frontmatter(f)
    claims.append(meta)

conn = duckdb.connect()
conn.execute("CREATE TABLE claims AS SELECT * FROM claims")
conn.execute("""
    -- ¿Qué claims tienen TESTED_PASS y no tienen mutation_tests_report?
    SELECT id, title FROM claims
    WHERE status = 'TESTED_PASS'
    AND (mutation_tests_report IS NULL OR mutation_tests_report = '')
""")
```

---

#### Candidato D — **RDF + SPARQL** (Knowledge Graph formal)

| Aspecto | Detalle |
|---------|---------|
| Qué es | Resource Description Framework — estándar W3C para representar grafos de conocimiento. SPARQL es el lenguaje de consulta. |
| Cómo resuelve P3 | Modela el corpus como un knowledge graph formal con ontología propia (`:Claim`, `:dependsOn`, `:testedBy`, etc.). Permite razonamiento formal sobre el grafo. |
| Ventaja clave | Estándar académico; interoperable con herramientas de física teórica e investigación. |
| Desventaja | Overhead de setup. Curva de aprendizaje de RDF/OWL para el equipo. |

---

**Recomendación P3:**
- **Corto plazo:** `DuckDB` + script Python de validación (implementable en 1 día).
- **Medio plazo:** `ChromaDB` para búsqueda semántica del corpus por agentes LLM.
- **Largo plazo** (>50 claims): `Neo4j` para el grafo de dependencias completo con visualización.

---

### P4 — Punto ciego compartido en verificación dual

**El problema:** Cadabra2 y SageMath ambos usan `η = diag(+1,-1,-1,-1)`. Un error sistemático de convención (e.g. signo de `D_μ`) pasa los dos verificadores simultáneamente.

#### Candidato A — **SymPy** como tercer verificador

| Aspecto | Detalle |
|---------|---------|
| Qué es | Librería Python de álgebra simbólica de propósito general. |
| Cómo resuelve P4 | Implementar los scripts de verificación en SymPy con representación completamente independiente de Cadabra2/SageMath. SymPy usa su propio motor de simplificación simbólica. |
| Ventaja clave | Puro Python, sin instalación extra. Puede usar convenciones alternativas (e.g. `(-+++)`) para cross-check. |
| Desventaja | SymPy tiene limitaciones con álgebra de Clifford no conmutativa; requiere `galgebra` o módulos específicos. |

```python
from sympy import symbols, Matrix, eye, zeros
from sympy.physics.matrices import mgamma

# Usar representación Dirac estándar
gamma = [mgamma(mu, diag=True) for mu in range(4)]
eta = Matrix([[1,0,0,0],[0,-1,0,0],[0,0,-1,0],[0,0,0,-1]])

# Verificar identidad gamma por SymPy independientemente
for mu in range(4):
    for nu in range(4):
        anticommutator = gamma[mu]*gamma[nu] + gamma[nu]*gamma[mu]
        expected = 2 * eta[mu,nu] * eye(4)
        assert anticommutator == expected, f"Clifford algebra failed at ({mu},{nu})"
```

---

#### Candidato B — **Lean4 / Mathlib** (verificación formal de teoremas)

| Aspecto | Detalle |
|---------|---------|
| Qué es | Lean4 es un proof assistant / lenguaje de programación funcional con sistema de tipos dependientes. Mathlib es su biblioteca matemática. |
| Cómo resuelve P4 | Formalizar el álgebra de Clifford y las simetrías gauge en Lean4. Un `theorem` en Lean4 con prueba completada es **matemáticamente irrefutable** bajo las hipótesis declaradas, independientemente de la representación matricial. |
| Ventaja clave | Elimina completamente el punto ciego de convenciones: las convenciones son axiomas explícitos del sistema de tipos. Si hay contradicción, Lean la detecta. |
| Desventaja | Curva de aprendizaje muy alta. Formalizar incluso CLAIM-0001 en Lean4 toma días de trabajo experto. No hay librería Lean existente para física de campos Post-RS. |
| Fit con QuantPostRS | Bajo a corto plazo, Muy alto a largo plazo para claims de alto impacto (espectro, BRST). |

---

#### Candidato C — **Verificación con representación alternativa** (Weyl o Majorana)

| Aspecto | Detalle |
|---------|---------|
| Qué es | Las matrices gamma admiten múltiples representaciones unitariamente equivalentes: Dirac, Weyl (quiral), Majorana. |
| Cómo resuelve P4 | Agregar un script SageMath-Weyl que verifica la misma identidad en representación de Weyl. Si las convenciones son correctas, el residuo es 0 en ambas representaciones. Si hay un error de convención, al menos una falla. |
| Ventaja clave | Sin tecnología nueva — es solo un script SageMath adicional con matrices diferentes. |
| Desventaja | No detecta errores en la lógica algebraica, solo en representaciones matriciales. |

```python
# Representación Weyl (quirale) — diferente de la Dirac usada en SCRIPT-SAGE-0001
sigma = [identity_matrix(2), ...]  # matrices de Pauli
gamma_weyl = [block_matrix([[zero_matrix(2), sigma[mu]], [sigma_bar[mu], zero_matrix(2)]]) 
              for mu in range(4)]
# Verificar el mismo claim con gamma_weyl
```

---

**Recomendación P4:**
- **Corto plazo:** Agregar SCRIPT-SAGE-WEYL-XXXX.sage con representación de Weyl para claims críticos.
- **Medio plazo:** SymPy como verificador simbólico independiente.
- **Largo plazo:** Lean4 para claims de alto valor (espectro, BRST nilpotencia).

---

### P5 — Scripts demasiado simples — CLAIM-0001 verifica `b·X - b·X = 0`

**El problema:** el script Cadabra2 actual literalmente evalúa `b D_μ ξ - b D_μ ξ`. El script SageMath evalúa `b * Dxi[mu] - b * Dxi[mu]`. Ambos son tautologías — no formalización real del claim.

#### Candidato A — **Reformalización con Cadabra2 real**

La invariancia de `W_μ` requiere:
1. Definir `W_μ = Ψ_μ - b D_μ χ` como objeto Cadabra2
2. Aplicar `δ_S`: sustituir `χ → χ + ξ` y `Ψ_μ → Ψ_μ + b D_μ ξ`
3. Calcular `δ_S W_μ = W_μ|_{nueva} - W_μ|_{original}` simbólicamente
4. Verificar que el residuo simplifica a 0

```python
# Script Cadabra2 correcto (propuesto para SCRIPT-CADABRA-0002)
{mu,nu}::Indices(spacetime, position=free).
{Psi_mu, chi, xi, W_mu}::Depends(x).
b::Constant.
D{#}::Derivative.

# Definición de W
W_mu := Psi_mu - b * D_mu{chi};

# Transformación de Stueckelberg
delta_Psi_mu := b * D_mu{xi};
delta_chi := xi;

# Variación de W bajo Stueckelberg
delta_W_mu := delta_Psi_mu - b * D_mu{delta_chi};
# = b D_μ ξ - b D_μ ξ
substitute(delta_W_mu, delta_chi -> xi);
canonicalise(delta_W_mu);
collect_terms(delta_W_mu);
```

Esto es algebraicamente idéntico al script actual, pero la **intención es visible**: el script demuestra que la cancelación ocurre porque `δ_S` y `D_μ` conmutan bajo `δ_S A_μ = 0`.

La formalización correcta para CLAIM-0002 (H_{μν}) es donde Cadabra2 aporta valor real, porque el conmutador `[D_μ, D_ν]` produce un término `F_{μν}` no trivial que debe cancelarse.

---

## 3. Arquitectura agéntica autónoma con procesos en paralelo

### 3.1 Visión general

La arquitectura propone un sistema multi-agente donde:
- Un **Orchestrator Agent** mantiene el estado del corpus y decide qué ejecutar
- **Worker Agents** especializados ejecutan en paralelo según disponibilidad de dependencias
- Un **Registry Service** (ChromaDB + DuckDB) provee memoria y búsqueda semántica
- Un **CI Gate** (pre-commit + Pydantic) enforcea las reglas del corpus automáticamente

```
┌─────────────────────────────────────────────────────────┐
│                  ORCHESTRATOR AGENT                      │
│  (LangGraph StateGraph — decide próximos claims)         │
│  • Lee corpus state desde Registry                       │
│  • Identifica claims ejecutables (deps satisfechas)      │
│  • Despacha Worker Agents en paralelo                    │
└────────────────────────┬────────────────────────────────┘
                         │  despacha en paralelo
         ┌───────────────┼───────────────────┐
         ▼               ▼                   ▼
┌────────────────┐ ┌────────────────┐ ┌──────────────────┐
│ CLAIM WRITER   │ │ SCRIPT RUNNER  │ │  MUTATION TESTER │
│   AGENT        │ │    AGENT       │ │     AGENT        │
│                │ │                │ │                  │
│ • Formula el   │ │ • Ejecuta      │ │ • Genera mutac.  │
│   claim mínimo │ │   Cadabra2     │ │   con Hypothesis │
│ • Crea         │ │ • Ejecuta      │ │ • Verifica que   │
│   CLAIM-XXXX  │ │   SageMath     │ │   FAIL en mutant │
│ • Crea scripts │ │ • Ejecuta Weyl │ │ • Crea REPORT    │
│   (Cadabra,    │ │   (cross-check)│ │   mutation       │
│    Sage, Weyl) │ │ • Captura      │ │                  │
└────────────────┘ │   residuos     │ └──────────────────┘
                   └───────┬────────┘
                           │
                    ┌──────▼──────┐
                    │  EVALUATOR  │
                    │    AGENT    │
                    │             │
                    │ • Clasifica │
                    │   resultado │
                    │ • Valida    │
                    │   schema    │
                    │   (Pydantic)│
                    │ • Crea      │
                    │   EVAL-XXXX │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  REGISTRY   │
                    │  UPDATER    │
                    │             │
                    │ • DuckDB    │
                    │ • ChromaDB  │
                    │ • Neo4j     │
                    └─────────────┘
```

---

### 3.2 Paralelismo: dos tracks simultáneos

El insight clave es que **Q-0003 y Q-0005 no dependen de Q-0001** y pueden ejecutarse ahora.

```
AHORA (paralelo):
├── TRACK A — Sanidad libre (Q-0003)
│     CLAIM-0005: q=0, verificar spin-3/2 puro
│     Tool: SageMath únicamente
│     Tiempo estimado: 1-2 días
│
├── TRACK B — Base de operadores (Q-0005)
│     CLAIM independiente: clasificar operadores Pauli
│     Tool: Cadabra2 únicamente
│     Tiempo estimado: 3-5 días
│
└── TRACK C — BRST (Q-0001) ← el largo
      CLAIM-0002: H_μν invariancia
      CLAIM-0003: covariancia EM
      CLAIM-0004: invariancia contacto
      CLAIM-0006: nilpotencia BRST
      Tool: Cadabra2 + SageMath + Weyl
      Tiempo estimado: semanas

DESBLOQUEO:
  Track A PASS + Track C CLAIM-0006 PASS → Q-0002 (espectro)
  Track B PASS + Q-0004 PASS → Q-0006 (coef. no-minimales)
```

---

### 3.3 Diseño detallado de los agentes

#### Orchestrator Agent

```python
# Pseudocódigo LangGraph
class CorpusState(TypedDict):
    claims: dict[str, ClaimStatus]
    ready_to_execute: list[str]
    running: list[str]
    completed: list[str]

def select_ready_claims(state: CorpusState) -> CorpusState:
    """Lee registry, identifica claims con todas las dependencias en TESTED_PASS."""
    registry = DuckDBRegistry.load()
    ready = registry.query("""
        SELECT c.id FROM claims c
        WHERE c.status IN ('PROPOSED', 'FORMALIZED')
        AND NOT EXISTS (
            SELECT 1 FROM dependencies d
            JOIN claims dep ON d.depends_on = dep.id
            WHERE d.claim_id = c.id
            AND dep.status != 'TESTED_PASS'
        )
    """)
    state["ready_to_execute"] = [r["id"] for r in ready]
    return state

# Grafo de ejecución
workflow = StateGraph(CorpusState)
workflow.add_node("select_ready", select_ready_claims)
workflow.add_node("spawn_workers", spawn_parallel_workers)  # fan-out
workflow.add_node("collect_results", collect_and_update_registry)  # fan-in
workflow.add_conditional_edges("collect_results", check_if_new_claims_ready)
```

---

#### Script Runner Agent

```python
import subprocess
import tempfile
from pathlib import Path

class ScriptRunnerAgent:
    def run_cadabra2(self, script_path: str) -> ScriptResult:
        result = subprocess.run(
            ["env", "MPLCONFIGDIR=/tmp/mpl-cadabra", "cadabra2", script_path],
            capture_output=True, text=True, timeout=300
        )
        return ScriptResult(
            tool="cadabra2",
            stdout=result.stdout,
            stderr=result.stderr,
            returncode=result.returncode,
            residue=self._extract_residue(result.stdout)
        )

    def run_sagemath(self, script_path: str) -> ScriptResult:
        result = subprocess.run(
            ["env", "DOT_SAGE=/tmp/sage-dot", "sage", script_path],
            capture_output=True, text=True, timeout=300
        )
        return ScriptResult(...)

    def run_weyl_cross_check(self, claim_id: str) -> ScriptResult:
        """Tercer verificador con representación Weyl."""
        weyl_script = self._generate_weyl_script(claim_id)
        return self.run_sagemath(weyl_script)
```

---

#### Mutation Tester Agent (con Hypothesis)

```python
from hypothesis import given, settings
from hypothesis.strategies import floats, sampled_from

class MutationTesterAgent:
    def test_claim(self, claim: ClaimSpec) -> MutationReport:
        mutations_tested = 0
        mutations_detected = 0

        # Mutar cada coeficiente del claim
        for coeff_name, correct_value in claim.coefficients.items():
            for mutated_value in self._generate_mutations(correct_value):
                result = self._run_with_mutation(claim, coeff_name, mutated_value)
                mutations_tested += 1
                if result.residue_norm > 1e-10:
                    mutations_detected += 1

        return MutationReport(
            claim_id=claim.id,
            total_mutations=mutations_tested,
            detected=mutations_detected,
            detection_rate=mutations_detected / mutations_tested,
            passed=mutations_detected == mutations_tested  # 100% detection required
        )

    def _generate_mutations(self, correct_value: float) -> list[float]:
        """Genera valores que NO son el correcto."""
        return [correct_value * 2, correct_value * 0.5,
                -correct_value, correct_value + 1.0,
                0.0, 1.0, -1.0]
```

---

#### Registry Service (DuckDB + ChromaDB)

```python
class CorpusRegistry:
    def __init__(self, workspace_path: str):
        self.db = duckdb.connect(f"{workspace_path}/.corpus_registry.duckdb")
        self.vector_store = chromadb.PersistentClient(
            path=f"{workspace_path}/.corpus_vectors"
        )
        self._init_schema()

    def _init_schema(self):
        self.db.execute("""
            CREATE TABLE IF NOT EXISTS artifacts (
                id VARCHAR PRIMARY KEY,
                type VARCHAR,  -- claim, script, report, eval, interp, decision, question
                title VARCHAR,
                status VARCHAR,
                created DATE,
                mutation_tests_report VARCHAR,
                file_path VARCHAR
            );
            CREATE TABLE IF NOT EXISTS dependencies (
                artifact_id VARCHAR,
                depends_on_id VARCHAR,
                PRIMARY KEY (artifact_id, depends_on_id)
            );
        """)

    def sync_from_filesystem(self, workspace_path: str):
        """Lee todos los archivos .md del corpus y actualiza el registry."""
        for folder in ["claims", "evaluations", "reports", "open_questions",
                       "interpretations", "decisions"]:
            for md_file in Path(f"{workspace_path}/{folder}").glob("*.md"):
                meta = extract_yaml_frontmatter(md_file)
                self.upsert_artifact(meta, str(md_file))
                # También indexar en ChromaDB para búsqueda semántica
                self.vector_store.get_or_create_collection("corpus").upsert(
                    documents=[md_file.read_text()],
                    ids=[meta["id"]]
                )

    def get_executable_claims(self) -> list[str]:
        return self.db.execute("""
            SELECT a.id FROM artifacts a
            WHERE a.type = 'claim'
            AND a.status IN ('PROPOSED', 'FORMALIZED')
            AND NOT EXISTS (
                SELECT 1 FROM dependencies d
                JOIN artifacts dep ON d.depends_on_id = dep.id
                WHERE d.artifact_id = a.id
                AND dep.status != 'TESTED_PASS'
            )
        """).fetchall()

    def validate_corpus_integrity(self) -> list[str]:
        """Retorna lista de violaciones de reglas del corpus."""
        violations = []

        # Regla: TESTED_PASS sin mutation tests
        missing_mutations = self.db.execute("""
            SELECT id FROM artifacts
            WHERE type = 'eval' AND status = 'TESTED_PASS'
            AND (mutation_tests_report IS NULL OR mutation_tests_report = '')
        """).fetchall()
        for (id,) in missing_mutations:
            violations.append(f"VIOLATION: {id} has TESTED_PASS but no mutation tests")

        return violations
```

---

### 3.4 Diagrama de flujo del ciclo completo

```
INICIO DE CICLO
      │
      ▼
Registry.sync_from_filesystem()
      │
      ▼
Orchestrator.select_ready_claims()
      │
      ├── Si no hay claims listos: STOP (investigador debe formular nuevos)
      │
      ▼
┌─────────────────────────────────────────────────┐
│ PARALLEL EXECUTION (fan-out)                     │
│                                                  │
│  claim_A ──► Writer ──► Runner ──► Mutator ──┐  │
│  claim_B ──► Writer ──► Runner ──► Mutator ──┤  │
│  claim_C ──► Writer ──► Runner ──► Mutator ──┘  │
└───────────────────────────┬─────────────────────┘
                            │ fan-in (join)
                            ▼
                    Evaluator.classify_all()
                            │
                            ▼
                    CI Gate (Pydantic validation)
                      ┌─────┴─────┐
                      │ PASS gate │ FAIL gate
                      ▼           ▼
                Registry.update  Notificar al investigador
                            │
                            ▼
                    ¿Hay nuevas preguntas
                     abiertas desbloqueadas?
                      ┌─────┴─────┐
                      │ SÍ        │ NO
                      ▼           ▼
                   INICIO       STOP — esperar
                  DE CICLO      decisión humana
```

---

## 4. Stack tecnológico recomendado

### Por capa

| Capa | Tecnología | Propósito | Prioridad |
|------|-----------|-----------|-----------|
| **Orquestación** | LangGraph | DAG de agentes con paralelismo | 🔴 Alta |
| **Verificación formal** | Cadabra2 (existente) | Álgebra abstracta tensorial | existente |
| **Verificación matricial** | SageMath (existente) | Matrices 4×4 explícitas | existente |
| **Tercer verificador** | SageMath Weyl + SymPy | Cross-check de convenciones | 🟡 Media |
| **Mutation testing** | Hypothesis + wrapper | Auto-generación de mutantes | 🔴 Alta |
| **Registry** | DuckDB | SQL sobre corpus metadata | 🔴 Alta |
| **Búsqueda semántica** | ChromaDB | RAG sobre corpus para agentes | 🟡 Media |
| **Grafo de deps** | Neo4j | Visualización y queries de grafo | 🟢 Baja (>50 claims) |
| **Prueba formal** | Lean4 / Mathlib | Verificación matemáticamente irrefutable | 🟢 Baja (largo plazo) |
| **Schema validation** | Pydantic | Enforce reglas del corpus en CI | 🔴 Alta |
| **CI hooks** | pre-commit | Gate antes de commit | 🔴 Alta |
| **Scheduler** | Prefect | UI de observabilidad del pipeline | 🟡 Media |

### Instalación base (corto plazo, hoy)

```bash
# En el workspace
pip install duckdb chromadb pydantic hypothesis pre-commit langgraph prefect

# Verificadores adicionales
pip install sympy  # tercer verificador simbólico
```

---

## 5. Prioridades de implementación

### Sprint 1 — Infraestructura crítica (1-2 días)

1. **DuckDB Registry** (`scripts/registry.py`): parse YAML frontmatter de todos los artefactos, queries de corpus integrity.
2. **pre-commit hook** (`scripts/validate_eval_schema.py`): bloquea TESTED_PASS sin mutation tests.
3. **Pydantic schemas** (`scripts/corpus_schemas.py`): tipos para Claim, Eval, Report.
4. **CLAIM-0005** (sanidad q=0, SageMath): primer claim en Track A paralelo.

### Sprint 2 — Paralelismo y mutation testing (3-5 días)

5. **LangGraph Orchestrator** básico: select_ready_claims + spawn workers.
6. **Mutation Tester Agent**: wrapper Hypothesis sobre SageMath.
7. **CLAIM-0002** (H_{μν} invariancia Stueckelberg) con script Cadabra2 real.
8. **Script Weyl** como cross-check para CLAIM-0001 y CLAIM-0002.

### Sprint 3 — Semántica y observabilidad (5-10 días)

9. **ChromaDB indexing** de todo el corpus.
10. **Prefect UI** para observabilidad del pipeline.
11. **CLAIM-0003, 0004** en Track C (covariancia EM, invariancia de contacto).
12. **CLAIM-0006** (nilpotencia BRST) — desbloquea Q-0002.

### Sprint 4 — Largo plazo

13. **Neo4j** cuando el corpus supere 50 artefactos.
14. **Lean4 formalization** de claims de alto impacto (espectro, BRST).

---

*Documento generado el 26-05-2026. Basado en análisis adversarial del corpus QuantPostRS y estado actual de tecnologías de orquestación agéntica, bases de datos de grafos y verificación formal.*
