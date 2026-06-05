# Schema2DDL - Development & Setup Guide

This guide describes how to configure your Delphi development environment to modify, compile, and run the `Schema2DDL` project.

## 1. Prerequisites

- **Delphi Version**: Delphi Athens (version 36.0) or newer is recommended.
- **Operating System**: Windows 10 or Windows 11.
- **MSBuild**: Part of the standard Embarcadero Studio installation.

---

## 2. Project Architecture

The codebase is organized as follows:

- `Schema2DDL.groupproj`: Project group bundling VCL and CLI projects.
- `Schema2DDLCLI.dpr`: Console CLI application.
- `Schema2DDLVCL.dpr`: Graphical VCL desktop application.
- `src/Schema2DDL.Engine.pas`: Relational parser mapping schemas to columns, types, and constraints.
- `src/Schema2DDL.Dialects.pas`: Implements `ISQLDialect` mapping JSON types to Postgres, Firebird, SQLite, and SQL Server SQL representations.

---

## 3. How to compile in Delphi IDE

1. Open the RAD Studio IDE.
2. Select **File > Open Project...** and choose `tools\Schema2DDL\Schema2DDL.groupproj`.
3. In the **Project Manager** pane, right-click on the project group or individual target (CLI or VCL).
4. Select **Build** (or press `Shift + F9`).
5. Compiled executables will be generated in the `.bin` output folder under `tools\Schema2DDL\.bin\`.

---

## 4. How to compile from Command Line

Use the MSBuild build tool under the Embarcadero command prompt:

```bash
# Call Delphi environment variables
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"

# Build all targets (CLI and VCL)
msbuild Schema2DDL.groupproj /p:Config=Release /p:Platform=Win32
```
