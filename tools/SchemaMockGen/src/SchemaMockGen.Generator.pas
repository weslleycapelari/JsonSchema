unit SchemaMockGen.Generator;

(*
--------------------------------------------------------------------------------
Seeded, constraint-driven mock JSON generator walking JSON Schema documents.
--------------------------------------------------------------------------------
*)

interface

uses
  System.Classes,
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  SchemaMockGen.Utils;

type
  /// <summary>
  ///   Generates mock JSON values conforming to constraints parsed from a JSON Schema.
  /// </summary>
  TSchemaMockGenerator = class
  strict private
    FRandom: TSeededRandom;
    FOwnsRandom: Boolean;

    function GenerateAny: TJSONValue;
    function GenerateNull: TJSONValue;
    function GenerateBool: TJSONValue;
    function GenerateNumber(pSchema: TJSONObject; const pForceInteger: Boolean): TJSONValue;
    function GenerateString(pSchema: TJSONObject): TJSONValue;
    function GenerateArray(pSchema: TJSONObject): TJSONValue;
    function GenerateObject(pSchema: TJSONObject): TJSONValue;
    function GenerateFromSchema(pSchema: TJSONValue): TJSONValue;
  public
    /// <summary>Creates a generator with an isolated seed.</summary>
    constructor Create(const pSeed: Int64); overload;

    /// <summary>Creates a generator sharing a pre-configured SeededRandom instance.</summary>
    constructor Create(pRandom: TSeededRandom); overload;
    destructor Destroy; override;

    /// <summary>Generates a mock JSON instance conforming to the provided JSON Schema.</summary>
    function Generate(pSchema: TJSONValue): TJSONValue;
  end;

implementation

{ TSchemaMockGenerator }

constructor TSchemaMockGenerator.Create(const pSeed: Int64);
begin
  inherited Create;
  FRandom := TSeededRandom.Create(pSeed);
  FOwnsRandom := True;
end;

constructor TSchemaMockGenerator.Create(pRandom: TSeededRandom);
begin
  inherited Create;
  FRandom := pRandom;
  FOwnsRandom := False;
end;

destructor TSchemaMockGenerator.Destroy;
begin
  if FOwnsRandom then
    FRandom.Free;
  inherited Destroy;
end;

function TSchemaMockGenerator.Generate(pSchema: TJSONValue): TJSONValue;
begin
  Result := GenerateFromSchema(pSchema);
end;

function TSchemaMockGenerator.GenerateFromSchema(pSchema: TJSONValue): TJSONValue;
var
  lSchemaObj: TJSONObject;
  lConstValue: TJSONValue;
  lEnumArray: TJSONArray;
  lAnyOfArray: TJSONArray;
  lOneOfArray: TJSONArray;
  lTypeVal: TJSONValue;
  lTypeStr: string;
  lIndex: Integer;
begin
  if not Assigned(pSchema) then
    Exit(GenerateAny);

  if pSchema is TJSONBool then
  begin
    if TJSONBool(pSchema).AsBoolean then
      Exit(GenerateAny)
    else
      Exit(GenerateNull); // False schema rejects everything; generate null as fallback
  end;

  if not (pSchema is TJSONObject) then
    Exit(GenerateAny);

  lSchemaObj := TJSONObject(pSchema);

  // --- const keyword ---
  if lSchemaObj.TryGetValue('const', lConstValue) then
    Exit(lConstValue.Clone as TJSONValue);

  // --- enum keyword ---
  if lSchemaObj.TryGetValue('enum', lEnumArray) and (lEnumArray.Count > 0) then
  begin
    lIndex := FRandom.NextInt(0, lEnumArray.Count - 1);
    Exit(lEnumArray.Items[lIndex].Clone as TJSONValue);
  end;

  // --- anyOf / oneOf keywords ---
  if lSchemaObj.TryGetValue('anyOf', lAnyOfArray) and (lAnyOfArray.Count > 0) then
  begin
    lIndex := FRandom.NextInt(0, lAnyOfArray.Count - 1);
    Exit(GenerateFromSchema(lAnyOfArray.Items[lIndex]));
  end;
  if lSchemaObj.TryGetValue('oneOf', lOneOfArray) and (lOneOfArray.Count > 0) then
  begin
    lIndex := FRandom.NextInt(0, lOneOfArray.Count - 1);
    Exit(GenerateFromSchema(lOneOfArray.Items[lIndex]));
  end;

  // --- type keyword ---
  if lSchemaObj.TryGetValue('type', lTypeVal) then
  begin
    if lTypeVal is TJSONString then
    begin
      lTypeStr := TJSONString(lTypeVal).Value;
    end else if lTypeVal is TJSONArray then
    begin
      lEnumArray := TJSONArray(lTypeVal);
      if lEnumArray.Count > 0 then
      begin
        lIndex := FRandom.NextInt(0, lEnumArray.Count - 1);
        if lEnumArray.Items[lIndex] is TJSONString then
          lTypeStr := TJSONString(lEnumArray.Items[lIndex]).Value
        else
          lTypeStr := 'string';
      end else
        lTypeStr := 'string';
    end else
      lTypeStr := 'string';
  end else
  begin
    // Heuristics if type is omitted
    if lSchemaObj.Values['properties'] <> nil then
      lTypeStr := 'object'
    else if (lSchemaObj.Values['items'] <> nil) or (lSchemaObj.Values['prefixItems'] <> nil) then
      lTypeStr := 'array'
    else if (lSchemaObj.Values['minimum'] <> nil) or (lSchemaObj.Values['maximum'] <> nil) then
      lTypeStr := 'number'
    else if (lSchemaObj.Values['minLength'] <> nil) or (lSchemaObj.Values['maxLength'] <> nil) then
      lTypeStr := 'string'
    else
    begin
      // Pick one type randomly
      case FRandom.NextInt(1, 6) of
        1: lTypeStr := 'null';
        2: lTypeStr := 'boolean';
        3: lTypeStr := 'integer';
        4: lTypeStr := 'string';
        5: lTypeStr := 'array';
        6: lTypeStr := 'object';
      end;
    end;
  end;

  if SameText(lTypeStr, 'null') then
    Exit(GenerateNull)
  else if SameText(lTypeStr, 'boolean') then
    Exit(GenerateBool)
  else if SameText(lTypeStr, 'integer') then
    Exit(GenerateNumber(lSchemaObj, True))
  else if SameText(lTypeStr, 'number') then
    Exit(GenerateNumber(lSchemaObj, False))
  else if SameText(lTypeStr, 'string') then
    Exit(GenerateString(lSchemaObj))
  else if SameText(lTypeStr, 'array') then
    Exit(GenerateArray(lSchemaObj))
  else if SameText(lTypeStr, 'object') then
    Exit(GenerateObject(lSchemaObj))
  else
    Exit(GenerateAny);
end;

function TSchemaMockGenerator.GenerateAny: TJSONValue;
begin
  case FRandom.NextInt(1, 4) of
    1: Result := GenerateNull;
    2: Result := GenerateBool;
    3: Result := TJSONNumber.Create(FRandom.NextInt(1, 100));
    4: Result := TJSONString.Create('mock_data');
  else
    Result := GenerateNull;
  end;
end;

function TSchemaMockGenerator.GenerateNull: TJSONValue;
begin
  Result := TJSONNull.Create;
end;

function TSchemaMockGenerator.GenerateBool: TJSONValue;
begin
  Result := TJSONBool.Create(FRandom.NextBool);
end;

function TSchemaMockGenerator.GenerateNumber(pSchema: TJSONObject; const pForceInteger: Boolean): TJSONValue;
var
  lMinVal, lMaxVal: TJSONValue;
  lMin, lMax: Double;
  lIntMin, lIntMax: Integer;
  lExclusiveMin, lExclusiveMax: Boolean;
  lMultipleVal: TJSONValue;
  lMultiple: Double;
  lVal: Double;
  lIntVal: Integer;
begin
  lExclusiveMin := False;
  lExclusiveMax := False;

  // Extract boundaries
  if pSchema.TryGetValue('exclusiveMinimum', lMinVal) then
  begin
    if lMinVal is TJSONBool then
    begin
      lExclusiveMin := TJSONBool(lMinVal).AsBoolean;
      if pSchema.TryGetValue('minimum', lMinVal) then
        lMin := (lMinVal as TJSONNumber).AsDouble
      else
        lMin := 0.0;
    end else if lMinVal is TJSONNumber then
    begin
      lMin := (lMinVal as TJSONNumber).AsDouble;
      lExclusiveMin := True;
    end else
      lMin := 0.0;
  end else if pSchema.TryGetValue('minimum', lMinVal) then
  begin
    lMin := (lMinVal as TJSONNumber).AsDouble;
  end else
    lMin := 0.0;

  if pSchema.TryGetValue('exclusiveMaximum', lMaxVal) then
  begin
    if lMaxVal is TJSONBool then
    begin
      lExclusiveMax := TJSONBool(lMaxVal).AsBoolean;
      if pSchema.TryGetValue('maximum', lMaxVal) then
        lMax := (lMaxVal as TJSONNumber).AsDouble
      else
        lMax := 100.0;
    end else if lMaxVal is TJSONNumber then
    begin
      lMax := (lMaxVal as TJSONNumber).AsDouble;
      lExclusiveMax := True;
    end else
      lMax := 100.0;
  end else if pSchema.TryGetValue('maximum', lMaxVal) then
  begin
    lMax := (lMaxVal as TJSONNumber).AsDouble;
  end else
    lMax := 100.0;

  if lMin > lMax then
    lMax := lMin + 10.0;

  if pForceInteger then
  begin
    lIntMin := Trunc(lMin);
    if lExclusiveMin and (Frac(lMin) = 0.0) then
      Inc(lIntMin);
    lIntMax := Trunc(lMax);
    if lExclusiveMax and (Frac(lMax) = 0.0) then
      Dec(lIntMax);

    if lIntMin > lIntMax then
      lIntMax := lIntMin;

    if pSchema.TryGetValue('multipleOf', lMultipleVal) then
    begin
      lMultiple := (lMultipleVal as TJSONNumber).AsDouble;
      if lMultiple > 0 then
      begin
        // Pick integer multiples in range
        lIntMin := Trunc(lIntMin / lMultiple);
        lIntMax := Trunc(lIntMax / lMultiple);
        if lIntMin > lIntMax then
          lIntMax := lIntMin;
        lIntVal := FRandom.NextInt(lIntMin, lIntMax) * Trunc(lMultiple);
        Exit(TJSONNumber.Create(lIntVal));
      end;
    end;

    Result := TJSONNumber.Create(FRandom.NextInt(lIntMin, lIntMax));
  end else
  begin
    lVal := lMin + FRandom.NextDouble * (lMax - lMin);
    Result := TJSONNumber.Create(lVal);
  end;
end;

function TSchemaMockGenerator.GenerateString(pSchema: TJSONObject): TJSONValue;
var
  lFormatVal: TJSONValue;
  lFormatStr: string;
  lMinLenVal, lMaxLenVal: TJSONValue;
  lMinLen, lMaxLen, lLen: Integer;
  lAlphabet: string;
  lSB: TStringBuilder;
  lI: Integer;
begin
  if pSchema.TryGetValue('format', lFormatVal) and (lFormatVal is TJSONString) then
  begin
    lFormatStr := TJSONString(lFormatVal).Value;
    if SameText(lFormatStr, 'date-time') then
      Exit(TJSONString.Create('2026-06-05T10:00:00Z'))
    else if SameText(lFormatStr, 'email') then
      Exit(TJSONString.Create(Format('mockuser%d@example.com', [FRandom.NextInt(100, 999)])))
    else if SameText(lFormatStr, 'uuid') then
      Exit(TJSONString.Create('123e4567-e89b-12d3-a456-426614174000'))
    else if SameText(lFormatStr, 'ipv4') then
      Exit(TJSONString.Create(Format('192.168.%d.%d', [FRandom.NextInt(1, 254), FRandom.NextInt(1, 254)])))
    else if SameText(lFormatStr, 'ipv6') then
      Exit(TJSONString.Create('2001:db8:85a3:0:0:8a2e:370:7334'));
  end;

  lMinLen := 0;
  if pSchema.TryGetValue('minLength', lMinLenVal) then
    lMinLen := (lMinLenVal as TJSONNumber).AsInt;

  lMaxLen := 20;
  if pSchema.TryGetValue('maxLength', lMaxLenVal) then
    lMaxLen := (lMaxLenVal as TJSONNumber).AsInt;

  if lMinLen > lMaxLen then
    lMaxLen := lMinLen + 10;

  lLen := FRandom.NextInt(lMinLen, lMaxLen);
  lAlphabet := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  lSB := TStringBuilder.Create;
  try
    for lI := 1 to lLen do
      lSB.Append(FRandom.NextChar(lAlphabet));
    Result := TJSONString.Create(lSB.ToString);
  finally
    lSB.Free;
  end;
end;

function TSchemaMockGenerator.GenerateArray(pSchema: TJSONObject): TJSONValue;
var
  lMinVal, lMaxVal: TJSONValue;
  lMin, lMax, lCount: Integer;
  lArray: TJSONArray;
  lItemsVal: TJSONValue;
  lPrefixItemsVal: TJSONValue;
  lPrefixArray: TJSONArray;
  lI: Integer;
begin
  lMin := 0;
  if pSchema.TryGetValue('minItems', lMinVal) then
    lMin := (lMinVal as TJSONNumber).AsInt;

  lMax := 5;
  if pSchema.TryGetValue('maxItems', lMaxVal) then
    lMax := (lMaxVal as TJSONNumber).AsInt;

  if lMin > lMax then
    lMax := lMin + 3;

  lCount := FRandom.NextInt(lMin, lMax);
  lArray := TJSONArray.Create;

  if pSchema.TryGetValue('prefixItems', lPrefixItemsVal) and (lPrefixItemsVal is TJSONArray) then
  begin
    lPrefixArray := TJSONArray(lPrefixItemsVal);
    for lI := 0 to lCount - 1 do
    begin
      if lI < lPrefixArray.Count then
        lArray.AddElement(GenerateFromSchema(lPrefixArray.Items[lI]))
      else if pSchema.TryGetValue('items', lItemsVal) then
        lArray.AddElement(GenerateFromSchema(lItemsVal))
      else
        lArray.AddElement(GenerateAny);
    end;
    Exit(lArray);
  end;

  if pSchema.TryGetValue('items', lItemsVal) then
  begin
    if lItemsVal is TJSONArray then
    begin
      // Draft 6/7 tuple items array
      lPrefixArray := TJSONArray(lItemsVal);
      for lI := 0 to lCount - 1 do
      begin
        if lI < lPrefixArray.Count then
          lArray.AddElement(GenerateFromSchema(lPrefixArray.Items[lI]))
        else
          lArray.AddElement(GenerateAny);
      end;
    end else
    begin
      // Single item schema
      for lI := 1 to lCount do
        lArray.AddElement(GenerateFromSchema(lItemsVal));
    end;
  end else
  begin
    for lI := 1 to lCount do
      lArray.AddElement(GenerateAny);
  end;

  Result := lArray;
end;

function TSchemaMockGenerator.GenerateObject(pSchema: TJSONObject): TJSONValue;
var
  lObj: TJSONObject;
  lPropsVal, lReqVal: TJSONValue;
  lPropsObj: TJSONObject;
  lReqArray: TJSONArray;
  lPropName: string;
  lPropSchema: TJSONValue;
  lI: Integer;
  lPair: TJSONPair;
begin
  lObj := TJSONObject.Create;

  lPropsObj := nil;
  if pSchema.TryGetValue('properties', lPropsVal) and (lPropsVal is TJSONObject) then
    lPropsObj := TJSONObject(lPropsVal);

  // Generate required properties
  if pSchema.TryGetValue('required', lReqVal) and (lReqVal is TJSONArray) then
  begin
    lReqArray := TJSONArray(lReqVal);
    for lI := 0 to lReqArray.Count - 1 do
    begin
      lPropName := lReqArray.Items[lI].Value;
      lPropSchema := nil;
      if Assigned(lPropsObj) then
        lPropSchema := lPropsObj.Values[lPropName];

      lObj.AddPair(lPropName, GenerateFromSchema(lPropSchema));
    end;
  end;

  // Optionally generate optional properties
  if Assigned(lPropsObj) then
  begin
    for lI := 0 to lPropsObj.Count - 1 do
    begin
      lPair := lPropsObj.Pairs[lI];
      lPropName := lPair.JsonString.Value;

      // Skip if already generated as required
      if lObj.Values[lPropName] = nil then
      begin
        // 50% chance to generate optional property
        if FRandom.NextBool then
          lObj.AddPair(lPropName, GenerateFromSchema(lPair.JsonValue));
      end;
    end;
  end;

  Result := lObj;
end;

end.
