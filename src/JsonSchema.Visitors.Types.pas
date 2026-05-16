unit JsonSchema.Visitors.Types;

interface

uses
  System.JSON,
  System.Classes,
  System.Generics.Collections;

type
  TScope = record
    BaseURI: string;
    SchemaNode: TJSONValue;
    SchemaPath: string;
    InstanceNode: TJSONValue;
    InstancePath: string;
    CoveredItems: TArray<Integer>;
    ContainsCount: Integer;
    VisitedKeywords: TArray<string>;
    CoveredProperties: TArray<string>;
    EvaluatedPropertiesInScope: THashSet<string>;
  end;

  TVisitorProc = procedure(const AValue: TJSONValue) of object;

  VisitorKeywordAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

implementation

{ VisitorKeywordAttribute }

constructor VisitorKeywordAttribute.Create(const AName: string);
begin
  FName := AName;
end;

end.
