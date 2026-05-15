unit JsonSchema.Visitors.Base;

interface

uses
  System.JSON,
  System.Classes,
  System.Generics.Collections,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces;

type
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
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string);
    destructor Destroy; override;

    function Core: IBaseCoreVisitor<T>;
    function Applicator: IBaseApplicatorVisitor<T>;
    function Validation: IBaseValidationVisitor<T>;
    function HyperSchema: IBaseHyperSchemaVisitor<T>;
    function RelativeJsonPointer: IBaseRelativeJsonPointer<T>;

    function KeywordPrecedence: TArray<string>; virtual;
    function PopScope: TScope;
    function PushScope(const AScope: TScope): IVisitor<T>;
    function CurrentScope(const AOffset: Integer = 0): TScope;
    function UpdateScope(const AScope: TScope; const AOffset: Integer = 0): IVisitor<T>;
    function VisitedKeywords: TArray<string>;
    function AddVisitedKeyword(const AKeyword: string): IVisitor<T>;
    function HasVisitedKeyword(const AKeyword: string): Boolean;
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): T; virtual; abstract;
  end;

  TBase<T: IVisitor<T>> = class(TInterfacedPersistent, IBase<T>)
  private
    FVisitor: T;
  public
    constructor Create(AVisitor: T);
    function Visitor: T;
  end;

implementation

uses
  JsonSchema.Common.Utils;

{ TBase<T> }

constructor TBase<T>.Create(AVisitor: T);
begin
  FVisitor := AVisitor;
end;

function TBase<T>.Visitor: T;
begin
  Result := FVisitor;
end;

{ TBaseVisitor<T> }

function TBaseVisitor<T>.AddVisitedKeyword(const AKeyword: string): IVisitor<T>;
var
  LScope: TScope;
begin
  Result := Self;
  LScope := CurrentScope;
  TUtils.AddArray<string>(LScope.VisitedKeywords, AKeyword);
  UpdateScope(LScope);
end;

function TBaseVisitor<T>.Applicator: IBaseApplicatorVisitor<T>;
begin
  Result := FApplicator;
end;

function TBaseVisitor<T>.Core: IBaseCoreVisitor<T>;
begin
  Result := FCore;
end;

constructor TBaseVisitor<T>.Create(const ASchema, AData: TJSONValue; const ABaseURI: string);
var
  LScope: TScope;
begin
  FData := AData;
  FScopeStack := TStack<TScope>.Create;

  LScope.BaseURI           := ABaseURI;
  LScope.SchemaPath        := '#';
  LScope.SchemaNode        := ASchema;
  LScope.InstancePath      := '#';
  LScope.InstanceNode      := AData;
  LScope.CoveredItems      := [];
  LScope.ContainsCount     := 0;
  LScope.VisitedKeywords   := [];
  LScope.CoveredProperties := [];
  LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
  FScopeStack.Push(LScope);
end;

function TBaseVisitor<T>.CurrentScope(const AOffset: Integer): TScope;
begin
  FillChar(Result, SizeOf(Result), 0);
  if FScopeStack.Count > AOffset then
    Result := FScopeStack.List[FScopeStack.Count - AOffset - 1];
end;

destructor TBaseVisitor<T>.Destroy;
var
  LScope: TScope;
  LFreedSets: TList<THashSet<string>>;
begin
  LFreedSets := TList<THashSet<string>>.Create;
  try
    for LScope in FScopeStack do
      if Assigned(LScope.EvaluatedPropertiesInScope) and not LFreedSets.Contains(LScope.EvaluatedPropertiesInScope) then
      begin
        LFreedSets.Add(LScope.EvaluatedPropertiesInScope);
        LScope.EvaluatedPropertiesInScope.Free;
      end;
  finally
    LFreedSets.Free;
  end;

  FScopeStack.Free;
  inherited;
end;

function TBaseVisitor<T>.HasVisitedKeyword(const AKeyword: string): Boolean;
var
  LList: TList<string>;
begin
  LList := TList<string>.Create(CurrentScope.VisitedKeywords);
  try
    Result := LList.Contains(AKeyword);
  finally
    LList.Free;
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

function TBaseVisitor<T>.PushScope(const AScope: TScope): IVisitor<T>;
var
  LScope: TScope;
begin
  Result := Self;
  LScope := AScope;

  if (FScopeStack.Count > 0) and Assigned(CurrentScope.EvaluatedPropertiesInScope) and
     (LScope.EvaluatedPropertiesInScope = CurrentScope.EvaluatedPropertiesInScope) then
    LScope.EvaluatedPropertiesInScope := THashSet<string>.Create
  else if not Assigned(LScope.EvaluatedPropertiesInScope) then
    LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  FScopeStack.Push(LScope);
end;

function TBaseVisitor<T>.RelativeJsonPointer: IBaseRelativeJsonPointer<T>;
begin
  Result := FRelativeJsonPointer;
end;

function TBaseVisitor<T>.UpdateScope(const AScope: TScope; const AOffset: Integer): IVisitor<T>;
begin
  Result := Self;
  if FScopeStack.Count > AOffset then
    FScopeStack.List[FScopeStack.Count - AOffset - 1] := AScope;
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
