---
id: REPORT-XXXX
type: report
title: Reporte de resultados para CLAIM-XXXX
created: YYYY-MM-DD
author: <autor>
claim: CLAIM-XXXX
scripts:
  - SCRIPT-CADABRA-XXXX
  - SCRIPT-SAGE-XXXX
status: provisional
notes: []
---

# Reporte REPORT-XXXX — Resultados del claim CLAIM-XXXX

## Resumen

Describe brevemente qué tests se realizaron, bajo qué hipótesis y qué herramienta se usó.

## Salida de Cadabra2

Incluye la salida relevante del script Cadabra2. Si el residuo es cero, indícalo claramente. Si queda residuo, indica su forma y anexa el archivo completo si es necesario.

```
(resumen de la salida)
```

## Salida de SageMath

Incluye la salida relevante del script SageMath. Si se realizó una verificación matricial, describe la matriz, la dimensión y el resultado (¿se obtuvo la matriz cero?). Si no aplica, indica por qué.

```
(resumen de la salida)
```

## Observaciones

- Señala cualquier ambigüedad o problema detectado (por ejemplo, convención errónea, residuo no reducido, necesidad de reglas adicionales).
- Indica si se realizaron pruebas de mutación y su resultado.
- Sugiere mejoras a los scripts si corresponde.

## Conclusión provisional

Proporciona un juicio preliminar: si el residuo parece anularse, si la prueba es incompleta, si se sugiere reclasificar el claim como `PARTIAL` o `FAIL`, etc. La evaluación formal se realizará en `EVAL-XXXX`.

---
