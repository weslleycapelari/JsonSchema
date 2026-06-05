# SchemaBundler

`SchemaBundler` is a utility designed to resolve, pack, and bundle multiple split JSON Schema files into a single, self-contained schema file. It eliminates external references (`$ref` referencing local files or HTTP URIs) by inlining them into a centralized `$defs` (or `definitions`) node, making schemas suitable for offline use and easy distribution.

## Features

- **Recursive Reference Resolution**: Follows external `$ref` pointers pointing to local files or network URLs.
- **Collision Prevention**: Automatically renames conflicting definitions and anchors when merging schemas from different locations.
- **Pointers Rewriting**: Rewrites all `$ref` paths in the bundled schema to point internally (e.g. `#/definitions/MyResolvedType`).
- **Minification**: Supports producing minified or prettified output schemas.

## Usage

Run the bundler via CLI, specifying the root schema file and output destination:
```bash
SchemaBundler.exe -i root_schema.json -o bundled_schema.json
```
