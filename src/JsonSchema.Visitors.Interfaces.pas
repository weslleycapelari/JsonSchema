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
  IBaseHyperSchemaVisitor<T> = interface;
  IBaseRelativeJsonPointer<T> = interface;

  /// <summary>
  /// Base interface that exposes a typed visitor reference, allowing nested
  /// visitor interfaces to navigate back to their owning visitor instance.
  /// </summary>
  IBase<T> = interface(IInterface)
    ['{BF2C3D3B-B604-4CF9-B705-7FE3D6FE4C15}']
    function Visitor: T;
  end;

  /// <summary>
  /// Main visitor orchestrator that coordinates keyword traversal, scope
  /// management, and delegation to category-specific sub-visitors (Core,
  /// Applicator, Validation, HyperSchema, RelativeJsonPointer).
  /// </summary>
  IVisitor<T> = interface(IInterface)
    ['{A86BDE88-3D1D-4AA7-BDE6-92949C001B3C}']
    function Core: IBaseCoreVisitor<T>;
    function Applicator: IBaseApplicatorVisitor<T>;
    function Validation: IBaseValidationVisitor<T>;
    function HyperSchema: IBaseHyperSchemaVisitor<T>;
    function RelativeJsonPointer: IBaseRelativeJsonPointer<T>;

    function KeywordPrecedence: TArray<string>;
    /// <summary>
    /// Removes and returns the top scope from the scope stack.
    /// </summary>
    function PopScope: TScope;
    /// <summary>
    /// Pushes a new scope onto the scope stack and returns the visitor for fluent chaining.
    /// </summary>
    function PushScope(const pScope: TScope): IVisitor<T>;
    /// <summary>
    /// Returns the scope at the given offset from the top of the scope stack.
    /// </summary>
    function CurrentScope(const pOffset: Integer = 0): TScope;
    /// <summary>
    /// Replaces the scope at the given offset from the top of the scope stack
    /// and returns the visitor for fluent chaining.
    /// </summary>
    function UpdateScope(const pScope: TScope; const pOffset: Integer = 0): IVisitor<T>;
    function VisitedKeywords: TArray<string>;
    /// <summary>
    /// Records a keyword as visited and returns the visitor for fluent chaining.
    /// </summary>
    function AddVisitedKeyword(const pKeyword: string): IVisitor<T>;
    /// <summary>
    /// Returns True if the given keyword has already been visited in the current traversal.
    /// </summary>
    function HasVisitedKeyword(const pKeyword: string): Boolean;
    /// <summary>
    /// Creates a new visitor instance bound to the given schema, data node, and base URI.
    /// </summary>
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): T;
  end;

  /// <summary>
  /// Visitor interface for core JSON Schema keywords: $schema, $id, $ref,
  /// $definitions, and boolean schema forms.
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
  /// Visitor interface for applicator keywords that combine or apply sub-schemas:
  /// allOf, anyOf, oneOf, not, if/then/else, properties, patternProperties,
  /// additionalProperties, items, additionalItems, and prefixItems.
  /// </summary>
  IBaseApplicatorVisitor<T> = interface(IBase<T>)
    ['{703DB02C-A44E-4584-8DC8-F3187C9790DB}']
    // Boolean
    procedure VisitAllOf(const pValue: TJSONArray);
    procedure VisitAnyOf(const pValue: TJSONArray);
    procedure VisitOneOf(const pValue: TJSONArray);
    procedure VisitNot(const pValue: TJSONValue);

    // Condition
    procedure VisitIf(const pValue: TJSONValue);
    procedure VisitThen(const pValue: TJSONValue);
    procedure VisitElse(const pValue: TJSONValue);

    // Objects
    procedure VisitProperties(const pValue: TJSONObject);
    procedure VisitPatternProperties(const pValue: TJSONObject);
    procedure VisitAdditionalProperties(const pValue: TJSONValue);

    // Arrays
    procedure VisitItems(const pValue: TJSONValue);
    procedure VisitAdditionalItems(const pValue: TJSONValue);
    procedure VisitPrefixItems(const pValue: TJSONArray);
  end;

  /// <summary>
  /// Visitor interface for validation keywords that constrain instance values:
  /// type, enum, const, numeric bounds (multipleOf, maximum, minimum,
  /// exclusiveMaximum, exclusiveMinimum), string constraints (maxLength,
  /// minLength, pattern, format), array constraints (maxItems, minItems,
  /// uniqueItems), and object constraints (maxProperties, minProperties, required).
  /// </summary>
  IBaseValidationVisitor<T> = interface(IBase<T>)
    ['{764D33F4-3B4F-4069-9CFC-2A9D732B0386}']
    // Geral
    procedure VisitType(const pValue: TJSONValue);
    procedure VisitEnum(const pValue: TJSONArray);
    procedure VisitConst(const pValue: TJSONValue);

    // Numérico
    procedure VisitMultipleOf(const pValue: TJSONNumber);
    procedure VisitMaximum(const pValue: TJSONNumber);
    procedure VisitExclusiveMaximum(const pValue: TJSONValue);
    procedure VisitMinimum(const pValue: TJSONNumber);
    procedure VisitExclusiveMinimum(const pValue: TJSONValue);

    // String
    procedure VisitMaxLength(const pValue: TJSONNumber);
    procedure VisitMinLength(const pValue: TJSONNumber);
    procedure VisitPattern(const pValue: TJSONString);
    procedure VisitFormat(const pValue: TJSONString);

    // Array
    procedure VisitMaxItems(const pValue: TJSONNumber);
    procedure VisitMinItems(const pValue: TJSONNumber);
    procedure VisitUniqueItems(const pValue: TJSONBool);

    // Objeto
    procedure VisitMaxProperties(const pValue: TJSONNumber);
    procedure VisitMinProperties(const pValue: TJSONNumber);
    procedure VisitRequired(const pValue: TJSONArray);
  end;

  /// <summary>
  /// Visitor interface for JSON Hyper-Schema keywords: base, links, href,
  /// targetSchema, submissionSchema, and hrefSchema link descriptors.
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
  /// Visitor interface for Relative JSON Pointer keywords, enabling
  /// pointer-relative navigation within a JSON document.
  /// </summary>
  IBaseRelativeJsonPointer<T> = interface(IBase<T>)
    ['{5FCB391C-EA34-44F8-B46B-05423547C9F6}']
  end;

implementation

end.
