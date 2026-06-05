# Developer Setup - Schema2Delphi

This guide helps you set up the development environment to build, edit, and run `Schema2Delphi`.

## Requirements

- **Delphi Compiler (DCC32)**: Version 36.0 (Delphi Athens) or higher.
- **RAD Studio IDE**: (Optional) to edit dfm forms visually.

## Directory Structure

```text
tools/Schema2Delphi/
├── Schema2Delphi.dpr                       # Main GUI program
├── Schema2Delphi.dproj                     # Delphi IDE project configuration
├── src/                                    # Tool source code folder
│   ├── Schema2Delphi.Main.pas              # Main VCL Form logic
│   ├── Schema2Delphi.Main.dfm              # Main Form design
│   ├── Schema2Delphi.Lote.pas              # Batch Form logic
│   ├── Schema2Delphi.Lote.dfm              # Batch Form design
│   ├── Schema2Delphi.AST.pas               # Delphi Code AST definition
│   ├── Schema2Delphi.Common.pas            # Shared interfaces & configs
│   ├── Schema2Delphi.Sanitizer.pas         # Identifiers sanitizers
│   ├── Schema2Delphi.TypeMapper.pas        # Schema type map engine
│   ├── Schema2Delphi.AttributeProcessor.pas# Metadata attributes generator
│   ├── Schema2Delphi.Visitor.pas           # AST builder orchestrator
│   └── Schema2Delphi.Utils.pas             # High-level API utilities
└── test/                                   # DUnit tests folder
```

---

## Compiling via Command Line

To compile the `Schema2Delphi` tool executable using the Delphi command-line compiler:

1. Open a terminal (such as PowerShell).
2. Navigate to the project root directory.
3. Run the following compilation command:

```powershell
dcc32 -U"src;src\Core;src\Core\URI;src\Drafts;src\Keywords\Core;src\Keywords\Format;src\Keywords\Logicals;src\Keywords\Metadata;src\Keywords\Validations;src\Localization;tools\Schema2Delphi\src" -NS"System;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win" tools\Schema2Delphi\Schema2Delphi.dpr
```

The output executable `Schema2Delphi.exe` will be generated directly in the `tools/Schema2Delphi/` folder.

---

## Editing DFM Form Files

To edit the graphical forms (`Schema2Delphi.Main.dfm` and `Schema2Delphi.Lote.dfm`), open RAD Studio and load the `Schema2Delphi.dproj` project. The IDE will render form components visually and keep source and design files synchronized.
