# SchemaValidatorCLI - Development & Setup

This document describes how to set up the development environment, compile the CLI utility, and compile its test suites.

## Directory Structure

```text
tools/SchemaValidatorCLI/
├── SchemaValidatorCLI.dpr                # Main project entry
├── README.md                             # Tool main overview
├── docs/                                 # Detailed documentation
├── src/                                  # Modular source units
│   ├── SchemaValidatorCLI.Config.pas     # Argument parser
│   ├── SchemaValidatorCLI.Utils.pas      # File and stdin utilities
│   ├── SchemaValidatorCLI.Formatters.pas # Plain Text/JSON/JUnit output formatting
│   └── SchemaValidatorCLI.Runner.pas     # Coordinator runner
└── test/                                 # Test suites
    ├── console/
    │   └── TestSchemaValidatorCLIConsole.dpr # DUnit Console runner
    ├── gui/
    │   └── TestSchemaValidatorCLIGui.dpr     # DUnit GUI runner
    └── src/
        └── TestSchemaValidatorCLI.pas        # Test suite code
```

## Compilation Guide

Ensure that the Delphi command-line compiler (`dcc32`) is added to your environment `PATH` variables.

### 1. Compiling the Production CLI Utility

To build the executable, open your shell in the `tools/SchemaValidatorCLI/` directory and run:

```bash
dcc32 -U"..\..\src;..\..\src\Core;..\..\src\Core\URI;..\..\src\Drafts;..\..\src\Keywords\Core;..\..\src\Keywords\Format;..\..\src\Keywords\Logicals;..\..\src\Keywords\Metadata;..\..\src\Keywords\Validations;..\..\src\Localization" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" SchemaValidatorCLI.dpr
```

The compiled `SchemaValidatorCLI.exe` will be generated directly in the `tools/SchemaValidatorCLI/` folder.

### 2. Compiling the Console Test Runner

To compile the DUnit console test runner, open your shell in the `tools/SchemaValidatorCLI/test/console/` directory and run:

```bash
dcc32 -U"..\..\src;..\..\..\..\src;..\..\..\..\src\Core;..\..\..\..\src\Core\URI;..\..\..\..\src\Drafts;..\..\..\..\src\Keywords\Core;..\..\..\..\src\Keywords\Format;..\..\..\..\src\Keywords\Logicals;..\..\..\..\src\Keywords\Metadata;..\..\..\..\src\Keywords\Validations;..\..\..\..\src\Localization" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" TestSchemaValidatorCLIConsole.dpr
```

### 3. Compiling the GUI Test Runner

To compile the DUnit GUI test runner, open your shell in the `tools/SchemaValidatorCLI/test/gui/` directory and run:

```bash
dcc32 -U"..\..\src;..\..\..\..\src;..\..\..\..\src\Core;..\..\..\..\src\Core\URI;..\..\..\..\src\Drafts;..\..\..\..\src\Keywords\Core;..\..\..\..\src\Keywords\Format;..\..\..\..\src\Keywords\Logicals;..\..\..\..\src\Keywords\Metadata;..\..\..\..\src\Keywords\Validations;..\..\..\..\src\Localization" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" TestSchemaValidatorCLIGui.dpr
```
