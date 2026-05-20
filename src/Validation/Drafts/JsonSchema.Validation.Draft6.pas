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

implementation

{ TDraft6Visitor }

constructor TDraft6Visitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
  const pCustomHint: TJSONValue);
begin
  inherited Create(pSchema, pData, pBaseURI, pCustomHint);

  FCore := TBaseCoreVisitor<TDraft6Visitor>.Create(Self);
  FApplicator := TBaseApplicatorVisitor<TDraft6Visitor>.Create(Self);
  FValidation := TBaseValidationVisitor<TDraft6Visitor>.Create(Self);
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

end.
