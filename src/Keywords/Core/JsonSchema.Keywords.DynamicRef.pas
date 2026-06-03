unit JsonSchema.Keywords.DynamicRef;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the '$dynamicRef' core validation keyword.
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
  /// <summary>Implements dynamic reference resolution per Draft 2020-12.</summary>
  TDynamicRefKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FRefPath: string;
    FCompileFunc: TCompileSchemaFunc;
    FStaticSchema: ICompiledSchema;
    FRefTargetValue: TJSONValue;
    FRootSchema: TJSONObject;
    FBaseURI: string;
    FAnchorName: string;
    FIsDynamic: Boolean;
    function GetKeywordName: string;
  public
    /// <summary>Initializes dynamicRef keyword.</summary>
    constructor Create(const pRefPath: string; const pTargetValue: TJSONValue; const pRootSchema: TJSONObject; const pBaseURI: string;
      const pAnchorName: string; const pIsDynamic: Boolean; const pCompileFunc: TCompileSchemaFunc);

    /// <summary>Validates the JSON instance dynamically against dynamic anchor or static fallback.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a dynamicRef keyword validator and resolves target references.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('$dynamicRef').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.JSONHelper,
  JsonSchema.Keywords.Ref,
  JsonSchema.Core.ValidationContext;

{ TDynamicRefKeyword }

class function TDynamicRefKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
var
  lRefStr: string;
  lAbsoluteRefURI: string;
  lBaseURI: string;
  lFragment: string;
  lHashIdx: Integer;
  lTargetValue: TJSONValue;
  lTargetRoot: TJSONObject;
  lTargetBaseURI: string;
  lRemoteSchema: TJSONValue;
  lResolvedBaseURI: string;
  lAnchorName: string;
  lIsDynamic: Boolean;
  lPair: TJSONPair;
begin
  lTargetBaseURI := '';
  lAnchorName := '';
  lIsDynamic := False;

  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
  begin
    lRefStr := pKeywordValue.Value;
    lAbsoluteRefURI := TSchemaRegistry.CombineURI(TSchemaRegistry.CurrentBaseURI, lRefStr);

    lHashIdx := lAbsoluteRefURI.IndexOf('#');
    if lHashIdx >= 0 then
    begin
      lBaseURI := lAbsoluteRefURI.Substring(0, lHashIdx);
      lFragment := lAbsoluteRefURI.Substring(lHashIdx);
    end else
    begin
      lBaseURI := lAbsoluteRefURI;
      lFragment := '';
    end;

    if TSchemaRegistry.FindSchema(lAbsoluteRefURI, lRemoteSchema) then
    begin
      if (lFragment = '') or (lFragment = '#') or (lFragment = '#/') or lFragment.StartsWith('#/') then
      begin
        lTargetValue := TRefKeyword.ResolveJsonPointerWithBase(lRemoteSchema, lFragment, lBaseURI, lResolvedBaseURI);
        lTargetBaseURI := lResolvedBaseURI;
      end
      else
      begin
        lTargetValue := lRemoteSchema;
        lTargetBaseURI := lAbsoluteRefURI;
      end;

      if lRemoteSchema is TJSONObject then
        lTargetRoot := TJSONObject(lRemoteSchema)
      else
        lTargetRoot := pParentSchema;
    end else if (lBaseURI <> '') and TSchemaRegistry.FindSchema(lBaseURI, lRemoteSchema) then
    begin
      lTargetValue := TRefKeyword.ResolveJsonPointerWithBase(lRemoteSchema, lFragment, lBaseURI, lResolvedBaseURI);
      if lRemoteSchema is TJSONObject then
        lTargetRoot := TJSONObject(lRemoteSchema)
      else
        lTargetRoot := pParentSchema;
      lTargetBaseURI := lResolvedBaseURI;
    end else
    begin
      lTargetValue := TRefKeyword.ResolveJsonPointerWithBase(
        TSchemaRegistry.CurrentRootSchema,
        lFragment,
        TSchemaRegistry.CurrentBaseURI,
        lResolvedBaseURI
      );
      lTargetRoot := TSchemaRegistry.CurrentRootSchema;
      lTargetBaseURI := lResolvedBaseURI;
    end;

    // Determine if reference is dynamic based on fragment and $dynamicAnchor presence in target
    if lFragment.StartsWith('#') and (not lFragment.Contains('/')) then
    begin
      lAnchorName := lFragment.Substring(1);
      if Assigned(lTargetValue) and (lTargetValue is TJSONObject) then
      begin
        lPair := TJSONObject(lTargetValue).Get('$dynamicAnchor');
        if Assigned(lPair) and (lPair.JsonValue is TJSONString) and (lPair.JsonValue.Value = lAnchorName) then
          lIsDynamic := True;
      end;
    end;

    Result := TDynamicRefKeyword.Create(lRefStr, lTargetValue, lTargetRoot, lTargetBaseURI, lAnchorName, lIsDynamic, pCompileFunc);
  end else
    Result := TDynamicRefKeyword.Create('', nil, nil, '', '', False, pCompileFunc);
end;

constructor TDynamicRefKeyword.Create(const pRefPath: string; const pTargetValue: TJSONValue; const pRootSchema: TJSONObject;
  const pBaseURI: string; const pAnchorName: string; const pIsDynamic: Boolean; const pCompileFunc: TCompileSchemaFunc);
begin
  inherited Create;
  FRefPath := pRefPath;
  FRefTargetValue := pTargetValue;
  FRootSchema := pRootSchema;
  FBaseURI := pBaseURI;
  FAnchorName := pAnchorName;
  FIsDynamic := pIsDynamic;
  FCompileFunc := pCompileFunc;
  FStaticSchema := nil;
end;

function TDynamicRefKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_DYNAMICREF;
end;

function TDynamicRefKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lDynamicSchema: ICompiledSchema;
  lOldRoot: TJSONObject;
  lOldBaseURI: string;
  lResolvedTargetObj: TJSONObject;
  lResolvedURI: string;
  lTargetBaseURI: string;
  lTargetRoot: TJSONObject;
  lRootVal: TJSONValue;
begin
  // Validation loop recursion guard
  if Assigned(FRefTargetValue) and (FRefTargetValue is TJSONObject) and
     TValidationContext.IsCurrentlyValidating(TJSONObject(FRefTargetValue), pInstance) then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lDynamicSchema := nil;
  if FIsDynamic then
  begin
    lResolvedTargetObj := TValidationContext.ResolveDynamicAnchor(FAnchorName);
    if Assigned(lResolvedTargetObj) then
    begin
      lResolvedURI := '';
      lTargetRoot := nil;
      lTargetBaseURI := '';
      if TSchemaRegistry.GetSchemaURI(lResolvedTargetObj, lResolvedURI) then
      begin
        if lResolvedURI.Contains('#') then
          lTargetBaseURI := lResolvedURI.Substring(0, lResolvedURI.IndexOf('#'))
        else
          lTargetBaseURI := lResolvedURI;

        if TSchemaRegistry.FindSchema(lTargetBaseURI, lRootVal) and (lRootVal is TJSONObject) then
          lTargetRoot := TJSONObject(lRootVal);
      end;

      if not Assigned(lTargetRoot) then
        lTargetRoot := FRootSchema;

      lOldRoot := TSchemaRegistry.CurrentRootSchema;
      lOldBaseURI := TSchemaRegistry.CurrentBaseURI;
      TSchemaRegistry.CurrentRootSchema := lTargetRoot;
      TSchemaRegistry.CurrentBaseURI := lTargetBaseURI;
      try
        lDynamicSchema := FCompileFunc(lResolvedTargetObj);
      finally
        TSchemaRegistry.CurrentRootSchema := lOldRoot;
        TSchemaRegistry.CurrentBaseURI := lOldBaseURI;
      end;
    end;
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
