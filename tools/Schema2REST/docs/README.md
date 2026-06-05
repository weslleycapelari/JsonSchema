# Schema2REST - Documentation

`Schema2REST` is a server-side route and controller generator from JSON Schema definitions. It is designed to read a JSON Schema file and generate a fully-featured, ready-to-run Delphi REST Router (for Horse) or Controller (for DMVCFramework) unit that automatically validates incoming request payloads.

## Features

- **Horse Router Generation**: Produces Horse route registration procedures with local middleware that parses the request body and runs `TJsonSchemaValidator`.
- **DMVCFramework Controller Generation**: Produces controller classes subclassing `TMVCController` decorated with `[MVCPath]` and `[MVCProduces]`, including inline payload verification.
- **Embedded Schema**: The target JSON schema is embedded as a string constant within the generated unit, ensuring the endpoint remains self-contained and easy to deploy.
- **VCL Graphical Interface & CLI**: Supports both an interactive desktop application and a batch-run command-line utility.

## Command-Line Arguments

The CLI utility support the following arguments:

```bash
Schema2RESTCLI.exe -s <schema_path> [-f <framework>] [-o <output_path>] [-e <entity_name>]
```

Options:

- `-s, --schema`: Path to the input JSON Schema file.
- `-f, --framework`: Target framework. Supports `Horse` (default) or `DMVC`.
- `-o, --output`: Path to write the generated `.pas` file. If omitted, prints output to stdout.
- `-e, --entity`: Entity name (used for unit naming, class naming, and endpoint path prefixing).
- `-h, --help`: Displays help messages.

## Code Generation Output

### Horse Example

The generated Horse Router defines:

- A local `ValidatePayload` middleware.
- Route actions: `GetEntities`, `GetEntity`, `CreateEntity`, `UpdateEntity`, `DeleteEntity`.
- A route registration procedure `Registry[EntityName]Routes` mapping methods to the endpoints with the payload validation middleware registered on `POST` and `PUT`.

### DMVCFramework Example

The generated DMVCFramework Controller defines:

- A controller class subclassing `TMVCController`.
- Attribute-mapped actions (e.g. `[MVCPath]`, `[MVCHTTPMethod]`).
- Inline `ValidatePayload` calls on write operations that return `HTTP 400 Bad Request` with the array of validation errors upon failure.
