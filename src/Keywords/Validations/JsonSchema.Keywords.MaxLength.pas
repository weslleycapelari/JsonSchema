unit JsonSchema.Keywords.MaxLength;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'maxLength' keyword under Draft 6.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Validates whether the length of a JSON string meets the maximum length requirements.</summary>
  TMaxLengthKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FMaxLength: Integer;
    function GetKeywordName: string;
  public
    /// <summary>Initializes the validator with the specified maximum length.</summary>
    /// <param name="pMaxLength">The maximum character length allowed for string values.</param>
    constructor Create(const pMaxLength: Integer);

    /// <summary>Validates the length of the JSON string instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('maxLength').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TMaxLengthKeyword }

class function TMaxLengthKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TMaxLengthKeyword.Create(Round(TJSONNumber(pKeywordValue).AsDouble));
end;

constructor TMaxLengthKeyword.Create(const pMaxLength: Integer);
begin
  inherited Create;
  FMaxLength := pMaxLength;
end;

function TMaxLengthKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_MAXLENGTH;
end;

function TMaxLengthKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
  function GetCodePointCount(const S: string): Integer;
  var
    i: Integer;
  begin
    Result := 0;
    i := 1;
    while i <= Length(S) do
    begin
      Inc(Result);
      if (S[i] >= #$D800) and (S[i] <= #$DBFF) and (i < Length(S)) and (S[i+1] >= #$DC00) and (S[i+1] <= #$DFFF) then
      begin
        Inc(i, 2);
      end else
      begin
        Inc(i);
      end;
    end;
  end;
var
  lValue: string;
  lLength: Integer;
  lContext: TJSONObject;
begin
  // maxLength validation only applies to JSON strings. Other types are ignored (valid).
  if not pInstance.IsJSONString then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lValue := TJSONString(pInstance).Value;
  lLength := GetCodePointCount(lValue);

  if lLength <= FMaxLength then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('limit', TJSONNumber.Create(FMaxLength));
      lContext.AddPair('actual', TJSONNumber.Create(lLength));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
