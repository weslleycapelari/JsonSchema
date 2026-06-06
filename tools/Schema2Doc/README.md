# Schema2Doc

`Schema2Doc` is a documentation generator that reads a JSON Schema and produces structured, human-readable documentation in Markdown or HTML formats.

## Features

- **Markdown Tables**: Generates clean Markdown tables summarizing requirements (types, required status, format patterns, default values, and descriptions).
- **Responsive HTML**: Generates clean, responsive HTML pages documenting the schema structures with a modern theme and visual type badges.
- **CLI & VCL GUI**: Command-Line Interface console program for scripts, and a Windows desktop VCL application.

## Compilation

Build using the Delphi IDE or MSBuild:

```bash
msbuild Schema2Doc.groupproj /p:Config=Release /p:Platform=Win32
```

Executables will be compiled to `.bin/`:

- `Schema2DocCLI.exe`
- `Schema2DocVCL.exe`

## Usage

```bash
Schema2DocCLI.exe -s <schema.json> [-o <doc_output>] [-f <format>] [-t <title>]
```

Example:

```bash
Schema2DocCLI.exe -s C:\schemas\User.json -f html -o C:\docs\User.html -t "User API Schema"
```
