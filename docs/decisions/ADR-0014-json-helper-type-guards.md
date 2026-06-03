# ADR-0014: JSON Helper Type Guards

Status: Accepted
Date: 2026-06-02

## Context

Delphi System.JSON has inheritance details (for example TJSONNumber and TJSONString) that can produce misleading type checks.

## Decision

Provide a helper (TJsonSchemaValueHelper) with explicit IsJSONObject/IsJSONArray/IsJSONString/IsJSONNumber and related checks used by keyword validators.

## Consequences

- Positive: consistent type semantics for validation logic.
- Positive: removes duplicated and error-prone type conditions.
- Trade-off: helper behavior becomes critical shared dependency.

## Evidence

- src/Core/JsonSchema.JSONHelper.pas
- src/Keywords/Validations/JsonSchema.Keywords.TypeKeyword.pas
- src/Keywords/Validations/JsonSchema.Keywords.MinLength.pas

## IDEA alignment

Aligned with strong typing and maintainability goals.
