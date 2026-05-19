unit JsonSchema.Validation.Draft6;

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
  /// <summary>Validation visitor implementing JSON Schema Draft 6 semantics.</summary>
  TDraft6Visitor = class(TValidationVisitor<TDraft6Visitor>)
  public
    /// <summary>Creates and wires all sub-visitors for Draft 6.</summary>
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue = nil);
    /// <summary>Factory method that produces a sibling Draft 6 visitor sharing the same registry.</summary>
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft6Visitor; override;
    /// <summary>Returns the ordered list of keywords that must be visited before others.</summary>
    function KeywordPrecedence: TArray<string>; override;
  end;

  /// <summary>Core visitor interface for Draft 6.</summary>
  IDraft6CoreVisitor = interface(IBaseCoreVisitor<TDraft6Visitor>)
    ['{7CA24508-A49A-4973-9561-3887FA4C56DE}']
  end;

  /// <summary>Applicator visitor interface for Draft 6.</summary>
  IDraft6ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft6Visitor>)
    ['{54925927-57C4-4001-990A-F0525D3BA477}']
  end;

  /// <summary>Validation visitor interface for Draft 6, adding contains, propertyNames and dependencies support.</summary>
  IDraft6ValidationVisitor = interface(IBaseValidationVisitor<TDraft6Visitor>)
    ['{5D766E26-B0A4-4883-99D6-A35EFDF19459}']
    procedure VisitContains(const pValue: TJSONValue);
    procedure VisitPropertyNames(const pValue: TJSONValue);
    procedure VisitDependencies(const pValue: TJSONObject);
  end;

  /// <summary>Relative JSON Pointer interface for Draft 6.</summary>
  IDraft6RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft6Visitor>)
    ['{82C702F1-0A1C-4CE3-8A87-CFA6DAE60437}']
  end;

  /// <summary>Concrete core visitor for Draft 6.</summary>
  TDraft6CoreVisitor = class(TBaseCoreVisitor<TDraft6Visitor>, IDraft6CoreVisitor)
  end;

  /// <summary>Concrete applicator visitor for Draft 6.</summary>
  TDraft6ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft6Visitor>, IDraft6ApplicatorVisitor)
  end;

  /// <summary>Concrete validation visitor for Draft 6, handling contains, propertyNames and dependencies keywords.</summary>
  TDraft6ValidationVisitor = class(TBaseValidationVisitor<TDraft6Visitor>, IDraft6ValidationVisitor)
    [VisitorKeyword('contains')]
    procedure VisitContains(const pValue: TJSONValue);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const pValue: TJSONValue);
    [VisitorKeyword('dependencies')]
    procedure VisitDependencies(const pValue: TJSONObject);
  end;

  /// <summary>Concrete relative JSON Pointer visitor for Draft 6.</summary>
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

constructor TDraft6Visitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue);
begin
  inherited Create(pSchema, pData, pBaseURI, pCustomHint);

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

function TDraft6Visitor.New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft6Visitor;
begin
  Result := TDraft6Visitor.Create(pSchema, pData, pBaseURI, FCustomHint);
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
end;

{ TDraft6ValidationVisitor }

procedure TDraft6ValidationVisitor.VisitContains(const pValue: TJSONValue);
begin
  inherited VisitContains(pValue);
end;

procedure TDraft6ValidationVisitor.VisitDependencies(const pValue: TJSONObject);
begin
  inherited VisitDependencies(pValue);
end;

procedure TDraft6ValidationVisitor.VisitPropertyNames(const pValue: TJSONValue);
begin
  inherited VisitPropertyNames(pValue);
end;

end.
