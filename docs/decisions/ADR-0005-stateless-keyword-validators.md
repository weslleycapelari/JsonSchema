# ADR-0005: Stateless Keyword Validators

Status: Accepted
Date: 2026-06-02

## Context

Keyword logic should be isolated, reusable, and easy to test.

## Decision

Each keyword class encapsulates its own parsed constraints in constructor fields and exposes Validate against runtime instances, without mutable shared state.

## Consequences

- Positive: high cohesion per keyword.
- Positive: straightforward unit testing.
- Trade-off: parser must instantiate many keyword objects during compilation.

## Evidence

- src/Keywords/Validations/JsonSchema.Keywords.TypeKeyword.pas
- src/Keywords/Validations/JsonSchema.Keywords.Minimum.pas
- src/Keywords/Logicals/JsonSchema.Keywords.AllOf.pas

## IDEA alignment

Aligned with the principle that each keyword must encapsulate its own behavior.
