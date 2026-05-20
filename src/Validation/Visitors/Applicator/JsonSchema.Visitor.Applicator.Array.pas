unit JsonSchema.Visitor.Applicator.&Array;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Common.Utils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

type
  /// <summary>
  ///   Visitor for array applicator keywords: items, additionalItems, prefixItems.
  ///   This class is meant to be composed into a full validation visitor.
  /// </summary>
  TArrayApplicatorVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseApplicatorVisitor<T>)
  private
    function GetValidationVisitor: IValidationVisitor<T>;
  public
    [VisitorKeyword('items')]
    procedure VisitItems(const pValue: TJSONValue);

    [VisitorKeyword('additionalItems')]
    procedure VisitAdditionalItems(const pValue: TJSONValue);

    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const pValue: TJSONArray);

    // Unsupported applicator methods – no‑op to satisfy the interface
    procedure VisitAllOf(const pValue: TJSONArray); virtual;
    procedure VisitAnyOf(const pValue: TJSONArray); virtual;
    procedure VisitOneOf(const pValue: TJSONArray); virtual;
    procedure VisitNot(const pValue: TJSONValue); virtual;
    procedure VisitIf(const pValue: TJSONValue); virtual;
    procedure VisitThen(const pValue: TJSONValue); virtual;
    procedure VisitElse(const pValue: TJSONValue); virtual;
    procedure VisitProperties(const pValue: TJSONObject); virtual;
    procedure VisitPatternProperties(const pValue: TJSONObject); virtual;
    procedure VisitAdditionalProperties(const pValue: TJSONValue); virtual;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

{ TArrayApplicatorVisitor<T> }

function TArrayApplicatorVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

procedure TArrayApplicatorVisitor<T>.VisitItems(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONArray;
  lCount: Integer;
  lMaxCount: Integer;
  lSchema: TJSONValue;
  lCovered: TList<Integer>;
  lNewScope: TScope;
  lWalker: IWalker;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lInstance := TJSONArray(lScope.InstanceNode);
  lCovered := TList<Integer>.Create(lScope.CoveredItems);
  try
    if pValue is TJSONArray then
    begin
      // items as an array (tuple validation)
      lMaxCount := Min(lInstance.Count, TJSONArray(pValue).Count);
      for lCount := 0 to lMaxCount - 1 do
      begin
        if lCovered.Contains(lCount) then
          Continue;

        lSchema := TJSONArray(pValue)[lCount];
        lNewScope := lScope;
        lNewScope.SchemaPath := Format('%s/items/%d', [lScope.SchemaPath, lCount]);
        lNewScope.SchemaNode := lSchema;
        lNewScope.InstanceNode := lInstance[lCount];
        lNewScope.InstancePath := Format('%s/%d', [lScope.InstancePath, lCount]);
        lNewScope.CoveredItems := [];
        lNewScope.ContainsCount := 0;
        lNewScope.VisitedKeywords := [];
        lNewScope.CoveredProperties := [];

        lVisitor.PushScope(lNewScope);
        try
          lWalker := TWalker<T>.Create(lSchema, lVisitor);
          lWalker.Walk;
        finally
          lVisitor.PopScope;
        end;

        TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      end;
    end
    else if (pValue is TJSONObject) or (pValue is TJSONBool) then
    begin
      // items as a single schema (list validation)
      lMaxCount := lInstance.Count;
      for lCount := 0 to lMaxCount - 1 do
      begin
        if lCovered.Contains(lCount) then
          Continue;

        lSchema := pValue;
        lNewScope := lScope;
        lNewScope.SchemaPath := Format('%s/items', [lScope.SchemaPath]);
        lNewScope.SchemaNode := lSchema;
        lNewScope.InstanceNode := lInstance[lCount];
        lNewScope.InstancePath := Format('%s/%d', [lScope.InstancePath, lCount]);
        lNewScope.CoveredItems := [];
        lNewScope.ContainsCount := 0;
        lNewScope.VisitedKeywords := [];
        lNewScope.CoveredProperties := [];

        lVisitor.PushScope(lNewScope);
        try
          lWalker := TWalker<T>.Create(lSchema, lVisitor);
          lWalker.Walk;
        finally
          lVisitor.PopScope;
        end;

        TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      end;
    end;
  finally
    lCovered.Free;
    lVisitor.UpdateScope(lScope);
  end;
end;

procedure TArrayApplicatorVisitor<T>.VisitAdditionalItems(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONArray;
  lItemsKeyword: TJSONValue;
  lCovered: TList<Integer>;
  lCount: Integer;
  lNewScope: TScope;
  lWalker: IWalker;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  // additionalItems only applies when 'items' is an array (tuple validation)
  if not (lScope.SchemaNode is TJSONObject) then
    Exit;

  if not TJSONObject(lScope.SchemaNode).TryGetValue('items', lItemsKeyword) then
    Exit;

  if not (lItemsKeyword is TJSONArray) then
    Exit;

  lInstance := TJSONArray(lScope.InstanceNode);
  lCovered := TList<Integer>.Create(lScope.CoveredItems);
  try
    for lCount := 0 to lInstance.Count - 1 do
    begin
      if lCovered.Contains(lCount) then
        Continue;

      lNewScope := lScope;
      lNewScope.SchemaPath := Format('%s/additionalItems', [lScope.SchemaPath]);
      lNewScope.SchemaNode := pValue;
      lNewScope.InstanceNode := lInstance[lCount];
      lNewScope.InstancePath := Format('%s/%d', [lScope.InstancePath, lCount]);
      lNewScope.CoveredItems := [];
      lNewScope.ContainsCount := 0;
      lNewScope.VisitedKeywords := [];
      lNewScope.CoveredProperties := [];

      lVisitor.PushScope(lNewScope);
      try
        lWalker := TWalker<T>.Create(pValue, lVisitor);
        lWalker.Walk;
      finally
        lVisitor.PopScope;
      end;

      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
    end;
  finally
    lCovered.Free;
    lVisitor.UpdateScope(lScope);
  end;
end;

procedure TArrayApplicatorVisitor<T>.VisitPrefixItems(const pValue: TJSONArray);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONArray;
  lCount: Integer;
  lMaxCount: Integer;
  lNewScope: TScope;
  lWalker: IWalker;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lInstance := TJSONArray(lScope.InstanceNode);
  lMaxCount := Min(lInstance.Count, pValue.Count);
  for lCount := 0 to lMaxCount - 1 do
  begin
    lNewScope := lScope;
    lNewScope.SchemaPath := Format('%s/prefixItems/%d', [lScope.SchemaPath, lCount]);
    lNewScope.SchemaNode := pValue[lCount];
    lNewScope.InstanceNode := lInstance[lCount];
    lNewScope.InstancePath := Format('%s/%d', [lScope.InstancePath, lCount]);
    lNewScope.CoveredItems := [];
    lNewScope.ContainsCount := 0;
    lNewScope.VisitedKeywords := [];
    lNewScope.CoveredProperties := [];

    lVisitor.PushScope(lNewScope);
    try
      lWalker := TWalker<T>.Create(pValue[lCount], lVisitor);
      lWalker.Walk;
    finally
      lVisitor.PopScope;
    end;

    TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
  end;
  lVisitor.UpdateScope(lScope);
end;

// Unsupported methods – no‑op to satisfy the interface
procedure TArrayApplicatorVisitor<T>.VisitAllOf(const pValue: TJSONArray);
begin
  // Empty – this visitor does not handle allOf
end;

procedure TArrayApplicatorVisitor<T>.VisitAnyOf(const pValue: TJSONArray);
begin
  // Empty – this visitor does not handle anyOf
end;

procedure TArrayApplicatorVisitor<T>.VisitOneOf(const pValue: TJSONArray);
begin
  // Empty – this visitor does not handle oneOf
end;

procedure TArrayApplicatorVisitor<T>.VisitNot(const pValue: TJSONValue);
begin
  // Empty – this visitor does not handle not
end;

procedure TArrayApplicatorVisitor<T>.VisitIf(const pValue: TJSONValue);
begin
  // Empty – this visitor does not handle if
end;

procedure TArrayApplicatorVisitor<T>.VisitThen(const pValue: TJSONValue);
begin
  // Empty – this visitor does not handle then
end;

procedure TArrayApplicatorVisitor<T>.VisitElse(const pValue: TJSONValue);
begin
  // Empty – this visitor does not handle else
end;

procedure TArrayApplicatorVisitor<T>.VisitProperties(const pValue: TJSONObject);
begin
  // Empty – this visitor does not handle properties
end;

procedure TArrayApplicatorVisitor<T>.VisitPatternProperties(const pValue: TJSONObject);
begin
  // Empty – this visitor does not handle patternProperties
end;

procedure TArrayApplicatorVisitor<T>.VisitAdditionalProperties(const pValue: TJSONValue);
begin
  // Empty – this visitor does not handle additionalProperties
end;

end.
