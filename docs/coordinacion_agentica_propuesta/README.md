# QuantPostRS Workflow — Sistema de agentes para investigación formal asistida

## 1. Propósito del proyecto

Este repositorio implementa un workflow de investigación formal asistida para el proyecto **QuantPostRS**. El objetivo no es que un agente “resuelva la física” de manera autónoma, sino construir un sistema auditable donde cada avance teórico quede registrado como parte de un corpus citable, reproducible y navegable.

La idea central es:

```text
Problema.tex
  → preguntas abiertas
  → claims mínimos
  → scripts Cadabra2/SageMath
  → reportes
  → evaluaciones
  → interpretaciones físicas controladas
```

El sistema busca evitar drift conceptual: ninguna producción previa se modifica silenciosamente. Si una idea se corrige, refuta o reemplaza, se crea un nuevo artefacto que enlaza formalmente al anterior.

---

## 2. Documentos principales

La carpeta contiene los siguientes documentos de diseño y operación:

```text
FISICO.md
master_agent.md
AGENTS.md
FORMAL_METHODS_GUIDE.md
AGENTS_review_monitor.md
QuantPostRS_workflow__Documentacion.pdf
Problema.tex
```

### `Problema.tex`

Es el documento de autoridad científica. Fija las convenciones, resultados establecidos, problemas abiertos y el estado conceptual de la investigación.

No debe modificarse salvo decisión humana explícita.

### `FISICO.md`

Define el rol del **Supervisor Científico**. Decide qué episodio de investigación lanzar, evalúa la calidad científica de los resultados y determina cuándo una línea puede clasificarse como:

```text
FUNDAMENTAL_FIELD_CANDIDATE
EFFECTIVE_FIELD_THEORY
FAILED_PROGRAM
HUMAN_DECISION_REQUIRED
```

El Físico no ejecuta mecánicamente tareas del repositorio: decide estrategia, prioridades y cierre científico.

### `master_agent.md`

Define el rol del **Agente Maestro**. Coordina episodios de trabajo:

1. diagnostica el estado del repo;
2. abre ramas;
3. formula prompts acotados para Codex;
4. revisa cambios;
5. decide si aceptar, iterar, rechazar o detener;
6. recomienda merge cuando corresponde.

El Agente Maestro no decide resultados físicos globales: eso corresponde al Físico.

### `AGENTS.md`

Contrato operativo general del repositorio. Fija convenciones, reglas duras, uso del corpus, roles de Cadabra2 y SageMath, y acciones prohibidas.

### `FORMAL_METHODS_GUIDE.md`

Guía metodológica del trabajo formal. Explica cómo pasar de preguntas abiertas a claims testeables, cómo usar Cadabra2 y SageMath, y cómo distinguir resultados algebraicos de interpretaciones físicas.

### `AGENTS_review_monitor.md`

Define el **Review Monitor Agent**, encargado de generar revisiones humanas en LaTeX. Sus productos van a `reviews/` y no forman parte del corpus primario.

### `QuantPostRS_workflow__Documentacion.pdf`

Documento de referencia para auditar e implementar el sistema de agentes. Resume el diseño del workflow, su filosofía de uso y el modo de organizar el repositorio.

---

## 3. Arquitectura conceptual de agentes

El sistema propone una jerarquía de agentes:

```text
FISICO.md
  ↓ decide estrategia científica
master_agent.md
  ↓ coordina episodios y controla Git/Codex
Codex CLI
  ↓ produce artefactos formales
claims / scripts / reports / evaluations / interpretations
```

### Nivel 1 — Físico

Responsable de la estrategia científica.

Decide:

- qué pregunta abierta importa ahora;
- qué episodio lanzar;
- si un resultado reduce incertidumbre física real;
- cuándo una línea está suficientemente cerrada;
- si el programa apunta a campo fundamental, EFT o fallo.

### Nivel 2 — Agente Maestro

Responsable de la ejecución organizada.

Coordina:

- ramas Git;
- prompts para Codex;
- revisión de cambios;
- aceptación, iteración, rechazo o detención;
- preservación del corpus append-only.

### Nivel 3 — Codex CLI

Responsable de producir artefactos acotados.

Puede crear:

- claims;
- scripts Cadabra2;
- scripts SageMath;
- reportes;
- evaluaciones;
- revisiones no canónicas.

No debe producir conclusiones físicas globales salvo instrucción explícita y evidencia formal suficiente.

### Nivel 4 — Review Monitor

Responsable de vistas humanas.

Genera:

- informes de estado de claims;
- revisiones completas en LaTeX;
- manifiestos de revisión;
- advertencias de drift, dependencias incompletas o usos indebidos de claims.

---

## 4. Corpus lógico distribuido

El proyecto usa un corpus lógico distribuido. Las carpetas siguientes contienen evidencia primaria una vez que tienen artefactos reales:

```text
open_questions/
claims/
scripts/
reports/
evaluations/
interpretations/
decisions/
```

Las carpetas siguientes no son evidencia primaria:

```text
working/
reviews/
```

`working/` se usa para borradores, scratchpads y trabajo temporal.

`reviews/` se usa para vistas humanas regenerables. Una revisión puede ser útil para decidir, pero no es evidencia primaria.

---

## 5. Principio append-only

Los artefactos del corpus no se editan ni se borran. Si una afirmación debe corregirse, se crea un nuevo artefacto con un nuevo ID.

Ejemplo:

```text
CLAIM-0010_gamma_trace_EOM.md
EVAL-0010_gamma_trace_partial.md
CLAIM-0017_weaker_gamma_trace_EOM.md
EVAL-0017_gamma_trace_pass.md
DECISION-0008_use_CLAIM-0017_not_CLAIM-0010.md
```

El corpus debe permitir reconstruir no solo qué se cree actualmente, sino también qué se intentó, qué falló y por qué fue descartado.

---

## 6. Convenciones fijas

El workflow adopta las siguientes convenciones:

```text
eta = diag(+1,-1,-1,-1)
{gamma^mu, gamma^nu} = 2 eta^{mu nu}
D_mu = partial_mu - i q A_mu
[D_mu,D_nu]X = - i q F_mu_nu X
slash D = gamma^mu D_mu
```

Estas convenciones deben coincidir entre:

- `Problema.tex`;
- `AGENTS.md`;
- scripts Cadabra2;
- scripts SageMath;
- reportes;
- evaluaciones.

Todo cambio de convención requiere una decisión explícita en `decisions/`.

---

## 7. Roles de Cadabra2 y SageMath

### Cadabra2

Cadabra2 es el auditor abstracto tensorial–espinorial.

Se usa para:

- manipulación de índices;
- álgebra de Clifford abstracta;
- trazas gamma;
- divergencias covariantes;
- conmutadores;
- variaciones de gauge;
- identidades de Noether;
- variaciones formales de acciones.

### SageMath

SageMath es el auditor de representación explícita y regresión.

Se usa para:

- matrices gamma explícitas en signatura `(+---)`;
- verificación componente a componente;
- tests de signos y coeficientes;
- pruebas de mutación;
- rangos, núcleos y símbolos principales;
- chequeos en fondos simples.

### Regla dura

```text
Cadabra2 prueba la identidad abstracta.
SageMath verifica una representación explícita independiente.
Ningún PASS debe declararse sin residuo cero explícito o justificación formal.
```

---

## 8. Estados de claims

Los claims pueden tener los siguientes estados:

```text
PROPOSED
FORMALIZED
TESTED_PASS
TESTED_PARTIAL
TESTED_FAIL
CONVENTION_MISMATCH
SUPERSEDED
REFUTED
RETRACTED
INCORPORATED
```

Solo claims `TESTED_PASS` o `INCORPORATED` pueden usarse como premisas para interpretaciones físicas.

---

## 9. Flujo típico de trabajo

Un episodio normal debería seguir esta secuencia:

```text
1. FISICO.md decide la pregunta y el objetivo.
2. master_agent.md abre una rama.
3. master_agent.md formula un prompt acotado para Codex.
4. Codex crea claim, scripts, reporte y evaluación.
5. master_agent.md revisa git diff y consistencia del corpus.
6. master_agent.md recomienda aceptar, iterar, rechazar o detener.
7. FISICO.md evalúa la calidad científica.
8. Si corresponde, se mergea.
9. Periódicamente, Review Monitor genera una revisión humana.
```

---

## 10. Git en el workflow

Git registra la historia técnica de archivos. El corpus registra la historia conceptual.

Uso recomendado:

```bash
git status
git checkout -b claim-0002-h-definition
codex
git status
git diff
```

Luego, si el episodio fue aceptado:

```bash
git add .
git commit -m "Add CLAIM-0002 H definition and commutator sign audit"
```

El Agente Maestro puede recomendar merge solo si:

- no se modificó `Problema.tex`;
- no se editaron artefactos previos del corpus;
- los cambios son append-only;
- los tests están documentados;
- la evaluación es prudente.

---

## 11. Criterios de aceptación de un episodio

Un episodio puede aceptarse si:

- responde a una pregunta abierta;
- produce claims mínimos y testeables;
- usa Cadabra2/SageMath adecuadamente;
- conserva residuos y comandos;
- documenta límites;
- no infiere física prematuramente;
- preserva el corpus append-only.

Debe rechazarse si:

- modifica `Problema.tex` sin autorización;
- edita artefactos previos;
- cambia convenciones para obtener cero;
- declara PASS sin evidencia;
- oculta FAIL;
- usa claims PARTIAL como premisas físicas.

Debe detenerse si:

- aparece una ambigüedad física no resoluble formalmente;
- hay contradicción entre claims `TESTED_PASS`;
- Cadabra2 y SageMath discrepan sin diagnóstico;
- se requiere decisión humana conceptual;
- avanzar exige cambiar la teoría.

---

## 12. Primeros episodios recomendados

La secuencia inicial sugerida es:

```text
CLAIM-0001 — invariancia de W_mu
CLAIM-0002 — definición de H_mu_nu y signo del conmutador
CLAIM-0003 — límite libre de Lambda(D) hacia Lambda(partial)
CLAIM-0004 — identidades gamma-null cargadas
CLAIM-0005 — matching libre básico
CLAIM-0006 — gamma-traza de las EOM
CLAIM-0007 — divergencia covariante de las EOM
```

No conviene abordar espectro completo, causalidad general o renormalización antes de asegurar estos bloques.

---

## 13. Resultados científicos globales

Al final de una línea de investigación, el Físico puede clasificar el programa como:

### Campo fundamental

```text
FINAL_RESULT: FUNDAMENTAL_FIELD_CANDIDATE
```

Requiere evidencia fuerte sobre espectro, positividad, causalidad, BRST, anomalías y comportamiento UV.

### Campo efectivo

```text
FINAL_RESULT: EFFECTIVE_FIELD_THEORY
```

Resultado positivo si la teoría es consistente dentro de un régimen de validez, aunque no sea fundamental.

### Investigación fallida

```text
FINAL_RESULT: FAILED_PROGRAM
```

Debe declararse si existe inconsistencia fatal, modos espurios inevitables, pérdida no reparable de positividad, acausalidad no controlable o imposibilidad de definir una EFT coherente.

### Decisión humana requerida

```text
FINAL_RESULT: HUMAN_DECISION_REQUIRED
```

Se usa cuando el sistema formal no puede avanzar sin una elección conceptual externa.

---

## 14. Uso con GitHub Copilot

Este README está diseñado para que GitHub Copilot pueda auditar la carpeta y ayudar a implementar el sistema de agentes.

Para una auditoría inicial con Copilot, se sugiere pedir:

```text
Leé README.md, FISICO.md, master_agent.md, AGENTS.md,
FORMAL_METHODS_GUIDE.md, AGENTS_review_monitor.md
y QuantPostRS_workflow__Documentacion.pdf.

No modifiques archivos.

Analizá si la estructura del repositorio implementa correctamente:
1. jerarquía Físico → Agente Maestro → Codex;
2. corpus append-only;
3. workflow de claims;
4. separación entre corpus y reviews;
5. uso de Cadabra2 y SageMath;
6. reglas de Git;
7. criterios de detención.

Reportá inconsistencias y proponé cambios mínimos.
```

Para implementar ajustes:

```text
Implementá solo los cambios mínimos necesarios para alinear el repositorio
con README.md, FISICO.md y master_agent.md.

No modifiques Problema.tex.
No edites artefactos existentes del corpus.
No crees claims nuevos.
No escribas scripts nuevos.
Al final listá todos los archivos modificados.
```

---

## 15. Advertencias

Este sistema no garantiza por sí mismo la corrección física del programa. Su función es hacer que los errores sean visibles, trazables y corregibles.

El objetivo no es automatizar la física, sino evitar que el razonamiento avance sin evidencia formal.

Frase rectora:

```text
The agent must not advance the theoretical argument faster than the formal checks can follow.
```

Versión operativa:

```text
La física puede correr, pero Cadabra2 y SageMath le piden documento en cada esquina.
```
