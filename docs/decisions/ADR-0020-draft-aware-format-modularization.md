# ADR-0020 - Draft-Aware Format Modularization

## Status

Accepted

## Context

The `format` keyword validation was originally implemented in a single massive unit (`JsonSchema.Keywords.Format.pas`). It contained huge regular expression strings exceeding 140 characters and multiple complex helper functions (e.g. for IPv6, ISO 8601 validation, leap-second arithmetic), which made it difficult to maintain. Furthermore, standard formats were validated globally without checking draft compliance, violating the JSON Schema spec (which states that standard formats not defined in the active draft version must be treated as unknown and pass validation).

## Decision

We restructured the format keyword validation subsystem by:

1. **Splitting Concerns**:
   - Extracted all regex patterns into a dedicated constants unit: `JsonSchema.Keywords.Format.Constants.pas` (with long strings concatenated across multiple lines to stay under 140 characters).
   - Extracted validation functions into dedicated domain-specific units:
     - `JsonSchema.Keywords.Format.IPv6.pas` for IPv6 validation.
     - `JsonSchema.Keywords.Format.DateTime.pas` for date, time, and leap second checks.
     - `JsonSchema.Keywords.Format.Iri.pas` for IRI checking.
     - `JsonSchema.Keywords.Format.UriTemplate.pas` for template matching.

2. **Making it Draft-Aware**:
   - Added draft-specific factory methods to `TFormatKeyword` (e.g., `CreateKeywordDraft6`, `CreateKeywordDraft7`, etc.).
   - Equipped `TFormatRegistry` with a standard formats map (`FStandardFormats`) linking each standard format name to the draft version in which it was introduced.
   - Refactored `TFormatRegistry.ValidateFormat` and `IsFormatSupported` to dynamically verify if a standard format is defined under the active compiler draft. If not supported, it is treated as an unknown format and immediately returns `True` (passes validation).
   - Simplified the registry instantiation by using direct function pointer assignments for custom validators and a `RegisterRegexFormat` utility.

## Consequences

- **Readability**: The main formatting unit is clean and readable, strictly adhering to the 140-character line length limit.
- **Specification Compliance**: Correctly supports draft-specific format semantics (e.g., Draft 6 validation of `"format": "uuid"` will now correctly pass instead of performing active checking).
- **Extensibility**: Custom formats can still be registered globally or per-draft using the registry interface.
