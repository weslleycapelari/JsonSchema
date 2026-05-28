unit JsonSchema.Visitors.Interfaces;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Types;

type
  IVisitor<T> = interface;
  IBaseCoreVisitor<T> = interface;
  IBaseApplicatorVisitor<T> = interface;
  IBaseValidationVisitor<T> = interface;
  IStringValidationVisitor<T> = interface;
  INumericValidationVisitor<T> = interface;
  IArrayValidationVisitor<T> = interface;
  IObjectValidationVisitor<T> = interface;
  IBaseHyperSchemaVisitor<T> = interface;
  IBaseRelativeJsonPointer<T> = interface;

  /// <summary>
  ///   Base interface that exposes a typed visitor reference, allowing nested
  ///   visitor interfaces to navigate back to their owning visitor instance.
  /// </summary>
  IBase<T> = interface(IInterface)
    ['{BF2C3D3B-B604-4CF9-B705-7FE3D6FE4C15}']
    function Visitor: T;
  end;

  /// <summary>
  ///   Main visitor orchestrator that coordinates keyword traversal, scope
  ///   management, and delegation to category-specific sub-visitors.
  /// </summary>
  IVisitor<T> = interface(IInterface)
    ['{A86BDE88-3D1D-4AA7-BDE6-92949C001B3C}']
    function Core: IBaseCoreVisitor<T>;
    function Applicator: IBaseApplicatorVisitor<T>;
    function ValidationComponents: TArray<IInterface>;
    function HyperSchema: IBaseHyperSchemaVisitor<T>;
    function RelativeJsonPointer: IBaseRelativeJsonPointer<T>;

    function KeywordPrecedence: TArray<string>;
    function PopScope: TScope;
    function PushScope(const pScope: TScope): IVisitor<T>;
    function CurrentScope(const pOffset: Integer = 0): TScope;
    function UpdateScope(const pScope: TScope; const pOffset: Integer = 0): IVisitor<T>;
    function VisitedKeywords: TArray<string>;
    function AddVisitedKeyword(const pKeyword: string): IVisitor<T>;
    function HasVisitedKeyword(const pKeyword: string): Boolean;
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): T;
  end;

  /// <summary>
  ///   Visitor interface for core JSON Schema keywords: $schema, $id, $ref,
  ///   definitions, and boolean schema forms.
  /// </summary>
  IBaseCoreVisitor<T> = interface(IBase<T>)
    ['{FB6620E4-078A-4C11-AD0E-5B8E6E6055D4}']
    procedure VisitSchema(const pValue: TJSONString);
    procedure VisitId(const pValue: TJSONString);
    procedure VisitRef(const pValue: TJSONString);
    procedure VisitDefinitions(const pValue: TJSONObject);
    procedure VisitBooleanSchema(const pValue: TJSONBool);
  end;

  /// <summary>
  ///   Visitor interface for applicator keywords that combine or apply sub-schemas:
  ///   allOf, anyOf, oneOf, not, if/then/else, properties, patternProperties,
  ///   additionalProperties, items, additionalItems, and prefixItems.
  /// </summary>
  IBaseApplicatorVisitor<T> = interface(IBase<T>)
    ['{703DB02C-A44E-4584-8DC8-F3187C9790DB}']
    procedure VisitAllOf(const pValue: TJSONArray);
    procedure VisitAnyOf(const pValue: TJSONArray);
    procedure VisitOneOf(const pValue: TJSONArray);
    procedure VisitNot(const pValue: TJSONValue);
    procedure VisitIf(const pValue: TJSONValue);
    procedure VisitThen(const pValue: TJSONValue);
    procedure VisitElse(const pValue: TJSONValue);
    procedure VisitProperties(const pValue: TJSONObject);
    procedure VisitPatternProperties(const pValue: TJSONObject);
    procedure VisitAdditionalProperties(const pValue: TJSONValue);
    procedure VisitItems(const pValue: TJSONValue);
    procedure VisitAdditionalItems(const pValue: TJSONValue);
    procedure VisitPrefixItems(const pValue: TJSONArray);
  end;

  /// <summary>
  ///   Visitor interface for validation keywords that constrain instance values:
  ///   type, enum, const, numeric bounds, string constraints, array constraints,
  ///   and object constraints.
  /// </summary>
  IBaseValidationVisitor<T> = interface(IBase<T>)
    ['{764D33F4-3B4F-4069-9CFC-2A9D732B0386}']
    procedure VisitType(const pValue: TJSONValue);
    procedure VisitEnum(const pValue: TJSONArray);
    procedure VisitConst(const pValue: TJSONValue);
  end;

  IStringValidationVisitor<T> = interface(IBase<T>)
    ['{12937DB2-6ED4-4286-B9BC-0D0BC4DCE060}']
    procedure VisitMaxLength(const pValue: TJSONNumber);
    procedure VisitMinLength(const pValue: TJSONNumber);
    procedure VisitPattern(const pValue: TJSONString);
    procedure VisitFormat(const pValue: TJSONString);
  end;

  INumericValidationVisitor<T> = interface(IBase<T>)
    ['{153A04DA-A41B-4523-96BE-8647DDAEDDED}']
    procedure VisitMultipleOf(const pValue: TJSONNumber);
    procedure VisitMaximum(const pValue: TJSONNumber);
    procedure VisitExclusiveMaximum(const pValue: TJSONValue);
    procedure VisitMinimum(const pValue: TJSONNumber);
    procedure VisitExclusiveMinimum(const pValue: TJSONValue);
  end;

  IArrayValidationVisitor<T> = interface(IBase<T>)
    ['{F213A31F-72CC-4D2A-BCF1-3180FA2CD40C}']
    procedure VisitMaxItems(const pValue: TJSONNumber);
    procedure VisitMinItems(const pValue: TJSONNumber);
    procedure VisitUniqueItems(const pValue: TJSONBool);
  end;

  IObjectValidationVisitor<T> = interface(IBase<T>)
    ['{A91B4C93-DE46-4B17-A6E5-FC9BD0C9E0EF}']
    procedure VisitMaxProperties(const pValue: TJSONNumber);
    procedure VisitMinProperties(const pValue: TJSONNumber);
    procedure VisitRequired(const pValue: TJSONArray);
    procedure VisitPropertyNames(const pValue: TJSONValue);
    procedure VisitDependencies(const pValue: TJSONObject);
    procedure VisitDependentRequired(const pValue: TJSONObject);
  end;

  /// <summary>
  ///   Visitor interface for JSON Hyper-Schema keywords: base, links, href,
  ///   targetSchema, submissionSchema, and hrefSchema link descriptors.
  /// </summary>
  IBaseHyperSchemaVisitor<T> = interface(IBase<T>)
    ['{94AE6A46-A543-4FD9-B262-E55D9D65F260}']
    procedure VisitBase(const pValue: TJSONString);
    procedure VisitLinks(const pValue: TJSONArray);
    procedure VisitHref(const pValue: TJSONString);
    procedure VisitTargetSchema(const pValue: TJSONValue);
    procedure VisitSubmissionSchema(const pValue: TJSONValue);
    procedure VisitHrefSchema(const pValue: TJSONValue);
  end;

  /// <summary>
  ///   Visitor interface for Relative JSON Pointer keywords, enabling
  ///   pointer-relative navigation within a JSON document.
  /// </summary>
  IBaseRelativeJsonPointer<T> = interface(IBase<T>)
    ['{5FCB391C-EA34-44F8-B46B-05423547C9F6}']
  end;

implementation

end.
