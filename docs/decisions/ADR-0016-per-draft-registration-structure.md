# ADR-0016: Per-Draft Registration Structure

Status: Accepted
Date: 2026-06-02

## Context

Each draft parser must remain readable while handling many keyword registrations.

## Decision

Split registration into parser-level methods:

- RegisterCoreKeywords
- RegisterValidationKeywords
- RegisterLogicalKeywords

## Consequences

- Positive: parser constructors stay concise.
- Positive: category-level maintenance is simpler.
- Trade-off: most registrations are currently duplicated across draft files.

## Evidence

- src/Drafts/JsonSchema.Draft6.Parser.pas
- src/Drafts/JsonSchema.Draft7.Parser.pas
- src/Drafts/JsonSchema.Draft2019_09.Parser.pas
- src/Drafts/JsonSchema.Draft2020_12.Parser.pas

## IDEA alignment

Aligned with separation of concerns and incremental extensibility.
