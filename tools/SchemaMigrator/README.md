# SchemaMigrator

`SchemaMigrator` is a utility designed to upgrade legacy JSON Schema documents (Draft 4, Draft 6, or Draft 7) to modern specifications (Draft 2020-12). It translates obsolete keywords, corrects internal reference pointers, splits hybrid dependencies, and prettifies the schema structure in a single operation.

## Features

- **Dialect Upgrade**: Updates the `$schema` dialect string to Draft 2020-12 and renames legacy `id` keywords to `$id`.
- **Definitions Relocation**: Renames `definitions` to `$defs` and recursively rewrites all `$ref` pointer paths accordingly (e.g. `#/definitions/User` becomes `#/$defs/User`).
- **Dependencies Splitting**: Detects hybrid Draft 4/7 `"dependencies"` structures, splitting them into property-only constraints (`"dependentRequired"`) and subschema-only constraints (`"dependentSchemas"`).
- **Tuple Upgrade**: Converts legacy array-style `"items"` validation into modern `"prefixItems"`, renaming `"additionalItems"` to `"items"`.
- **Top-Key Reordering**: Re-orders properties to place core metadata keywords (like `$schema`, `$id`, `title`, `description`, `type`) at the very top of the JSON object.
- **CLI & VCL GUI**: Standalone CLI console program for automation, and a modern themed Windows VCL desktop application.

## Compilation

Build using the Delphi IDE or MSBuild:
```bash
msbuild SchemaMigrator.groupproj /p:Config=Release /p:Platform=Win32
```

Executables will be compiled to `.bin/`:
- `SchemaMigratorCLI.exe`
- `SchemaMigratorVCL.exe`

## Usage

```bash
SchemaMigratorCLI.exe -i <input_schema.json> [-o <output_schema.json>] [--minify]
```

Example:
```bash
SchemaMigratorCLI.exe -i C:\schemas\LegacyUser.json -o C:\schemas\ModernUser.json
```
