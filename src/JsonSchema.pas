unit JsonSchema;

interface

uses
  System.JSON,
  JsonSchema.Types,
  JsonSchema.Interfaces,
  JsonSchema.Walker;

type
  /// <summary>
  ///   Main entry point for JSON Schema validation.
  ///   Automatically detects the draft version from the $schema keyword
  ///   or falls back to Draft 2020‑12.
  /// </summary>
  TJsonSchema = class
  public
    /// <summary>
    ///   Validates pData against pSchema and returns the validation result.
    ///   The draft is auto‑detected from the $schema keyword when pDraft is dvUnknown.
    /// </summary>
    /// <param name="pSchema">The JSON Schema document.</param>
    /// <param name="pData">The JSON value to validate.</param>
    /// <param name="pDraft">
    ///   Draft version override; dvUnknown means auto‑detect.
    /// </param>
    /// <param name="pCustomHints">
    ///   Optional JSON object with per‑field custom error hints.
    ///   Structure: { "path/to/field": { "errorType": "custom hint" } }
    /// </param>
    class function Validate(const pSchema, pData: TJSONValue; const pDraft: TDraftVersion = TDraftVersion.dvUnknown;
      const pCustomHints: TJSONValue = nil): IValidationResult; static;
  end;

implementation

uses
  System.SysUtils,
  JsonSchema.Exceptions,
  JsonSchema.Validation.Result,
  JsonSchema.Validation.Draft6,
  JsonSchema.Validation.Draft7,
  JsonSchema.Validation.Draft2019_09,
  JsonSchema.Validation.Draft2020_12,
  JsonSchema.Common.Utils,
  JsonSchema.Registry.Uri;

{ TJsonSchema }

class function TJsonSchema.Validate(const pSchema, pData: TJSONValue; const pDraft: TDraftVersion;
  const pCustomHints: TJSONValue): IValidationResult;
var
  lWalker: IWalker;
  lBaseURI: string;
begin
  if not Assigned(pSchema) then
    raise EJsonSchemaError.Create('Schema cannot be nil');

  if not Assigned(pData) then
    raise EJsonSchemaError.Create('Data cannot be nil');

  lBaseURI := TUtils.UriGenerateRandom;
  lWalker := TValidationWalker.New(pSchema, pData, pCustomHints, pDraft);

  if not Assigned(lWalker) then
    raise EJsonSchemaError.Create('Validation walker could not be created for the selected draft.');

  lWalker.Walk;

  // The walker must expose the validation result.
  // This assumes IWalker has a method GetValidationResult: IValidationResult.
  // In a complete refactoring, that method would be present.
  Result := lWalker.GetValidationResult;
  if not Assigned(Result) then
    raise EJsonSchemaError.Create('Validation finished without producing a validation result.');
end;

end.
