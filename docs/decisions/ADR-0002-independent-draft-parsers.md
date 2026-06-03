# ADR-0002: Independent Draft Parsers Without Inheritance Chains

Status: Accepted
Date: 2026-06-02

## Context

Different drafts may diverge in keyword semantics. Inheritance chains between drafts make divergence and maintenance harder.

## Decision

Implement each draft parser as an independent class with its own registry setup, instead of parser inheritance.

## Consequences

- Positive: clear boundaries per draft.
- Positive: safe place for draft-specific semantics.
- Trade-off: duplicated registration code where behavior is currently identical.

## Evidence

- src/Drafts/JsonSchema.Draft6.Parser.pas
- src/Drafts/JsonSchema.Draft7.Parser.pas
- src/Drafts/JsonSchema.Draft2019_09.Parser.pas
- src/Drafts/JsonSchema.Draft2020_12.Parser.pas

## IDEA alignment

Directly aligned with IDEA.md guidance to avoid draft inheritance chains.
