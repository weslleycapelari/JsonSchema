unit JsonSchema.Keywords.Examples;

(*
--------------------------------------------------------------------------------
Implements the 'examples' metadata keyword.
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
  /// <summary>Stores the 'examples' array metadata.</summary>
  TExamplesKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FExamples: TJSONArray;
    function GetKeywordName: string;
  public
    /// <summary>Initializes examples keyword with target array value.</summary>
    constructor Create(const pExamples: TJSONArray);
    destructor Destroy; override;

    /// <summary>Always returns valid, as 'examples' acts as metadata rather than an instance constraint.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a examples keyword from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('examples').</summary>
    property KeywordName: string read GetKeywordName;

    /// <summary>Examples JSON array.</summary>
    property Examples: TJSONArray read FExamples;
  end;

implementation

{ TExamplesKeyword }

constructor TExamplesKeyword.Create(const pExamples: TJSONArray);
begin
  inherited Create;
  if Assigned(pExamples) then
    FExamples := pExamples.Clone as TJSONArray
  else
    FExamples := nil;
end;

destructor TExamplesKeyword.Destroy;
begin
  FExamples.Free;
  inherited Destroy;
end;

class function TExamplesKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONArray) then
    Result := TExamplesKeyword.Create(TJSONArray(pKeywordValue))
  else
    Result := TExamplesKeyword.Create(nil);
end;

function TExamplesKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_EXAMPLES;
end;

function TExamplesKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.ValidResult;
end;

end.
