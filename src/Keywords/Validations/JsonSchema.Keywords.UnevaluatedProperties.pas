unit JsonSchema.Keywords.UnevaluatedProperties;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'unevaluatedProperties' keyword.
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
  /// <summary>Validates any object properties that are not matched by other keywords in this validation run.</summary>
  TUnevaluatedPropertiesKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FSchema: ICompiledSchema;
    function GetKeywordName: string;
  public
    /// <summary>Initializes unevaluatedProperties keyword with the compiled schema.</summary>
    constructor Create(const pSchema: ICompiledSchema);

    /// <summary>Validates unevaluated properties of the JSON object instance.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('unevaluatedProperties').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper,
  JsonSchema.Core.ValidationContext;

{ TUnevaluatedPropertiesKeyword }

class function TUnevaluatedPropertiesKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TUnevaluatedPropertiesKeyword.Create(pCompileFunc(pKeywordValue));
end;

constructor TUnevaluatedPropertiesKeyword.Create(const pSchema: ICompiledSchema);
begin
  inherited Create;
  FSchema := pSchema;
end;

function TUnevaluatedPropertiesKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_UNEVALUATEDPROPERTIES;
end;

function TUnevaluatedPropertiesKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lObj: TJSONObject;
  lPair: TJSONPair;
  lResults: TArray<IValidationResult>;
  lSubResult: IValidationResult;
  lHasFalse: Boolean;
  lErr: IValidationError;
  lCtx: TJSONObject;
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
    if not TValidationContext.IsPropertyEvaluated(pInstance, lPair.JsonString.Value) then
    begin
      TValidationContext.MarkPropertyEvaluated(pInstance, lPair.JsonString.Value);

      if Assigned(FSchema) then
      begin
        lSubResult := FSchema.Validate(lPair.JsonValue);
        if not lSubResult.IsValid then
        begin
          lHasFalse := False;
          for lErr in lSubResult.Errors do
          begin
            if lErr.Keyword = 'false' then
              lHasFalse := True;
          end;

          if lHasFalse then
          begin
            lCtx := TJSONObject.Create;
            try
              lCtx.AddPair('propertyName', TJSONString.Create(lPair.JsonString.Value));
              lResults := lResults + [TValidationResult.InvalidResult(GetKeywordName, lCtx)];
            finally
              lCtx.Free;
            end;
          end else
          begin
            lResults := lResults + [lSubResult];
          end;
        end;
      end;
    end;
  end;

  Result := TValidationResult.Combined(lResults);
end;

end.
