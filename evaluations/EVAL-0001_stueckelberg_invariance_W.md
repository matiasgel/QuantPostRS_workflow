---
id: EVAL-0001
type: evaluation
title: Evaluacion del claim CLAIM-0001
created: 2026-05-17
author: Codex
evaluates:
  - CLAIM-0001
reports:
  - REPORT-0001
result: TESTED_PASS
warnings:
  - Cadabra2 emite un warning de Matplotlib/Axes3D no relacionado con el residuo.
  - SageMath requiere DOT_SAGE=/tmp/sage-dot en el sandbox.
  - No se realizaron pruebas de mutacion en este primer claim minimo.
---

# Evaluacion EVAL-0001 - Claim CLAIM-0001

## Evidencia evaluada

- **Claim**: el bloque \(W_\mu=\Psi_\mu-bD_\mu\chi\) es invariante bajo la
  transformacion Stueckelberg local no restringida
  \(\delta_S\chi=\xi\), \(\delta_S\Psi_\mu=bD_\mu\xi\), \(\delta_SA_\mu=0\),
  con \(D_\mu b=0\).
- **Reporte considerado**: `reports/REPORT-0001_stueckelberg_invariance_W.md`.
- **Scripts considerados**:
  `scripts/cadabra/SCRIPT-CADABRA-0001_stueckelberg_invariance_W.cdb` y
  `scripts/sage/SCRIPT-SAGE-0001_stueckelberg_invariance_W.sage`.

## Analisis

El residuo probado por ambos scripts es
\[
\mathrm{RES}_\mu=\delta_S\Psi_\mu-bD_\mu(\delta_S\chi)
=bD_\mu\xi-bD_\mu\xi.
\]
Cadabra2 reduce el residuo abstracto a cero y SageMath confirma por cuatro
componentes simbolicas que el mismo residuo es \((0,0,0,0)\).

La prueba usa las convenciones fijadas en `AGENTS.md` y no modifica definiciones ni
convenciones para obtener la cancelacion. En este claim no interviene el conmutador
\([D_\mu,D_\nu]\), pero se preserva la convencion declarada como dependencia del
contexto formal.

## Resultado

`TESTED_PASS`.

La evidencia ejecutable disponible muestra residuo exactamente cero tanto en Cadabra2
como en SageMath.

## Consecuencias

El claim queda disponible como premisa formal algebraica segun el protocolo del
corpus. No se declara aqui ninguna interpretacion fisica.

## Enlaces

- Dependencias:
  - `Q-0001`
  - `AGENTS.md`
  - `FORMAL_METHODS_GUIDE.md`
  - `decisions/DECISION-0001.md`
- Claim evaluado:
  - `claims/CLAIM-0001_stueckelberg_invariance_W.md`
- Reporte:
  - `reports/REPORT-0001_stueckelberg_invariance_W.md`

---
