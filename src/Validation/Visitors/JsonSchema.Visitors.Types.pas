unit JsonSchema.Visitors.Types;

interface

uses
  System.JSON,
  System.Generics.Collections;

type
  /// <summary>
  ///   Holds the full traversal context for a single step in the schema walk.
  ///   Copied by value onto the scope stack, so each recursive call gets its own snapshot.
  /// </summary>
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

  /// <summary>
  ///   Procedure type dispatched by the walker when a keyword is encountered.
  ///   The pValue argument is the JSON value associated with the keyword.
  /// </summary>
  TVisitorProc = procedure(const pValue: TJSONValue) of object;

  /// <summary>
  ///   Marks a visitor method as the handler for one or more JSON Schema keywords.
  ///   The walker discovers these via RTTI and populates its dispatch table at construction time.
  /// </summary>
  VisitorKeywordAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const pName: string);
    property Name: string read FName;
  end;

implementation

{ VisitorKeywordAttribute }

constructor VisitorKeywordAttribute.Create(const pName: string);
begin
  FName := pName;
end;

end.
