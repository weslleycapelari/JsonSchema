unit JsonSchema.Validation.Draft6;

interface

uses
  System.JSON,
  JsonSchema.Types,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitor.Core.Base,
  JsonSchema.Visitor.Applicator.Base,
  JsonSchema.Visitor.Validation.Base,
  JsonSchema.Visitor.Validation.&String,
  JsonSchema.Visitor.Validation.Numeric,
  JsonSchema.Visitor.Validation.&Array,
  JsonSchema.Visitor.Validation.&Object,
  JsonSchema.Visitor.RelativePointer.Stub,
  JsonSchema.Visitor.HyperSchema.Stub,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces;

type
  /// <summary>Main validation visitor implementing JSON Schema Draft 6 semantics.</summary>
  TDraft6Visitor = class(TValidationVisitor<TDraft6Visitor>)
  public
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
      const pCustomHint: TJSONValue = nil);
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft6Visitor; override;
    function KeywordPrecedence: TArray<string>; override;
  end;

  /// <summary>Core visitor for Draft 6 – adds full $ref resolution with cross‑draft support.</summary>
  TDraft6CoreVisitor = class(TBaseCoreVisitor<TDraft6Visitor>)
  public
    procedure VisitRef(const pValue: TJSONString); override;
  end;

  TDraft6ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft6Visitor>)
  public
    procedure VisitAllOf(const pValue: TJSONArray); override;
    procedure VisitAnyOf(const pValue: TJSONArray); override;
    procedure VisitOneOf(const pValue: TJSONArray); override;
    procedure VisitNot(const pValue: TJSONValue); override;
    procedure VisitProperties(const pValue: TJSONObject); override;
    procedure VisitPatternProperties(const pValue: TJSONObject); override;
    procedure VisitAdditionalProperties(const pValue: TJSONValue); override;
    procedure VisitItems(const pValue: TJSONValue); override;
    procedure VisitAdditionalItems(const pValue: TJSONValue); override;
    // if/then/else não existem no Draft 6 – não sobrescrevemos (herdam no‑op)
  end;

  TDraft6ValidationVisitor = class(TBaseValidationVisitor<TDraft6Visitor>)
  public
    procedure VisitContains(const pValue: TJSONValue);
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Math;

{ TDraft6Visitor }

constructor TDraft6Visitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
  const pCustomHint: TJSONValue);
begin
  inherited Create(pSchema, pData, pBaseURI, pCustomHint);

  FCore := TDraft6CoreVisitor.Create(Self);
  FApplicator := TDraft6ApplicatorVisitor.Create(Self);
  
  SetLength(FValidationComponents, 5);
  FValidationComponents[0] := TDraft6ValidationVisitor.Create(Self);
  FValidationComponents[1] := TStringValidationVisitor<TDraft6Visitor>.Create(Self);
  FValidationComponents[2] := TNumericValidationVisitor<TDraft6Visitor>.Create(Self);
  FValidationComponents[3] := TArrayValidationVisitor<TDraft6Visitor>.Create(Self);
  FValidationComponents[4] := TObjectValidationVisitor<TDraft6Visitor>.Create(Self);

  FHyperSchema := TStubHyperSchemaVisitor<TDraft6Visitor>.Create(Self);
  FRelativeJsonPointer := TStubRelativeJsonPointer<TDraft6Visitor>.Create(Self);
end;

function TDraft6Visitor.New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft6Visitor;
begin
  Result := TDraft6Visitor.Create(pSchema, pData, pBaseURI, FCustomHint);
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
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
    'items',
    'additionalItems',
    'contains',
    'allOf',
    'anyOf',
    'oneOf',
    'not'
  ];
end;

{ TDraft6CoreVisitor }

procedure TDraft6CoreVisitor.VisitRef(const pValue: TJSONString);
begin
  inherited;

end;

{ TDraft6ApplicatorVisitor }

procedure TDraft6ApplicatorVisitor.VisitAdditionalItems(const pValue: TJSONValue);
begin
  inherited;

end;

procedure TDraft6ApplicatorVisitor.VisitAdditionalProperties(const pValue: TJSONValue);
begin
  inherited;

end;

procedure TDraft6ApplicatorVisitor.VisitAllOf(const pValue: TJSONArray);
begin
  inherited;

end;

procedure TDraft6ApplicatorVisitor.VisitAnyOf(const pValue: TJSONArray);
begin
  inherited;

end;

procedure TDraft6ApplicatorVisitor.VisitItems(const pValue: TJSONValue);
begin
  inherited;

end;

procedure TDraft6ApplicatorVisitor.VisitNot(const pValue: TJSONValue);
begin
  inherited;

end;

procedure TDraft6ApplicatorVisitor.VisitOneOf(const pValue: TJSONArray);
begin
  inherited;

end;

procedure TDraft6ApplicatorVisitor.VisitPatternProperties(const pValue: TJSONObject);
begin
  inherited;

end;

procedure TDraft6ApplicatorVisitor.VisitProperties(const pValue: TJSONObject);
begin
  inherited;

end;

{ TDraft6ValidationVisitor }

procedure TDraft6ValidationVisitor.VisitContains(const pValue: TJSONValue);
begin
  inherited;

end;

end.
