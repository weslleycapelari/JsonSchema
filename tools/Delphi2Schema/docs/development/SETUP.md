# Delphi2Schema - Development & Setup Guide

This guide describes how to configure your Delphi development environment to modify, compile, and run the `Delphi2Schema` project.

## 1. Prerequisites

- **Delphi Version**: Delphi Athens (version 36.0) or newer is recommended.
- **Operating System**: Windows 10 or Windows 11.
- **MSBuild**: Part of the standard Embarcadero Studio installation, used for compilation.

---

## 2. Project Architecture

The codebase is organized as follows:

- `Delphi2Schema.groupproj`: Project group that bundles VCL and CLI projects.
- `Delphi2SchemaCLI.dpr`: Program entry point for the console CLI application.
- `Delphi2SchemaVCL.dpr`: Program entry point for the modern graphical VCL desktop application.
- `src/Delphi2Schema.Engine.pas`: The core reflection processor. It walks through RTTI structures and generates the JSON representation.
- `src/Delphi2Schema.Attributes.pas`: Defines the attribute types extending `TCustomAttribute`.
- `src/Delphi2Schema.Samples.pas`: Declares the demo models. **Important**: Because Delphi strips out unused classes during compilation, referencing classes in the `initialization` block of this unit is mandatory to keep their RTTI active.

---

## 3. How to compile in Delphi IDE

1. Open the RAD Studio IDE.
2. Select **File > Open Project...** and choose `tools\Delphi2Schema\Delphi2Schema.groupproj`.
3. In the **Project Manager** pane, right-click on the project group or individual target (CLI or VCL).
4. Select **Build** (or press `Shift + F9`).
5. Compiled executables will be generated in the `.bin` output folder under `tools\Delphi2Schema\.bin\`.

---

## 4. How to compile from Command Line

Use the MSBuild build tool under the Embarcadero command prompt:

```bash
# Call Delphi environment variables
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"

# Build all targets (CLI and VCL)
msbuild Delphi2Schema.groupproj /p:Config=Release /p:Platform=Win32
```
