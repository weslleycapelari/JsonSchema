# ADR-0001: Plugin Registry for Keywords

Status: Accepted
Date: 2026-06-02

## Context

The validator must support many JSON Schema keywords and evolve across drafts without turning parser code into a large conditional chain.

## Decision

Use a keyword registry (TKeywordRegistry) that maps keyword names to factory delegates. Parsers register supported keywords declaratively.

## Consequences

- Positive: easy extension with new keywords.
- Positive: draft-specific support can differ by registration.
- Trade-off: keyword registration must be maintained explicitly per parser.

## Evidence

- src/Core/JsonSchema.Registry.pas
- src/Drafts/JsonSchema.Draft6.Parser.pas
- src/Drafts/JsonSchema.Draft7.Parser.pas
- src/Drafts/JsonSchema.Draft2019_09.Parser.pas
- src/Drafts/JsonSchema.Draft2020_12.Parser.pas

## IDEA alignment

Aligned with the goal of avoiding monolithic validation logic and enabling extensibility.
