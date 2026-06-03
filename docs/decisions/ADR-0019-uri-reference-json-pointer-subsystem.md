# ADR-0019 - RFC-Compliant URI and JSON Pointer Subsystem

## Status

Accepted

## Context

Before this decision, the library relied on naive string manipulations for resolving base URIs, relative paths, and JSON Pointer fragments (`$ref`). This led to non-compliant behavior in edge cases defined by RFC 3986 (URI Generic Syntax) and RFC 6901 (JSON Pointer). We needed a robust, fully compliant, and self-contained URI subsystem.

## Decision

We implemented a dedicated URI and JSON Pointer validation and parsing subsystem under `src/Core/URI/`. The subsystem consists of:

1. **`JsonSchema.Core.URI.Types`**: Declares enumerations, exception classes, and standard validation regexes (such as `URI_PATTERN` using PCRE capturing groups).
2. **`JsonSchema.Core.URI.Reference`**: Defines an immutable, record-based representation (`TURIReference`) of a parsed URI to handle components (scheme, authority, path, query, fragment).
3. **`JsonSchema.Core.URI.Utils`**: Centralizes static helper routines, including RFC 6901 pointer segment decoding, URI normalization, reference merging, and base-relative resolution.
4. **`JsonSchema.Core.URI.ParseResult`**: Captures parsing outcomes and component locations.
5. **`JsonSchema.Core.URI.Builder`**: Implements a builder pattern (`TURIBuilder`) to facilitate programmatically modifying or reassembling URI components.
6. **`JsonSchema.Core.URI.Validator`**: Provides rules to validate absolute/relative URIs and pointer schemas.

This subsystem is compiled within `src/Core/URI/` and integrated into the global `TSchemaRegistry` and the pluggable `TFormatRegistry`.

## Consequences

- **Correctness**: Guarantees compliance with RFC 3986 and RFC 6901 specs during reference resolution and schema validation.
- **Maintainability**: Centralizes complex URI string-splitting and character-escaping code in one place.
- **Independence**: The URI parsing module does not depend on external validation facade structures.
