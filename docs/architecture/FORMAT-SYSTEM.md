# Format Validation Subsystem

## 1. Purpose

This document describes the design of the pluggable, modularized, and draft-aware format validation subsystem. It explains how standard and custom semantic formats are registered, grouped, and validated against draft specifications.

---

## 2. Structural Modularization

To prevent a single massive file and comply with line length requirements, format validation is divided into highly cohesive units under `src/Keywords/Format/`:

- **Constants (`JsonSchema.Keywords.Format.Constants.pas`)**: Declares all format-related regex pattern strings. Long expressions are broken into multi-line concatenations to stay within 140-column limits.
- **Extracted Validator Units**: Domain-specific logic is moved to separate helper files:
  - `JsonSchema.Keywords.Format.IPv6.pas`: Houses the `IsValidIPv6` parser.
  - `JsonSchema.Keywords.Format.DateTime.pas`: Houses date/time ISO 8601 parsing (`SafeTryISO8601ToDate`, `IsLeapSecondTimeValid`, `IsValidDateTime`, `IsValidTime`, `IsValidDate`).
  - `JsonSchema.Keywords.Format.Iri.pas`: Houses internationalized resource identifier validation (`IsValidIri`).
  - `JsonSchema.Keywords.Format.UriTemplate.pas`: Houses URI template validation.

---

## 3. Draft-Aware Validation Architecture

Standard format validation is draft-aware. Standard formats not defined in the active compiler draft version are treated as unknown formats and automatically pass validation.

### A. Supported Formats Mapping

The `TFormatRegistry` maps standard formats to their introduction draft version in `FStandardFormats` at initialization:

| Draft Version | Standard Formats Added |
| :--- | :--- |
| **Draft 6** | `date-time`, `email`, `hostname`, `ipv4`, `ipv6`, `uri`, `uri-reference`, `uri-template`, `json-pointer` |
| **Draft 7** | `date`, `time`, `iri`, `iri-reference`, `idn-email`, `idn-hostname`, `relative-json-pointer`, `regex` |
| **Draft 2019-09** | `uuid`, `duration` |
| **Draft 2020-12** | (Inherits Draft 2019-09 formats) |

### B. Dynamic Supported Verification

At validation time, `IsFormatSupported` verifies draft compatibility using a chronological ordinal comparison of the [TDraftVersion](../../src/Core/JsonSchema.Core.Interfaces.pas#L17) enum:

```pascal
class function TFormatRegistry.IsFormatSupported(const pFormatName: string; const pDraft: TDraftVersion): Boolean;
var
  lMinDraft: TDraftVersion;
begin
  if FStandardFormats.TryGetValue(LowerCase(pFormatName), lMinDraft) then
    Result := Ord(pDraft) >= Ord(lMinDraft)
  else
    Result := False; // Custom formats handled separately
end;
```

---

## 4. Pluggable Registry Interface

The `TFormatRegistry` maintains the global registry of validation functions.

- **`RegisterFormat(const pFormatName: string; const pValidator: TFormatValidatorFunc)`**: Registers a custom validator function for a specific format. Custom formats are checked across all draft compilations.
- **`RegisterRegexFormat(const pFormatName, pPattern: string)`**: Registers a format validator based on a regular expression pattern.
- **`ValidateFormat(const pFormatName, pValue: string; const pDraft: TDraftVersion; out pFound: Boolean): Boolean`**: Looks up the validator and executes it if it is supported under the specified draft. Returns `True` (passes) if the format is unsupported or unregistered.
