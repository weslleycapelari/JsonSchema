# ADR-0017: Dependencies Keyword Dual-Mode Interpretation

Status: Accepted
Date: 2026-06-02

## Context

The dependencies keyword supports two behaviors:

- property dependency (array of required sibling properties)
- schema dependency (sub-schema that the instance must satisfy)

## Decision

Parse dependencies into internal rules with explicit rule type and validate accordingly at runtime.

## Consequences

- Positive: captures both spec-defined dependency forms.
- Positive: explicit rule model improves readability and testability.
- Trade-off: deprecated/newer draft differences may require additional branching in future keywords.

## Evidence

- src/Keywords/Validations/JsonSchema.Keywords.Dependencies.pas

## IDEA alignment

Aligned with object validation expansion and extensible keyword design.
