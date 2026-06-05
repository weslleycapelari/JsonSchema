# ADR-0001: Compiled-Schema AST Code Generator

## Status

Approved

## Context

The legacy implementation of `Schema2Delphi` traversed raw JSON schema trees directly (via visitors). This approach had several limitations:

1. It required manual, error-prone duplication of `$ref` pointer resolution logic.
2. It bypassed the core library's robust parsing and draft-validation engine.
3. It struggled with complex keyword schemas (like nested arrays and format schemas).

## Decision

We decided to shift `Schema2Delphi` to walk the **pre-compiled keyword AST** produced by the core parsing engine.

- Instead of raw JSON, the orchestrator receives an compiled schema interface `ICompiledSchema`.
- It walks the compiled keywords by type-casting the generic `IJsonSchemaKeyword` instances back to their concrete keyword implementations (e.g. `TPropertiesKeyword`, `TRefKeyword`).
- These keywords expose their internal structures as read-only properties, allowing clean, out-of-the-box reference and dialect resolution.

## Consequences

- **Pros**:
  - Automatically resolves `$ref` pointers using the core's `TSchemaRegistry`.
  - Supports all JSON Schema drafts (6, 7, 2019-09, 2020-12) natively.
  - Significantly reduces codebase size by removing custom tree walkers.
- **Cons**:
  - Requires exposing internal compiled keyword fields as read-only properties in the core library, slightly increasing public API exposure.
