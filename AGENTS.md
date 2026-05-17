# AGENTES – Workflow de Investigación Formal para QuantPostRS

## Misión del repositorio

Este repositorio está destinado a realizar trabajo teórico formal asistido sobre `Problema.tex`. El archivo `Problema.tex` es la fuente autorizada de supuestos, convenciones, resultados establecidos y problemas abiertos. Los agentes pueden proponer nuevos *claims* (afirmaciones) únicamente como pasos locales hacia los problemas abiertos declarados en `Problema.tex` o de manera claramente motivada por el mismo.

## Convenciones fijas (no negociables)

- **Signatura**: la métrica es \(\eta = \mathrm{diag}(+1,-1,-1,-1)\).
- **Álgebra de Clifford**: \(\{\gamma^\mu,\gamma^\nu\} = 2\,\eta^{\mu\nu}\,\mathbb{1}\).
- **Derivada covariante**: \(D_\mu = \partial_\mu - \mathrm{i}\,q\,A_\mu\).
- **Conmutador covariante**: \([D_\mu,D_\nu]\,X = -\mathrm{i}\,q\,F_{\mu\nu}\,X\).
- **Constancia covariante de las gammas**: \(D_\mu\gamma^\nu = 0\).
- **Conmutación**: \(D_\mu\), \(m\), \(q\) y demás coeficientes escalar conmutan con las matrices gamma, excepto cuando se especifique lo contrario.
- **Operador slash**: \(\slashed D = \gamma^\mu D_\mu\).
- **Subida/bajada de índices**: \(X^\mu = \eta^{\mu\nu} X_\nu\) y \(X_\mu = \eta_{\mu\nu} X^\nu\).

Estas convenciones no deben ser modificadas sin una decisión explícita registrada en el corpus.

## Regla anti-deriva (corpus inmutable)

En este repositorio, el corpus histórico es un corpus lógico distribuido en carpetas de primer nivel: `open_questions/`, `claims/`, `scripts/`, `reports/`, `evaluations/`, `interpretations/` y `decisions/`. Los artefactos que se añaden a esas carpetas son *inmutables*: no pueden modificarse ni borrarse. Para revisiones o refutaciones se deben crear nuevos artefactos que hagan referencia explícita a los anteriores (`supersedes`, `refutes`, etc.).  
Los archivos de trabajo y revisiones (`working/`, `reviews/`) sí pueden modificarse; no son evidencia primaria.

## Flujo de trabajo general

1. **Lectura de contexto**: el agente lee el `Problema.tex` y el índice actual del corpus.
2. **Identificación de problemas abiertos**: se registran preguntas abiertas en `open_questions/`.
3. **Formulación de claim**: se define un *claim* mínimo y se crea `claims/CLAIM-XXXX.md`.
4. **Formalización**: se escriben scripts Cadabra2 (`scripts/cadabra/SCRIPT-CADABRA-XXXX.cdb`) y/o SageMath (`scripts/sage/SCRIPT-SAGE-XXXX.sage`) que codifican el claim.
5. **Ejecutar pruebas**: se corren los scripts, se capturan residuos y se crea un reporte `reports/REPORT-XXXX.md`.
6. **Evaluación**: se crea `evaluations/EVAL-XXXX.md` que clasifica el claim como `TESTED_PASS`, `TESTED_PARTIAL`, `TESTED_FAIL`, `CONVENTION_MISMATCH`, etc.
7. **Interpretación física**: solo claims con estatus `TESTED_PASS` pueden usarse como premisas para interpretación; se documenta en `interpretations/`.
8. **Decisiones**: cambios de convenciones, reglas o lineamientos se registran en `decisions/`.

Cada claim, script, reporte, evaluación e interpretación debe enlazar formalmente a los artefactos de los que depende (usando campos YAML como `depends_on`, `uses_scripts`, etc.).

## Roles de las herramientas

- **Cadabra2**: auditor abstracto tensorial–espinorial. Se utiliza para manipular índices, gammas, trazas, divergencias, conmutadores, variaciones de acciones y comprobación formal de identidades.
- **SageMath**: auditor de regresión en representaciones explícitas. Se utiliza para comprobar identidades usando matrices gamma \(4\times 4\), analizar símbolos principales en fondos simples, calcular rangos y núcleos, y realizar pruebas de mutación.
- **Review Monitor**: produce revisiones en LaTeX del estado del corpus; no forma parte del corpus.

## Semántica de estatus de claims

- **PROPOSED**: claim formulado sin formalización aún.
- **FORMALIZED**: claim con scripts listos para probar.
- **TESTED_PASS**: scripts se ejecutan y el residuo es exactamente cero, bajo las convenciones declaradas.
- **TESTED_PARTIAL**: scripts ejecutan, pero queda residuo sin reducir, o la formalización cubre solo parte del claim.
- **TESTED_FAIL**: el residuo es distinto de cero bajo las hipótesis declaradas.
- **CONVENTION_MISMATCH**: los scripts o las pruebas usan convenciones incompatibles.
- **SUPERSEDED**: claim reemplazado por otro.
- **REFUTED**: claim refutado explicitamente.
- **RETRACTED**: claim retirado.

Solo claims `TESTED_PASS` pueden usarse como premisa para conclusiones físicas.

## Reglas duras adicionales

1. Un claim no puede saltar de `PROPOSED` a `INCORPORATED` sin pasar por una prueba formal.
2. Un claim sólo puede utilizarse como premisa si su estatus es `TESTED_PASS` o `INCORPORATED`.
3. Los scripts que prueban un claim no pueden modificar convenciones ni definiciones adoptadas.
4. **Sage PASS** certifica identidades matriciales bajo la representación \((+---)\); un `PARTIAL` de Cadabra2 nunca puede sobreescribir un `PASS` de Sage.
5. **Cadabra PASS** requiere residuo cero explícito en código ejecutable Cadabra2.
6. Mutar coeficientes, signos o definiciones para obtener un residuo nulo se considera incorrecto; las pruebas deben detectar mutaciones artificiales.
7. Toda decisión sobre convención o cambio de reglas debe registrarse en `decisions/`.
8. No está permitido declarar conclusiones físicas basadas en claims `PARTIAL` o `PROPOSED`.

## Acciones prohibidas

- Editar o borrar artefactos del corpus lógico distribuido (`open_questions/`, `claims/`, `scripts/`, `reports/`, `evaluations/`, `interpretations/`, `decisions/`).
- Cambiar el `Problema.tex .
- Ajustar los scripts para que el residuo desaparezca eliminando términos en la definición original.
- Reemplazar definiciones para evitar residuo sin documentarlo.
- Ignorar warnings del Review Monitor sobre dependencias sin `TESTED_PASS`.

---
