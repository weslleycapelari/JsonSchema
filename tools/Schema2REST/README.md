# Schema2REST

`Schema2REST` is a client-generation tool that reads JSON Schemas or OpenAPI descriptions and generates strongly typed REST Client units in Delphi.

## Features

- **Native Delphi Components**: Generates code that uses native Delphi REST components (`TRESTClient`, `TRESTRequest`, `TRESTResponse`) or lightweight `System.Net.HttpClient`.
- **Strong Typing**: Creates classes and methods mapping to API endpoints, accepting and returning strongly typed Delphi DTO structures.
- **Serialization Mapping**: Integrates automatic JSON serialization and deserialization routines.
- **Asynchronous Requests**: Support generating async method overloads utilizing Delphi's Task Library (PPL).
