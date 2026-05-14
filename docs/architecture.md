# Architecture

## Overview

This project is a Delphi library for JSON Schema validation. The architecture separates the public entry point, draft selection, schema walking, validation visitors, message translation, and resource and reference resolution.

## Validation flow

1. The public API receives the schema and the input JSON document.
2. The runtime identifies the draft from an explicit parameter or from `$schema`.
3. If no draft is provided explicitly and the schema does not declare `$schema`, the current behavior falls back to Draft 2020-12.
4. The walker traverses the schema and dispatches keywords to the draft-specific visitor.
5. The visitor collects results and translated errors.

## Layers

### Public core

The public core exposes the main entry point and the integration types used by consumers of the library.

### Walker and visitors

The walker uses RTTI to locate methods marked by keyword metadata. The visitors implement validation behavior by draft and by keyword category.

### Registry and URI

The registry is responsible for resource bookkeeping, base URI tracking, and fragment resolution. It supports reference lookup and keeps named anchors and dynamic anchors available to visitors, without exposing draft-specific lookup details to the walker. This keeps reference handling centralized while leaving the draft-specific rules inside the visitor layer.

### Translation

The translation layer separates validation messages into enUS and ptBR.

## Confirmed runtime drafts

- Draft 6
- Draft 7
- Draft 2019-09
- Draft 2020-12

## Historical fixtures

- Draft 3
- Draft 4
- draft-next

These appear in the test fixtures, but they must not be documented as confirmed runtime support.

## Tests and tooling

- `test` contains the DUnit project and schema fixtures used for regression coverage.
- `tools/Schema2Delphi` contains the auxiliary code-generation tool.

## Known boundaries

- There is no public CLI evidenced in the repository.
- Compatibility must be maintained draft by draft.
- Translated messages exist only for enUS and ptBR.

## Evolution rule

Architecture changes should preserve compatibility for the supported drafts, the existing translated messages, reference resolution, and per-draft test coverage.
