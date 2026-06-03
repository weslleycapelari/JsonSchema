# Domain

## What this library validates

This library validates JSON instances against JSON Schema documents.

The domain includes:

- schema parsing and compilation
- keyword evaluation
- draft-specific behavior
- reference resolution
- localized validation feedback

## Core domain concepts

### Schema

A JSON document that describes constraints for another JSON document.

### Instance

The JSON value being validated.

### Draft

A version of the JSON Schema specification with its own rules and semantics.

### Dialect

The implementation view of a draft inside the library.

### Keyword

A single validation or core rule such as `type`, `minLength`, or `$ref`.

### Vocabulary

A related group of keywords, such as validation, logical, or core keywords.

### Compiled schema

The runtime representation of a parsed schema, built from keyword validators.

### Validation result

The object returned after validation, including validity state and any errors.

### Validation error

A structured failure entry with keyword name, message, resolution, and technical context.

### Schema registry

A shared lookup mechanism for schema resources, URIs, and references.

## Project-specific interpretation

The codebase currently groups keywords into:

- Core keywords
- Validation keywords
- Logical keywords

That organization is practical today, while vocabulary-level separation remains a future refinement.

## Boundaries

This is a library domain, not an application domain.

That means the documentation should focus on:

- contracts
- validation behavior
- supported drafts
- error semantics
- extension points

It should not introduce business-domain rules unrelated to JSON Schema itself.
