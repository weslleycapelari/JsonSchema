# ADR-0011: Schema Registry with Pre-Scan and Resolution

Status: Accepted
Date: 2026-06-02

## Context

Reference resolution requires discoverable schema resources by URI, including nested ids and anchors.

## Decision

Maintain a centralized schema registry that can:

- register schemas by URI
- pre-scan recursively for id/$id/$anchor
- resolve local files and HTTP resources
- combine base and relative URI segments

## Consequences

- Positive: enables robust $ref resolution workflow.
- Positive: supports local cache and remote fallback.
- Trade-off: URI handling has custom logic and must be verified against edge RFC cases.

## Evidence

- src/Core/JsonSchema.Core.SchemaRegistry.pas
- src/Keywords/Core/JsonSchema.Keywords.Id.pas
- src/Keywords/Core/JsonSchema.Keywords.Ref.pas

## IDEA alignment

Aligned with Phase 4 goals ($ref, $id, registry, URI resolution).
