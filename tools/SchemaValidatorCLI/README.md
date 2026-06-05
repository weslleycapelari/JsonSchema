# SchemaValidatorCLI

`SchemaValidatorCLI` is a command-line interface (CLI) validation utility written in Delphi. It compiles JSON Schemas and validates JSON documents against them, returning standardized exit codes and diagnostic reports.

## Features

- **Draft Selection**: Manually force a draft version (Draft 6, 7, 2019-09, 2020-12) or allow automatic detection via `$schema`.
- **Pipeline-Friendly**: Returns exit code `0` on validation success, and non-zero on validation failures or runtime errors.
- **Format Enforcement Options**: Toggle strict format validation assertions via command-line arguments.
- **Structured Error Logging**: Outputs validation errors as plain text, JSON arrays, or JUnit XML reports for CI/CD integrations.
