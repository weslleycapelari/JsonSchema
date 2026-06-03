# ADR-0004: Unified Keyword Factory Signature

Status: Accepted
Date: 2026-06-02

## Context

Some keywords require only their value, while others need parent schema inspection and recursive sub-schema compilation.

## Decision

Use a unified keyword factory delegate with three inputs:

- keyword value
- parent schema object
- compile delegate (TCompileSchemaFunc)

## Consequences

- Positive: same registration model for simple and complex keywords.
- Positive: supports sibling-aware keywords and recursive sub-schemas.
- Trade-off: factory signatures are broader than needed for simple keywords.

## Evidence

- src/Core/JsonSchema.Registry.pas
- src/Core/JsonSchema.Core.Interfaces.pas
- src/Keywords/Validations/JsonSchema.Keywords.Items.pas
- src/Keywords/Validations/JsonSchema.Keywords.AdditionalProperties.pas

## IDEA alignment

Aligned with extensibility and separation of concerns.
