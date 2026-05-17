# Guía de métodos formales — Análisis del documento QuantPostRS

## Propósito

Esta guía explica la filosofía y los métodos que guían el trabajo formal asistido en este repositorio. El objetivo no es automatizar completamente el razonamiento físico, sino garantizar que cada paso algebraico que respalda una conclusión física pase por comprobaciones formales reproducibles.

## Ciclo de investigación propuesto

1. **Autoridad de `Problema.tex`**: `Problema.tex` fija las convenciones, los resultados establecidos y las preguntas abiertas.
2. **Pregunta abierta**: El investigador detecta una pregunta que aún no está resuelta.
3. **Claim candidato**: Se formula un claim mínimo que, de ser demostrado, avanza la pregunta abierta.
4. **Residuo formal**: El claim se traduce a expresiones que permiten calcular un residuo (la diferencia entre ambas partes de la identidad o el operador).
5. **Pruebas Cadabra2/SageMath**: Se ejecutan scripts para evaluar el residuo.
6. **Clasificación**: El resultado se clasifica (PASS, PARTIAL, FAIL, etc.).
7. **Interpretación física**: Solo a partir de claims con PASS se extraen conclusiones físicas.
8. **Bucle**: Una nueva pregunta surge; el ciclo se repite.

## Estados de los objetos

Cada tipo de artefacto en el corpus (claim, script, reporte, evaluación, interpretación, decisión) tiene un campo `status`. Los estados posibles para un claim son:

- `PROPOSED`: propuesto pero sin formalización.
- `FORMALIZED`: existen scripts para probarlo.
- `TESTED_PASS`: los scripts produjeron residuo cero.
- `TESTED_PARTIAL`: la prueba es incompleta o dejó residuo.
- `TESTED_FAIL`: el residuo es distinto de cero bajo las hipótesis declaradas.
- `CONVENTION_MISMATCH`: se detectó un desacuerdo de convenciones.
- `SUPERSEDED`, `REFUTED`, `RETRACTED`: el claim fue reemplazado o invalidado.

Otros artefactos (scripts, reportes, evaluaciones, interpretaciones, decisiones) tienen sus propios estados, como `EXECUTABLE`, `PASSING`, `FAILING_EXPECTED`, `FAILING_UNEXPECTED`, `SUPPORTED`, `UNSUPPORTED`, etc. Definir y actualizar estos estados es parte del protocolo de control.

## Principio de claim mínimo

Es preferible dividir una pregunta en muchos claims pequeños y manejables, cada uno con un residuo concreto a probar, que en un claim enorme y vago. Por ejemplo, en lugar de "la teoría cargada no propaga modos espurios", se descompone en claims algebraicos (traza gamma, divergencia, rango del símbolo, etc.).

## Tipos de claims

1. **Algebraicos**: identidades gamma, conmutadores, variaciones de gauge, Bianchi. Estos se prueban con Cadabra2 y se confirman con Sage.
2. **Dinámicos**: propiedades de las ecuaciones de movimiento, rango del operador, comportamiento en límites y fondos concretos. Estos se prueban con Sage en representaciones explícitas.
3. **Físicos**: conclusiones sobre el espectro, modos propagados, causalidad, etc. Se apoyan en varios claims algebraicos/dinámicos ya probados.

## Fases del workflow

- **Fase 0 – Congelar convenciones**: auditar que las convenciones del `Problema.tex` están claras e implementadas en `scripts/shared/`.
- **Fase 1 – Reproducir lo establecido**: usar Cadabra2 y Sage para reproducir las invariancias y resultados ya conocidos.
- **Fase 2 – Mapear preguntas abiertas**: crear `open_questions/` con las preguntas pendientes del `Problema.tex`.
- **Fase 3 – Generar claims mínimos**: para cada pregunta, proponer claims concretos.
- **Fase 4 – Auditoría formal**: formalizar y ejecutar los tests.
- **Fase 5 – Interpretación controlada**: a partir de los PASS, extraer conclusiones físicas.

## Organización del corpus

- Los objetos son inmutables; cada nueva revisión produce un nuevo artefacto con un identificador único (por ejemplo `CLAIM-0010`, `SCRIPT-SAGE-0022`).
- Cada artefacto debe incluir un bloque YAML con metadatos (`id`, `type`, `title`, `status`, `created`, etc.) y los campos de dependencia (`depends_on`, `uses_scripts`, `tested_by`, etc.).
- Los índices (`corpus/index.md`, `corpus/registry.yml`) se actualizan para reflejar la vista actual sobre el corpus, pero no son evidencia.

## Mutaciones y pruebas de robustez

Es obligatorio realizar pruebas de mutación: alterar artificialmente coeficientes, signos o métricas en copias temporales de los scripts para verificar que los tests detectan el fallo. Si una mutación pasa inadvertida, el claim no se considera robusto.

## Uso coordinado de Cadabra2 y SageMath

- Cadabra2 es la herramienta para manipular tensores y gammas en abstracto; permite declarar índices, simplificar expresiones y aplicar reglas de Clifford.
- SageMath se usa para verificar representaciones matriciales y resultados numéricos; complementa a Cadabra2 detectando errores de signo o coeficientes.
- Un claim no se considera totalmente probado hasta que ambos verificadores han concordado o se ha justificado por qué no se requiere uno de ellos.

## Consideraciones prácticas

- Ejecuta siempre los scripts de no-regresión antes de añadir nuevos claims.
- Documenta las hipótesis y el contexto de cada claim; el éxito de la prueba depende de las condiciones asumidas.
- Mantén claras las diferencias entre evidencia (corpus) y herramientas de trabajo (`working/`), así como entre resultados algebraicos y interpretaciones físicas.

---
