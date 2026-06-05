unit JSON2Schema.Engine;

(*
--------------------------------------------------------------------------------
JSON2Schema Engine - Infers JSON Schema from arbitrary JSON instances.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.RegularExpressions, System.Generics.Collections;

type
  /// <summary>Options configuration for the JSON Schema inference engine.</summary>
  TJSON2SchemaOptions = record
    Draft: string;
    InferFormats: Boolean;
    MakeRequired: Boolean;
  end;

  /// <summary>Engine class for generating JSON Schema from JSON instances.</summary>
  TJSON2SchemaGenerator = class
  private
    FOptions: TJSON2SchemaOptions;

    function InferValue(pValue: TJSONValue): TJSONObject;
    function InferObject(pObj: TJSONObject): TJSONObject;
    function InferArray(pArr: TJSONArray): TJSONObject;
    function DetectStringFormat(const pValue: string): string;
  public
    constructor Create;

    /// <summary>Generates the complete JSON Schema document for a given JSON value.</summary>
    function GenerateSchema(pInstance: TJSONValue): TJSONObject;

    property Options: TJSON2SchemaOptions read FOptions write FOptions;
  end;

implementation

{ TJSON2SchemaGenerator }

constructor TJSON2SchemaGenerator.Create;
begin
  inherited Create;
  FOptions.Draft := 'http://json-schema.org/draft-07/schema#';
  FOptions.InferFormats := True;
  FOptions.MakeRequired := False;
end;

function TJSON2SchemaGenerator.DetectStringFormat(const pValue: string): string;
const
  // Simple format validation regexes
  REGEX_EMAIL = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  REGEX_UUID = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
  REGEX_DATE = '^\d{4}-\d{2}-\d{2}$';
  REGEX_DATETIME = '^\d{4}-\d{2}-\d{2}[Tt]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:[Zz]|[+-]\d{2}:?\d{2})?$';
begin
  Result := '';
  if not FOptions.InferFormats then
    Exit;

  if TRegEx.IsMatch(pValue, REGEX_DATETIME) then
    Result := 'date-time'
  else if TRegEx.IsMatch(pValue, REGEX_DATE) then
    Result := 'date'
  else if TRegEx.IsMatch(pValue, REGEX_EMAIL) then
    Result := 'email'
  else if TRegEx.IsMatch(pValue, REGEX_UUID) then
    Result := 'uuid';
end;

function TJSON2SchemaGenerator.InferValue(pValue: TJSONValue): TJSONObject;
var
  lSchema: TJSONObject;
  lFormat: string;
  lRawValue: string;
begin
  lSchema := TJSONObject.Create;

  if pValue is TJSONNull then
  begin
    lSchema.AddPair('type', 'null');
  end
  else if (pValue is TJSONTrue) or (pValue is TJSONFalse) then
  begin
    lSchema.AddPair('type', 'boolean');
  end;

  // Check if it's a number
  if (pValue is TJSONNumber) then
  begin
    lRawValue := pValue.Value;
    if not lRawValue.Contains('.') and not lRawValue.Contains('e') and not lRawValue.Contains('E') then
      lSchema.AddPair('type', 'integer')
    else
      lSchema.AddPair('type', 'number');
  end;

  // Check if it's a string
  if (pValue is TJSONString) then
  begin
    lSchema.AddPair('type', 'string');
    lFormat := DetectStringFormat(pValue.Value);
    if lFormat <> '' then
      lSchema.AddPair('format', lFormat);
  end;

  // Check if it's an object
  if (pValue is TJSONObject) then
  begin
    lSchema.Free;
    Exit(InferObject(pValue as TJSONObject));
  end;

  // Check if it's an array
  if (pValue is TJSONArray) then
  begin
    lSchema.Free;
    Exit(InferArray(pValue as TJSONArray));
  end;

  Result := lSchema;
end;

function TJSON2SchemaGenerator.InferObject(pObj: TJSONObject): TJSONObject;
var
  lSchema: TJSONObject;
  lProperties: TJSONObject;
  lRequired: TJSONArray;
  lPair: TJSONPair;
  lPropSchema: TJSONObject;
begin
  lSchema := TJSONObject.Create;
  lSchema.AddPair('type', 'object');

  lProperties := TJSONObject.Create;
  lRequired := TJSONArray.Create;

  for lPair in pObj do
  begin
    lPropSchema := InferValue(lPair.JsonValue);
    lProperties.AddPair(lPair.JsonString.Value, lPropSchema);

    if FOptions.MakeRequired then
      lRequired.Add(lPair.JsonString.Value);
  end;

  lSchema.AddPair('properties', lProperties);
  if (lRequired.Count > 0) then
    lSchema.AddPair('required', lRequired)
  else
    lRequired.Free;

  Result := lSchema;
end;

function TJSON2SchemaGenerator.InferArray(pArr: TJSONArray): TJSONObject;
var
  lSchema: TJSONObject;
  lItemsSchema: TJSONObject;
  lItem: TJSONValue;
  lAnyOf: TJSONArray;
  lUniqueTypes: TStringList;
  lSubSchema: TJSONObject;
  lTypeStr: string;
begin
  lSchema := TJSONObject.Create;
  lSchema.AddPair('type', 'array');

  if pArr.Count = 0 then
  begin
    lSchema.AddPair('items', TJSONObject.Create);
    Exit(lSchema);
  end;

  // Analyze item types
  lUniqueTypes := TStringList.Create;
  try
    lUniqueTypes.Sorted := True;
    lUniqueTypes.Duplicates := dupIgnore;

    for lItem in pArr do
    begin
      if lItem is TJSONNull then lUniqueTypes.Add('null')
      else if (lItem is TJSONTrue) or (lItem is TJSONFalse) then lUniqueTypes.Add('boolean')
      else if lItem is TJSONNumber then lUniqueTypes.Add('number')
      else if lItem is TJSONString then lUniqueTypes.Add('string')
      else if lItem is TJSONObject then lUniqueTypes.Add('object')
      else if lItem is TJSONArray then lUniqueTypes.Add('array');
    end;

    if lUniqueTypes.Count = 1 then
    begin
      // Homogeneous array - infer from the first element
      lItemsSchema := InferValue(pArr.Items[0]);
      lSchema.AddPair('items', lItemsSchema);
    end
    else
    begin
      // Heterogeneous array - construct "anyOf" sub-schemas
      lAnyOf := TJSONArray.Create;
      for lTypeStr in lUniqueTypes do
      begin
        lSubSchema := TJSONObject.Create;
        lSubSchema.AddPair('type', lTypeStr);
        lAnyOf.Add(lSubSchema);
      end;
      lSchema.AddPair('items', TJSONObject.Create(TJSONPair.Create('anyOf', lAnyOf)));
    end;
  finally
    lUniqueTypes.Free;
  end;

  Result := lSchema;
end;

function TJSON2SchemaGenerator.GenerateSchema(pInstance: TJSONValue): TJSONObject;
var
  lRoot: TJSONObject;
  lTemp: TJSONObject;
  lPair: TJSONPair;
begin
  if not Assigned(pInstance) then
    Exit(nil);

  lRoot := InferValue(pInstance);
  if Assigned(lRoot) then
  begin
    lTemp := TJSONObject.Create;
    lTemp.AddPair('$schema', FOptions.Draft);
    
    while lRoot.Count > 0 do
    begin
      lPair := lRoot.Pairs[0];
      lRoot.RemovePair(lPair.JsonString.Value);
      lTemp.AddPair(lPair);
    end;
    
    lRoot.Free;
    lRoot := lTemp;
  end;

  Result := lRoot;
end;

end.
