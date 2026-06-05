# Developer Setup - Schema2Delphi

This guide helps you set up the development environment to build, edit, and run the `Schema2Delphi` CLI and VCL GUI applications.

## Requirements

- **Delphi Compiler (DCC32)**: Version 36.0 (Delphi Athens) or higher.
- **RAD Studio IDE**: (Optional) to edit VCL design forms visually.

## Directory Structure

```text
tools/Schema2Delphi/
├── Schema2Delphi.groupproj          # Delphi Group Project linking VCL and CLI
├── Schema2DelphiCLI.dpr             # CLI Program entry point
├── Schema2DelphiCLI.dproj           # CLI IDE project configuration
├── Schema2DelphiVCL.dpr             # VCL GUI Program entry point
├── Schema2DelphiVCL.dproj           # VCL GUI IDE project configuration
├── README.md                        # Tool main overview
├── docs/                            # Detailed documentation
├── src/                             # Shared source code folder
│   ├── Schema2Delphi.Main.pas       # Main VCL Form logic
│   ├── Schema2Delphi.Main.dfm       # Main VCL Form design layout
│   ├── Schema2Delphi.Lote.pas       # Batch VCL Form logic
│   ├── Schema2Delphi.Lote.dfm       # Batch VCL Form design layout
│   ├── Schema2Delphi.AST.pas        # Delphi Code AST definition
│   ├── Schema2Delphi.Common.pas     # Shared interfaces & configs
│   ├── Schema2Delphi.Sanitizer.pas  # Identifier sanitizers
│   ├── Schema2Delphi.TypeMapper.pas # Schema type mapping engine
│   ├── Schema2Delphi.Visitor.pas    # AST builder visitor
│   └── Schema2Delphi.Utils.pas      # High-level helper utilities
└── test/                            # Test suite
```

---

## Compiling via Command Line

To compile the `Schema2Delphi` executables using the Delphi command-line compiler:

1. Open your terminal in the `tools/Schema2Delphi/` folder.
2. Compile the **CLI tool**:

```bash
dcc32 -U"..\..\src;..\..\src\Core;..\..\src\Core\URI;..\..\src\Drafts;..\..\src\Keywords\Core;..\..\src\Keywords\Format;..\..\src\Keywords\Logicals;..\..\src\Keywords\Metadata;..\..\src\Keywords\Validations;..\..\src\Localization;src" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" Schema2DelphiCLI.dpr
```

1. Compile the **VCL GUI application**:

```bash
dcc32 -U"..\..\src;..\..\src\Core;..\..\src\Core\URI;..\..\src\Drafts;..\..\src\Keywords\Core;..\..\src\Keywords\Format;..\..\src\Keywords\Logicals;..\..\src\Keywords\Metadata;..\..\src\Keywords\Validations;..\..\src\Localization;src" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" Schema2DelphiVCL.dpr
```

The compiled executables (`Schema2DelphiCLI.exe` and `Schema2DelphiVCL.exe`) will be generated directly in the `tools/Schema2Delphi/` folder.

---

## Editing GUI Form Files

To edit the VCL graphical forms, open RAD Studio and load the project group `Schema2Delphi.groupproj`. You can open `Schema2DelphiVCL.dproj` directly in the IDE to design the forms visually.
