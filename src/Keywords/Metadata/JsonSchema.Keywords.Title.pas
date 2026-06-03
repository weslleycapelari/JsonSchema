unit JsonSchema.Keywords.Title;

(*
--------------------------------------------------------------------------------
Implements the 'title' metadata keyword.
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
  /// <summary>Stores the 'title' metadata.</summary>
  TTitleKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FTitle: string;
    function GetKeywordName: string;
  public
    /// <summary>Initializes title keyword with the defined string.</summary>
    constructor Create(const pTitle: string);

    /// <summary>Always returns valid, as 'title' acts as metadata rather than an instance constraint.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a title keyword from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('title').</summary>
    property KeywordName: string read GetKeywordName;

    /// <summary>Title string value.</summary>
    property Title: string read FTitle;
  end;

implementation

{ TTitleKeyword }

constructor TTitleKeyword.Create(const pTitle: string);
begin
  inherited Create;
  FTitle := pTitle;
end;

class function TTitleKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
    Result := TTitleKeyword.Create(pKeywordValue.Value)
  else
    Result := TTitleKeyword.Create('');
end;

function TTitleKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_TITLE;
end;

function TTitleKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.ValidResult;
end;

end.
