unit JsonSchema.Keywords.Comment;

(*
--------------------------------------------------------------------------------
Implements validation logic for the '$comment' keyword (metadata description).
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
  /// <summary>Metadata validator for schema comments. Ignored at validation time.</summary>
  TCommentKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FComment: string;
    function GetKeywordName: string;
  public
    /// <summary>Initializes comment keyword.</summary>
    constructor Create(const pComment: string);

    /// <summary>Always returns success since comments are non-validating metadata.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Factory method to create the comment keyword.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword ('$comment').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TCommentKeyword }

constructor TCommentKeyword.Create(const pComment: string);
begin
  inherited Create;
  FComment := pComment;
end;

class function TCommentKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
    Result := TCommentKeyword.Create(pKeywordValue.Value)
  else
    Result := TCommentKeyword.Create('');
end;

function TCommentKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_COMMENT;
end;

function TCommentKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.ValidResult;
end;

end.
