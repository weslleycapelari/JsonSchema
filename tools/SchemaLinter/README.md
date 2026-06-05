# SchemaLinter

`SchemaLinter` is a static analysis tool (linter) for JSON Schemas. It enforces best practices, structural consistency, and highlights common design errors.

## Features

- **Documentation Coverage**: Highlights schema objects that lack `title` or `description` metadata keywords.
- **Ref Validation**: Scans all `$ref` paths and flags dead links or unresolved local pointers before compile-time.
- **Performance Warnings**: Warns about expensive validation keywords (like complex regex patterns in `patternProperties` or deep nested recursive loops).
- **Style Rules**: Enforces consistent naming conventions for keys and references.
