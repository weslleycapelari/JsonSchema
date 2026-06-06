# VisualTestSuiteRunner

`VisualTestSuiteRunner` is a compliance validation utility designed to load and run the official JSON Schema Test Suite against the core Delphi JSON Schema validation engine (`TJsonSchemaValidator`). It tracks validation success rates per file, displays compliance metrics, and provides an interactive visual client to inspect schemas, test instances, expected results, and validator error messages for failing test cases.

## Features

- **Test Suite Loading**: Reads official test cases from `.json` suite directories (e.g. `tests/draft2020-12/`).
- **Draft Compatibility Filtering**: Run compliance validations selecting specific drafts (Draft 6, Draft 7, Draft 2019-09, Draft 2020-12).
- **Interactive VCL Client**: Features a structured tree view to navigate files, test groups, and individual test cases. Detailed side panels display JSON schemas, instance data, expected validation status, and runtime error messages.
- **Progress & Compliance Metrics**: Displays a live progress bar and colored compliance percentage (e.g. `Compliance: 98.7%`) showing standard validation conformance.
- **CLI Automation Support**: Standalone console runner supporting silent run and JSON reports export, ideal for CI/CD automation pipelines.

## Compilation

Build using the Delphi IDE or MSBuild:
```bash
msbuild VisualTestSuiteRunner.groupproj /p:Config=Release /p:Platform=Win32
```

Executables will be compiled to `.bin/`:
- `VisualTestSuiteRunnerCLI.exe`
- `VisualTestSuiteRunnerVCL.exe`

## Usage

```bash
VisualTestSuiteRunnerCLI.exe -i <suite_directory_path> [-d <draft>] [-o <output_report.json>] [--quiet]
```

### Options:
- `-i, --input <path>`: Path to the JSON Schema Test Suite directory (required)
- `-d, --draft <version>`: Draft specification version to test (default: `2020-12`)
- `-o, --output <path>`: Path to save a structured JSON compliance report
- `--quiet`: Suppress logging individual file results on stdout

### Example:
```bash
VisualTestSuiteRunnerCLI.exe -i C:\json-schema-tests\tests\draft2020-12 -o compliance_report.json
```
