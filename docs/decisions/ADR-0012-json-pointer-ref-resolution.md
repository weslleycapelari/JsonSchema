# ADR-0012: JSON Pointer-Based $ref Resolution with Recursion Guard

Status: Accepted
Date: 2026-06-02

## Context

References may target internal pointers and external schemas. Cyclic references must not cause stack overflow.

## Decision

Resolve $ref through JSON Pointer navigation and compile referenced schema lazily. Use a validating flag to prevent recursive loops during runtime validation.

## Consequences

- Positive: supports internal and external references.
- Positive: protects against infinite recursion.
- Trade-off: unresolved targets currently produce generic invalid results and need clearer diagnostics over time.

## Evidence

- src/Keywords/Core/JsonSchema.Keywords.Ref.pas
- src/Core/JsonSchema.Core.SchemaRegistry.pas

## IDEA alignment

Aligned with reference support roadmap and production reliability goals.
