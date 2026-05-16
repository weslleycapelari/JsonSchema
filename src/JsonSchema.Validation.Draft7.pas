unit JsonSchema.Validation.Draft7;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces;

type
  TDraft7Visitor = class(TValidationVisitor<TDraft7Visitor>)
  public
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue = nil);
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft7Visitor; override;
    function KeywordPrecedence: TArray<string>; override;
  end;

  IDraft7CoreVisitor = interface(IBaseCoreVisitor<TDraft7Visitor>)
    ['{2F760166-4F1C-4493-966C-2D42C0419A00}']
    procedure VisitComment(const AValue: TJSONString);
  end;

  IDraft7ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft7Visitor>)
    ['{CC689354-8C13-42BD-A0AE-9C408FE5D95D}']
    procedure VisitIf(const AValue: TJSONValue);
    procedure VisitThen(const AValue: TJSONValue);
    procedure VisitElse(const AValue: TJSONValue);
  end;

  IDraft7ValidationVisitor = interface(IBaseValidationVisitor<TDraft7Visitor>)
    ['{D1BBFC58-5212-4322-83D2-CD7B211B3969}']
    procedure VisitConst(const AValue: TJSONValue);
    procedure VisitContains(const AValue: TJSONValue);
    procedure VisitPropertyNames(const AValue: TJSONValue);
    procedure VisitDependencies(const AValue: TJSONObject);
  end;

  IDraft7RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft7Visitor>)
    ['{2DDD2C75-0B7F-4C9A-8D13-A611019E580D}']
  end;

  TDraft7CoreVisitor = class(TBaseCoreVisitor<TDraft7Visitor>, IDraft7CoreVisitor)
    procedure VisitComment(const AValue: TJSONString);
  end;

  TDraft7ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft7Visitor>, IDraft7ApplicatorVisitor)
    [VisitorKeyword('if')]
    procedure VisitIf(const AValue: TJSONValue);
    [VisitorKeyword('then')]
    procedure VisitThen(const AValue: TJSONValue);
    [VisitorKeyword('else')]
    procedure VisitElse(const AValue: TJSONValue);
  end;

  TDraft7ValidationVisitor = class(TBaseValidationVisitor<TDraft7Visitor>, IDraft7ValidationVisitor)
    [VisitorKeyword('const')]
    procedure VisitConst(const AValue: TJSONValue);
    [VisitorKeyword('contains')]
    procedure VisitContains(const AValue: TJSONValue);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const AValue: TJSONValue);
    [VisitorKeyword('dependencies')]
    procedure VisitDependencies(const AValue: TJSONObject);
  end;

  TDraft7RelativeJsonPointer = class(TBaseRelativeJsonPointer<TDraft7Visitor>, IDraft7RelativeJsonPointer)
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Common.Utils,
  JsonSchema.Translate.Types,
  JsonSchema.Walker;

{ TDraft7Visitor }

constructor TDraft7Visitor.Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue);
begin
  inherited Create(ASchema, AData, ABaseURI, ACustomHint);

  FCore                := TDraft7CoreVisitor.Create(Self);
  FApplicator          := TDraft7ApplicatorVisitor.Create(Self);
  FValidation          := TDraft7ValidationVisitor.Create(Self);
  FRelativeJsonPointer := TDraft7RelativeJsonPointer.Create(Self);
end;

function TDraft7Visitor.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$id',
    'id',
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

function TDraft7Visitor.New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft7Visitor;
begin
  Result := TDraft7Visitor.Create(ASchema, AData, ABaseURI, FCustomHint);
  Result.FRegistry.Free;
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
end;

{ TDraft7CoreVisitor }

procedure TDraft7CoreVisitor.VisitComment(const AValue: TJSONString);
begin

end;

{ TDraft7ApplicatorVisitor }

procedure TDraft7ApplicatorVisitor.VisitElse(const AValue: TJSONValue);
var
  LScope: TScope;
  LWalker: IWalker;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  if LScope.SchemaNode.FindValue('if') = nil then
    Exit;

  LNewScope := LScope;
  LNewScope.SchemaPath        := Format('%s/else', [LScope.SchemaPath]);
  LNewScope.SchemaNode        := AValue;
  LNewScope.CoveredItems      := [];
  LNewScope.ContainsCount     := 0;
  LNewScope.VisitedKeywords   := [];
  LNewScope.CoveredProperties := [];

  Visitor.PushScope(LNewScope);
  try
    LWalker := TWalker<TDraft7Visitor>.Create(LNewScope.SchemaNode, Visitor);
    LWalker.Walk;
  finally
    Visitor.PopScope;
  end;
end;

procedure TDraft7ApplicatorVisitor.VisitIf(const AValue: TJSONValue);
var
  LScope: TScope;
  LWalker: IWalker;
  LSchema: TJSONValue;
  LSubVisitor: TDraft7Visitor;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  LNewScope := LScope;
  LNewScope.SchemaPath        := Format('%s/if', [LScope.SchemaPath]);
  LNewScope.SchemaNode        := AValue;
  LNewScope.CoveredItems      := [];
  LNewScope.ContainsCount     := 0;
  LNewScope.VisitedKeywords   := [];
  LNewScope.CoveredProperties := [];

  LSubVisitor := Visitor.New(LNewScope.SchemaNode, LNewScope.InstanceNode, LScope.BaseURI);
  LSubVisitor.PushScope(LNewScope);
  try
    LWalker := TWalker<TDraft7Visitor>.Create(LNewScope.SchemaNode, LSubVisitor);
    LWalker.Walk;
  finally
    LNewScope := LSubVisitor.PopScope;
    LScope.CoveredItems      := TUtils.MergeArray<Integer>([LScope.CoveredItems, LNewScope.CoveredItems]);
    LScope.CoveredProperties := TUtils.MergeArray<string>([LScope.CoveredProperties, LNewScope.CoveredProperties]);
  end;

  Visitor.UpdateScope(LScope);

  if LSubVisitor.Result.IsValid and LScope.SchemaNode.TryGetValue('then', LSchema) then
    VisitThen(LSchema)
  else if (not LSubVisitor.Result.IsValid) and LScope.SchemaNode.TryGetValue('else', LSchema) then
    VisitElse(LSchema);

  Visitor
    .AddVisitedKeyword('then')
    .AddVisitedKeyword('else');
end;

procedure TDraft7ApplicatorVisitor.VisitThen(const AValue: TJSONValue);
var
  LScope: TScope;
  LWalker: IWalker;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  if LScope.SchemaNode.FindValue('if') = nil then
    Exit;

  LNewScope := LScope;
  LNewScope.SchemaPath        := Format('%s/then', [LScope.SchemaPath]);
  LNewScope.SchemaNode        := AValue;
  LNewScope.CoveredItems      := [];
  LNewScope.ContainsCount     := 0;
  LNewScope.VisitedKeywords   := [];
  LNewScope.CoveredProperties := [];

  Visitor.PushScope(LNewScope);
  try
    LWalker := TWalker<TDraft7Visitor>.Create(LNewScope.SchemaNode, Visitor);
    LWalker.Walk;
  finally
    Visitor.PopScope;
  end;
end;

{ TDraft7ValidationVisitor }

procedure TDraft7ValidationVisitor.VisitConst(const AValue: TJSONValue);
begin
  inherited VisitConst(AValue);
end;

procedure TDraft7ValidationVisitor.VisitContains(const AValue: TJSONValue);
begin
  inherited VisitContains(AValue);
end;

procedure TDraft7ValidationVisitor.VisitDependencies(const AValue: TJSONObject);
begin
  inherited VisitDependencies(AValue);
end;

procedure TDraft7ValidationVisitor.VisitPropertyNames(const AValue: TJSONValue);
begin
  inherited VisitPropertyNames(AValue);
end;

end.

