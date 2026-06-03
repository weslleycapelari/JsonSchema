# ADR-0018: Defer Visitor Pattern Adoption

Status: Accepted
Date: 2026-06-02

## Context

IDEA.md discusses potential visitors (compile, evaluation, annotation, output, optimization), but premature introduction can overcomplicate MVP and early phases.

## Decision

Current implementation validates through direct keyword invocation from compiled schema. Visitor abstraction is intentionally deferred.

## Consequences

- Positive: simpler current code path and lower cognitive load.
- Positive: faster delivery for core validation features.
- Trade-off: advanced outputs/annotations may require architectural extension later.

## Evidence

- src/Core/JsonSchema.CompiledSchema.pas
- src/Keywords (direct Validate implementations)

## IDEA alignment

Aligned with IDEA guidance to avoid over-engineering visitors prematurely.
