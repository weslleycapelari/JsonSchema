# ADR-0010: Validation Result Consolidation Model

Status: Accepted
Date: 2026-06-02

## Context

A single validation run can produce failures from multiple keywords and nested schemas.

## Decision

Use TValidationResult.Combined to flatten arrays of IValidationResult into one aggregated result.

## Consequences

- Positive: unified output contract to callers.
- Positive: supports logical and nested keyword scenarios.
- Trade-off: flattened aggregation does not preserve full hierarchical failure tree.

## Evidence

- src/Core/JsonSchema.Results.pas
- src/Core/JsonSchema.CompiledSchema.pas
- src/Keywords/Logicals/JsonSchema.Keywords.AllOf.pas

## IDEA alignment

Aligned with validation result reporting requirements from MVP and beyond.
