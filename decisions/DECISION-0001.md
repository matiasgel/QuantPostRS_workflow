---
id: DECISION-0001
type: decision
title: Corpus logico distribuido en carpetas de primer nivel
status: ACTIVE
created: 2026-05-17
depends_on:
  - AGENTS.md
  - FORMAL_METHODS_GUIDE.md
supersedes: []
refutes: []
---

# DECISION-0001: Corpus logico distribuido en carpetas de primer nivel

## Contexto

La auditoria inicial del repositorio detecto que no existe un directorio literal
`corpus/`. En cambio, la estructura actual contiene carpetas de primer nivel para
los artefactos formales del workflow:

- `open_questions/`
- `claims/`
- `scripts/`
- `reports/`
- `evaluations/`
- `interpretations/`
- `decisions/`

## Decision

Por ahora se adopta como estructura oficial un corpus logico distribuido en esas
carpetas de primer nivel. Toda referencia operativa al corpus debe entenderse como
referencia a ese conjunto distribuido, salvo que una decision posterior cree o adopte
un directorio literal `corpus/`.

## Alcance

Las carpetas `open_questions/`, `claims/`, `scripts/`, `reports/`,
`evaluations/`, `interpretations/` y `decisions/` contienen evidencia primaria del
workflow. Una vez creados artefactos reales en ellas, esos artefactos son
inmutables: no deben modificarse ni borrarse. Las revisiones, correcciones,
refutaciones o reemplazos deben registrarse mediante nuevos artefactos que enlacen
explicitamente a los anteriores con campos como `supersedes`, `refutes` u otros
metadatos equivalentes.

Las carpetas `working/` y `reviews/` no son evidencia primaria. Sus contenidos son
material de trabajo o revision humana y pueden regenerarse o modificarse segun el
workflow aplicable.

## Consecuencias

- No se requiere crear un directorio literal `corpus/` para iniciar el trabajo
  formal.
- Las reglas de inmutabilidad del corpus aplican al corpus logico distribuido.
- Los agentes deben evitar ambiguedades entre `corpus/` como nombre historico de la
  evidencia primaria y la estructura real de este repositorio.
