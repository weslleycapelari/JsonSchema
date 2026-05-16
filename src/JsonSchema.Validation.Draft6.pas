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

{ TDraft6ValidationVisitor }

procedure TDraft6ValidationVisitor.VisitContains(const AValue: TJSONValue);
begin
  inherited VisitContains(AValue);
end;

procedure TDraft6ValidationVisitor.VisitDependencies(const AValue: TJSONObject);
begin
  inherited VisitDependencies(AValue);
end;

procedure TDraft6ValidationVisitor.VisitPropertyNames(const AValue: TJSONValue);
begin
  inherited VisitPropertyNames(AValue);
end;


end.
