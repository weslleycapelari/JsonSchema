unit JsonSchema.Walker;

interface

uses
  System.JSON,
  System.Classes,
  System.Generics.Collections,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Walker.Types;

type
  IWalker = interface(IInterface)
    ['{AEC155F6-90DD-479F-AD21-3B26426AF03B}']
    procedure Walk;
  end;

  TWalker<T: IVisitor<T>> = class(TInterfacedPersistent, IWalker)
  private
    FSchema: TJSONValue;
    FVisitor: T;
    FVisitorMethod: TDictionary<string, TVisitorProc>;

    procedure DispatchVisit(const AName: string; const AValue: TJSONValue);
    procedure PopulateVisitorMethods;
  public
    constructor Create(const ASchema: TJSONValue; const AVisitor: T);
    destructor Destroy; override;

    procedure Walk;
    function Visitor: T;
  end;

  TValidationWalker = class
  public
    class function New(const ASchema, AData: TJSONValue; const ACustomHint: TJSONValue = nil): IWalker;
  end;

implementation

uses
  System.Rtti,
  System.SysUtils,
  JsonSchema.Common.Utils,
  JsonSchema.Validation.Draft6,
  JsonSchema.Validation.Draft7,
  JsonSchema.Validation.Draft2019_09,
  JsonSchema.Validation.Draft2020_12;

{ TWalker<T> }

constructor TWalker<T>.Create(const ASchema: TJSONValue; const AVisitor: T);
begin
  FSchema := ASchema;
  FVisitor := AVisitor;
  FVisitorMethod := TDictionary<string, TVisitorProc>.Create;

  PopulateVisitorMethods;
end;

destructor TWalker<T>.Destroy;
begin
  FVisitorMethod.Free;
  inherited;
end;

procedure TWalker<T>.DispatchVisit(const AName: string; const AValue: TJSONValue);
begin
  if not FVisitorMethod.ContainsKey(AName) then
    Exit;

  FVisitorMethod.Items[AName](AValue);
end;

procedure TWalker<T>.PopulateVisitorMethods;
var
  LType: TRttiType;
  LMethod: TRttiMethod;
  LObject: TObject;
  LObjects: TArray<TObject>;
  LContext: TRttiContext;
  LMethodPtr: TMethod;
  LAttribute: TCustomAttribute;
  LParameters: TArray<TRttiParameter>;
begin
  LContext := TRttiContext.Create;
  LObjects := [
    TObject(FVisitor.Core),
    TObject(FVisitor.Applicator),
    TObject(FVisitor.Validation),
    TObject(FVisitor.HyperSchema),
    TObject(FVisitor.RelativeJsonPointer)
  ];

  for LObject in LObjects do
  begin
    LType := LContext.GetType(LObject.ClassType);
    for LMethod in LType.GetMethods do
    begin
      for LAttribute in LMethod.GetAttributes do
      begin
        if not (LAttribute is VisitorKeywordAttribute) then
          Continue;

        if VisitorKeywordAttribute(LAttribute).Name.IsEmpty then
          Continue;

        LParameters := LMethod.GetParameters;

        if Length(LParameters) <> 1 then
          Continue;

        LMethodPtr := default(TMethod);
        LMethodPtr.Code := LMethod.CodeAddress;
        LMethodPtr.Data := LObject;

        FVisitorMethod.AddOrSetValue(VisitorKeywordAttribute(LAttribute).Name, TVisitorProc(LMethodPtr));
      end;
    end;
  end;
end;

function TWalker<T>.Visitor: T;
begin
  Result := FVisitor;
end;

procedure TWalker<T>.Walk;
var
  LPair: TJSONPair;
  LKeyword: string;
  LJsonValue: TJSONValue;
  LPrecedence: TArray<string>;
  LPrecedentKeyword: string;
begin
  if not Assigned(FSchema) then
    Exit;

  if not Assigned(FVisitor) then
    Exit;

  // Se for um schema booleano (true ou false)
  if (FSchema is TJSONBool) then
  begin
    FVisitor.Core.VisitBooleanSchema(TJSONBool(FSchema));
    Exit;
  end;

  if not (FSchema is TJSONObject) then
    Exit;

  if TJSONObject(FSchema).TryGetValue('$ref', LJsonValue) then
  begin
    DispatchVisit('$ref', LJsonValue);
    Exit;
  end;

  LPrecedence := FVisitor.KeywordPrecedence;

  if Length(LPrecedence) > 0 then
  begin
    for LPrecedentKeyword in LPrecedence do
    begin
      if TJSONObject(FSchema).TryGetValue(LPrecedentKeyword, LJsonValue) then
      begin
        if FVisitor.HasVisitedKeyword(LPrecedentKeyword) then
          Continue;

        DispatchVisit(LPrecedentKeyword, LJsonValue);
        FVisitor.AddVisitedKeyword(LPrecedentKeyword);
      end;
    end;
  end;

  for LPair in TJSONObject(FSchema) do
  begin
    LKeyword := LPair.JsonString.Value;

    if FVisitor.HasVisitedKeyword(LKeyword) then
      Continue;

    DispatchVisit(LKeyword, LPair.JsonValue);
  end;
end;

{ TValidationWalker }

class function TValidationWalker.New(const ASchema, AData: TJSONValue; const ACustomHint: TJSONValue): IWalker;
var
  LDraft: TDraftVersion;
  LSchema: string;
  LBaseURI: string;
begin
  ASchema.TryGetValue('$schema', LSchema);
  LDraft := TDraftVersion.FromSchema(LSchema);
  LBaseURI := TUtils.UriGenerateRandom;

  case LDraft of
    dvDraft6:       Result := TWalker<TDraft6Visitor>.Create(ASchema, TDraft6Visitor.Create(ASchema, AData, LBaseURI, ACustomHint));
    dvDraft7:       Result := TWalker<TDraft7Visitor>.Create(ASchema, TDraft7Visitor.Create(ASchema, AData, LBaseURI, ACustomHint));
    dvDraft2019_09: Result := TWalker<TDraft2019_09Visitor>.Create(ASchema, TDraft2019_09Visitor.Create(ASchema, AData, LBaseURI, ACustomHint));
    dvDraft2020_12: Result := TWalker<TDraft2020_12Visitor>.Create(ASchema, TDraft2020_12Visitor.Create(ASchema, AData, LBaseURI, ACustomHint));
  else
    Result := TWalker<TDraft2020_12Visitor>.Create(ASchema, TDraft2020_12Visitor.Create(ASchema, AData, LBaseURI, ACustomHint));
  end;
end;

end.
