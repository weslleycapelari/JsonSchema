unit JsonSchema.Visitor.Validation.Numeric;

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
  JsonSchema.Common.Utils;

type
  /// <summary>
  ///   Visitor for numeric validation keywords: multipleOf, maximum, exclusiveMaximum,
  ///   minimum, exclusiveMinimum.
  ///   This class is meant to be composed into a full validation visitor.
  /// </summary>
  TNumericValidationVisitor<T: IValidationVisitor<T>> = class(TBase<T>, INumericValidationVisitor<T>)
  private
    function GetValidationVisitor: IValidationVisitor<T>;
    function GetSilentMode: Boolean;
    function IsNumericInstance(const pInstance: TJSONValue): Boolean;
  public
    [VisitorKeyword('multipleOf')]
    procedure VisitMultipleOf(const pValue: TJSONNumber);

    [VisitorKeyword('maximum')]
    procedure VisitMaximum(const pValue: TJSONNumber);

    [VisitorKeyword('exclusiveMaximum')]
    procedure VisitExclusiveMaximum(const pValue: TJSONValue);

    [VisitorKeyword('minimum')]
    procedure VisitMinimum(const pValue: TJSONNumber);

    [VisitorKeyword('exclusiveMinimum')]
    procedure VisitExclusiveMinimum(const pValue: TJSONValue);

  end;

implementation

uses
  System.SysUtils,
  System.Math;

{ TNumericValidationVisitor<T> }

function TNumericValidationVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

function TNumericValidationVisitor<T>.GetSilentMode: Boolean;
var
  lMode: IDraft2019_09ValidationVocabularyMode;
begin
  Result := False;
  if Supports(Visitor, IDraft2019_09ValidationVocabularyMode, lMode) then
    Result := lMode.IsValidationVocabularySilent;
end;

function TNumericValidationVisitor<T>.IsNumericInstance(const pInstance: TJSONValue): Boolean;
var
  lType: string;
begin
  lType := TUtils.JsonGetType(pInstance);
  Result := (lType = 'number') or (lType = 'integer');
end;

procedure TNumericValidationVisitor<T>.VisitMultipleOf(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lValue: Extended;
  lDivisor: Extended;
  lDivision: Extended;
  lRounded: Extended;
  lEpsilon: Extended;
  lInverse: Extended;
  lInverseRounded: Extended;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if GetSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not IsNumericInstance(lScope.InstanceNode) then
    Exit;

  lValue := TUtils.JsonGetFloat(lScope.InstanceNode);
  lDivisor := TUtils.JsonGetFloat(pValue);
  if lDivisor = 0 then
    Exit;

  // For integers, also check 1/divisor is integer to avoid floating overflow
  if TUtils.JsonGetType(lScope.InstanceNode) = 'integer' then
  begin
    lInverse := 1 / lDivisor;
    lInverseRounded := Round(lInverse);
    if Abs(lInverse - lInverseRounded) <= 1E-12 then
      Exit;
  end;

  if Abs(lValue) < 1E-15 then
    Exit;

  lDivision := lValue / lDivisor;
  if IsInfinite(lDivision) or IsNan(lDivision) then
  begin
    lVisitor.AddError(TErrorType.vetMultipleOf, [pValue.Value]);
    Exit;
  end;

  lRounded := Round(lDivision);
  if Abs(lValue) < 1E-15 then
    lEpsilon := Max(1E-30, Abs(lDivisor) * 1E-12)
  else
    lEpsilon := Max(1E-12, Abs(lDivision) * 1E-12);

  if Abs(lDivision - lRounded) > lEpsilon then
    lVisitor.AddError(TErrorType.vetMultipleOf, [pValue.Value]);
end;

procedure TNumericValidationVisitor<T>.VisitMaximum(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMax: Extended;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if GetSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not IsNumericInstance(lScope.InstanceNode) then
    Exit;

  lMax := TUtils.JsonGetFloat(pValue);
  if TUtils.JsonGetFloat(lScope.InstanceNode) > lMax then
    lVisitor.AddError(TErrorType.vetMaximum, [lMax.ToString]);
end;

procedure TNumericValidationVisitor<T>.VisitExclusiveMaximum(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lLimitValue: Extended;
  lIsExclusive: Boolean;
  lLimitSchema: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if GetSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not IsNumericInstance(lScope.InstanceNode) then
    Exit;

  if pValue is TJSONNumber then
  begin
    lLimitValue := TUtils.JsonGetFloat(pValue);
    lIsExclusive := True;
  end
  else if pValue is TJSONBool then
  begin
    lIsExclusive := TJSONBool(pValue).AsBoolean;
    if not lIsExclusive then
      Exit;

    if not ((lScope.SchemaNode is TJSONObject) and
            TJSONObject(lScope.SchemaNode).TryGetValue('maximum', lLimitSchema) and
            (lLimitSchema is TJSONNumber)) then
      Exit;

    lLimitValue := TUtils.JsonGetFloat(lLimitSchema);
  end
  else
    Exit;

  if lIsExclusive and (TUtils.JsonGetFloat(lScope.InstanceNode) >= lLimitValue) then
    lVisitor.AddError(TErrorType.vetExclusiveMaximum, [lLimitValue.ToString]);
end;

procedure TNumericValidationVisitor<T>.VisitMinimum(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMin: Extended;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if GetSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not IsNumericInstance(lScope.InstanceNode) then
    Exit;

  lMin := TUtils.JsonGetFloat(pValue);
  if TUtils.JsonGetFloat(lScope.InstanceNode) < lMin then
    lVisitor.AddError(TErrorType.vetMinimum, [lMin.ToString]);
end;

procedure TNumericValidationVisitor<T>.VisitExclusiveMinimum(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lLimitValue: Extended;
  lIsExclusive: Boolean;
  lLimitSchema: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if GetSilentMode then
    Exit;

  lScope := lVisitor.CurrentScope;
  if not IsNumericInstance(lScope.InstanceNode) then
    Exit;

  if pValue is TJSONNumber then
  begin
    lLimitValue := TUtils.JsonGetFloat(pValue);
    lIsExclusive := True;
  end
  else if pValue is TJSONBool then
  begin
    lIsExclusive := TJSONBool(pValue).AsBoolean;
    if not lIsExclusive then
      Exit;

    if not ((lScope.SchemaNode is TJSONObject) and
            TJSONObject(lScope.SchemaNode).TryGetValue('minimum', lLimitSchema) and
            (lLimitSchema is TJSONNumber)) then
      Exit;

    lLimitValue := TUtils.JsonGetFloat(lLimitSchema);
  end
  else
    Exit;

  if lIsExclusive and (TUtils.JsonGetFloat(lScope.InstanceNode) <= lLimitValue) then
    lVisitor.AddError(TErrorType.vetExclusiveMinimum, [lLimitValue.ToString]);
end;



end.
