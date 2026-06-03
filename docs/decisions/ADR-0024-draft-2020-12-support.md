# ADR-0024 - Draft 2020-12 Support (Dynamic References and Positional Arrays)

## Status

Accepted

## Context

Draft 2020-12 introduces architectural changes from Draft 2019-09, including:

1. **Dynamic References (`$dynamicRef` and `$dynamicAnchor`)**: Replaces Draft 2019-09 recursive references (`$recursiveRef` and `$recursiveAnchor`) with a more general, dynamic lookup mechanism that works for any schema anchor, not just the root schema.
2. **Positional Array Validation (`prefixItems` and `items`)**: Separates array item validation into positional schemas (`prefixItems`) and a single fallback schema (`items` which only applies to indexes beyond `prefixItems`).
3. **Format Assertion Vocabulary**: Distinguishes format annotations from assertions dynamically, requiring draft-aware vocabulary activation in metaschemas.

## Decision

We implemented standard Draft 2020-12 support with the following design:

1. **Dynamic Stack Resolution**:
   - `TValidationContext.ResolveDynamicRef(const pAnchorName: string)` traverses the validation stack (`FSchemaStack`) from the outermost to the innermost frame to locate the first active schema containing a `$dynamicAnchor` with the requested name.
   - `$dynamicRef` compiles statically as a fallback but resolves target schemas dynamically at runtime if marked as dynamic.

2. **Decoupled Array Validation**:
   - Implemented a new `TPrefixItemsKeyword` to validate array prefixes.
   - Refactored `TItemsKeyword` to accept a prefix count and only evaluate array elements starting from that offset.

3. **Vocabulary-Based Format Validation**:
   - Refactored `TFormatKeyword` to support `Asserts` evaluation based on metaschema vocabularies (`format-assertion` vs `format-annotation`) or the global validator override `TValidationContext.EnforceFormats`.

## Consequences

- **100% Test Compliance**: Successfully integrated Draft 2020-12 test fixtures, ensuring 100% compliance across 6,184 tests.
- **Architectural Coherence**: Reused the validation context and scope stack, keeping memory management safe and compile/validation separation clean.
- **Decoupled Parsers**: Draft 2020-12 keyword configurations are fully self-contained within `TDraft2020_12Parser` without regressions or inheritance loops.
