unit JsonSchema.Keywords.Properties;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'properties' keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Validates defined object properties against their corresponding compiled sub-schemas.</summary>
  TPropertiesKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FProperties: TDictionary<string, ICompiledSchema>;
    function GetKeywordName: string;
  public
    /// <summary>Initializes properties keyword by parsing schema object with given compile function.</summary>
    constructor Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc); overload;

    /// <summary>Initializes properties keyword directly with a dictionary of compiled schemas.</summary>
    constructor Create(const pProperties: TDictionary<string, ICompiledSchema>); overload;

    destructor Destroy; override;

    /// <summary>Validates the properties of the JSON object instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('properties').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper,
  JsonSchema.Core.ValidationContext;

{ TPropertiesKeyword }

class function TPropertiesKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TPropertiesKeyword.Create(pKeywordValue, pCompileFunc);
end;

constructor TPropertiesKeyword.Create(const pKeywordValue: TJSONValue; const pCompileFunc: TCompileSchemaFunc);
var
  lPair: TJSONPair;
  lObj: TJSONObject;
begin
  inherited Create;
  FProperties := TDictionary<string, ICompiledSchema>.Create;
  if (Assigned(pKeywordValue)) and (pKeywordValue is TJSONObject) then
  begin
    lObj := TJSONObject(pKeywordValue);
    for lPair in lObj do
    begin
      FProperties.Add(lPair.JsonString.Value, pCompileFunc(lPair.JsonValue));
    end;
  end;
end;

constructor TPropertiesKeyword.Create(const pProperties: TDictionary<string, ICompiledSchema>);
begin
  inherited Create;
  FProperties := pProperties;
end;

destructor TPropertiesKeyword.Destroy;
begin
  FProperties.Free;
  inherited Destroy;
end;

function TPropertiesKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_PROPERTIES;
end;

function TPropertiesKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lObj: TJSONObject;
  lPair: TJSONPair;
  lResults: TArray<IValidationResult>;
  lSchema: ICompiledSchema;
begin
  if not pInstance.IsJSONObject then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lObj := TJSONObject(pInstance);
  lResults := [];

  for lPair in lObj do
  begin
    if FProperties.TryGetValue(lPair.JsonString.Value, lSchema) then
    begin
      TValidationContext.MarkPropertyEvaluated(pInstance, lPair.JsonString.Value);
      lResults := lResults + [lSchema.Validate(lPair.JsonValue)];
    end;
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
