---
id: CLAIM-XXXX
type: claim
title: Título corto del claim
status: PROPOSED
created: YYYY-MM-DD
author: <autor>
source_tex:
  file: Problema.tex
  labels: []
  sections: []
depends_on: []
tested_by: []
uses_scripts: []
evaluated_by: []
supersedes: []
superseded_by: []
conflicts_with: []
tags: []
---

# CLAIM-XXXX — <Título descriptivo>

## Claim

Expresa de forma precisa la afirmación algebraica o dinámica que quieres probar. Debe ser lo más concreto posible (por ejemplo, una identidad gamma, una expresión que debe anularse, una relación de conmutadores, etc.).

## Supuestos

Enumera las hipótesis necesarias para que el claim sea válido:

- Convenciones métricas.
- Álgebra de Clifford.
- Definición de derivada covariante.
- Conmutatividad o no de ciertos operadores con las gammas.
- Límite o fondo específico (por ejemplo \(F_{\mu\nu} = 0\) o \(F_{\mu\nu}\) constante).
- Reglas de integración por partes, etc.

## Residuo esperado

Define la expresión cuyo valor debe ser cero si el claim es cierto. Por ejemplo:

```
\[
\mathrm{RESIDUO} := \Lambda^{\mu\nu}(D)\,\gamma_\nu.
\]
```

Indica si se espera residuo exactamente cero o bajo qué simplificaciones.

## Formalización (scripts)

- **Cadabra2**: referencia al script `scripts/cadabra/SCRIPT-CADABRA-XXXX.cdb` que contiene la codificación del claim.
- **SageMath**: referencia al script `scripts/sage/SCRIPT-SAGE-XXXX.sage` si se necesita verificación matricial.

No es necesario incluir código aquí; solo la ruta y explicación.

## Resultado

Después de ejecutar las pruebas y la evaluación, este campo se actualizará a `TESTED_PASS`, `TESTED_PARTIAL`, `TESTED_FAIL`, `CONVENTION_MISMATCH`, etc., y se añadirán los campos correspondientes (`tested_by`, `evaluated_by`).

## Interpretación física

Este campo debe dejarse en blanco hasta que el claim tenga estatus `TESTED_PASS`. Describe de manera breve qué implicaciones físicas se derivan si el claim es correcto.

---
