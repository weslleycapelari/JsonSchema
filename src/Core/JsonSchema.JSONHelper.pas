unit JsonSchema.JSONHelper;

(*
--------------------------------------------------------------------------------
Provides a class helper for TJSONValue to simplify secure type checks.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.Generics.Collections;

type
  /// <summary>Class helper extending TJSONValue with schema type validation helper methods.</summary>
  TJsonSchemaValueHelper = class helper for TJSONValue
  public
    /// <summary>Checks safely if the JSON value is a string. Excludes numbers explicitly.</summary>
    function IsJSONString: Boolean;

    /// <summary>Checks if the JSON value is a number.</summary>
    function IsJSONNumber: Boolean;

    /// <summary>Checks if the JSON value is an integer (number with no fractional part).</summary>
    function IsJSONInteger: Boolean;

    /// <summary>Checks if the JSON value is a boolean.</summary>
    function IsJSONBoolean: Boolean;

    /// <summary>Checks if the JSON value is null.</summary>
    function IsJSONNull: Boolean;

    /// <summary>Checks if the JSON value is a JSON array.</summary>
    function IsJSONArray: Boolean;

    /// <summary>Checks if the JSON value is a JSON object.</summary>
    function IsJSONObject: Boolean;

    /// <summary>Returns the string representation of the JSON type (e.g., 'string', 'number').</summary>
    function GetJSONType: string;

    /// <summary>Performs a recursive deep equality check between this JSON value and another.</summary>
    function DeepEquals(const pOther: TJSONValue): Boolean;
  end;

implementation

{ TJsonSchemaValueHelper }

function TJsonSchemaValueHelper.IsJSONString: Boolean;
begin
  // Based on System.JSON hierarchy: TJSONNumber inherits from TJSONString.
  // We explicitly check that it is not a TJSONNumber to ensure correct string validation.
  Result := (Self <> nil) and (Self is TJSONString) and not (Self is TJSONNumber);
end;

function TJsonSchemaValueHelper.IsJSONNumber: Boolean;
begin
  Result := (Self <> nil) and (Self is TJSONNumber);
end;

function TJsonSchemaValueHelper.IsJSONInteger: Boolean;
begin
  Result := (Self <> nil) and (Self is TJSONNumber) and (Frac(TJSONNumber(Self).AsDouble) = 0);
end;

function TJsonSchemaValueHelper.IsJSONBoolean: Boolean;
begin
  // Based on System.JSON hierarchy: TJSONTrue and TJSONFalse inherit from TJSONBool.
  // Checking "is TJSONBool" is sufficient to match all JSON boolean instances.
  Result := (Self <> nil) and (Self is TJSONBool);
end;

function TJsonSchemaValueHelper.IsJSONNull: Boolean;
begin
  Result := (Self <> nil) and (Self is TJSONNull);
end;

function TJsonSchemaValueHelper.IsJSONArray: Boolean;
begin
  Result := (Self <> nil) and (Self is TJSONArray);
end;

function TJsonSchemaValueHelper.IsJSONObject: Boolean;
begin
  Result := (Self <> nil) and (Self is TJSONObject);
end;

function TJsonSchemaValueHelper.GetJSONType: string;
begin
  if Self = nil then
    Result := 'null'
  else if IsJSONNumber then
    Result := 'number'
  else if IsJSONString then
    Result := 'string'
  else if IsJSONBoolean then
    Result := 'boolean'
  else if IsJSONNull then
    Result := 'null'
  else if IsJSONArray then
    Result := 'array'
  else if IsJSONObject then
    Result := 'object'
  else
    Result := 'unknown';
end;

function TJsonSchemaValueHelper.DeepEquals(const pOther: TJSONValue): Boolean;
var
  lIndex: Integer;
  lResult: Boolean;
  lPair: TJSONPair;
  lOtherVal: TJSONValue;
begin
  if (Self = nil) and (pOther = nil) then
    Exit(True);

  if (Self = nil) or (pOther = nil) then
    Exit(False);

  // Check type equality
  if Self.IsJSONNumber <> pOther.IsJSONNumber then
    Exit(False);
  if Self.IsJSONString <> pOther.IsJSONString then
    Exit(False);
  if Self.IsJSONBoolean <> pOther.IsJSONBoolean then
    Exit(False);
  if Self.IsJSONNull <> pOther.IsJSONNull then
    Exit(False);
  if Self.IsJSONArray <> pOther.IsJSONArray then
    Exit(False);
  if Self.IsJSONObject <> pOther.IsJSONObject then
    Exit(False);

  // Compare values depending on actual types
  if Self.IsJSONNumber then
    Exit(TJSONNumber(Self).AsDouble = TJSONNumber(pOther).AsDouble);

  if Self.IsJSONString then
    Exit(TJSONString(Self).Value = TJSONString(pOther).Value);

  if Self.IsJSONBoolean then
    Exit(TJSONBool(Self).AsBoolean = TJSONBool(pOther).AsBoolean);

  if Self.IsJSONNull then
    Exit(True);

  if Self.IsJSONArray then
  begin
    if TJSONArray(Self).Count <> TJSONArray(pOther).Count then
      Exit(False);

    lResult := True;
    lIndex := 0;
    while lResult and (lIndex < TJSONArray(Self).Count) do
    begin
      lResult := TJSONArray(Self).Items[lIndex].DeepEquals(TJSONArray(pOther).Items[lIndex]);
      Inc(lIndex);
    end;
    Exit(lResult);
  end;

  if Self.IsJSONObject then
  begin
    if TJSONObject(Self).Count <> TJSONObject(pOther).Count then
      Exit(False);

    lResult := True;
    lIndex := 0;
    while lResult and (lIndex < TJSONObject(Self).Count) do
    begin
      lPair := TJSONObject(Self).Pairs[lIndex];
      lOtherVal := TJSONObject(pOther).Values[lPair.JsonString.Value];
      if lOtherVal = nil then
        lResult := False
      else
        lResult := lPair.JsonValue.DeepEquals(lOtherVal);
      Inc(lIndex);
    end;
    Exit(lResult);
  end;

  Result := False;
end;

end.
