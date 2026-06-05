# SchemaMockGen - Development & Setup

This document describes how to compile the `SchemaMockGen` (CLI) and `SchemaMockGenGUI` (VCL) applications.

## Directory Structure

```text
tools/SchemaMockGen/
├── SchemaMockGen.dpr                     # Main entry program file (CLI)
├── SchemaMockGenGUI.dpr                  # Main entry program file (VCL GUI)
├── README.md                             # Tool main overview
├── src/                                  # Tool shared source units
│   ├── SchemaMockGen.Config.pas          # CLI argument parser
│   ├── SchemaMockGen.Utils.pas           # Seeded random generator and file utils
│   ├── SchemaMockGen.Generator.pas       # Recursive schema walker and JSON mock generator
│   ├── SchemaMockGen.Runner.pas          # CLI execution orchestrator
│   ├── SchemaMockGenGUI.Main.pas         # Main VCL GUI Form unit
│   └── SchemaMockGenGUI.Main.dfm         # Main VCL GUI Form layout
└── test/                                 # Test suites
```

## Compilation Guide

Ensure that the Delphi command-line compiler (`dcc32`) is added to your environment `PATH` variables.

### 1. Compiling the Production CLI Utility

To build the executable, open your shell in the `tools/SchemaMockGen/` directory and run:

```bash
dcc32 SchemaMockGen.dpr
```

The compiled `SchemaMockGen.exe` will be generated directly in the `tools/SchemaMockGen/` folder.

### 2. Compiling the Production GUI Desktop Application

To build the VCL desktop tool, open your shell in the `tools/SchemaMockGen/` directory and run:

```bash
dcc32 SchemaMockGenGUI.dpr
```

The compiled `SchemaMockGenGUI.exe` will be generated directly in the `tools/SchemaMockGen/` folder.
