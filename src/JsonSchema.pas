unit JsonSchema;

interface

uses
  System.JSON,
  JsonSchema.Common.Utils,
  JsonSchema.Translate.enUS,
  JsonSchema.Translate.ptBR,
  JsonSchema.Translate.Utils,
  JsonSchema.Translate.Types,
  JsonSchema.Translate.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Types,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Validation.Draft6,
  JsonSchema.Validation.Draft7,
  JsonSchema.Validation.Draft2019_09,
  JsonSchema.Validation.Draft2020_12,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

type
  TLanguage = JsonSchema.Translate.Types.TLanguage;

  TValidationResult = JsonSchema.Validation.Types.TValidationResult;
  TError            = JsonSchema.Validation.Types.TError;
  IValidationResult = JsonSchema.Validation.Interfaces.IValidationResult;
  IError            = JsonSchema.Validation.Interfaces.IError;

  TDraftVersion       = JsonSchema.Walker.Types.TDraftVersion;
  TDraftVersionHelper = JsonSchema.Walker.Types.TDraftVersionHelper;

  /// <summary>
  /// Main entry point for JSON Schema validation.
  /// Selects the correct draft visitor based on the $schema keyword or explicit parameter.
  /// </summary>
  TJsonSchema = class
  public
    /// <summary>
    /// Validates pData against pSchema and returns the validation result.
    /// The draft is auto-detected from the $schema keyword when pDraft is dvUnknown.
    /// </summary>
    /// <param name="pSchema">The JSON Schema document.</param>
    /// <param name="pData">The JSON value to validate.</param>
    /// <param name="pDraft">Draft version override; dvUnknown means auto-detect.</param>
    /// <param name="pCustomHints">Optional JSON object with per-field custom error hints.</param>
    class function Validate(const pSchema, pData: TJSONValue;
      const pDraft: TDraftVersion = TDraftVersion.dvUnknown;
      const pCustomHints: TJSONValue = nil): IValidationResult; static;
  end;

implementation

uses
  System.SysUtils;

{ TJsonSchema }

class function TJsonSchema.Validate(const pSchema, pData: TJSONValue; const pDraft: TDraftVersion;
  const pCustomHints: TJSONValue): IValidationResult;
var
  lDraft: string;
  lWalker: IWalker;
  lBaseURI: string;
  lDraftVersion: TDraftVersion;
  lVisitorDraft6: TDraft6Visitor;
  lVisitorDraft7: TDraft7Visitor;
  lVisitorDraft2019_09: TDraft2019_09Visitor;
  lVisitorDraft2020_12: TDraft2020_12Visitor;
begin
  lDraft := pDraft.ToSchema;
  if pDraft = TDraftVersion.dvUnknown then
    if not pSchema.TryGetValue('$schema', lDraft) then
      lDraft := TDraftVersion.dvDraft2020_12.ToSchema;

  lDraftVersion := TDraftVersion.FromSchema(lDraft);
  lBaseURI := TUtils.UriGenerateRandom;

  case lDraftVersion of
    dvDraft6:
      begin
        lVisitorDraft6 := TDraft6Visitor.Create(pSchema, pData, lBaseURI, pCustomHints);
        lWalker := TWalker<TDraft6Visitor>.Create(pSchema, lVisitorDraft6);
        lWalker.Walk;
        Result  := lVisitorDraft6.Result;
      end;
    dvDraft7:
      begin
        lVisitorDraft7 := TDraft7Visitor.Create(pSchema, pData, lBaseURI, pCustomHints);
        lWalker := TWalker<TDraft7Visitor>.Create(pSchema, lVisitorDraft7);
        lWalker.Walk;
        Result  := lVisitorDraft7.Result;
      end;
    dvDraft2019_09:
      begin
        lVisitorDraft2019_09 := TDraft2019_09Visitor.Create(pSchema, pData, lBaseURI, pCustomHints);
        lWalker := TWalker<TDraft2019_09Visitor>.Create(pSchema, lVisitorDraft2019_09);
        lWalker.Walk;
        Result  := lVisitorDraft2019_09.Result;
      end;
    dvDraft2020_12:
      begin
        lVisitorDraft2020_12 := TDraft2020_12Visitor.Create(pSchema, pData, lBaseURI, pCustomHints);
        lWalker := TWalker<TDraft2020_12Visitor>.Create(pSchema, lVisitorDraft2020_12);
        lWalker.Walk;
        Result  := lVisitorDraft2020_12.Result;
      end
  else
    raise Exception.Create('Invalid or unsupported JSON Schema draft version.');
  end;
end;

end.
