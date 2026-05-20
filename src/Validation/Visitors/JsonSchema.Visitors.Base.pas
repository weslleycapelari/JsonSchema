unit JsonSchema.Visitors.Base;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Common.Utils;

type
  /// <summary>
  ///   Base visitor that owns and manages the scope stack for schema traversal.
  ///   Subclasses must implement the New method to create a fresh visitor
  ///   instance of the same concrete type.
  /// </summary>
  TBaseVisitor<T> = class(TInterfacedObject, IVisitor<T>)
  protected
    FCore: IBaseCoreVisitor<T>;
    FApplicator: IBaseApplicatorVisitor<T>;
    FValidation: IBaseValidationVisitor<T>;
    FHyperSchema: IBaseHyperSchemaVisitor<T>;
    FRelativeJsonPointer: IBaseRelativeJsonPointer<T>;

    FData: TJSONValue;
    FScopeStack: TStack<TScope>;

    function GetCurrentScope(const pOffset: Integer): TScope;
    procedure SetCurrentScope(const pScope: TScope; const pOffset: Integer);
  public
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string);
    destructor Destroy; override;

    function Core: IBaseCoreVisitor<T>;
    function Applicator: IBaseApplicatorVisitor<T>;
    function Validation: IBaseValidationVisitor<T>;
    function HyperSchema: IBaseHyperSchemaVisitor<T>;
    function RelativeJsonPointer: IBaseRelativeJsonPointer<T>;

    function KeywordPrecedence: TArray<string>; virtual;
    function PopScope: TScope;
    function PushScope(const pScope: TScope): IVisitor<T>;
    function CurrentScope(const pOffset: Integer = 0): TScope;
    function UpdateScope(const pScope: TScope; const pOffset: Integer = 0): IVisitor<T>;
    function VisitedKeywords: TArray<string>;
    function AddVisitedKeyword(const pKeyword: string): IVisitor<T>;
    function HasVisitedKeyword(const pKeyword: string): Boolean;
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): T; virtual; abstract;
  end;

  /// <summary>
  ///   Base helper that holds a reference to the owning visitor and exposes it via Visitor.
  ///   Used as a base for category-specific visitors (Core, Applicator, etc.).
  /// </summary>
  TBase<T: IVisitor<T>> = class(TInterfacedObject, IBase<T>)
  private
    FVisitor: T;
  protected
    /// <summary>Returns the current scope from the validation visitor.</summary>
    function GetCurrentScope: TScope;

    /// <summary>Updates the current scope in the validation visitor.</summary>
    procedure UpdateScope(const pScope: TScope);
  public
    constructor Create(pVisitor: T);
    function Visitor: T;
  end;

implementation

uses
  System.SysUtils,
  JsonSchema.Exceptions;

{ TBaseVisitor<T> }

constructor TBaseVisitor<T>.Create(const pSchema, pData: TJSONValue; const pBaseURI: string);
var
  lScope: TScope;
begin
  inherited Create;
  FData := pData;
  FScopeStack := TStack<TScope>.Create;

  lScope.BaseURI := pBaseURI;
  lScope.SchemaPath := '#';
  lScope.SchemaNode := pSchema;
  lScope.InstancePath := '#';
  lScope.InstanceNode := pData;
  lScope.CoveredItems := [];
  lScope.ContainsCount := 0;
  lScope.VisitedKeywords := [];
  lScope.CoveredProperties := [];
  lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
  FScopeStack.Push(lScope);
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

function TBaseVisitor<T>.Core: IBaseCoreVisitor<T>;
begin
  Result := FCore;
end;

function TBaseVisitor<T>.Applicator: IBaseApplicatorVisitor<T>;
begin
  Result := FApplicator;
end;

function TBaseVisitor<T>.Validation: IBaseValidationVisitor<T>;
begin
  Result := FValidation;
end;

function TBaseVisitor<T>.HyperSchema: IBaseHyperSchemaVisitor<T>;
begin
  Result := FHyperSchema;
end;

function TBaseVisitor<T>.RelativeJsonPointer: IBaseRelativeJsonPointer<T>;
begin
  Result := FRelativeJsonPointer;
end;

function TBaseVisitor<T>.KeywordPrecedence: TArray<string>;
begin
  Result := [];
end;

function TBaseVisitor<T>.PopScope: TScope;
begin
  Result := Default(TScope);
  if not Assigned(FScopeStack) or (FScopeStack.Count = 0) then
    raise EJsonSchemaError.Create('Scope stack underflow: cannot pop from an empty scope stack.');

  Result := FScopeStack.Pop;
end;

function TBaseVisitor<T>.PushScope(const pScope: TScope): IVisitor<T>;
var
  lScope: TScope;
begin
  Result := Self;
  if not Assigned(FScopeStack) then
    FScopeStack := TStack<TScope>.Create;

  lScope := pScope;

  // Ensure EvaluatedPropertiesInScope is not shared with parent scope
  if (FScopeStack.Count > 0) and Assigned(CurrentScope.EvaluatedPropertiesInScope) and
     (lScope.EvaluatedPropertiesInScope = CurrentScope.EvaluatedPropertiesInScope) then
    lScope.EvaluatedPropertiesInScope := THashSet<string>.Create
  else if not Assigned(lScope.EvaluatedPropertiesInScope) then
    lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  FScopeStack.Push(lScope);
end;

function TBaseVisitor<T>.CurrentScope(const pOffset: Integer): TScope;
begin
  Result := Default(TScope);
  if not Assigned(FScopeStack) then
    raise EJsonSchemaError.Create('Scope stack is not initialized.');

  if (pOffset = 0) and (FScopeStack.Count = 0) then
    raise EJsonSchemaError.Create('Scope stack is empty: current scope is unavailable.');

  if FScopeStack.Count > pOffset then
    Result := FScopeStack.List[FScopeStack.Count - pOffset - 1];
end;

function TBaseVisitor<T>.UpdateScope(const pScope: TScope; const pOffset: Integer): IVisitor<T>;
begin
  Result := Self;
  if not Assigned(FScopeStack) then
    raise EJsonSchemaError.Create('Scope stack is not initialized.');

  if (pOffset = 0) and (FScopeStack.Count = 0) then
    raise EJsonSchemaError.Create('Scope stack is empty: cannot update current scope.');

  if FScopeStack.Count > pOffset then
    FScopeStack.List[FScopeStack.Count - pOffset - 1] := pScope;
end;

function TBaseVisitor<T>.VisitedKeywords: TArray<string>;
begin
  Result := CurrentScope.VisitedKeywords;
end;

function TBaseVisitor<T>.AddVisitedKeyword(const pKeyword: string): IVisitor<T>;
var
  lScope: TScope;
begin
  Result := Self;
  lScope := CurrentScope;
  TUtils.AddArray<string>(lScope.VisitedKeywords, pKeyword);
  UpdateScope(lScope);
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

function TBaseVisitor<T>.GetCurrentScope(const pOffset: Integer): TScope;
begin
  Result := CurrentScope(pOffset);
end;

procedure TBaseVisitor<T>.SetCurrentScope(const pScope: TScope; const pOffset: Integer);
begin
  UpdateScope(pScope, pOffset);
end;

{ TBase<T> }

constructor TBase<T>.Create(pVisitor: T);
begin
  inherited Create;
  FVisitor := pVisitor;
end;

function TBase<T>.GetCurrentScope: TScope;
var
  lVisitor: IVisitor<T>;
begin
  FillChar(Result, SizeOf(Result), 0);
  lVisitor := Visitor;
  if Assigned(lVisitor) then
    Result := lVisitor.CurrentScope;
end;

procedure TBase<T>.UpdateScope(const pScope: TScope);
var
  lVisitor: IVisitor<T>;
begin
  lVisitor := Visitor;
  if Assigned(lVisitor) then
    lVisitor.UpdateScope(pScope);
end;

function TBase<T>.Visitor: T;
begin
  Result := FVisitor;
end;

end.
