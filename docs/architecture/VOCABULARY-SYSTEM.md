# Vocabulary System

## Purpose

This document explains how keyword families are organized in the current implementation and how that organization may evolve.

## Current vocabulary grouping

The code currently groups keywords by domain:

- `Keywords/Core`
- `Keywords/Validations`
- `Keywords/Logicals`
- `Keywords/Format`
- `Keywords/Metadata`

This grouping is practical for the codebase and keeps related behavior close together.

## Dynamic Vocabulary Activation (Draft 2019-09+)

Beginning with Draft 2019-09, the library dynamically models vocabulary activation. During schema compilation, the parser:

1. Retrieves the active schema's `$schema` meta-schema.
2. Inspects the `$vocabulary` object of the meta-schema.
3. Maps each keyword to its standard vocabulary URI (Core, Applicator, Validation, Format, Meta-Data).
4. If a vocabulary is explicitly disabled (`false`) in the meta-schema, the parser dynamically disables compilation of its respective keywords (they will not validate).
5. Core vocabulary keywords are always implicitly enabled.
6. The `format` vocabulary can be explicitly overridden/forced via `TJsonSchemaValidator.EnforceFormats`.

## Extension boundary

The registry and keyword factory design provide the main extension boundary for future vocabularies and custom keywords.

## Vocabulary mapping

The parser groups standard keywords under the following URIs:

- **Core (`.../vocab/core`)**: `$id`, `$schema`, `$anchor`, `$ref`, `$recursiveRef`, `$recursiveAnchor`, `$vocabulary`, `$comment`, `$defs`
- **Applicator (`.../vocab/applicator`)**: `allOf`, `anyOf`, `oneOf`, `not`, `if`, `then`, `else`, `dependentSchemas`, `propertyNames`, `properties`, `patternProperties`, `additionalProperties`, `items`, `additionalItems`, `contains`, `unevaluatedProperties`, `unevaluatedItems`
- **Validation (`.../vocab/validation`)**: `type`, `enum`, `const`, `multipleOf`, `maximum`, `exclusiveMaximum`, `minimum`, `exclusiveMinimum`, `maxLength`, `minLength`, `pattern`, `maxItems`, `minItems`, `uniqueItems`, `maxContains`, `minContains`, `maxProperties`, `minProperties`, `required`, `dependentRequired`
- **Format (`.../vocab/format`)**: `format`
- **Meta-Data (`.../vocab/meta-data`)**: `title`, `description`, `default`, `deprecated`, `readOnly`, `writeOnly`, `examples`

## Rule

Document vocabulary-level changes explicitly when a keyword moves across categories or when a new vocabulary becomes visible in runtime behavior.
