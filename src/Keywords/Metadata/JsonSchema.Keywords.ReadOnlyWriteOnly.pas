unit JsonSchema.Keywords.ReadOnlyWriteOnly;

(*
--------------------------------------------------------------------------------
Implements the 'readOnly' and 'writeOnly' metadata keywords (validation no-op).
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
  /// <summary>Metadata keywords for readOnly/writeOnly properties. Ignored at validation time.</summary>
  TReadOnlyWriteOnlyKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FKeywordName: string;
    function GetKeywordName: string;
  public
    /// <summary>Initializes readOnly or writeOnly validator.</summary>
    constructor Create(const pKeywordName: string);

    /// <summary>Always returns success since readOnly/writeOnly are non-validating annotations.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a readOnly keyword validator instance.</summary>
    class function CreateReadOnlyKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Creates a writeOnly keyword validator instance.</summary>
    class function CreateWriteOnlyKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator.</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TReadOnlyWriteOnlyKeyword }

constructor TReadOnlyWriteOnlyKeyword.Create(const pKeywordName: string);
begin
  inherited Create;
  FKeywordName := pKeywordName;
end;

class function TReadOnlyWriteOnlyKeyword.CreateReadOnlyKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TReadOnlyWriteOnlyKeyword.Create(KEYWORD_READONLY);
end;

class function TReadOnlyWriteOnlyKeyword.CreateWriteOnlyKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TReadOnlyWriteOnlyKeyword.Create(KEYWORD_WRITEONLY);
end;

function TReadOnlyWriteOnlyKeyword.GetKeywordName: string;
begin
  Result := FKeywordName;
end;

function TReadOnlyWriteOnlyKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.ValidResult;
end;

end.
