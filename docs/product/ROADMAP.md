# Roadmap

## Now

The codebase currently focuses on a draft-aware validation engine with:

- Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12 support
- compiled-schema validation
- core, validation, logical, format, and metadata keywords
- localized enUS and ptBR messages
- schema registry and reference resolution

## Next priorities

The most valuable next steps are:

- improve per-draft semantic documentation where drafts diverge
- expand or formalize vocabulary boundaries
- strengthen the official test-suite story
- document extension points for custom keywords and localization
- continue refining reference and URI handling edge cases

## Later goals

Longer-term goals from the product vision remain valid, including:

- HyperSchema
- Relative JSON Pointer
- custom vocabularies
- richer annotation and output support
- additional tooling around schemas and diagnostics

## Roadmap rule

A roadmap item should only be documented as implemented after it is observable in src and covered by tests or explicit validation evidence.
