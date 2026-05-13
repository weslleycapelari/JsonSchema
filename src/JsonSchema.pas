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

  TJsonSchema = class
  public
    class function Validate(const ASchema, AData: TJSONValue;
      const ADraft: TDraftVersion = TDraftVersion.dvUnknown; const ACustomHints: TJSONValue = nil): IValidationResult; static;
  end;

implementation

uses
  System.SysUtils;

{ TJsonSchema }

class function TJsonSchema.Validate(const ASchema, AData: TJSONValue; const ADraft: TDraftVersion;
  const ACustomHints: TJSONValue): IValidationResult;
var
  LDraft: string;
  LWalker: IWalker;
  LBaseURI: string;
  LDraftVersion: TDraftVersion;
  LVisitorDraft6: TDraft6Visitor;
  LVisitorDraft7: TDraft7Visitor;
  LVisitorDraft2019_09: TDraft2019_09Visitor;
  LVisitorDraft2020_12: TDraft2020_12Visitor;
begin
  LDraft := ADraft.ToSchema;
  if ADraft = TDraftVersion.dvUnknown then
    if not ASchema.TryGetValue('$schema', LDraft) then
      LDraft := TDraftVersion.dvDraft2020_12.ToSchema;

  LDraftVersion := TDraftVersion.FromSchema(LDraft);
  LBaseURI := TUtils.UriGenerateRandom;

  case LDraftVersion of
    dvDraft6:
      begin
        LVisitorDraft6 := TDraft6Visitor.Create(ASchema, AData, LBaseURI, ACustomHints);
        LWalker := TWalker<TDraft6Visitor>.Create(ASchema, LVisitorDraft6);
        LWalker.Walk;
        Result  := LVisitorDraft6.Result;
      end;
    dvDraft7:
      begin
        LVisitorDraft7 := TDraft7Visitor.Create(ASchema, AData, LBaseURI, ACustomHints);
        LWalker := TWalker<TDraft7Visitor>.Create(ASchema, LVisitorDraft7);
        LWalker.Walk;
        Result  := LVisitorDraft7.Result;
      end;
    dvDraft2019_09:
      begin
        LVisitorDraft2019_09 := TDraft2019_09Visitor.Create(ASchema, AData, LBaseURI, ACustomHints);
        LWalker := TWalker<TDraft2019_09Visitor>.Create(ASchema, LVisitorDraft2019_09);
        LWalker.Walk;
        Result  := LVisitorDraft2019_09.Result;
      end;
    dvDraft2020_12:
      begin
        LVisitorDraft2020_12 := TDraft2020_12Visitor.Create(ASchema, AData, LBaseURI, ACustomHints);
        LWalker := TWalker<TDraft2020_12Visitor>.Create(ASchema, LVisitorDraft2020_12);
        LWalker.Walk;
        Result  := LVisitorDraft2020_12.Result;
      end
  else
    raise Exception.Create('Error in schema draft version selection');
  end;
end;

end.

