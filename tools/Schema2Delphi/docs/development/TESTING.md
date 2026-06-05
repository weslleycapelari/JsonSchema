# Testing Guide - Schema2Delphi

This guide details the test structure and commands to verify `Schema2Delphi`'s AST-based generator.

## Test Structure

`Schema2Delphi`'s test cases are located in the `tools/Schema2Delphi/test/` directory:

- **`test/src/TestSchema2Delphi.pas`**: Contains DUnit test assertions checking Class mode, Record mode, enums generation, nullable types, reserved word sanitization, and destructor memory leak loops.
- **`test/console/TestSchema2DelphiConsole.dpr`**: Command-line DUnit test runner project.
- **`test/gui/TestSchema2DelphiGUI.dpr`**: Graphical DUnit test runner project.

---

## 1. Running Console Tests

To compile and execute the command-line DUnit test runner:

1. Open a terminal.
2. Navigate to the `tools/Schema2Delphi/test/console/` directory.
3. Compile the runner using:

   ```powershell
   dcc32 -U"..\..\..\..\src;..\..\..\..\src\Core;..\..\..\..\src\Core\URI;..\..\..\..\src\Drafts;..\..\..\..\src\Keywords\Core;..\..\..\..\src\Keywords\Format;..\..\..\..\src\Keywords\Logicals;..\..\..\..\src\Keywords\Metadata;..\..\..\..\src\Keywords\Validations;..\..\..\..\src\Localization;..\..\src" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" TestSchema2DelphiConsole.dpr
   ```

4. Run the executable:

   ```powershell
   .\TestSchema2DelphiConsole.exe
   ```

---

## 2. Running GUI Tests

To compile and launch the graphical DUnit test runner:

1. Open a terminal.
2. Navigate to the `tools/Schema2Delphi/test/gui/` directory.
3. Compile the runner using:

   ```powershell
   dcc32 -U"..\..\..\..\src;..\..\..\..\src\Core;..\..\..\..\src\Core\URI;..\..\..\..\src\Drafts;..\..\..\..\src\Keywords\Core;..\..\..\..\src\Keywords\Format;..\..\..\..\src\Keywords\Logicals;..\..\..\..\src\Keywords\Metadata;..\..\..\..\src\Keywords\Validations;..\..\..\..\src\Localization;..\..\src" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" TestSchema2DelphiGUI.dpr
   ```

4. Execute `TestSchema2DelphiGUI.exe` to launch the interactive DUnit GUI form and click "Run" to view visual test results.
