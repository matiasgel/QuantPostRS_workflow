---
id: CLAIM-0001
type: claim
title: Invariancia Stueckelberg local del bloque W_mu
status: TESTED_PASS
created: 2026-05-17
author: Codex
source_tex:
  file: Problema.tex
  labels:
    - eq:Wcal-def
    - eq:S-transf
  sections:
    - "subsec:el-bloque-stueckelberg-invariante"
    - "subsec:problemas-abiertos-reformulados"
depends_on:
  - Q-0001
  - AGENTS.md
  - FORMAL_METHODS_GUIDE.md
  - decisions/DECISION-0001.md
tested_by:
  - REPORT-0001
uses_scripts:
  - scripts/cadabra/SCRIPT-CADABRA-0001_stueckelberg_invariance_W.cdb
  - scripts/sage/SCRIPT-SAGE-0001_stueckelberg_invariance_W.sage
evaluated_by:
  - EVAL-0001
supersedes: []
superseded_by: []
conflicts_with: []
tags:
  - stueckelberg
  - off_shell
  - covariant_derivative
  - W_block
---

# CLAIM-0001 - Invariancia Stueckelberg local del bloque W_mu

## Claim

El bloque
\[
W_\mu = \Psi_\mu - b D_\mu \chi
\]
es invariante bajo la transformacion Stueckelberg local no restringida
\[
\delta_S\chi=\xi,\qquad
\delta_S\Psi_\mu=bD_\mu\xi,\qquad
\delta_S A_\mu=0.
\]

## Supuestos

- La metrica es \(\eta=\mathrm{diag}(+1,-1,-1,-1)\).
- La derivada covariante es \(D_\mu=\partial_\mu-\mathrm{i}qA_\mu\).
- El conmutador covariante actua como \([D_\mu,D_\nu]X=-\mathrm{i}qF_{\mu\nu}X\).
- El coeficiente \(b\) es escalar y constante frente a \(D_\mu\): \(D_\mu b=0\).
- \(D_\mu\) actua linealmente sobre los campos y sobre el parametro local \(\xi\).
- \(\delta_S\) conmuta con \(D_\mu\) sobre \(\chi\) bajo \(\delta_S A_\mu=0\).

## Residuo esperado

\[
\mathrm{RES}_\mu :=
\delta_S W_\mu
= \delta_S\Psi_\mu-bD_\mu(\delta_S\chi)
= bD_\mu\xi-bD_\mu\xi.
\]

Se espera residuo exactamente cero.

## Formalizacion (scripts)

- **Cadabra2**: `scripts/cadabra/SCRIPT-CADABRA-0001_stueckelberg_invariance_W.cdb` formaliza el residuo abstracto y comprueba que se reduce a cero.
- **SageMath**: `scripts/sage/SCRIPT-SAGE-0001_stueckelberg_invariance_W.sage` verifica por componentes simbolicas que el mismo residuo se anula.

## Resultado

Los scripts asociados producen residuo cero. La evaluacion formal `EVAL-0001` clasifica este claim como `TESTED_PASS`.

## Interpretacion fisica

Sin interpretar en este artefacto. La interpretacion fisica queda pospuesta por protocolo.

---
