unit JsonSchema.Visitors.Base;

interface

uses
  System.JSON,
  System.Classes,
  System.Generics.Collections,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces;

type
  /// <summary>Base visitor that owns and manages the scope stack for schema traversal.</summary>
  TBaseVisitor<T> = class(TInterfacedPersistent, IVisitor<T>)
  protected
    FCore: IBaseCoreVisitor<T>;
    FApplicator: IBaseApplicatorVisitor<T>;
    FValidation: IBaseValidationVisitor<T>;
    FHyperSchema: IBaseHyperSchemaVisitor<T>;
    FRelativeJsonPointer: IBaseRelativeJsonPointer<T>;

    FData: TJSONValue;
    FScopeStack: TStack<TScope>;
  public
    /// <summary>Initialises the scope stack and pushes the root scope derived from the supplied schema and data nodes.</summary>
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string);
    destructor Destroy; override;

    function Core: IBaseCoreVisitor<T>;
    function Applicator: IBaseApplicatorVisitor<T>;
    function Validation: IBaseValidationVisitor<T>;
    function HyperSchema: IBaseHyperSchemaVisitor<T>;
    function RelativeJsonPointer: IBaseRelativeJsonPointer<T>;

    function KeywordPrecedence: TArray<string>; virtual;
    /// <summary>Pops and returns the top scope from the stack.</summary>
    function PopScope: TScope;
    /// <summary>Pushes a new scope onto the stack, ensuring a fresh EvaluatedPropertiesInScope set.</summary>
    function PushScope(const pScope: TScope): IVisitor<T>;
    /// <summary>Returns the scope at the given depth offset from the top of the stack.</summary>
    function CurrentScope(const pOffset: Integer = 0): TScope;
    /// <summary>Replaces the scope at the given depth offset with the supplied value.</summary>
    function UpdateScope(const pScope: TScope; const pOffset: Integer = 0): IVisitor<T>;
    function VisitedKeywords: TArray<string>;
    /// <summary>Appends a keyword to the visited-keywords list of the current scope.</summary>
    function AddVisitedKeyword(const pKeyword: string): IVisitor<T>;
    /// <summary>Returns True if the given keyword has already been visited in the current scope.</summary>
    function HasVisitedKeyword(const pKeyword: string): Boolean;
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): T; virtual; abstract;
  end;

  /// <summary>Base helper that holds a reference to the owning visitor and exposes it via Visitor.</summary>
  TBase<T: IVisitor<T>> = class(TInterfacedPersistent, IBase<T>)
  private
    FVisitor: T;
  public
    constructor Create(pVisitor: T);
    function Visitor: T;
  end;

implementation

uses
  JsonSchema.Common.Utils;

{ TBase<T> }

constructor TBase<T>.Create(pVisitor: T);
begin
  FVisitor := pVisitor;
end;

function TBase<T>.Visitor: T;
begin
  Result := FVisitor;
end;

{ TBaseVisitor<T> }

function TBaseVisitor<T>.AddVisitedKeyword(const pKeyword: string): IVisitor<T>;
var
  lScope: TScope;
begin
  Result := Self;
  lScope := CurrentScope;
  TUtils.AddArray<string>(lScope.VisitedKeywords, pKeyword);
  UpdateScope(lScope);
end;

function TBaseVisitor<T>.Applicator: IBaseApplicatorVisitor<T>;
begin
  Result := FApplicator;
end;

function TBaseVisitor<T>.Core: IBaseCoreVisitor<T>;
begin
  Result := FCore;
end;

constructor TBaseVisitor<T>.Create(const pSchema, pData: TJSONValue; const pBaseURI: string);
var
  lScope: TScope;
begin
  FData := pData;
  FScopeStack := TStack<TScope>.Create;

  lScope.BaseURI           := pBaseURI;
  lScope.SchemaPath        := '#';
  lScope.SchemaNode        := pSchema;
  lScope.InstancePath      := '#';
  lScope.InstanceNode      := pData;
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
  FScopeStack.Push(lScope);
end;

function TBaseVisitor<T>.CurrentScope(const pOffset: Integer): TScope;
begin
  FillChar(Result, SizeOf(Result), 0);
  if FScopeStack.Count > pOffset then
    Result := FScopeStack.List[FScopeStack.Count - pOffset - 1];
end;

destructor TBaseVisitor<T>.Destroy;
var
  lScope: TScope;
  lFreedSets: TList<THashSet<string>>;
begin
  lFreedSets := TList<THashSet<string>>.Create;
  try
    for lScope in FScopeStack do
      if Assigned(lScope.EvaluatedPropertiesInScope) and not lFreedSets.Contains(lScope.EvaluatedPropertiesInScope) then
      begin
        lFreedSets.Add(lScope.EvaluatedPropertiesInScope);
        lScope.EvaluatedPropertiesInScope.Free;
      end;
  finally
    lFreedSets.Free;
  end;

  FScopeStack.Free;
  inherited;
end;

function TBaseVisitor<T>.HasVisitedKeyword(const pKeyword: string): Boolean;
var
  lList: TList<string>;
begin
  lList := TList<string>.Create(CurrentScope.VisitedKeywords);
  try
    Result := lList.Contains(pKeyword);
  finally
    lList.Free;
  end;
end;

function TBaseVisitor<T>.HyperSchema: IBaseHyperSchemaVisitor<T>;
begin
  Result := FHyperSchema;
end;

function TBaseVisitor<T>.KeywordPrecedence: TArray<string>;
begin
  Result := [];
end;

function TBaseVisitor<T>.PopScope: TScope;
begin
  Result := FScopeStack.Pop;
end;

function TBaseVisitor<T>.PushScope(const pScope: TScope): IVisitor<T>;
var
  lScope: TScope;
begin
  Result := Self;
  lScope := pScope;

  if (FScopeStack.Count > 0) and Assigned(CurrentScope.EvaluatedPropertiesInScope) and
     (lScope.EvaluatedPropertiesInScope = CurrentScope.EvaluatedPropertiesInScope) then
    lScope.EvaluatedPropertiesInScope := THashSet<string>.Create
  else if not Assigned(lScope.EvaluatedPropertiesInScope) then
    lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  FScopeStack.Push(lScope);
end;

function TBaseVisitor<T>.RelativeJsonPointer: IBaseRelativeJsonPointer<T>;
begin
  Result := FRelativeJsonPointer;
end;

function TBaseVisitor<T>.UpdateScope(const pScope: TScope; const pOffset: Integer): IVisitor<T>;
begin
  Result := Self;
  if FScopeStack.Count > pOffset then
    FScopeStack.List[FScopeStack.Count - pOffset - 1] := pScope;
end;

function TBaseVisitor<T>.Validation: IBaseValidationVisitor<T>;
begin
  Result := FValidation;
end;

function TBaseVisitor<T>.VisitedKeywords: TArray<string>;
begin
  Result := CurrentScope.VisitedKeywords;
end;

end.
