# SchemaOptimizer

`SchemaOptimizer` is a utility designed to analyze and optimize JSON Schema files by removing unused local definitions, merging redundant type constraints, flattening nested logical blocks, and pruning empty subschemas. It reduces schema size and complexity, making them cleaner and more performant.

## Features

- **Unused Definitions Pruning**: Iteratively scans for and prunes `$defs` and `definitions` that are not referenced by any `$ref` pointer in the entire document.
- **allOf Flattening & Merging**: Flattens nested `allOf` blocks and merges non-conflicting properties and validations directly into the parent schema object.
- **Empty & Duplicate Pruning**: Removes redundant logical elements, empty objects (`{}`) in logical blocks, and deduplicates types (e.g. `type: ["string", "string"]` becomes `type: "string"`).
- **Top-Key Reordering**: Re-orders properties to place core metadata keywords (like `$schema`, `$id`, `title`, `description`, `type`) at the very top of the JSON object.
- **CLI & VCL GUI**: Standalone CLI console program for automation, and a modern themed Windows VCL desktop application displaying byte reduction savings and count of removed definitions.

## Compilation

Build using the Delphi IDE or MSBuild:
```bash
msbuild SchemaOptimizer.groupproj /p:Config=Release /p:Platform=Win32
```

Executables will be compiled to `.bin/`:
- `SchemaOptimizerCLI.exe`
- `SchemaOptimizerVCL.exe`

## Usage

```bash
SchemaOptimizerCLI.exe -i <input_schema.json> [-o <output_schema.json>] [options]
```

### Options:
- `-i, --input <path>`: Path to the input JSON Schema file (required)
- `-o, --output <path>`: Path to save the optimized schema (prints to stdout if omitted)
- `--no-unused`: Do not remove unused `$defs`/`definitions`
- `--no-allof`: Do not merge or flatten nested `allOf` blocks
- `--no-prune`: Do not prune empty subschemas or duplicate values
- `--minify`: Minify output JSON schema instead of formatting

### Example:
```bash
SchemaOptimizerCLI.exe -i C:\schemas\UserSchema.json -o C:\schemas\UserSchema.min.json --minify
```
