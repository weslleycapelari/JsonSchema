# Delphi2Schema - Testing Guide

This guide explains how to compile and run the DUnit test suite for `Delphi2Schema` to ensure correctness of type mapping and engine rules.

## 1. Test Project Structure

Tests are organized under the `test/` directory of the tool:

- `test/src/TestDelphi2Schema.pas`: Core test cases including schema generation checks, options validations, attributes checking, and subprocess CLI execution.
- `test/console/TestDelphi2SchemaConsole.dpr`: DUnit console runner. Useful for automated checks or run from terminal.
- `test/gui/TestDelphi2SchemaGui.dpr`: DUnit GUI runner. Displays a visual checklist window.

---

## 2. Running Console Tests

Execute the console test suite using the Embarcadero command prompt or terminal:

```bash
# Compile console tests
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
msbuild test\console\TestDelphi2SchemaConsole.dproj /p:Config=Release /p:Platform=Win32

# Execute tests
test\console\.bin\TestDelphi2SchemaConsole.exe
```

A successful run displays a summary showing `OK: 3 tests`.

---

## 3. Running GUI Tests

If you prefer a visual interface:

```bash
# Compile GUI test project
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
msbuild test\gui\TestDelphi2SchemaGui.dproj /p:Config=Release /p:Platform=Win32

# Execute tests
test\gui\.bin\TestDelphi2SchemaGui.exe
```

This launches the visual DUnit tree-view panel where you can run individual or all test nodes.
