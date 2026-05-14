# JsonSchema

Delphi library for JSON Schema validation with confirmed runtime support for Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.

## What this project does

- Validates JSON documents against JSON Schema documents.
- Selects the draft from `$schema` or from an explicit draft passed by the caller.
- Runs validation through walkers, visitors, and a resource registry.
- Exposes validation messages in enUS and ptBR.
- Includes URI helpers and the Schema2Delphi helper tool in `tools/`.

## Confirmed scope

- Runtime confirmed: Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.
- Draft 6: 100% Compliant (1151/1151 tests passed).
- Draft 7: 100% Compliant (1467/1467 tests passed).
- Historical test fixtures: Draft 3, Draft 4, and draft-next appear in the test fixtures, but they are not confirmed runtime support.

## Quick start and validation

The public entry point is `TJsonSchema.Validate`. Pass a schema and an input JSON value, then inspect the result.

1. Parse the schema and the data as `TJSONValue` values.
2. Call `TJsonSchema.Validate`.
3. Check `IsValid` and, if needed, inspect `Errors`.

```pascal
uses
  System.JSON,
  JsonSchema;

var
  Schema: TJSONValue;
  Data: TJSONValue;
  Result: IValidationResult;
begin
  Schema := TJSONObject.ParseJSONValue('{"type":"object"}');
  Data := TJSONObject.ParseJSONValue('{"name":"Ada"}');
  try
    Result := TJsonSchema.Validate(Schema, Data);

    if Result.IsValid then
      Exit;

    for var Error in Result.Errors do
      Writeln(Error.ErrorMessage);
  finally
    Schema.Free;
    Data.Free;
  end;
end;
```

Validation draft selection follows these rules:

- An explicit draft parameter takes precedence.
- If no draft is passed and the schema does not declare `$schema`, validation falls back to Draft 2020-12.
- If the schema declares `$schema`, that value drives draft selection.

If you are validating a draft-specific change, update or add a draft-specific test before opening a PR. The DUnit GUI project lives in [test/gui/TestJsonSchema.dproj](test/gui/TestJsonSchema.dproj).

## Repository layout

- `src`: core library.
- `test`: DUnit project and schema fixtures.
- `tools`: auxiliary tools, including Schema2Delphi.
- `docs`: architecture and draft support documentation.

## Testing documentation

- [Testing Guide](docs/testing.md): test harness architecture, CLI options, progress/failure output, report formats, and examples.

## How to contribute

- Open an issue before larger changes.
- Prefer small, focused pull requests.
- Add or adjust tests when you change validation, URI handling, translation, or draft compatibility.
- Update public documentation when the contract changes.
- Do not promise support for drafts that exist only in fixtures.

## License

MIT. See [LICENSE](LICENSE).
