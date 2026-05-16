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

  IBase<T> = interface(IInterface)
    ['{BF2C3D3B-B604-4CF9-B705-7FE3D6FE4C15}']
    function Visitor: T;
  end;

  IVisitor<T> = interface(IInterface)
    ['{A86BDE88-3D1D-4AA7-BDE6-92949C001B3C}']
    function Core: IBaseCoreVisitor<T>;
    function Applicator: IBaseApplicatorVisitor<T>;
    function Validation: IBaseValidationVisitor<T>;
    function HyperSchema: IBaseHyperSchemaVisitor<T>;
    function RelativeJsonPointer: IBaseRelativeJsonPointer<T>;

    function KeywordPrecedence: TArray<string>;
    function PopScope: TScope;
    function PushScope(const AScope: TScope): IVisitor<T>;
    function CurrentScope(const AOffset: Integer = 0): TScope;
    function UpdateScope(const AScope: TScope; const AOffset: Integer = 0): IVisitor<T>;
    function VisitedKeywords: TArray<string>;
    function AddVisitedKeyword(const AKeyword: string): IVisitor<T>;
    function HasVisitedKeyword(const AKeyword: string): Boolean;
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): T;
  end;

  IBaseCoreVisitor<T> = interface(IBase<T>)
    ['{FB6620E4-078A-4C11-AD0E-5B8E6E6055D4}']
    procedure VisitSchema(const AValue: TJSONString);
    procedure VisitId(const AValue: TJSONString);
    procedure VisitRef(const AValue: TJSONString);
    procedure VisitDefinitions(const AValue: TJSONObject);
    procedure VisitBooleanSchema(const AValue: TJSONBool);
  end;

  IBaseApplicatorVisitor<T> = interface(IBase<T>)
    ['{703DB02C-A44E-4584-8DC8-F3187C9790DB}']
    // Boolean
    procedure VisitAllOf(const AValue: TJSONArray);
    procedure VisitAnyOf(const AValue: TJSONArray);
    procedure VisitOneOf(const AValue: TJSONArray);
    procedure VisitNot(const AValue: TJSONValue);

    // Condition
    procedure VisitIf(const AValue: TJSONValue);
    procedure VisitThen(const AValue: TJSONValue);
    procedure VisitElse(const AValue: TJSONValue);

    // Objects
    procedure VisitProperties(const AValue: TJSONObject);
    procedure VisitPatternProperties(const AValue: TJSONObject);
    procedure VisitAdditionalProperties(const AValue: TJSONValue);

    // Arrays
    procedure VisitItems(const AValue: TJSONValue);
    procedure VisitAdditionalItems(const AValue: TJSONValue);
    procedure VisitPrefixItems(const AValue: TJSONArray);
  end;

  IBaseValidationVisitor<T> = interface(IBase<T>)
    ['{764D33F4-3B4F-4069-9CFC-2A9D732B0386}']
    // Geral
    procedure VisitType(const AValue: TJSONValue);
    procedure VisitEnum(const AValue: TJSONArray);
    procedure VisitConst(const AValue: TJSONValue);

    // Num�rico
    procedure VisitMultipleOf(const AValue: TJSONNumber);
    procedure VisitMaximum(const AValue: TJSONNumber);
    procedure VisitExclusiveMaximum(const AValue: TJSONValue);
    procedure VisitMinimum(const AValue: TJSONNumber);
    procedure VisitExclusiveMinimum(const AValue: TJSONValue);

    // String
    procedure VisitMaxLength(const AValue: TJSONNumber);
    procedure VisitMinLength(const AValue: TJSONNumber);
    procedure VisitPattern(const AValue: TJSONString);
    procedure VisitFormat(const AValue: TJSONString);

    // Array
    procedure VisitMaxItems(const AValue: TJSONNumber);
    procedure VisitMinItems(const AValue: TJSONNumber);
    procedure VisitUniqueItems(const AValue: TJSONBool);

    // Objeto
    procedure VisitMaxProperties(const AValue: TJSONNumber);
    procedure VisitMinProperties(const AValue: TJSONNumber);
    procedure VisitRequired(const AValue: TJSONArray);
  end;

  IBaseHyperSchemaVisitor<T> = interface(IBase<T>)
    ['{94AE6A46-A543-4FD9-B262-E55D9D65F260}']
    procedure VisitBase(const AValue: TJSONString);
    procedure VisitLinks(const AValue: TJSONArray);

    procedure VisitHref(const AValue: TJSONString);
    procedure VisitTargetSchema(const AValue: TJSONValue);
    procedure VisitSubmissionSchema(const AValue: TJSONValue);
    procedure VisitHrefSchema(const AValue: TJSONValue);
  end;

  IBaseRelativeJsonPointer<T> = interface(IBase<T>)
    ['{5FCB391C-EA34-44F8-B46B-05423547C9F6}']
  end;

implementation

end.
