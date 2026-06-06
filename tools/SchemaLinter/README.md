# SchemaLinter

`SchemaLinter` is a static analysis tool (linter) for JSON Schemas. It enforces best practices, structural consistency, and highlights common logical conflicts and security risks.

## Features

- **Limits Consistency**: Flags contradictory constraints (e.g. `minimum` > `maximum`, `minLength` > `maxLength`, `minItems` > `maxItems`, `minProperties` > `maxProperties`).
- **Required Fields Integrity**: Warns when properties listed in the `"required"` array are missing from the `"properties"` block.
- **Regex Security Check (ReDoS)**: Parses regular expressions in `"pattern"` and `"patternProperties"` to detect nested quantifiers that can lead to catastrophic backtracking.
- **Obsolete Keywords**: Flags legacy features (like `"dependencies"` or `"definitions"`) in favor of modern alternatives (`"dependentRequired"`, `"dependentSchemas"`, and `"$defs"`).
- **Documentation Gaps**: Alerts about missing root `"title"` metadata or missing `"description"` metadata in property definitions.
- **CLI & VCL GUI**: Standalone console tool for automation and a modern visual Windows VCL desktop client.

## Compilation

Build using the Delphi IDE or MSBuild:

```bash
msbuild SchemaLinter.groupproj /p:Config=Release /p:Platform=Win32
```

Executables will be compiled to `.bin/`:

- `SchemaLinterCLI.exe`
- `SchemaLinterVCL.exe`

## Usage

```bash
SchemaLinterCLI.exe -s <schema.json> [-o <report_output>] [-m <min_severity>]
```

Example:

```bash
SchemaLinterCLI.exe -s C:\schemas\User.json -m warning -o C:\reports\linter_report.md
```
