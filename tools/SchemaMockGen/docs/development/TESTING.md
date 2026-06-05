# SchemaMockGen - Testing Guide

This guide describes how to run and write tests for `SchemaMockGen`.

## Testing Strategy

To guarantee the reliability of mock data generation, `SchemaMockGen` is tested using:

1. **Unit Testing**: Tests the `TSeededRandom` LCG implementation (reproducibility) and configuration parsing.
2. **Conformity Testing**: Runs the generator against complex schemas (objects, arrays, strings with constraints like `minimum` / `maxLength`) and passes the generated mock output to our core `TJsonSchemaValidator` library, asserting that the output is 100% compliant with the schema rules.
3. **Integration Testing**: Spawns `SchemaMockGen.exe` as a child process using pipes to assert exit codes and stdout redirection.

All tests are implemented in `tools/SchemaMockGen/test/src/TestSchemaMockGen.pas` and run under the DUnit framework.

## Running Tests

Ensure that you compile the production CLI binary first (as described in the [Setup Guide](SETUP.md)) before running tests, as integration tests depend on `SchemaMockGen.exe`.

### 1. Running Console Tests

To execute tests and view output directly in your shell:

1. Open your console in `tools/SchemaMockGen/test/console/`.
2. Compile the console runner:

   ```bash
   dcc32 -U"..\..\src;..\..\..\..\src;..\..\..\..\src\Core;..\..\..\..\src\Core\URI;..\..\..\..\src\Drafts;..\..\..\..\src\Keywords\Core;..\..\..\..\src\Keywords\Format;..\..\..\..\src\Keywords\Logicals;..\..\..\..\src\Keywords\Metadata;..\..\..\..\src\Keywords\Validations;..\..\..\..\src\Localization" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" TestSchemaMockGenConsole.dpr
   ```

3. Run the compiled executable:

   ```powershell
   ./TestSchemaMockGenConsole.exe
   ```

### 2. Running GUI Tests

To execute tests visually:

1. Open your console in `tools/SchemaMockGen/test/gui/`.
2. Compile the GUI runner:

   ```bash
   dcc32 -U"..\..\src;..\..\..\..\src;..\..\..\..\src\Core;..\..\..\..\src\Core\URI;..\..\..\..\src\Drafts;..\..\..\..\src\Keywords\Core;..\..\..\..\src\Keywords\Format;..\..\..\..\src\Keywords\Logicals;..\..\..\..\src\Keywords\Metadata;..\..\..\..\src\Keywords\Validations;..\..\..\..\src\Localization" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" TestSchemaMockGenGui.dpr
   ```

3. Run the compiled GUI executable:

   ```powershell
   ./TestSchemaMockGenGui.exe
   ```
