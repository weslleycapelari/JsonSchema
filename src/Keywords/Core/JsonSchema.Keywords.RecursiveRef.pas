unit JsonSchema.Keywords.RecursiveRef;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the '$recursiveRef' core keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Core.SchemaRegistry,
  JsonSchema.Results;

type
  /// <summary>Implements the dynamic recursive schema reference resolution per Draft 2019-09.</summary>
  TRecursiveRefKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FRefPath: string;
    FCompileFunc: TCompileSchemaFunc;
    FStaticSchema: ICompiledSchema;
    FRefTargetValue: TJSONValue;
    FRootSchema: TJSONObject;
    FBaseURI: string;
    function GetKeywordName: string;
  public
    /// <summary>Initializes recursiveRef validator.</summary>
    constructor Create(const pRefPath: string; const pTargetValue: TJSONValue; const pRootSchema: TJSONObject; const pBaseURI: string;
      const pCompileFunc: TCompileSchemaFunc);

    /// <summary>Validates the JSON instance dynamically against active recursive anchor or static fallback.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a keyword validator instance from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('$recursiveRef').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper,
  JsonSchema.Core.ValidationContext;

{ TRecursiveRefKeyword }

class function TRecursiveRefKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
var
  lRefStr: string;
  lAbsoluteRefURI: string;
  lTargetValue: TJSONValue;
  lTargetRoot: TJSONObject;
  lTargetBaseURI: string;
  lRemoteSchema: TJSONValue;
begin
  lTargetBaseURI := '';

  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
  begin
    lRefStr := pKeywordValue.Value;
    lAbsoluteRefURI := TSchemaRegistry.CombineURI(TSchemaRegistry.CurrentBaseURI, lRefStr);

    if TSchemaRegistry.FindSchema(lAbsoluteRefURI, lRemoteSchema) then
    begin
      lTargetValue := lRemoteSchema;
      if lRemoteSchema is TJSONObject then
        lTargetRoot := TJSONObject(lRemoteSchema)
      else
        lTargetRoot := pParentSchema;
      lTargetBaseURI := lAbsoluteRefURI;
    end else
    begin
      lTargetValue := TSchemaRegistry.CurrentRootSchema;
      lTargetRoot := TSchemaRegistry.CurrentRootSchema;
      lTargetBaseURI := TSchemaRegistry.CurrentBaseURI;
    end;

    Result := TRecursiveRefKeyword.Create(lRefStr, lTargetValue, lTargetRoot, lTargetBaseURI, pCompileFunc);
  end else
    Result := TRecursiveRefKeyword.Create('', nil, nil, '', pCompileFunc);
end;

constructor TRecursiveRefKeyword.Create(const pRefPath: string; const pTargetValue: TJSONValue; const pRootSchema: TJSONObject;
  const pBaseURI: string; const pCompileFunc: TCompileSchemaFunc);
begin
  inherited Create;
  FRefPath := pRefPath;
  FRefTargetValue := pTargetValue;
  FRootSchema := pRootSchema;
  FBaseURI := pBaseURI;
  FCompileFunc := pCompileFunc;
  FStaticSchema := nil;
end;

function TRecursiveRefKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_RECURSIVEREF;
end;

function TRecursiveRefKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lDynamicSchema: ICompiledSchema;
  lOldRoot: TJSONObject;
  lOldBaseURI: string;
begin
  // Validation loop recursion guard
  if Assigned(FRefTargetValue) and (FRefTargetValue is TJSONObject) and
     TValidationContext.IsCurrentlyValidating(TJSONObject(FRefTargetValue), pInstance) then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lDynamicSchema := nil;
  if Assigned(FRefTargetValue) and (FRefTargetValue is TJSONObject) and
     TSchemaRegistry.IsRecursiveAnchor(TJSONObject(FRefTargetValue)) then
  begin
    lDynamicSchema := TValidationContext.ResolveRecursiveRef;
  end;

  if Assigned(lDynamicSchema) then
  begin
    Result := lDynamicSchema.Validate(pInstance);
    Exit;
  end;

  if not Assigned(FRefTargetValue) then
  begin
    Result := TValidationResult.InvalidResult(GetKeywordName);
    Exit;
  end;

  if not Assigned(FStaticSchema) then
  begin
    lOldRoot := TSchemaRegistry.CurrentRootSchema;
    lOldBaseURI := TSchemaRegistry.CurrentBaseURI;
    TSchemaRegistry.CurrentRootSchema := FRootSchema;
    TSchemaRegistry.CurrentBaseURI := FBaseURI;
    try
      FStaticSchema := FCompileFunc(FRefTargetValue);
    finally
      TSchemaRegistry.CurrentRootSchema := lOldRoot;
      TSchemaRegistry.CurrentBaseURI := lOldBaseURI;
    end;
  end;

  Result := FStaticSchema.Validate(pInstance);
end;

end.
