unit JsonSchema.CompiledSchema;

(*
--------------------------------------------------------------------------------
Contains the post-compiled JSON Schema, composed of a structured set of
keyword validators.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Class responsible for managing and executing the validation of all compiled keywords.</summary>
  TFalseSchemaKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    function GetKeywordName: string;
  public
    function Validate(const pInstance: TJSONValue): IValidationResult;
    property KeywordName: string read GetKeywordName;
  end;

  /// <summary>Class responsible for managing and executing the validation of all compiled keywords.</summary>
  TCompiledSchema = class(TInterfacedObject, ICompiledSchema)
  strict private
    FKeywords: TArray<IJsonSchemaKeyword>;
  public
    constructor Create(const pKeywords: TArray<IJsonSchemaKeyword>);

    /// <summary>Executes the validation of all schema keywords against the JSON value.</summary>
    /// <param name="pInstance">JSON value to validate.</param>
    /// <returns>The consolidated result containing any validation errors.</returns>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a compiled schema representing boolean false (always invalid).</summary>
    class function CreateFalseSchema: ICompiledSchema; static;

    /// <summary>Creates a compiled schema representing boolean true (always valid).</summary>
    class function CreateTrueSchema: ICompiledSchema; static;

    /// <summary>List of active keyword validators in the compiled schema.</summary>
    property Keywords: TArray<IJsonSchemaKeyword> read FKeywords;
  end;

implementation

{ TFalseSchemaKeyword }

function TFalseSchemaKeyword.GetKeywordName: string;
begin
  Result := 'false';
end;

function TFalseSchemaKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.InvalidResult('false');
end;

{ TCompiledSchema }

constructor TCompiledSchema.Create(const pKeywords: TArray<IJsonSchemaKeyword>);
begin
  inherited Create;
  FKeywords := pKeywords;
end;

class function TCompiledSchema.CreateFalseSchema: ICompiledSchema;
var
  lKeywords: TArray<IJsonSchemaKeyword>;
begin
  lKeywords := [TFalseSchemaKeyword.Create];
  Result := TCompiledSchema.Create(lKeywords);
end;

class function TCompiledSchema.CreateTrueSchema: ICompiledSchema;
var
  lKeywords: TArray<IJsonSchemaKeyword>;
begin
  lKeywords := [];
  Result := TCompiledSchema.Create(lKeywords);
end;

function TCompiledSchema.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lResults: TArray<IValidationResult>;
  lKeyword: IJsonSchemaKeyword;
  lIndex: Integer;
begin
  lResults := [];

  // We pre-allocate the array size to optimize memory allocation in loops
  SetLength(lResults, Length(FKeywords));

  lIndex := 0;
  for lKeyword in FKeywords do
  begin
    lResults[lIndex] := lKeyword.Validate(pInstance);
    Inc(lIndex);
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
