unit JsonSchema.Validation.Draft6;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces;

type
  TDraft6Visitor = class(TValidationVisitor<TDraft6Visitor>)
  public
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue = nil);
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft6Visitor; override;
    function KeywordPrecedence: TArray<string>; override;
  end;

  IDraft6CoreVisitor = interface(IBaseCoreVisitor<TDraft6Visitor>)
    ['{7CA24508-A49A-4973-9561-3887FA4C56DE}']
  end;

  IDraft6ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft6Visitor>)
    ['{54925927-57C4-4001-990A-F0525D3BA477}']
  end;

  IDraft6ValidationVisitor = interface(IBaseValidationVisitor<TDraft6Visitor>)
    ['{5D766E26-B0A4-4883-99D6-A35EFDF19459}']
    procedure VisitContains(const AValue: TJSONValue);
    procedure VisitPropertyNames(const AValue: TJSONValue);
    procedure VisitDependencies(const AValue: TJSONObject);
  end;

  IDraft6HyperSchemaVisitor = interface(IBaseHyperSchemaVisitor<TDraft6Visitor>)
    ['{15A0CFBF-864E-4094-9EAF-AB072B3F1900}']
    procedure VisitMedia(const AValue: TJSONObject);
    procedure VisitReadOnly(const AValue: TJSONBool);

    procedure VisitRel(const AValue: TJSONString);
    procedure VisitTitle(const AValue: TJSONString);
    procedure VisitMediaType(const AValue: TJSONString);
    procedure VisitSubmissionEncType(const AValue: TJSONString);
  end;

  IDraft6RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft6Visitor>)
    ['{82C702F1-0A1C-4CE3-8A87-CFA6DAE60437}']
  end;

  TDraft6CoreVisitor = class(TBaseCoreVisitor<TDraft6Visitor>, IDraft6CoreVisitor)
  end;

  TDraft6ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft6Visitor>, IDraft6ApplicatorVisitor)
  end;

  TDraft6ValidationVisitor = class(TBaseValidationVisitor<TDraft6Visitor>, IDraft6ValidationVisitor)
    [VisitorKeyword('contains')]
    procedure VisitContains(const AValue: TJSONValue);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const AValue: TJSONValue);
    [VisitorKeyword('dependencies')]
    procedure VisitDependencies(const AValue: TJSONObject);
  end;

  TDraft6HyperSchemaVisitor = class(TBaseHyperSchemaVisitor<TDraft6Visitor>, IDraft6HyperSchemaVisitor)
    [VisitorKeyword('media')]
    procedure VisitMedia(const AValue: TJSONObject);
    [VisitorKeyword('readOnly')]
    procedure VisitReadOnly(const AValue: TJSONBool);

    [VisitorKeyword('rel')]
    procedure VisitRel(const AValue: TJSONString);
    [VisitorKeyword('title')]
    procedure VisitTitle(const AValue: TJSONString);
    [VisitorKeyword('mediaType')]
    procedure VisitMediaType(const AValue: TJSONString);
    [VisitorKeyword('submissionEncType')]
    procedure VisitSubmissionEncType(const AValue: TJSONString);
  end;

  TDraft6RelativeJsonPointer = class(TBaseRelativeJsonPointer<TDraft6Visitor>, IDraft6RelativeJsonPointer)
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Common.Utils,
  JsonSchema.Translate.Types,
  JsonSchema.Walker;

{ TDraft6Visitor }

constructor TDraft6Visitor.Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue);
begin
  inherited Create(ASchema, AData, ABaseURI, ACustomHint);

  FCore                := TDraft6CoreVisitor.Create(Self);
  FApplicator          := TDraft6ApplicatorVisitor.Create(Self);
  FValidation          := TDraft6ValidationVisitor.Create(Self);
  FHyperSchema         := TDraft6HyperSchemaVisitor.Create(Self);
  FRelativeJsonPointer := TDraft6RelativeJsonPointer.Create(Self);
end;

function TDraft6Visitor.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$id',
    '$ref',
    'properties',
    'patternProperties',
    'additionalProperties',
    'prefixItems',
    'items',
    'contains',
    'additionalItems',
    'if',
    'allOf',
    'anyOf',
    'oneOf'
  ];
end;

function TDraft6Visitor.New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft6Visitor;
begin
  Result := TDraft6Visitor.Create(ASchema, AData, ABaseURI, FCustomHint);
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
end;

{ TDraft6HyperSchemaVisitor }

procedure TDraft6HyperSchemaVisitor.VisitMedia(const AValue: TJSONObject);
begin

end;

procedure TDraft6HyperSchemaVisitor.VisitMediaType(const AValue: TJSONString);
begin

end;

procedure TDraft6HyperSchemaVisitor.VisitReadOnly(const AValue: TJSONBool);
begin

end;

procedure TDraft6HyperSchemaVisitor.VisitRel(const AValue: TJSONString);
begin

end;

procedure TDraft6HyperSchemaVisitor.VisitSubmissionEncType(const AValue: TJSONString);
begin

end;

procedure TDraft6HyperSchemaVisitor.VisitTitle(const AValue: TJSONString);
begin

end;

{ TDraft6ValidationVisitor }

procedure TDraft6ValidationVisitor.VisitContains(const AValue: TJSONValue);
var
  LScope: TScope;
  LCount: Integer;
  LWalker: IWalker;
  LVisitor: TDraft6Visitor;
  LNewScope: TScope;
  LInstance: TJSONArray;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  if AValue is TJSONBool then
  begin
    if TJSONBool(AValue).AsBoolean and (TJSONArray(LScope.InstanceNode).Count > 0) then
      Exit;

    if not TJSONBool(AValue).AsBoolean then
    begin
       Visitor.AddError(vetContains);
       Exit;
    end;
  end;

  LInstance := TJSONArray(LScope.InstanceNode);
  for LCount := 0 to LInstance.Count - 1 do
  begin
    LNewScope := LScope;
    with LNewScope do
    begin
      SchemaPath        := Format('%s/contains', [SchemaPath]);
      SchemaNode        := AValue;
      InstanceNode      := LInstance[LCount];
      InstancePath      := Format('%s/%d', [InstancePath, LCount]);
      CoveredItems      := [];
      ContainsCount     := 0;
      VisitedKeywords   := [];
      CoveredProperties := [];
    end;

    Visitor.PushScope(LNewScope);
    LVisitor := Visitor.New(AValue, LInstance[LCount], LScope.BaseURI);
    try
      LWalker := TWalker<TDraft6Visitor>.Create(AValue, LVisitor);
      LWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if LVisitor.Result.IsValid then
      Inc(LScope.ContainsCount);
  end;

  Visitor.UpdateScope(LScope);
  if LScope.ContainsCount = 0 then
    Visitor.AddError(vetContains);
end;

procedure TDraft6ValidationVisitor.VisitDependencies(const AValue: TJSONObject);
var
  LScope: TScope;
  LInstance: TJSONObject;
  LDependencyPair: TJSONPair;
  LDependencyValue: TJSONValue;
  LRequiredList: TJSONArray;
  LRequiredValue: TJSONValue;
  LRequiredName: string;
  LNewScope: TScope;
  LWalker: IWalker;
  LVisitor: TDraft6Visitor;
  LError: IError;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LInstance := TJSONObject(LScope.InstanceNode);
  for LDependencyPair in AValue do
  begin
    if LInstance.FindValue(LDependencyPair.JsonString.Value) = nil then
      Continue;

    LDependencyValue := LDependencyPair.JsonValue;

    if LDependencyValue is TJSONArray then
    begin
      LRequiredList := TJSONArray(LDependencyValue);
      for LRequiredValue in LRequiredList do
      begin
        if not (LRequiredValue is TJSONString) then
          Continue;

        LRequiredName := TJSONString(LRequiredValue).Value;
        if LInstance.FindValue(LRequiredName) = nil then
          Visitor.AddError(vetDependentRequired, [LDependencyPair.JsonString.Value, LRequiredName]);
      end;
      Continue;
    end;

    if (LDependencyValue is TJSONObject) or (LDependencyValue is TJSONBool) then
    begin
      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath        := Format('%s/dependencies/%s', [LScope.SchemaPath, LDependencyPair.JsonString.Value]);
        SchemaNode        := LDependencyValue;
        InstanceNode      := LScope.InstanceNode;
        InstancePath      := LScope.InstancePath;
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      LVisitor := Visitor.New(LDependencyValue, LScope.InstanceNode, LScope.BaseURI);
      LVisitor.PushScope(LNewScope);
      try
        LWalker := TWalker<TDraft6Visitor>.Create(LDependencyValue, LVisitor);
        LWalker.Walk;
      finally
        LVisitor.PopScope;
      end;

      if not LVisitor.Result.IsValid then
        for LError in LVisitor.Result.Errors do
          Visitor.Result.AddError(LError);
    end;
  end;
end;

procedure TDraft6ValidationVisitor.VisitPropertyNames(const AValue: TJSONValue);
var
  LPair: TJSONPair;
  LScope: TScope;
  LWalker: IWalker;
  LVisitor: TDraft6Visitor;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  for LPair in TJSONObject(LScope.InstanceNode) do
  begin
    LNewScope := LScope;
    with LNewScope do
    begin
      SchemaPath        := Format('%s/propertyNames', [SchemaPath]);
      SchemaNode        := AValue;
      InstanceNode      := LPair.JsonString;
      InstancePath      := Format('%s/%s', [InstancePath, LPair.JsonString.Value]);
      CoveredItems      := [];
      ContainsCount     := 0;
      VisitedKeywords   := [];
      CoveredProperties := [];
    end;

    Visitor.PushScope(LNewScope);
    LVisitor := Visitor.New(LNewScope.SchemaNode, LNewScope.InstanceNode, LScope.BaseURI);
    try
      LWalker := TWalker<TDraft6Visitor>.Create(LNewScope.SchemaNode, LVisitor);
      LWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if not LVisitor.Result.IsValid then
      Visitor.AddError(vetInvalidPropertyName, [LPair.JsonString.Value]);
  end;
end;


end.
