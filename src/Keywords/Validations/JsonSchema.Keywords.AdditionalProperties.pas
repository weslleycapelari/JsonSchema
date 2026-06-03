unit JsonSchema.Keywords.AdditionalProperties;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'additionalProperties' keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.RegularExpressions,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Validates object properties that are not matched by sibling 'properties' or 'patternProperties'.</summary>
  TAdditionalPropertiesKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FPropertiesKeys: TArray<string>;
    FPatternRegexes: TArray<TRegEx>;
    FAdditionalSchema: ICompiledSchema;
    function GetKeywordName: string;
  public
    /// <summary>Initializes additionalProperties by extracting sibling definitions and compiling the schema.</summary>
    constructor Create(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject; const pCompileFunc: TCompileSchemaFunc);

    /// <summary>Validates additional properties in the JSON object instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('additionalProperties').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TAdditionalPropertiesKeyword }

class function TAdditionalPropertiesKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TAdditionalPropertiesKeyword.Create(pKeywordValue, pParentSchema, pCompileFunc);
end;

constructor TAdditionalPropertiesKeyword.Create(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc);
var
  lPropVal: TJSONValue;
  lPair: TJSONPair;
begin
  inherited Create;
  FPropertiesKeys := [];
  FPatternRegexes := [];
  FAdditionalSchema := nil;

  if Assigned(pParentSchema) then
  begin
    // 1. Extract keys from sibling 'properties'
    if pParentSchema.TryGetValue('properties', lPropVal) then
    begin
      if lPropVal is TJSONObject then
      begin
        for lPair in TJSONObject(lPropVal) do
        begin
          SetLength(FPropertiesKeys, Length(FPropertiesKeys) + 1);
          FPropertiesKeys[High(FPropertiesKeys)] := lPair.JsonString.Value;
        end;
      end;
    end;

    // 2. Extract and compile regexes from sibling 'patternProperties'
    if pParentSchema.TryGetValue('patternProperties', lPropVal) then
    begin
      if lPropVal is TJSONObject then
      begin
        for lPair in TJSONObject(lPropVal) do
        begin
          SetLength(FPatternRegexes, Length(FPatternRegexes) + 1);
          FPatternRegexes[High(FPatternRegexes)] := TRegEx.Create('(*UCP)' + lPair.JsonString.Value, [roCompiled]);
        end;
      end;
    end;
  end;

  // 3. Compile the additionalProperties schema
  if Assigned(pKeywordValue) then
  begin
    FAdditionalSchema := pCompileFunc(pKeywordValue);
  end;
end;

function TAdditionalPropertiesKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_ADDITIONALPROPERTIES;
end;

function TAdditionalPropertiesKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lObj: TJSONObject;
  lPair: TJSONPair;
  lKeyName: string;
  lIsDeclared: Boolean;
  lIdx: Integer;
  lResults: TArray<IValidationResult>;
  lSubResult: IValidationResult;
  lErr: IValidationError;
  lHasFalse: Boolean;
  lCtx: TJSONObject;
begin
  if not pInstance.IsJSONObject then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lObj := TJSONObject(pInstance);
  lResults := [];

  for lPair in lObj do
  begin
    lKeyName := lPair.JsonString.Value;

    // Check if key is in 'properties'
    lIsDeclared := False;
    lIdx := 0;
    while (not lIsDeclared) and (lIdx < Length(FPropertiesKeys)) do
    begin
      if FPropertiesKeys[lIdx] = lKeyName then
      begin
        lIsDeclared := True;
      end;
      Inc(lIdx);
    end;

    // Check if key matches any regex in 'patternProperties'
    lIdx := 0;
    while (not lIsDeclared) and (lIdx < Length(FPatternRegexes)) do
    begin
      if FPatternRegexes[lIdx].IsMatch(lKeyName) then
      begin
        lIsDeclared := True;
      end;
      Inc(lIdx);
    end;

    // If key is not matched by properties or patternProperties, validate against additionalProperties
    if not lIsDeclared then
    begin
      if Assigned(FAdditionalSchema) then
      begin
        lSubResult := FAdditionalSchema.Validate(lPair.JsonValue);
        if not lSubResult.IsValid then
        begin
          lHasFalse := False;
          for lErr in lSubResult.Errors do
          begin
            if lErr.Keyword = 'false' then
            begin
              lHasFalse := True;
            end;
          end;

          if lHasFalse then
          begin
            lCtx := TJSONObject.Create;
            try
              lCtx.AddPair('propertyName', TJSONString.Create(lKeyName));
              lResults := lResults + [TValidationResult.InvalidResult(GetKeywordName, lCtx)];
            finally
              lCtx.Free;
            end;
          end else
          begin
            lResults := lResults + [lSubResult];
          end;
        end;
      end;
    end;
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
