# ADR-0015: Validator Facade as Public Entry Point

Status: Accepted
Date: 2026-06-02

## Context

Consumers need a compact API while internals remain modular and draft-aware.

## Decision

Expose TJsonSchemaValidator as the main public facade. It selects parser by draft, compiles schema, validates instances, and localizes errors.

## Consequences

- Positive: simple and stable API for users.
- Positive: internals can evolve behind facade.
- Trade-off: default draft behavior is explicit and may need caller awareness when schema draft differs.

## Evidence

- src/JsonSchema.Validator.pas

## IDEA alignment

Directly aligned with the simple public API vision.
