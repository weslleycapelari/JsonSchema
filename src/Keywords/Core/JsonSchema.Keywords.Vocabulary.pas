unit JsonSchema.Keywords.Vocabulary;

(*
--------------------------------------------------------------------------------
Implements the '$vocabulary' core keyword (validation no-op).
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
  /// <summary>Vocabulary selection core keyword. Ignored at instance validation time.</summary>
  TVocabularyKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    function GetKeywordName: string;
  public
    /// <summary>Always returns success since vocabulary does not validate instances.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('$vocabulary').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TVocabularyKeyword }

class function TVocabularyKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TVocabularyKeyword.Create;
end;

function TVocabularyKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_VOCABULARY;
end;

function TVocabularyKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.ValidResult;
end;

end.
