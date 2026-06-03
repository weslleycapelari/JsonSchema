# ADR-0003: Compile-Before-Validate Pipeline

Status: Accepted
Date: 2026-06-02

## Context

Raw schema interpretation on every validation run is slower and mixes parsing concerns with runtime evaluation.

## Decision

Adopt a pipeline that compiles schema JSON into keyword validators (ICompiledSchema) before instance validation.

## Consequences

- Positive: reusable compiled schemas.
- Positive: separation of parse and validate phases.
- Trade-off: up-front compilation cost and additional object graph.

## Evidence

- src/JsonSchema.Validator.pas
- src/Core/JsonSchema.CompiledSchema.pas
- src/Drafts/JsonSchema.Draft6.Parser.pas

## IDEA alignment

Matches the IDEA.md requirement for schema compilation and reusable compiled schemas.
