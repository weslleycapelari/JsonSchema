# Schema2REST

`Schema2REST` is a server-side route and controller generator from JSON Schema definitions for Delphi. It reads a JSON Schema and generates fully functional REST endpoints for **Horse** (middleware router) or **DMVCFramework** (attributes-decorated controller), embedding automatic incoming request payload validation.

## Features

- **Horse & DMVCFramework Support**: Generate complete files matching the architecture of either framework.
- **Embedded Schema Validation**: Integrates directly with `TJsonSchemaValidator` to validate incoming `POST` and `PUT` bodies against the original schema.
- **VCL Desktop GUI**: An interactive design editor to paste schemas, preview generated code, and export Pascal units.
- **Command-Line Interface (CLI)**: A scriptable console program for batch generation.

## Compilation and Running

Compile the tool by opening `Schema2REST.groupproj` in Delphi IDE or compile via MSBuild:

```bash
msbuild Schema2REST.groupproj /p:Config=Release /p:Platform=Win32
```

The output binaries will be placed in the `.bin` folder:

- `Schema2RESTCLI.exe`: Console CLI application.
- `Schema2RESTVCL.exe`: Windows VCL Graphical Application.

## Usage

### Command Line Interface (CLI)

```bash
Schema2RESTCLI.exe -s <schema_path> -f <framework> -e <entity_name> [-o <output_path>]
```

Example:

```bash
Schema2RESTCLI.exe -s C:\schemas\Customer.json -f Horse -e Customer -o C:\src\Customer.Router.pas
```

### DUnit Test Suite

Unit and integration tests are located in the `test/` directory. Run the console test suite:

```bash
cd test\console\.bin
TestSchema2RESTConsole.exe
```
