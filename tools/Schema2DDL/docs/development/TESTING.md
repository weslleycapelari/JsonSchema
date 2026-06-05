# Schema2DDL - Testing Guide

This guide explains how to compile and run the DUnit test suite for `Schema2DDL` to ensure correct SQL mappings and constraints translations.

## 1. Test Project Structure

Tests are organized under the `test/` directory of the tool:

- `test/src/TestSchema2DDL.pas`: Core test cases including PostgreSQL dialect mappings, Firebird mappings, SQLite/MSSQL mappings, relational nested objects/foreign keys, and subprocess CLI execution.
- `test/console/TestSchema2DDLConsole.dpr`: DUnit console runner.
- `test/gui/TestSchema2DDLGui.dpr`: DUnit GUI runner.

---

## 2. Running Console Tests

Execute the console test suite using the Embarcadero command prompt or terminal:

```bash
# Compile console tests
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
msbuild test\console\TestSchema2DDLConsole.dproj /p:Config=Release /p:Platform=Win32

# Execute tests
test\console\.bin\TestSchema2DDLConsole.exe
```

A successful run displays a summary showing `OK: 4 tests`.

---

## 3. Running GUI Tests

If you prefer a visual interface:

```bash
# Compile GUI test project
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
msbuild test\gui\TestSchema2DDLGui.dproj /p:Config=Release /p:Platform=Win32

# Execute tests
test\gui\.bin\TestSchema2DDLGui.exe
```

This launches the visual DUnit tree-view panel where you can run individual or all test nodes.
