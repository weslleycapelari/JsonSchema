# ADR-0009: Validation Error Context as JSON Metadata

Status: Accepted
Date: 2026-06-02

## Context

Different keywords need different details in error payloads (expected, actual, limits, property names, and patterns).

## Decision

Store error context in a TJSONObject attached to IValidationError, populated by each keyword.

## Consequences

- Positive: flexible metadata schema for errors.
- Positive: localization can use structured context.
- Trade-off: context fields are dynamic and only validated at runtime.

## Evidence

- src/Core/JsonSchema.Results.pas
- src/Keywords/Validations/JsonSchema.Keywords.TypeKeyword.pas
- src/Keywords/Validations/JsonSchema.Keywords.Pattern.pas

## IDEA alignment

Aligned with clean API and detailed validation reporting.
