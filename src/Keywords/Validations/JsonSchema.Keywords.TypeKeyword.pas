unit JsonSchema.Keywords.TypeKeyword;

interface

uses
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Validates whether the primitive JSON type of the instance matches the expected schema type(s).</summary>
  TTypeKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FExpectedTypes: TArray<string>;
  private
    function GetKeywordName: string;
    function GetActualType(const pInstance: TJSONValue): string;
    function MatchesType(const pInstance: TJSONValue): Boolean;
  public
    /// <summary>Initializes the validator with a single expected primitive JSON type.</summary>
    constructor Create(const pExpectedType: string); overload;

    /// <summary>Initializes the validator with multiple expected primitive JSON types.</summary>
    constructor Create(const pExpectedTypes: TArray<string>); overload;

    /// <summary>Validates the type of the JSON instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('type').</summary>
    property KeywordName: string read GetKeywordName;

    /// <summary>List of expected types for this keyword.</summary>
    property ExpectedTypes: TArray<string> read FExpectedTypes;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTypeKeyword }

class function TTypeKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
var
  lTypes: TArray<string>;
  lArr: TJSONArray;
  lIdx: Integer;
begin
  if pKeywordValue is TJSONArray then
  begin
    lTypes := [];
    lArr := TJSONArray(pKeywordValue);
    lIdx := 0;
    while lIdx < lArr.Count do
    begin
      SetLength(lTypes, Length(lTypes) + 1);
      lTypes[High(lTypes)] := lArr.Items[lIdx].Value;
      Inc(lIdx);
    end;
    Result := TTypeKeyword.Create(lTypes);
  end else
  begin
    Result := TTypeKeyword.Create(TJSONString(pKeywordValue).Value);
  end;
end;

constructor TTypeKeyword.Create(const pExpectedType: string);
begin
  inherited Create;
  FExpectedTypes := [pExpectedType];
end;

constructor TTypeKeyword.Create(const pExpectedTypes: TArray<string>);
begin
  inherited Create;
  FExpectedTypes := pExpectedTypes;
end;

function TTypeKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_TYPE;
end;

function TTypeKeyword.GetActualType(const pInstance: TJSONValue): string;
begin
  Result := pInstance.GetJSONType;
end;

function TTypeKeyword.MatchesType(const pInstance: TJSONValue): Boolean;
var
  lExpected: string;
  lMatch: Boolean;
  lIndex: Integer;
begin
  lMatch := False;
  lIndex := 0;

  while (not lMatch) and (lIndex < Length(FExpectedTypes)) do
  begin
    lExpected := FExpectedTypes[lIndex];

    if pInstance = nil then
    begin
      lMatch := (lExpected = 'null');
    end else if lExpected = 'number' then
    begin
      lMatch := pInstance.IsJSONNumber;
    end else if lExpected = 'integer' then
    begin
      lMatch := pInstance.IsJSONInteger;
    end else if lExpected = 'string' then
    begin
      lMatch := pInstance.IsJSONString;
    end else if lExpected = 'boolean' then
    begin
      lMatch := pInstance.IsJSONBoolean;
    end else if lExpected = 'null' then
    begin
      lMatch := pInstance.IsJSONNull;
    end else if lExpected = 'array' then
    begin
      lMatch := pInstance.IsJSONArray;
    end else if lExpected = 'object' then
    begin
      lMatch := pInstance.IsJSONObject;
    end;

    Inc(lIndex);
  end;

  Result := lMatch;
end;

function TTypeKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lContext: TJSONObject;
  lExpectedArray: TJSONArray;
  lIndex: Integer;
begin
  if MatchesType(pInstance) then
  begin
    Result := TValidationResult.ValidResult;
  end else
  begin
    lContext := TJSONObject.Create;
    try
      if Length(FExpectedTypes) = 1 then
      begin
        lContext.AddPair('expected', FExpectedTypes[0]);
      end else
      begin
        lExpectedArray := TJSONArray.Create;
        lIndex := 0;
        while lIndex < Length(FExpectedTypes) do
        begin
          lExpectedArray.Add(FExpectedTypes[lIndex]);
          Inc(lIndex);
        end;
        lContext.AddPair('expected', lExpectedArray);
      end;

      lContext.AddPair('actual', GetActualType(pInstance));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
