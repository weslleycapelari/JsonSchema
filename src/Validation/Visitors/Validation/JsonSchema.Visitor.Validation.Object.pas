unit JsonSchema.Visitor.Validation.&Object;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Types,
  JsonSchema.Interfaces,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Common.Utils,
  JsonSchema.JsonPathUtils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

type
  /// <summary>
  ///   Visitor for object validation keywords: maxProperties, minProperties,
  ///   required, propertyNames, dependencies, dependentRequired.
  ///   This class is meant to be composed into a full validation visitor.
  /// </summary>
  TObjectValidationVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IObjectValidationVisitor<T>)
  private
    function GetValidationVisitor: IValidationVisitor<T>;
  public
    [VisitorKeyword('maxProperties')]
    procedure VisitMaxProperties(const pValue: TJSONNumber);

    [VisitorKeyword('minProperties')]
    procedure VisitMinProperties(const pValue: TJSONNumber);

    [VisitorKeyword('required')]
    procedure VisitRequired(const pValue: TJSONArray);

    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const pValue: TJSONValue);

    [VisitorKeyword('dependencies')]
    procedure VisitDependencies(const pValue: TJSONObject);

    [VisitorKeyword('dependentRequired')]
    procedure VisitDependentRequired(const pValue: TJSONObject);

  end;

implementation

uses
  System.SysUtils,
  System.RegularExpressions;

{ TObjectValidationVisitor<T> }

function TObjectValidationVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

procedure TObjectValidationVisitor<T>.VisitMaxProperties(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMax: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lMax := TUtils.JsonGetInteger(pValue);
  if TJSONObject(lScope.InstanceNode).Count > lMax then
    lVisitor.AddError(TErrorType.vetMaxProperties, [lMax]);
end;

procedure TObjectValidationVisitor<T>.VisitMinProperties(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMin: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lMin := TUtils.JsonGetInteger(pValue);
  if TJSONObject(lScope.InstanceNode).Count < lMin then
    lVisitor.AddError(TErrorType.vetMinProperties, [lMin]);
end;

procedure TObjectValidationVisitor<T>.VisitRequired(const pValue: TJSONArray);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lRequired: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lRequired in pValue do
    if lInstance.FindValue(lRequired.Value) = nil then
      lVisitor.AddError(TErrorType.vetRequiredPropertyMissing, [lRequired.Value]);
end;

procedure TObjectValidationVisitor<T>.VisitPropertyNames(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lPair: TJSONPair;
  lSubVisitor: IValidationVisitor<T>;
  lWalker: IWalker;
  lNewScope: TScope;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lPair in lInstance do
  begin
    lNewScope := lVisitor.CurrentScope;
    lNewScope.SchemaNode := pValue;
    lNewScope.InstanceNode := lPair.JsonString;
    lNewScope.InstancePath := TJsonPathUtils.JoinPath(lScope.InstancePath, lPair.JsonString.Value);
    lNewScope.CoveredItems := [];
    lNewScope.ContainsCount := 0;
    lNewScope.VisitedKeywords := [];
    lNewScope.CoveredProperties := [];

    lSubVisitor := lVisitor.New(pValue, lPair.JsonString, lScope.BaseURI);
    lSubVisitor.PushScope(lNewScope);
    try
      lWalker := TWalker<T>.Create(pValue, lSubVisitor);
      lWalker.Walk;
    finally
      lSubVisitor.PopScope;
    end;

    if not lSubVisitor.Result.IsValid then
      lVisitor.AddError(TErrorType.vetInvalidPropertyName, [lPair.JsonString.Value]);
  end;
end;

procedure TObjectValidationVisitor<T>.VisitDependencies(const pValue: TJSONObject);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lDependencyValue: TJSONValue;
  lRequiredList: TJSONArray;
  lRequiredValue: TJSONValue;
  lRequiredName: string;
  lSubVisitor: IValidationVisitor<T>;
  lWalker: IWalker;
  lNewScope: TScope;
  lError: IError;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lDependencyPair in pValue do
  begin
    if lInstance.FindValue(lDependencyPair.JsonString.Value) = nil then
      Continue;

    lDependencyValue := lDependencyPair.JsonValue;

    // Array form: dependentRequired (legacy)
    if lDependencyValue is TJSONArray then
    begin
      lRequiredList := TJSONArray(lDependencyValue);
      for lRequiredValue in lRequiredList do
      begin
        if not (lRequiredValue is TJSONString) then
          Continue;

        lRequiredName := TJSONString(lRequiredValue).Value;
        if lInstance.FindValue(lRequiredName) = nil then
          lVisitor.AddError(TErrorType.vetDependentRequired, [lDependencyPair.JsonString.Value, lRequiredName]);
      end;
      Continue;
    end;

    // Schema form: dependentSchemas (legacy)
    if (lDependencyValue is TJSONObject) or (lDependencyValue is TJSONBool) then
    begin
      lNewScope := lScope;
      lNewScope.SchemaPath := Format('%s/dependencies/%s', [lScope.SchemaPath, lDependencyPair.JsonString.Value]);
      lNewScope.SchemaNode := lDependencyValue;
      lNewScope.CoveredItems := [];
      lNewScope.ContainsCount := 0;
      lNewScope.VisitedKeywords := [];
      lNewScope.CoveredProperties := [];
      lNewScope.EvaluatedPropertiesInScope := nil;

      lSubVisitor := lVisitor.New(lDependencyValue, lScope.InstanceNode, lScope.BaseURI);
      lSubVisitor.PushScope(lNewScope);
      try
        lWalker := TWalker<T>.Create(lDependencyValue, lSubVisitor);
        lWalker.Walk;
      finally
        lSubVisitor.PopScope;
      end;

      if not lSubVisitor.Result.IsValid then
        for lError in lSubVisitor.Result.Errors do
          lVisitor.Result.AddError(lError);
    end;
  end;
end;

procedure TObjectValidationVisitor<T>.VisitDependentRequired(const pValue: TJSONObject);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lRequiredList: TJSONArray;
  lRequiredValue: TJSONValue;
  lRequiredName: string;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lDependencyPair in pValue do
  begin
    if lInstance.FindValue(lDependencyPair.JsonString.Value) = nil then
      Continue;

    if not (lDependencyPair.JsonValue is TJSONArray) then
      Continue;

    lRequiredList := TJSONArray(lDependencyPair.JsonValue);
    for lRequiredValue in lRequiredList do
    begin
      if not (lRequiredValue is TJSONString) then
        Continue;

      lRequiredName := TJSONString(lRequiredValue).Value;
      if lInstance.FindValue(lRequiredName) = nil then
        lVisitor.AddError(TErrorType.vetDependentRequired, [lDependencyPair.JsonString.Value, lRequiredName]);
    end;
  end;
end;



end.
