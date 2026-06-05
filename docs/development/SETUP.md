# Setup

## Purpose

This guide explains how to prepare a local environment for building and testing JsonSchema Delphi.

## Requirements

- Windows
- Delphi IDE compatible with the project files in the repository
- A working Delphi RTL/VCL installation
- Access to the source tree in this repository

The project does not rely on external package managers or non-Delphi runtime dependencies.

## Repository entry points

The current test entry points are:

- `test/gui/TestJsonSchema.dpr`
- `test/console/TestJsonSchemaConsole.dpr`

Each auxiliary developer tool under `tools/` includes a Delphi Project Group (`.groupproj`) uniting its CLI and VCL applications:

- `tools/SchemaMockGen/SchemaMockGen.groupproj`
- `tools/Schema2Delphi/Schema2Delphi.groupproj`
- `tools/SchemaValidator/SchemaValidator.groupproj`

The repository also contains the library source under `src/` and supporting fixtures under `test/src/` and `test/schemas/`.

## Recommended workflow

1. Open the repository in Delphi IDE.
2. Load the test project you want to run.
3. Build the project.
4. Run the tests.
5. Inspect failures in the IDE test runner or console output.

## Command-line build

If you build from the command line, use the Delphi compiler available in your environment.

Typical options are:

- `dcc64.exe` for direct Delphi compilation
- `msbuild` when the project setup and environment support it

If the compiler is not already available in the current shell, use the Delphi developer command prompt or a clean environment that exposes the compiler binaries.

## Validation checklist

After setup, confirm that you can:

- open the main source units
- build the selected test project
- execute the test suite
- see localized validation output in enUS and ptBR scenarios

## Notes

- The supported runtime drafts are Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.
- Historical fixtures may mention older drafts, but they are not a substitute for runtime support.
