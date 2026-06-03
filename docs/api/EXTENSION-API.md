# Extension API Reference

This document describes the extension points provided by the **JsonSchema Delphi** library to register custom validation keywords and custom semantic formats.

---

## 1. Custom Keywords Extension

To add a new schema keyword validation, you must:

1. Implement the `IJsonSchemaKeyword` interface.
2. Provide a static factory function matching `TKeywordFactoryFunc`.
3. Register the keyword inside the target `TKeywordRegistry` of the corresponding draft parser.

### Core Interface: `IJsonSchemaKeyword`

```pascal
type
  IJsonSchemaKeyword = interface
    ['{F40608DE-4395-46D0-B0F7-832F6E3B9F2A}']
    function GetKeywordName: string;
    function Validate(const pInstance: TJSONValue): IValidationResult;
    property KeywordName: string read GetKeywordName;
  end;
```

### Factory Function Signature

```pascal
type
  TKeywordFactoryFunc = reference to function(
    const pKeywordValue: TJSONValue;
    const pParentSchema: TJSONObject;
    const pCompileFunc: TCompileSchemaFunc
  ): IJsonSchemaKeyword;
```

### Example: Custom `x-even` Keyword

This keyword checks if a numeric value is an even number.

```pascal
unit JsonSchema.Keywords.Even;

interface

uses
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  TXEvenKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FEnabled: Boolean;
    function GetKeywordName: string;
  public
    constructor Create(const pEnabled: Boolean);
    function Validate(const pInstance: TJSONValue): IValidationResult;

    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;
  end;

implementation

constructor TXEvenKeyword.Create(const pEnabled: Boolean);
begin
  inherited Create;
  FEnabled := pEnabled;
end;

function TXEvenKeyword.GetKeywordName: string;
begin
  Result := 'x-even';
end;

function TXEvenKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lValue: Int64;
  lContext: TJSONObject;
begin
  // Only apply even validations to integer instances
  if not (pInstance is TJSONNumber) then
    Exit(TValidationResult.ValidResult);

  if not FEnabled then
    Exit(TValidationResult.ValidResult);

  lValue := TJSONNumber(pInstance).AsInt64;
  if (lValue mod 2) = 0 then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('actual', TJSONNumber.Create(lValue));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

class function TXEvenKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONBool) then
    Result := TXEvenKeyword.Create(TJSONBool(pKeywordValue).AsBoolean)
  else
    Result := TXEvenKeyword.Create(False);
end;

end.
```

### Registering the Custom Keyword in the Parser

To enable the parser to resolve `x-even`, register it in the parser registry:

```pascal
uses
  JsonSchema.Draft7.Parser,
  JsonSchema.Keywords.Even;

// Register the keyword inside Draft 7 validation keyword pool
TDraft7Parser.Registry.RegisterKeyword('x-even', TXEvenKeyword.CreateKeyword);
```

---

## 2. Custom Formats Extension

Custom semantic string formats can be registered globally. Custom format names are not constrained by standard draft rules; they are validated across all draft compilations by default.

### Registering Custom Formats via `TFormatRegistry`

Use the `TFormatRegistry.RegisterFormat` class method to register your validation logic:

```pascal
uses
  System.SysUtils,
  JsonSchema.Keywords.Format;

initialization
  // Register a validator for credit cards matching standard formats
  TFormatRegistry.RegisterFormat('credit-card',
    function(const pValue: string): Boolean
    begin
      // Basic credit card validation logic (e.g. Luhn algorithm check)
      Result := (pValue.Length = 16) and TRegEx.IsMatch(pValue, '^[0-9]+$');
    end);
```

### Adding regular expression formats

If your validation consists of a simple regular expression pattern, you can use the `RegisterRegexFormat` utility to register it in one line:

```pascal
uses
  JsonSchema.Keywords.Format;

initialization
  TFormatRegistry.RegisterRegexFormat('brazilian-cep', '^[0-9]{5}-[0-9]{3}$');
```
