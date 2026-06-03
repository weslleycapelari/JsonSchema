# ADR-0016: Per-Draft Registration Structure

Status: Accepted
Date: 2026-06-02

## Context

Each draft parser must remain readable while handling many keyword registrations.

## Decision

Split registration into parser-level methods by semantic keyword category:

- RegisterCoreKeywords
- RegisterFormatKeywords
- RegisterLogicalKeywords
- RegisterMetadataKeywords
- RegisterValidationKeywords

## Consequences

- Positive: parser constructors stay concise and fully structured.
- Positive: category-level maintenance is simple and explicit.
- Trade-off: registrations are duplicated across draft files, but explicitly custom to each draft's version requirements.

## Evidence

- src/Drafts/JsonSchema.Draft6.Parser.pas
- src/Drafts/JsonSchema.Draft7.Parser.pas
- src/Drafts/JsonSchema.Draft2019_09.Parser.pas
- src/Drafts/JsonSchema.Draft2020_12.Parser.pas

## IDEA alignment

Aligned with separation of concerns and incremental extensibility.
