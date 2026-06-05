# SchemaValidator

`SchemaValidator` provides JSON Schema validation utilities written in Delphi, packaging both a pipeline-friendly Command-Line Interface (CLI) and a Desktop VCL GUI application.

It compiles JSON Schemas and validates JSON documents against them, supporting multiple JSON Schema draft versions (Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12).

## Core Capabilities

- **CLI & GUI Interfaces**: Run validations from the command line in CI/CD pipelines or interactively via the desktop app.
- **Draft Selection**: Manually force a draft version or allow automatic detection via `$schema`.
- **Pipeline-Friendly**: CLI returns exit code `0` on validation success, and non-zero on validation failures or runtime errors.
- **Format Enforcement**: Toggle strict format validation assertions.
- **Structured Error Logging**: CLI outputs validation errors as plain text, JSON arrays, or JUnit XML reports.
- **VCL Desktop Interface**: Load schema and instance files, choose drafts/locales, and view failures in a clean grid showing the exact keyword, message, and suggested resolution.

## Documentation Index

- Detailed documentation is available under [docs/](docs/README.md).
