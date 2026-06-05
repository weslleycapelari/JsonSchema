# JsonSchema

JsonSchema Delphi is a JSON Schema validation library written in Delphi. It is built around a compiled-schema execution model, a draft-aware parser layer, a central schema registry, and localized validation output.

## What this project does

- Validates JSON documents against JSON Schema documents.
- Supports Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12 at runtime.
- Compiles schemas before validation.
- Keeps keyword behavior isolated in keyword units.
- Produces localized validation messages in enUS and ptBR.
- Resolves references and schema resources through a registry.
- Includes auxiliary developer tools under `tools/`: SchemaMockGen (data mock generator), Schema2Delphi (Delphi DTO class generator), SchemaValidator (JSON Schema validator), Delphi2Schema (JSON Schema generator from Delphi classes/records using RTTI), Schema2DDL (Relational DDL generator), Schema2REST (Horse/DMVC route and controller generator), and JSON2Schema (JSON Schema generator from JSON instance documents). Each tool provides both a Command-Line Interface (CLI) and a Desktop VCL GUI application.

## Confirmed scope

- Runtime confirmed: Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.
- Draft 6 and Draft 7 have strong compliance coverage in the repository history.
- Historical test fixtures for Draft 3, Draft 4, and draft-next are present, but they are not confirmed runtime support.

## Quick start

The main public entry point is `TJsonSchemaValidator`.

1. Parse the schema and instance as `TJSONValue` values.
2. Create `TJsonSchemaValidator`.
3. Call `Validate` with the schema, instance, and optional draft.
4. Inspect `IsValid`, `Errors`, `Message`, and `Resolution`.

## Validation rules

- The validator overload without an explicit draft uses Draft 6.
- The draft-specific overload routes to the selected draft parser.
- Validation occurs against compiled keyword validators, not raw schema JSON.

## Repository layout

- `src`: library source.
- `test`: DUnit projects and schema fixtures.
- `tools`: auxiliary tools.
- `docs`: architecture, product, development, API, decisions, and operations documentation.

## Documentation

- [Documentation index](docs/README.md)
- [Architecture](docs/architecture/ARCHITECTURE.md)
- [Decisions](docs/decisions/README.md)
- [Testing guide](docs/development/TESTING.md)
- [Setup guide](docs/development/SETUP.md)

## Contributing

- Prefer small, focused changes.
- Update or add tests when validation, URI handling, translation, or draft compatibility changes.
- Keep docs in sync with observable runtime behavior.
- Do not describe fixture-only support as runtime support.

## License

MIT. See [LICENSE](LICENSE).
