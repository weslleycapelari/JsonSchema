unit JsonSchema.Keywords.Ref;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the '$ref' core validation keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  System.NetEncoding,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Core.SchemaRegistry,
  JsonSchema.Keywords.Id,
  JsonSchema.Results;

type
  /// <summary>Implements the validation rule/reference navigation for $ref keyword.</summary>
  TRefKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FRefPath: string;
    FCompileFunc: TCompileSchemaFunc;
    FResolvedSchema: ICompiledSchema;
    FRefTargetValue: TJSONValue;
    FRootSchema: TJSONObject;
    FBaseURI: string;
    function GetKeywordName: string;
  public
    class function ResolveJsonPointerWithBase(const pRoot: TJSONValue; const pPointer, pBaseURI: string;
      out pResolvedBaseURI: string): TJSONValue; static;
    /// <summary>Initializes ref keyword pointing to target resolved JSON value.</summary>
    constructor Create(const pRefPath: string; const pTargetValue: TJSONValue; const pRootSchema: TJSONObject; const pBaseURI: string;
      const pCompileFunc: TCompileSchemaFunc);

    /// <summary>Validates the instance against the referenced compiled sub-schema.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a ref keyword validator and resolves target reference pointer.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('$ref').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

uses
  JsonSchema.Core.ValidationContext;

{ TRefKeyword }

constructor TRefKeyword.Create(const pRefPath: string; const pTargetValue: TJSONValue; const pRootSchema: TJSONObject;
  const pBaseURI: string; const pCompileFunc: TCompileSchemaFunc);
begin
  inherited Create;
  FRefPath := pRefPath;
  FRefTargetValue := pTargetValue;
  FRootSchema := pRootSchema;
  FBaseURI := pBaseURI;
  FCompileFunc := pCompileFunc;
  FResolvedSchema := nil;
end;

class function TRefKeyword.ResolveJsonPointerWithBase(const pRoot: TJSONValue; const pPointer, pBaseURI: string;
  out pResolvedBaseURI: string): TJSONValue;
var
  lNormalized: string;
  lTokens: TArray<string>;
  lToken: string;
  lCleanToken: string;
  lIdx: Integer;
  lPair: TJSONPair;
  lIdValue: string;
begin
  Result := pRoot;
  pResolvedBaseURI := pBaseURI;
  if not Assigned(pRoot) then
    Exit(nil);

  lNormalized := pPointer;
  if lNormalized.StartsWith('#') then
    lNormalized := lNormalized.Substring(1);

  if (lNormalized = '') or (lNormalized = '/') then
    Exit(Result);

  if lNormalized.StartsWith('/') then
    lNormalized := lNormalized.Substring(1);

  lTokens := lNormalized.Split(['/']);
  for lToken in lTokens do
  begin
    if not Assigned(Result) then
      Exit(nil);

    // URI fragment JSON Pointers are percent-encoded before JSON Pointer unescaping.
    lCleanToken := TNetEncoding.URL.Decode(lToken).Replace('~1', '/').Replace('~0', '~');

    if Result is TJSONObject then
    begin
      Result := TJSONObject(Result).Values[lCleanToken]
    end
    else if Result is TJSONArray then
    begin
      if TryStrToInt(lCleanToken, lIdx) and (lIdx >= 0) and (lIdx < TJSONArray(Result).Count) then
        Result := TJSONArray(Result).Items[lIdx]
      else
        Exit(nil);
    end else
      Exit(nil);

    if Result is TJSONObject then
    begin
      lPair := TJSONObject(Result).Get('$id');
      if Assigned(lPair) and (lPair.JsonValue is TJSONString) then
      begin
        lIdValue := lPair.JsonValue.Value;
        pResolvedBaseURI := TSchemaRegistry.CombineURI(pResolvedBaseURI, lIdValue);
        if lIdValue.StartsWith('#') then
          pResolvedBaseURI := pBaseURI;
      end else
      begin
        lPair := TJSONObject(Result).Get('id');
        if Assigned(lPair) and (lPair.JsonValue is TJSONString) then
        begin
          lIdValue := lPair.JsonValue.Value;
          pResolvedBaseURI := TSchemaRegistry.CombineURI(pResolvedBaseURI, lIdValue);
          if lIdValue.StartsWith('#') then
            pResolvedBaseURI := pBaseURI;
        end;
      end;
    end;
  end;
end;

class function TRefKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
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
begin
  lTargetBaseURI := '';

  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
  begin
    lRefStr := pKeywordValue.Value;
    // Get absolute URI combining the base URI of the current compilation stack
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
      // 1. Try exact lookup in schema registry (anchors/full URIs)
      if (lFragment = '') or (lFragment = '#') or (lFragment = '#/') or lFragment.StartsWith('#/') then
      begin
        lTargetValue := ResolveJsonPointerWithBase(lRemoteSchema, lFragment, lBaseURI, lResolvedBaseURI);
        lTargetBaseURI := lResolvedBaseURI;
      end else
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
      lTargetValue := ResolveJsonPointerWithBase(lRemoteSchema, lFragment, lBaseURI, lResolvedBaseURI);
      if lRemoteSchema is TJSONObject then
        lTargetRoot := TJSONObject(lRemoteSchema)
      else
        lTargetRoot := pParentSchema;
      lTargetBaseURI := lResolvedBaseURI;
    end else
    begin
      lTargetValue := ResolveJsonPointerWithBase(
        TSchemaRegistry.CurrentRootSchema,
        lFragment,
        TSchemaRegistry.CurrentBaseURI,
        lResolvedBaseURI
      );
      lTargetRoot := TSchemaRegistry.CurrentRootSchema;
      lTargetBaseURI := lResolvedBaseURI;
    end;

    Result := TRefKeyword.Create(lRefStr, lTargetValue, lTargetRoot, lTargetBaseURI, pCompileFunc);
  end else
    Result := TRefKeyword.Create('', nil, nil, '', pCompileFunc);
end;

function TRefKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_REF;
end;

function TRefKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lOldRoot: TJSONObject;
  lOldBaseURI: string;
begin
  // Validation loop recursion guard (prevents stack overflow on loop references)
  if Assigned(FRefTargetValue) and (FRefTargetValue is TJSONObject) and
     TValidationContext.IsCurrentlyValidating(TJSONObject(FRefTargetValue), pInstance) then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  if not Assigned(FRefTargetValue) then
  begin
    Result := TValidationResult.InvalidResult(GetKeywordName);
    Exit;
  end;

  if not Assigned(FResolvedSchema) then
  begin
    lOldRoot := TSchemaRegistry.CurrentRootSchema;
    lOldBaseURI := TSchemaRegistry.CurrentBaseURI;
    TSchemaRegistry.CurrentRootSchema := FRootSchema;
    TSchemaRegistry.CurrentBaseURI := FBaseURI;
    try
      FResolvedSchema := FCompileFunc(FRefTargetValue);
    finally
      TSchemaRegistry.CurrentRootSchema := lOldRoot;
      TSchemaRegistry.CurrentBaseURI := lOldBaseURI;
    end;
  end;

  Result := FResolvedSchema.Validate(pInstance);
end;

end.
