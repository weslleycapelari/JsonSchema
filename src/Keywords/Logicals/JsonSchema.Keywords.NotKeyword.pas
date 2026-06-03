unit JsonSchema.Keywords.NotKeyword;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'not' logical keyword.
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
  /// <summary>Validates that the JSON instance does NOT conform to the specified sub-schema.</summary>
  TNotKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FNotSchema: ICompiledSchema;
    function GetKeywordName: string;
  public
    /// <summary>Initializes not keyword with the compiled sub-schema.</summary>
    constructor Create(const pNotSchema: ICompiledSchema);

    /// <summary>Validates that the JSON instance fails validation of the sub-schema.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('not').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TNotKeyword }

constructor TNotKeyword.Create(const pNotSchema: ICompiledSchema);
begin
  inherited Create;
  FNotSchema := pNotSchema;
end;

class function TNotKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TNotKeyword.Create(pCompileFunc(pKeywordValue));
end;

function TNotKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_NOT;
end;

function TNotKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  if not Assigned(FNotSchema) then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  if FNotSchema.Validate(pInstance).IsValid then
  begin
    Result := TValidationResult.InvalidResult(GetKeywordName);
  end else
  begin
    Result := TValidationResult.ValidResult;
  end;
end;

end.
