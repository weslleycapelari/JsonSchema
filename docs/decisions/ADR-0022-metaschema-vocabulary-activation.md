# ADR-0022 - Metaschema Vocabulary Activation

## Status

Accepted

## Context

Starting in Draft 2019-09, schema authors can declare custom vocabularies and select which standard vocabularies are active via the `$vocabulary` object in meta-schemas. If a vocabulary is disabled (set to `false` or omitted in an opt-in vocabulary scenario), its respective keywords must not be compiled or executed. In particular, the format vocabulary is disabled by default in the Draft 2019-09 meta-schema, but must be enforceable during test runs and custom client configurations.

## Decision

We implemented dynamic metaschema vocabulary activation inside the compilation pipeline:

1. **Vocabulary Keyword Mapping**:
   - Added `GetKeywordVocabulary(const pKeyword: string): string` to map standard keywords to their vocabulary URIs (Core, Applicator, Validation, Format, Meta-Data).

2. **Compilation Verification**:
   - Implemented `IsKeywordEnabled(const pKeyword: string; const pSchema: TJSONObject): Boolean` in `TDraft2019_09Parser`.
   - This routine retrieves the meta-schema URI, locates the meta-schema from the `TSchemaRegistry`, checks the `$vocabulary` JSON object, and disables compilation of keywords belonging to disabled vocabularies.
   - Core vocabulary keywords are always implicitly enabled.

3. **Format Enforcement Override**:
   - Integrated the public facade option `TJsonSchemaValidator.EnforceFormats` via `TValidationContext.EnforceFormats`.
   - If `EnforceFormats` is `True`, the parser bypasses vocabulary checks for the `'format'` keyword, allowing it to compile and run format validation.

## Consequences

- **Specification Compliance**: Fully complies with Draft 2019-09 meta-schema vocabulary rules (e.g. custom meta-schemas with no validation vocabulary will correctly ignore validation keywords).
- **Flexibility**: Clients can enable format validation on Draft 2019-09 schemas using the `EnforceFormats` facade property.
- **Performance**: Disabled keywords are filtered out at compile time, saving execution CPU cycles.
