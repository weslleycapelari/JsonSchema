unit JsonSchema.Keywords.Description;

(*
--------------------------------------------------------------------------------
Implements the 'description' metadata keyword.
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
  /// <summary>Stores the 'description' metadata.</summary>
  TDescriptionKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FDescription: string;
    function GetKeywordName: string;
  public
    /// <summary>Initializes description keyword with the defined string.</summary>
    constructor Create(const pDescription: string);

    /// <summary>Always returns valid, as 'description' acts as metadata rather than an instance constraint.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a description keyword from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('description').</summary>
    property KeywordName: string read GetKeywordName;

    /// <summary>Description string value.</summary>
    property Description: string read FDescription;
  end;

implementation

{ TDescriptionKeyword }

constructor TDescriptionKeyword.Create(const pDescription: string);
begin
  inherited Create;
  FDescription := pDescription;
end;

class function TDescriptionKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
    Result := TDescriptionKeyword.Create(pKeywordValue.Value)
  else
    Result := TDescriptionKeyword.Create('');
end;

function TDescriptionKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_DESCRIPTION;
end;

function TDescriptionKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.ValidResult;
end;

end.
