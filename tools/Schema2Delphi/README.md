# Schema2Delphi

`Schema2Delphi` is a code-generation utility designed to compile JSON Schema definitions and automatically output strongly typed Delphi (`.pas`) class or record declarations. This bridges the gap between web APIs (contracted via JSON Schema) and Delphi client/server applications.

## Features

- **Object-Oriented Generation**: Translates JSON Schema object structures into fully formed Delphi classes complete with property getters, setters, and backing fields.
- **Support for Nested Schemas**: Recursively parses embedded schemas, generating child classes and associations.
- **Array & Collection Parsing**: Maps JSON Schema arrays to Delphi `TArray<T>` or `TObjectList<T>` structures.
- **Batch Processing**: Supports batch conversion (`Schema2Delphi.Lote`), allowing compilation of multiple schema files from a folder in a single execution.
- **Serialization Friendly**: Generates code compatible with Delphi standard JSON serialization attributes (e.g. `[MVCObject]`, `REST.Json`).

## Usage

Compile and run `Schema2Delphi.dpr` (RAD Studio project) to use the graphical GUI tool or call the compiler routines programmatically.
