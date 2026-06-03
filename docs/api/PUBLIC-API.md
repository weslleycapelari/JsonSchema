# Public API Reference

This document describes the public entry points, interfaces, and usage guides for consuming the **JsonSchema Delphi** library.

---

## 1. Core Architecture Overview

The library operates on a compiled-validation paradigm. The public validator receives a schema, determines its draft version (or uses the requested draft), compiles it into internal keyword validator instances, and validates the target JSON value.

All localized validation errors are aggregated and returned through a single validation result object.

---

## 2. Core Namespaces and Types

To consume the library, you should reference the following units in your uses clause:

- **`JsonSchema.Validator`**: Declares `TJsonSchemaValidator`.
- **`JsonSchema.Core.Interfaces`**: Declares `IValidationResult`, `IValidationError`, and `TDraftVersion`.
- **`JsonSchema.Localization.Enums`**: Declares `TLocale`.

---

## 3. The Public Facade: `TJsonSchemaValidator`

`TJsonSchemaValidator` is the main entry point to validate JSON structures.

### Constructor

```pascal
constructor Create(const pLocale: TLocale = TLocale.EnUS);
```

- Initializes the validator with the target localization mapping.
- Defaults to `TLocale.EnUS`. Supported values include `TLocale.EnUS` and `TLocale.PtBR`.

### Properties

- **`EnforceFormats: Boolean`**: Enables or disables format validation assertions.
  - Defaults to `True`.
  - **Draft 2019-09/2020-12 Compliance**: In Draft 2019-09 and later, the `format` keyword behaves purely as an annotation and does not raise validation errors by default. Setting `EnforceFormats` to `True` overrides this behavior, forcing format rules to act as assertions.

### Validation Methods

```pascal
function Validate(const pSchema, pInstance: TJSONValue): IValidationResult; overload;
```

- Validates the instance against the schema using **Draft 6** by default.

```pascal
function Validate(const pSchema, pInstance: TJSONValue; const pDraft: TDraftVersion): IValidationResult; overload;
```

- Validates the instance against the schema using the specified draft version:
  - `TDraftVersion.dvDraft6`
  - `TDraftVersion.dvDraft7`
  - `TDraftVersion.dvDraft2019_09`
  - `TDraftVersion.dvDraft2020_12`

---

## 4. Validation Result Contracts

### `IValidationResult`

- **`IsValid: Boolean`**: Returns `True` if validation succeeded, `False` otherwise.
- **`Errors: TArray<IValidationError>`**: List of collected validation errors.

### `IValidationError`

- **`Keyword: string`**: The technical name of the keyword that failed (e.g. `type`, `minimum`, `format`).
- **`Message: string`**: Localized description explaining the validation failure.
- **`Resolution: string`**: Localized instructions on how to resolve the validation failure.
- **`SchemaPath: string`**: JSON Pointer indicating the location of the failed keyword inside the schema.
- **`InstancePath: string`**: JSON Pointer indicating the location of the failed value inside the instance JSON.
- **`Context: TJSONObject`**: Raw metadata values associated with the failure (e.g., limit, pattern, actual value).

---

## 5. Usage Example

Here is a complete example of compiling a schema, validating an instance, and inspecting localized errors in Portuguese:

```pascal
program JsonSchemaValidationDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  JsonSchema.Validator,
  JsonSchema.Core.Interfaces,
  JsonSchema.Localization.Enums;

procedure RunValidation;
var
  lValidator: TJsonSchemaValidator;
  lSchema: TJSONObject;
  lInstance: TJSONObject;
  lResult: IValidationResult;
  lError: IValidationError;
begin
  // Set up the validator to output messages in Portuguese
  lValidator := TJsonSchemaValidator.Create(TLocale.PtBR);
  try
    // Define a JSON Schema
    lSchema := TJSONObject.ParseJSONValue(
      '{' +
      '  "type": "object",' +
      '  "properties": {' +
      '    "age": { "type": "integer", "minimum": 18 },' +
      '    "email": { "type": "string", "format": "email" }' +
      '  },' +
      '  "required": ["age", "email"]' +
      '}'
    ) as TJSONObject;

    // Define a JSON Instance that violates validation rules
    lInstance := TJSONObject.ParseJSONValue(
      '{' +
      '  "age": 16,' +              // Too young (minimum 18)
      '  "email": "invalid-email"'  // Not a valid email pattern
      '}'
    ) as TJSONObject;

    try
      // Validate the instance using Draft 7
      lResult := lValidator.Validate(lSchema, lInstance, TDraftVersion.dvDraft7);

      if lResult.IsValid then
      begin
        WriteLn('JSON is valid!');
      end
      else
      begin
        WriteLn('Validation failed with the following errors:');
        for lError in lResult.Errors do
        begin
          WriteLn(Format('Keyword: %s', [lError.Keyword]));
          WriteLn(Format('Path: %s', [lError.InstancePath]));
          WriteLn(Format('Message: %s', [lError.Message]));
          WriteLn(Format('Resolution: %s', [lError.Resolution]));
          WriteLn('----------------------------------------');
        end;
      end;
    finally
      lSchema.Free;
      lInstance.Free;
    end;
  finally
    lValidator.Free;
  end;
end;

begin
  try
    RunValidation;
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
```
