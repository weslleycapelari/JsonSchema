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
  /// <summary>Class representing boolean false schema validation.</summary>
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
    FSchemaObj: TJSONObject;
  public
    /// <summary>Initializes compiled schema with its keywords and raw schema context.</summary>
    constructor Create(const pKeywords: TArray<IJsonSchemaKeyword>; const pSchemaObj: TJSONObject = nil);

    /// <summary>Executes validation under the active validation traversal stack.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a compiled schema representing boolean false.</summary>
    class function CreateFalseSchema: ICompiledSchema; static;

    /// <summary>Creates a compiled schema representing boolean true.</summary>
    class function CreateTrueSchema: ICompiledSchema; static;

    /// <summary>List of active keyword validators in the compiled schema.</summary>
    property Keywords: TArray<IJsonSchemaKeyword> read FKeywords;

    /// <summary>Raw JSON Schema object from which this schema was compiled.</summary>
    property SchemaObj: TJSONObject read FSchemaObj;
  end;

implementation

uses
  JsonSchema.Core.ValidationContext;

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

constructor TCompiledSchema.Create(const pKeywords: TArray<IJsonSchemaKeyword>; const pSchemaObj: TJSONObject);
begin
  inherited Create;
  FKeywords := pKeywords;
  FSchemaObj := pSchemaObj;
end;

class function TCompiledSchema.CreateFalseSchema: ICompiledSchema;
var
  lKeywords: TArray<IJsonSchemaKeyword>;
begin
  lKeywords := [TFalseSchemaKeyword.Create];
  Result := TCompiledSchema.Create(lKeywords, nil);
end;

class function TCompiledSchema.CreateTrueSchema: ICompiledSchema;
var
  lKeywords: TArray<IJsonSchemaKeyword>;
begin
  lKeywords := [];
  Result := TCompiledSchema.Create(lKeywords, nil);
end;

function TCompiledSchema.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lResults: TArray<IValidationResult>;
  lKeyword: IJsonSchemaKeyword;
  lIndex: Integer;
begin
  TValidationContext.PushSchema(FSchemaObj, Self, pInstance);
  TValidationContext.PushScope;
  try
    lResults := [];
    SetLength(lResults, Length(FKeywords));

    lIndex := 0;
    for lKeyword in FKeywords do
    begin
      lResults[lIndex] := lKeyword.Validate(pInstance);
      Inc(lIndex);
    end;

    Result := TValidationResult.Combined(lResults);
  finally
    TValidationContext.PopScope(Assigned(Result) and Result.IsValid);
    TValidationContext.PopSchema;
  end;
end;

end.
