unit JsonSchema.Visitor.Validation.&Array;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Common.Utils,
  JsonSchema.FormatValidator,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

type
  /// <summary>
  ///   Visitor for array validation keywords: maxItems, minItems, uniqueItems,
  ///   contains, maxContains, minContains.
  ///   This class is meant to be composed into a full validation visitor.
  /// </summary>
  TArrayValidationVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IArrayValidationVisitor<T>)
  private
    function GetValidationVisitor: IValidationVisitor<T>;
  public
    [VisitorKeyword('maxItems')]
    procedure VisitMaxItems(const pValue: TJSONNumber);

    [VisitorKeyword('minItems')]
    procedure VisitMinItems(const pValue: TJSONNumber);

    [VisitorKeyword('uniqueItems')]
    procedure VisitUniqueItems(const pValue: TJSONBool);

    [VisitorKeyword('contains')]
    procedure VisitContains(const pValue: TJSONValue);

    [VisitorKeyword('maxContains')]
    procedure VisitMaxContains(const pValue: TJSONNumber);

    [VisitorKeyword('minContains')]
    procedure VisitMinContains(const pValue: TJSONNumber);

  end;

implementation

uses
  System.SysUtils,
  System.Math,
  System.RegularExpressions,
  JsonSchema.JsonPathUtils;

{ TArrayValidationVisitor<T> }

function TArrayValidationVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

procedure TArrayValidationVisitor<T>.VisitMaxItems(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMax: Integer;
  lInstance: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  lInstance := lScope.InstanceNode;

  if TUtils.JsonGetType(lInstance) <> 'array' then
    Exit;

  lMax := TUtils.JsonGetInteger(pValue);
  if TJSONArray(lInstance).Count > lMax then
    lVisitor.AddError(TErrorType.vetMaxItems, [lMax]);
end;

procedure TArrayValidationVisitor<T>.VisitMinItems(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMin: Integer;
  lInstance: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  lInstance := lScope.InstanceNode;

  if TUtils.JsonGetType(lInstance) <> 'array' then
    Exit;

  lMin := TUtils.JsonGetInteger(pValue);
  if TJSONArray(lInstance).Count < lMin then
    lVisitor.AddError(TErrorType.vetMinItems, [lMin]);
end;

procedure TArrayValidationVisitor<T>.VisitUniqueItems(const pValue: TJSONBool);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lArray: TJSONArray;
  lI: Integer;
  lJ: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if not pValue.AsBoolean then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lArray := TJSONArray(lScope.InstanceNode);
  for lI := 0 to lArray.Count - 2 do
    for lJ := lI + 1 to lArray.Count - 1 do
      if TUtils.JsonEquals(lArray.Items[lI], lArray.Items[lJ]) then
      begin
        lVisitor.AddError(TErrorType.vetUniqueItems, [lArray.Items[lI].ToString]);
        Exit;
      end;
end;

procedure TArrayValidationVisitor<T>.VisitContains(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONArray;
  lCount: Integer;
  lSubVisitor: IValidationVisitor<T>;
  lWalker: IWalker;
  lNewScope: TScope;
  lMinContainsNode: TJSONValue;
  lMinimumContains: Integer;
  lItemPath: string;
  lHasMinContains: Boolean;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lInstance := TJSONArray(lScope.InstanceNode);

  // Boolean true: array must be non‑empty
  if pValue is TJSONBool then
  begin
    if TJSONBool(pValue).AsBoolean then
    begin
      if lInstance.Count > 0 then
      begin
        // Mark all items as covered
        for lCount := 0 to lInstance.Count - 1 do
        begin
          TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
          lItemPath := TJsonPathUtils.JoinPath(lScope.InstancePath, lCount.ToString);
          lVisitor.Result.AddEvaluatedProperty(lItemPath);
        end;
        lVisitor.UpdateScope(lScope);
        Exit;
      end;
      lVisitor.AddError(TErrorType.vetContains);
    end
    else
      lVisitor.AddError(TErrorType.vetContains);
    Exit;
  end;

  // Boolean false or schema: evaluate against each item
  lVisitor.PushScope(lScope);
  try
    for lCount := 0 to lInstance.Count - 1 do
    begin
      lNewScope := lVisitor.CurrentScope;
      lNewScope.SchemaNode := pValue;
      lNewScope.InstanceNode := lInstance[lCount];
      lNewScope.InstancePath := TJsonPathUtils.JoinPath(lScope.InstancePath, lCount.ToString);
      lNewScope.CoveredItems := [];
      lNewScope.ContainsCount := 0;
      lNewScope.VisitedKeywords := [];
      lNewScope.CoveredProperties := [];

      lSubVisitor := lVisitor.New(pValue, lInstance[lCount], lScope.BaseURI);
      lSubVisitor.PushScope(lNewScope);
      try
        lWalker := TWalker<T>.Create(pValue, lSubVisitor);
        lWalker.Walk;
      finally
        lSubVisitor.PopScope;
      end;

      if lSubVisitor.Result.IsValid then
      begin
        Inc(lScope.ContainsCount);
        TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
        lItemPath := TJsonPathUtils.JoinPath(lScope.InstancePath, lCount.ToString);
        lVisitor.Result.AddEvaluatedProperty(lItemPath);
      end;
    end;
  finally
    lVisitor.UpdateScope(lScope);
    lVisitor.PopScope;
  end;

  // Enforce minContains (default 1) and maxContains
  lHasMinContains := (lScope.SchemaNode is TJSONObject) and
                     TJSONObject(lScope.SchemaNode).TryGetValue('minContains', lMinContainsNode);
  if lHasMinContains and (lMinContainsNode is TJSONNumber) then
    lMinimumContains := TUtils.JsonGetInteger(TJSONNumber(lMinContainsNode))
  else
    lMinimumContains := 1;

  if lScope.ContainsCount < lMinimumContains then
    if lMinimumContains = 1 then
      lVisitor.AddError(TErrorType.vetContains)
    else
      lVisitor.AddError(TErrorType.vetMinContains, [lMinimumContains, lScope.ContainsCount]);

  if (lScope.SchemaNode is TJSONObject) and
     TJSONObject(lScope.SchemaNode).TryGetValue('maxContains', lMinContainsNode) and
     (lMinContainsNode is TJSONNumber) then
  begin
    if lScope.ContainsCount > TUtils.JsonGetInteger(TJSONNumber(lMinContainsNode)) then
      lVisitor.AddError(TErrorType.vetMaxContains, [TUtils.JsonGetInteger(TJSONNumber(lMinContainsNode)), lScope.ContainsCount]);
  end;
end;

procedure TArrayValidationVisitor<T>.VisitMaxContains(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if lScope.SchemaNode.FindValue('contains') = nil then
    Exit;

  if lScope.ContainsCount > TUtils.JsonGetInteger(pValue) then
    lVisitor.AddError(TErrorType.vetMaxContains, [TUtils.JsonGetInteger(pValue), lScope.ContainsCount]);
end;

procedure TArrayValidationVisitor<T>.VisitMinContains(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMinimum: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if lScope.SchemaNode.FindValue('contains') = nil then
    Exit;

  lMinimum := TUtils.JsonGetInteger(pValue);
  if lScope.ContainsCount < lMinimum then
    if lMinimum = 1 then
      lVisitor.AddError(TErrorType.vetContains)
    else
      lVisitor.AddError(TErrorType.vetMinContains, [lMinimum, lScope.ContainsCount]);
end;



end.
