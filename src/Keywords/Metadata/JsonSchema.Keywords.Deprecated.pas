unit JsonSchema.Keywords.Deprecated;

(*
--------------------------------------------------------------------------------
Implements the 'deprecated' metadata keyword (validation no-op).
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
  /// <summary>Metadata keyword flagging deprecated properties. Ignored at validation time.</summary>
  TDeprecatedKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    function GetKeywordName: string;
  public
    /// <summary>Always returns success since deprecated is a non-validating annotation.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('deprecated').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TDeprecatedKeyword }

class function TDeprecatedKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TDeprecatedKeyword.Create;
end;

function TDeprecatedKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_DEPRECATED;
end;

function TDeprecatedKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.ValidResult;
end;

end.
