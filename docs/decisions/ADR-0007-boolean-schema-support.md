# ADR-0007: Boolean Schema Support (true/false)

Status: Accepted
Date: 2026-06-02

## Context

JSON Schema allows boolean schemas where true accepts any instance and false rejects all instances.

## Decision

Represent true schema as an empty compiled schema and false schema as a compiled schema containing a dedicated false keyword validator.

## Consequences

- Positive: direct spec support with low complexity.
- Positive: works in top-level and nested ParseSchema flows.
- Trade-off: introduces a synthetic keyword for false behavior.

## Evidence

- src/Core/JsonSchema.CompiledSchema.pas
- src/Drafts/JsonSchema.Draft6.Parser.pas
- src/JsonSchema.Validator.pas

## IDEA alignment

Aligned with standards compliance and draft-ready architecture.
