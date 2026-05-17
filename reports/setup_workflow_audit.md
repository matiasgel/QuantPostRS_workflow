---
id: SETUP-WORKFLOW-AUDIT-0001
type: report
title: Reporte de setup del workflow QuantPostRS
created: 2026-05-17
author: Codex
claim: null
scripts: []
status: informational
depends_on:
  - AGENTS.md
  - FORMAL_METHODS_GUIDE.md
  - AGENTS_review_monitor.md
  - decisions/DECISION-0001.md
  - Problema.tex
notes:
  - "Reporte de setup: no formaliza ni evalua claims."
---

# Reporte de setup del workflow QuantPostRS

## 1. Estructura actual del repositorio

Directorios de control y configuracion:

- `.agents/`
- `.codex/`
- `.git/`

Archivos de raiz detectados:

- `.gitignore`
- `AGENTS.md`
- `AGENTS_review_monitor.md`
- `FORMAL_METHODS_GUIDE.md`
- `Problema.tex`

Corpus logico distribuido:

- `open_questions/`
  - `Q_TEMPLATE.md`
- `claims/`
  - `CLAIM_TEMPLATE.md`
- `scripts/`
  - `scripts/cadabra/`
  - `scripts/sage/`
- `reports/`
  - `REPORT_TEMPLATE.md`
  - `setup_workflow_audit.md`
- `evaluations/`
  - `EVAL_TEMPLATE.md`
- `interpretations/`
  - `INTERP_TEMPLATE.md`
- `decisions/`
  - `DECISION-0001.md`

Trabajo y revision, no evidencia primaria:

- `working/`
- `reviews/`
  - `reviews/current/`

## 2. Archivos esperados presentes y ausentes

Presentes:

- `AGENTS.md`
- `FORMAL_METHODS_GUIDE.md`
- `AGENTS_review_monitor.md`
- `Problema.tex`
- `decisions/DECISION-0001.md`
- Plantillas en `open_questions/`, `claims/`, `reports/`, `evaluations/` e `interpretations/`
- Directorios `scripts/cadabra/` y `scripts/sage/`

Ausentes o no detectados:

- `Guia_usuario.tex`
- Directorio literal `corpus/`
- `corpus/index.md`
- `corpus/registry.yml`
- `scripts/shared/`
- Claims reales distintos de `CLAIM_TEMPLATE.md`
- Open questions reales distintas de `Q_TEMPLATE.md`
- Scripts Cadabra2 o SageMath reales
- Evaluaciones reales distintas de `EVAL_TEMPLATE.md`
- Interpretaciones reales distintas de `INTERP_TEMPLATE.md`
- Revisiones actuales en `reviews/current/`

Segun `DECISION-0001`, la ausencia de un directorio literal `corpus/` no bloquea el
workflow: el corpus logico esta distribuido en carpetas de primer nivel.

## 3. Convenciones detectadas en `Problema.tex`

Convenciones explicitas para lectura automatica:

- `A_mu` es el potencial electromagnetico.
- `A=-1/2` es el parametro historico de contacto de Rarita-Schwinger; no debe
  identificarse con `A_mu`.
- La derivada covariante se usa como `D_mu X = (partial_mu - i q A_mu) X`.
- La transformacion electromagnetica asociada es `X -> exp(i q lambda) X` y
  `A_mu -> A_mu + partial_mu lambda`.
- `lambda(x)` es el parametro de `U(1)_em`, no un parametro de fijacion de gauge.
- `xi` es el parametro clasico de Stueckelberg; en el sector libre de tesis esta
  restringido por `slashed partial xi = 0`.
- En la completacion cargada, la simetria Stueckelberg local se organiza mediante
  el bloque invariante `W_mu`.
- `epsilon` es el parametro de contacto.
- Los ghosts `c`, `eta` y `rho` corresponden a `U(1)_em`, Stueckelberg y contacto,
  respectivamente.
- Toda afirmacion de consistencia cuantica debe leerse como programa o test pendiente
  salvo que el documento la declare demostrada.

Convenciones operativas que `AGENTS.md` fija para el workflow:

- Signatura `eta = diag(+1,-1,-1,-1)`.
- Algebra de Clifford `{gamma^mu,gamma^nu} = 2 eta^{mu nu} 1`.
- Conmutador covariante `[D_mu,D_nu] X = -i q F_{mu nu} X`.
- Constancia covariante `D_mu gamma^nu = 0`.
- `D_mu`, `m`, `q` y coeficientes escalares conmutan con las matrices gamma salvo
  indicacion contraria.
- Slash `slashed D = gamma^mu D_mu`.
- Subida y bajada de indices con `eta`.

## 4. Comparacion entre `Problema.tex`, `AGENTS.md` y `FORMAL_METHODS_GUIDE.md`

Coincidencias principales:

- AGENTS.md, FORMAL_METHODS_GUIDE.md y este reporte toman `Problema.tex` como fuente autorizada para convenciones,
  resultados establecidos y problemas abiertos.
- `AGENTS.md` y `Problema.tex` coinciden en la derivada covariante
  `D_mu = partial_mu - i q A_mu`.
- `AGENTS.md` y `Problema.tex` coinciden en el conmutador
  `[D_mu,D_nu] X = -i q F_{mu nu} X`.
- `FORMAL_METHODS_GUIDE.md` coincide con `AGENTS.md` en que no se deben extraer
  conclusiones fisicas sin comprobaciones formales reproducibles.
- `FORMAL_METHODS_GUIDE.md` y `Problema.tex` coinciden en separar resultados
  algebraicos/cinematicos de tests dinamicos y cuanticos pendientes.
- `AGENTS.md` y `DECISION-0001.md` ya adoptan el corpus logico distribuido como
  estructura vigente.

Diferencias de nivel:

- `Problema.tex` contiene formulacion fisica,
  convenciones de lectura y lista de problemas abiertos.
- `AGENTS.md` es protocolo operativo: fija reglas duras, estados de claims,
  inmutabilidad y restricciones de uso.
- `FORMAL_METHODS_GUIDE.md` es guia metodologica: describe fases, tipos de claims,
  pruebas de mutacion y coordinacion Cadabra2/SageMath.

Estado de resultados:

- `Problema.tex` declara demostradas invariancias clasicas de la construccion cargada.
- En el corpus logico todavia no hay claims, scripts, reportes de prueba ni
  evaluaciones que certifiquen esos resultados como `TESTED_PASS`.
- Por lo tanto, para el workflow formal, esos resultados deben reproducirse como
  claims minimos antes de usarse como premisas formales de interpretaciones fisicas.

## 5. Advertencias de ambiguedad

- `FORMAL_METHODS_GUIDE.md` todavia menciona `corpus/index.md` y
  `corpus/registry.yml`; esos archivos no existen y la decision activa adopta un
  corpus logico distribuido.
- `AGENTS_review_monitor.md` todavia describe entradas bajo `corpus/claims/`,
  `corpus/scripts/`, etc.; debe interpretarse a traves de `DECISION-0001` como
  referencia al corpus logico distribuido.
- `FORMAL_METHODS_GUIDE.md` menciona auditar convenciones implementadas en
  `scripts/shared/`, pero ese directorio no existe.
- `AGENTS.md` contiene una errata menor en la accion prohibida "Cambiar el
  `Problema.tex ." con comilla/backtick incompleto.
- No existe indice o registry actual del corpus logico. La vista del estado se obtiene
  por recorrido de carpetas.
- Las plantillas estan dentro de carpetas del corpus logico. Conviene tratarlas como
  plantillas iniciales, no como evidencia formal de claims, evaluaciones o reportes.
- El archivo `Problema.tex` usa afirmaciones teoricas demostradas en el texto, pero el
  workflow formal todavia no las ha convertido en artefactos auditables.

## 6. Recomendacion del siguiente paso seguro

El siguiente paso seguro es crear un mapa de preguntas abiertas en `open_questions/`
basado estrictamente en la seccion de problemas abiertos de `Problema.tex`, sin crear
claims todavia. Ese mapa deberia usar identificadores estables, depender de
`Problema.tex` y de `DECISION-0001`, y distinguir preguntas algebraicas, dinamicas y
fisicas.

Despues de ese mapa, el primer trabajo formal deberia ser seleccionar una sola pregunta
abierta y formular un claim minimo reproducible, con residuo claro y alcance limitado.
No corresponde extraer interpretaciones fisicas hasta tener claims `TESTED_PASS`.
