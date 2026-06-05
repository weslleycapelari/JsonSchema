# SchemaValidator - Development & Setup

This document describes how to set up the development environment, compile the CLI and VCL GUI utilities, and compile the test runners.

## Directory Structure

```text
tools/SchemaValidator/
├── SchemaValidator.groupproj        # Delphi Group Project linking VCL and CLI
├── SchemaValidatorCLI.dpr           # CLI Program entry point
├── SchemaValidatorCLI.dproj         # CLI IDE project configuration
├── SchemaValidatorVCL.dpr           # VCL GUI Program entry point
├── SchemaValidatorVCL.dproj         # VCL GUI IDE project configuration
├── README.md                        # Tool main overview
├── docs/                            # Detailed documentation
├── src/                             # Modular source units
│   ├── SchemaValidator.Config.pas   # Argument parser
│   ├── SchemaValidator.Utils.pas    # File and stdin utilities
│   ├── SchemaValidator.Formatters.pas# Plain Text/JSON/JUnit output formatting
│   ├── SchemaValidator.Runner.pas   # Coordinator runner
│   ├── SchemaValidator.Main.pas     # Main VCL GUI Form logic
│   └── SchemaValidator.Main.dfm     # Main VCL GUI Form design layout
└── test/                            # Test suites
    ├── console/
    │   └── TestSchemaValidatorConsole.dpr # DUnit Console runner
    ├── gui/
    │   └── TestSchemaValidatorGui.dpr     # DUnit GUI runner
    └── src/
        └── TestSchemaValidator.pas        # Test suite code
```

## Compilation Guide

Ensure that the Delphi command-line compiler (`dcc32`) is added to your environment `PATH` variables.

### 1. Compiling the Production CLI Utility

To build the executable, open your shell in the `tools/SchemaValidator/` directory and run:

```bash
dcc32 -U"..\..\src;..\..\src\Core;..\..\src\Core\URI;..\..\src\Drafts;..\..\src\Keywords\Core;..\..\src\Keywords\Format;..\..\src\Keywords\Logicals;..\..\src\Keywords\Metadata;..\..\src\Keywords\Validations;..\..\src\Localization;src" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" SchemaValidatorCLI.dpr
```

The compiled `SchemaValidatorCLI.exe` will be generated directly in the `tools/SchemaValidator/` folder.

### 2. Compiling the Desktop VCL GUI Application

To build the VCL GUI application, open your shell in the `tools/SchemaValidator/` directory and run:

```bash
dcc32 -U"..\..\src;..\..\src\Core;..\..\src\Core\URI;..\..\src\Drafts;..\..\src\Keywords\Core;..\..\src\Keywords\Format;..\..\src\Keywords\Logicals;..\..\src\Keywords\Metadata;..\..\src\Keywords\Validations;..\..\src\Localization;src" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" SchemaValidatorVCL.dpr
```

The compiled `SchemaValidatorVCL.exe` will be generated directly in the `tools/SchemaValidator/` folder.

### 3. Compiling the Console Test Runner

To compile the DUnit console test runner, open your shell in the `tools/SchemaValidator/test/console/` directory and run:

```bash
dcc32 -U"..\..\src;..\..\..\..\src;..\..\..\..\src\Core;..\..\..\..\src\Core\URI;..\..\..\..\src\Drafts;..\..\..\..\src\Keywords\Core;..\..\..\..\src\Keywords\Format;..\..\..\..\src\Keywords\Logicals;..\..\..\..\src\Keywords\Metadata;..\..\..\..\src\Keywords\Validations;..\..\..\..\src\Localization;..\..\src" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" TestSchemaValidatorConsole.dpr
```

### 4. Compiling the GUI Test Runner

To compile the DUnit GUI test runner, open your shell in the `tools/SchemaValidator/test/gui/` directory and run:

```bash
dcc32 -U"..\..\src;..\..\..\..\src;..\..\..\..\src\Core;..\..\..\..\src\Core\URI;..\..\..\..\src\Drafts;..\..\..\..\src\Keywords\Core;..\..\..\..\src\Keywords\Format;..\..\..\..\src\Keywords\Logicals;..\..\..\..\src\Keywords\Metadata;..\..\..\..\src\Keywords\Validations;..\..\..\..\src\Localization;..\..\src" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" TestSchemaValidatorGui.dpr
```
