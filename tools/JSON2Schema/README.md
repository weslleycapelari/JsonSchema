# JSON2Schema

`JSON2Schema` is a developer utility designed to generate a valid JSON Schema (Draft 7 or Draft 2020-12) from arbitrary JSON instance document samples. It supports type detection, format matches, and customizable array/object properties rules.

## Features

- **Automatic Format Detection**: Matches date-time, date, email, and UUIDv4 pattern rules.
- **Complex Type Handling**: Handles homogeneous arrays, mixed arrays (with `anyOf`), and recursive nested structures.
- **Graphical & Command-line**: Run inside Windows desktop VCL app or automate in CLI console scripts.

## Compilation

Build using Delphi IDE or MSBuild:

```bash
msbuild JSON2Schema.groupproj /p:Config=Release /p:Platform=Win32
```

Executables will be compiled to `.bin/`:

- `JSON2SchemaCLI.exe`
- `JSON2SchemaVCL.exe`

## Usage

```bash
JSON2SchemaCLI.exe -i <sample.json> [-o <schema.json>] [--required]
```
