# SchemaValidatorCLI - Testing Guide

This guide describes how to run and write tests for the `SchemaValidatorCLI` utility.

## Testing Strategy

To ensure high reliability, `SchemaValidatorCLI` is validated using a two-tier testing approach:

1. **Unit Testing**: Tests internal CLI components such as the argument parsing logic (`ParseArgumentsEx`) and the schema version auto-detection (`AutoDetectDraft`). These run entirely in memory.
2. **Integration Testing**: Spawns the compiled `SchemaValidatorCLI.exe` binary as a child process using the Windows API. It validates:
   - Proper input/output piping and redirect behavior.
   - Exact stdout strings for plain text, JSON, and JUnit XML output options.
   - Correct process exit codes (`0` for valid, `1` for invalid, `2` for errors).

All tests are implemented in `tools/SchemaValidatorCLI/test/src/TestSchemaValidatorCLI.pas` and run under the DUnit framework.

## Running Tests

Before running the tests, compile the production CLI binary first (as described in the [Setup Guide](SETUP.md)), since the integration tests depend on `SchemaValidatorCLI.exe`.

### 1. Running Console Tests

To execute tests and view output directly in your shell:

1. Open your console in `tools/SchemaValidatorCLI/test/console/`.
2. Compile the console runner:

   ```bash
   dcc32 -U"..\..\src;..\..\..\..\src;..\..\..\..\src\Core;..\..\..\..\src\Core\URI;..\..\..\..\src\Drafts;..\..\..\..\src\Keywords\Core;..\..\..\..\src\Keywords\Format;..\..\..\..\src\Keywords\Logicals;..\..\..\..\src\Keywords\Metadata;..\..\..\..\src\Keywords\Validations;..\..\..\..\src\Localization" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" TestSchemaValidatorCLIConsole.dpr
   ```

3. Run the compiled executable:

   ```powershell
   ./TestSchemaValidatorCLIConsole.exe
   ```

### 2. Running GUI Tests

To execute tests visually:

1. Open your console in `tools/SchemaValidatorCLI/test/gui/`.
2. Compile the GUI runner:

   ```bash
   dcc32 -U"..\..\src;..\..\..\..\src;..\..\..\..\src\Core;..\..\..\..\src\Core\URI;..\..\..\..\src\Drafts;..\..\..\..\src\Keywords\Core;..\..\..\..\src\Keywords\Format;..\..\..\..\src\Keywords\Logicals;..\..\..\..\src\Keywords\Metadata;..\..\..\..\src\Keywords\Validations;..\..\..\..\src\Localization" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" TestSchemaValidatorCLIGui.dpr
   ```

3. Run the compiled GUI executable:

   ```powershell
   ./TestSchemaValidatorCLIGui.exe
   ```

   *This will open the graphical DUnit Test Runner window. Press **F9** or click **Run** to execute.*
