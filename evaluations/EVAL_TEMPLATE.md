---
id: EVAL-XXXX
type: evaluation
title: Evaluación del claim CLAIM-XXXX
created: YYYY-MM-DD
author: <autor>
evaluates:
  - CLAIM-XXXX
reports:
  - REPORT-XXXX
result: pending
warnings: []
---

# Evaluación EVAL-XXXX — Claim CLAIM-XXXX

## Evidencia evaluada

- **Claim**: describir brevemente qué se afirma.
- **Reportes considerados**: referencia a los reportes examinados.

## Análisis

- Discute si la evidencia presentada en los reportes es suficiente para declarar `TESTED_PASS`.
- Analiza la adecuación de las hipótesis, convenciones y herramientas utilizadas.
- Considera el resultado de las pruebas de mutación, si existen.
- Nota cualquier conflicto con otros claims, convenciones o decisiones.

## Resultado

Establece el `result` a una de las opciones: `TESTED_PASS`, `TESTED_PARTIAL`, `TESTED_FAIL`, `CONVENTION_MISMATCH`. Explica las razones.

## Consecuencias

- Si el resultado es `TESTED_PASS`, indicar que el claim puede usarse como premisa.
- Si es `PARTIAL` o `FAIL`, sugerir qué se debe corregir o reforzar.
- Si es `CONVENTION_MISMATCH`, describir cómo reconciliar las diferencias.

## Enlaces

- Dependencias actualizadas: agregar `depends_on`.
- Claims afectados: listar claims que dependen de éste.

---
