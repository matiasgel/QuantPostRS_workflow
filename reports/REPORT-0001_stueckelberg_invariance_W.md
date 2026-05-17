---
id: REPORT-0001
type: report
title: Reporte de resultados para CLAIM-0001
created: 2026-05-17
author: Codex
claim: CLAIM-0001
scripts:
  - SCRIPT-CADABRA-0001
  - SCRIPT-SAGE-0001
status: PASSING
notes:
  - Q_TEMPLATE.md ya contenia source_tex.file igual a Problema.tex; no requirio cambio de contenido.
  - SageMath requiere DOT_SAGE en una ruta escribible dentro del sandbox.
  - Cadabra2 emite un warning de Matplotlib/Axes3D no relacionado con el residuo.
---

# Reporte REPORT-0001 - Resultados del claim CLAIM-0001

## Resumen

Se verifico el residuo de la variacion Stueckelberg local del bloque
\[
W_\mu=\Psi_\mu-bD_\mu\chi
\]
bajo
\[
\delta_S\chi=\xi,\qquad
\delta_S\Psi_\mu=bD_\mu\xi,\qquad
\delta_SA_\mu=0.
\]
El residuo formalizado fue
\[
\mathrm{RES}_\mu=bD_\mu\xi-bD_\mu\xi.
\]

Antes de crear el claim se reviso `open_questions/Q_TEMPLATE.md`. El campo
`source_tex.file` ya usaba `Problema.tex`; por tanto no se modifico contenido
metodologico ni nominal adicional.

## Comandos ejecutados

```bash
cadabra2 scripts/cadabra/SCRIPT-CADABRA-0001_stueckelberg_invariance_W.cdb
env MPLCONFIGDIR=/tmp/mpl-cadabra cadabra2 scripts/cadabra/SCRIPT-CADABRA-0001_stueckelberg_invariance_W.cdb
sage scripts/sage/SCRIPT-SAGE-0001_stueckelberg_invariance_W.sage
env DOT_SAGE=/tmp/sage-dot sage scripts/sage/SCRIPT-SAGE-0001_stueckelberg_invariance_W.sage
```

El primer comando SageMath fallo por intentar escribir temporales en
`/home/daniel/.sage`, que esta fuera de las rutas escribibles del sandbox. La
ejecucion con `DOT_SAGE=/tmp/sage-dot` fue la ejecucion valida reportada.

## Salida de Cadabra2

Salida relevante de la ejecucion valida:

```text
CLAIM-0001 Cadabra2 residue:
0
0
0
0
CLAIM-0001 Cadabra2 result: PASS
```

Residuo de Cadabra2:
\[
\mathrm{RES}_\mu=0.
\]

## Salida de SageMath

Salida relevante de la ejecucion valida:

```text
CLAIM-0001 SageMath residue:
[0, 0, 0, 0]
CLAIM-0001 SageMath result: PASS
```

Residuo de SageMath por componentes:
\[
(0,0,0,0).
\]

## Observaciones

- Cadabra2 imprimio ceros intermedios por las rutinas de simplificacion antes de la
  salida etiquetada; no queda residuo no nulo.
- Cadabra2 emitio un warning de Matplotlib/Axes3D incluso con `MPLCONFIGDIR` en
  `/tmp`. El warning no afecta la ejecucion del script ni el residuo.
- SageMath necesita `DOT_SAGE=/tmp/sage-dot` bajo este sandbox para poder crear
  archivos temporales.
- No se realizaron pruebas de mutacion para este primer claim minimo; el test cubre
  la cancelacion directa del residuo declarado.

## Conclusion provisional

Ambos scripts ejecutables reducen el residuo declarado a cero. Corresponde clasificar
`CLAIM-0001` como `TESTED_PASS`.

---
