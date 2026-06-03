# ADR-0013: Global Compilation Context for Root Schema and Base URI

Status: Accepted
Date: 2026-06-02

## Context

During recursive compilation, id/ref keywords need access to root schema and current base URI.

## Decision

Use process-global variables gCurrentRootSchema and gCurrentBaseURI to share compilation context across parser and core keywords.

## Consequences

- Positive: simple integration across parser and keyword units.
- Positive: avoids threading context through many method signatures.
- Trade-off: requires strict reset/restore discipline and caution under concurrent validations.

## Evidence

- src/Keywords/Core/JsonSchema.Keywords.Ref.pas
- src/Keywords/Core/JsonSchema.Keywords.Id.pas
- src/JsonSchema.Validator.pas
- src/Drafts/JsonSchema.Draft6.Parser.pas

## IDEA alignment

Supports current architecture pragmatically; may need future refactor for stronger isolation in parallel workloads.
