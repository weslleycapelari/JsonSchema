# Delphi2Schema

`Delphi2Schema` is a **Code-to-Schema** tool designed to automatically generate JSON Schema definitions from Delphi source code or runtime type metadata. It enables developers to maintain a single source of truth for their data structures in Delphi and export them as standard JSON Schema contracts.

## Features

- **Runtime RTTI Extraction**: Inspects compiled Delphi classes, records, and enums at runtime using `System.Rtti` to produce corresponding schemas.
- **Static AST Analysis**: Parses Delphi unit files (`.pas`) statically (without compilation) to extract structures.
- **Custom Attributes Integration**: Translates Delphi custom attributes (e.g., `[JSONSchemaRequired]`, `[JSONSchemaPattern('regex')]`, `[JSONSchemaRange(1, 100)]`) directly into JSON Schema validation keywords.
- **Automatic Type Mapping**: Translates Pascal types (`string`, `Integer`, `Double`, `Boolean`, arrays, enums, nested classes) into standard JSON Schema types.

## Installation & Usage

Refer to the project documentation for compiling `Delphi2Schema` as a CLI utility or importing the RTTI extraction unit directly into your Delphi applications.
