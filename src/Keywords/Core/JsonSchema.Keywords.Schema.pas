unit JsonSchema.Keywords.Schema;

(*
--------------------------------------------------------------------------------
Implements the validation rule/metadata for the '$schema' core keyword.
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
  /// <summary>Validates and stores the '$schema' meta-schema declaration.</summary>
  TSchemaKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FSchemaURI: string;
    function GetKeywordName: string;
  public
    /// <summary>Initializes schema keyword with target meta-schema URI.</summary>
    constructor Create(const pSchemaURI: string);

    /// <summary>Always returns valid, as '$schema' acts as metadata rather than an instance constraint.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a schema keyword validator from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('$schema').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TSchemaKeyword }

constructor TSchemaKeyword.Create(const pSchemaURI: string);
begin
  inherited Create;
  FSchemaURI := pSchemaURI;
end;

class function TSchemaKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
    Result := TSchemaKeyword.Create(pKeywordValue.Value)
  else
    Result := TSchemaKeyword.Create('');
end;

function TSchemaKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_SCHEMA;
end;

function TSchemaKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.ValidResult;
end;

end.
