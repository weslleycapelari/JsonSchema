unit JsonSchema.Validation.Draft7;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Validation.Visitor.Core,
  JsonSchema.Validation.Visitor.Applicator,
  JsonSchema.Validation.Visitor.Validation;

type
  /// <summary>Validation visitor implementing JSON Schema Draft 7 semantics.</summary>
  TDraft7Visitor = class(TValidationVisitor<TDraft7Visitor>)
  public
    /// <summary>Creates and wires all sub-visitors for Draft 7.</summary>
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue = nil);
    /// <summary>Factory method that produces a sibling Draft 7 visitor sharing the same registry.</summary>
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft7Visitor; override;
    /// <summary>Returns the ordered list of keywords that must be visited before others.</summary>
    function KeywordPrecedence: TArray<string>; override;
  end;

  /// <summary>Core visitor interface specific to Draft 7, adding $comment support.</summary>
  IDraft7CoreVisitor = interface(IBaseCoreVisitor<TDraft7Visitor>)
    ['{2F760166-4F1C-4493-966C-2D42C0419A00}']
    procedure VisitComment(const pValue: TJSONString);
  end;

  /// <summary>Applicator visitor interface specific to Draft 7, adding if/then/else support.</summary>
  IDraft7ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft7Visitor>)
    ['{CC689354-8C13-42BD-A0AE-9C408FE5D95D}']
    procedure VisitIf(const pValue: TJSONValue);
    procedure VisitThen(const pValue: TJSONValue);
    procedure VisitElse(const pValue: TJSONValue);
  end;

  /// <summary>Validation visitor interface specific to Draft 7, adding const, contains, propertyNames and dependencies support.</summary>
  IDraft7ValidationVisitor = interface(IBaseValidationVisitor<TDraft7Visitor>)
    ['{D1BBFC58-5212-4322-83D2-CD7B211B3969}']
    procedure VisitConst(const pValue: TJSONValue);
    procedure VisitContains(const pValue: TJSONValue);
    procedure VisitPropertyNames(const pValue: TJSONValue);
    procedure VisitDependencies(const pValue: TJSONObject);
  end;

  /// <summary>Relative JSON Pointer interface specific to Draft 7.</summary>
  IDraft7RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft7Visitor>)
    ['{2DDD2C75-0B7F-4C9A-8D13-A611019E580D}']
  end;

  /// <summary>Concrete core visitor for Draft 7, handling the $comment keyword.</summary>
  TDraft7CoreVisitor = class(TBaseCoreVisitor<TDraft7Visitor>, IDraft7CoreVisitor)
    procedure VisitComment(const pValue: TJSONString);
  end;

  /// <summary>Concrete applicator visitor for Draft 7, handling if/then/else conditional application.</summary>
  TDraft7ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft7Visitor>, IDraft7ApplicatorVisitor)
    [VisitorKeyword('if')]
    procedure VisitIf(const pValue: TJSONValue);
    [VisitorKeyword('then')]
    procedure VisitThen(const pValue: TJSONValue);
    [VisitorKeyword('else')]
    procedure VisitElse(const pValue: TJSONValue);
  end;

  /// <summary>Concrete validation visitor for Draft 7, handling const, contains, propertyNames and dependencies keywords.</summary>
  TDraft7ValidationVisitor = class(TBaseValidationVisitor<TDraft7Visitor>, IDraft7ValidationVisitor)
    [VisitorKeyword('const')]
    procedure VisitConst(const pValue: TJSONValue);
    [VisitorKeyword('contains')]
    procedure VisitContains(const pValue: TJSONValue);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const pValue: TJSONValue);
    [VisitorKeyword('dependencies')]
    procedure VisitDependencies(const pValue: TJSONObject);
  end;

  /// <summary>Concrete relative JSON Pointer visitor for Draft 7.</summary>
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

constructor TDraft7Visitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue);
begin
  inherited Create(pSchema, pData, pBaseURI, pCustomHint);

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

function TDraft7Visitor.New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft7Visitor;
begin
  Result := TDraft7Visitor.Create(pSchema, pData, pBaseURI, FCustomHint);
  Result.FRegistry.Free;
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
end;

{ TDraft7CoreVisitor }

procedure TDraft7CoreVisitor.VisitComment(const pValue: TJSONString);
begin

end;

{ TDraft7ApplicatorVisitor }

procedure TDraft7ApplicatorVisitor.VisitElse(const pValue: TJSONValue);
var
  lScope: TScope;
  lWalker: IWalker;
  lNewScope: TScope;
begin
  lScope := Visitor.CurrentScope;
  if lScope.SchemaNode.FindValue('if') = nil then
    Exit;

  lNewScope := lScope;
  lNewScope.SchemaPath        := Format('%s/else', [lScope.SchemaPath]);
  lNewScope.SchemaNode        := pValue;
  lNewScope.CoveredItems      := [];
  lNewScope.ContainsCount     := 0;
  lNewScope.VisitedKeywords   := [];
  lNewScope.CoveredProperties := [];

  Visitor.PushScope(lNewScope);
  try
    lWalker := TWalker<TDraft7Visitor>.Create(lNewScope.SchemaNode, Visitor);
    lWalker.Walk;
  finally
    Visitor.PopScope;
  end;
end;

procedure TDraft7ApplicatorVisitor.VisitIf(const pValue: TJSONValue);
var
  lScope: TScope;
  lWalker: IWalker;
  lSchema: TJSONValue;
  lSubVisitor: TDraft7Visitor;
  lNewScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  lNewScope := lScope;
  lNewScope.SchemaPath        := Format('%s/if', [lScope.SchemaPath]);
  lNewScope.SchemaNode        := pValue;
  lNewScope.CoveredItems      := [];
  lNewScope.ContainsCount     := 0;
  lNewScope.VisitedKeywords   := [];
  lNewScope.CoveredProperties := [];

  lSubVisitor := Visitor.New(lNewScope.SchemaNode, lNewScope.InstanceNode, lScope.BaseURI);
  lSubVisitor.PushScope(lNewScope);
  try
    lWalker := TWalker<TDraft7Visitor>.Create(lNewScope.SchemaNode, lSubVisitor);
    lWalker.Walk;
  finally
    lNewScope := lSubVisitor.PopScope;
    lScope.CoveredItems      := TUtils.MergeArray<Integer>([lScope.CoveredItems, lNewScope.CoveredItems]);
    lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lNewScope.CoveredProperties]);
  end;

  Visitor.UpdateScope(lScope);

  if lSubVisitor.Result.IsValid and lScope.SchemaNode.TryGetValue('then', lSchema) then
    VisitThen(lSchema)
  else if (not lSubVisitor.Result.IsValid) and lScope.SchemaNode.TryGetValue('else', lSchema) then
    VisitElse(lSchema);

  Visitor
    .AddVisitedKeyword('then')
    .AddVisitedKeyword('else');
end;

procedure TDraft7ApplicatorVisitor.VisitThen(const pValue: TJSONValue);
var
  lScope: TScope;
  lWalker: IWalker;
  lNewScope: TScope;
begin
  lScope := Visitor.CurrentScope;
  if lScope.SchemaNode.FindValue('if') = nil then
    Exit;

  lNewScope := lScope;
  lNewScope.SchemaPath        := Format('%s/then', [lScope.SchemaPath]);
  lNewScope.SchemaNode        := pValue;
  lNewScope.CoveredItems      := [];
  lNewScope.ContainsCount     := 0;
  lNewScope.VisitedKeywords   := [];
  lNewScope.CoveredProperties := [];

  Visitor.PushScope(lNewScope);
  try
    lWalker := TWalker<TDraft7Visitor>.Create(lNewScope.SchemaNode, Visitor);
    lWalker.Walk;
  finally
    Visitor.PopScope;
  end;
end;

{ TDraft7ValidationVisitor }

procedure TDraft7ValidationVisitor.VisitConst(const pValue: TJSONValue);
begin
  inherited VisitConst(pValue);
end;

procedure TDraft7ValidationVisitor.VisitContains(const pValue: TJSONValue);
begin
  inherited VisitContains(pValue);
end;

procedure TDraft7ValidationVisitor.VisitDependencies(const pValue: TJSONObject);
begin
  inherited VisitDependencies(pValue);
end;

procedure TDraft7ValidationVisitor.VisitPropertyNames(const pValue: TJSONValue);
begin
  inherited VisitPropertyNames(pValue);
end;

end.
