# URI and JSON Pointer Subsystem

## 1. Purpose

This document explains the architecture of the RFC-compliant URI (RFC 3986) and JSON Pointer (RFC 6901) subsystem implemented in `src/Core/URI/`.

This subsystem is responsible for parsing identifiers, resolving relative references, and navigating JSON structures for `$ref` pointer schema compilation.

---

## 2. Core Components

The subsystem is composed of five specialized, cohesive units located in `src/Core/URI/`:

### A. Types (`JsonSchema.Core.URI.Types.pas`)

- Declares standard exception classes (`ERFC3986Exception`, `EValidationError`, `EMissingComponentError`).
- Exports helper constants, such as `URI_PATTERN`, which uses PCRE named capturing groups to isolate scheme, authority, path, query, and fragment parts.

### B. Reference (`JsonSchema.Core.URI.Reference.pas`)

- Declares the immutable `TURIReference` record.
- Operates on pre-parsed URI components, ensuring that URI manipulation logic remains side-effect free.

### C. Utilities (`JsonSchema.Core.URI.Utils.pas`)

- Centralizes static algorithms defined in standard specs:
  - **JSON Pointer Decoding**: Safe replacements (`~1` to `/`, `~0` to `~`) per RFC 6901.
  - **URI Normalization**: Case-folding schemes/hosts and removing dot segments (`.` / `..`).
  - **Path Merging**: Merging relative paths with base paths according to RFC 3986 Section 5.2.3.
  - **Reference Resolution**: Merging relative URIs into absolute base URIs.

### D. Parse Result (`JsonSchema.Core.URI.ParseResult.pas`)

- Captures token boundaries and status info resulting from parsing efforts.

### E. Builder & Validator (`JsonSchema.Core.URI.Builder.pas` & `JsonSchema.Core.URI.Validator.pas`)

- `TURIBuilder` implements the builder pattern to facilitate mutating, normalizing, and reassembling URI components.
- `TURIValidator` provides strict, RFC-compliant rules to validate if a string represents an absolute URI, a relative URI reference, or a valid JSON Pointer fragment.

---

## 3. Reference Resolution Lifecycle

During schema compilation, reference resolution follows these stages:

1. **Pre-Scanning**: The schema parser pre-scans the schema JSON object. Any `$id` or `id` attributes are resolved to establish base URIs for the sub-schemas.
2. **Path Merging**: When a `$ref` is encountered, it is parsed into a `TURIReference`. If it is relative, `TURIUtils.Resolve` merges it with the current base URI.
3. **Pointer Navigation**: If the reference contains a fragment (JSON Pointer), the compiler splits the pointer into segments, decodes them using `TURIUtils.DecodeJsonPointerSegment`, and navigates the compiled schema map to resolve the target node.
