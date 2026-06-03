unit JsonSchema.Draft2019_09.Parser;

(*
--------------------------------------------------------------------------------
Provides compilation and parsing capabilities for Draft 2019-09 schemas.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.CompiledSchema,
  JsonSchema.Registry;

type
  /// <summary>Compiler for Draft 2019-09 schemas. Registers standard keywords and dynamic referencers.</summary>
  TDraft2019_09Parser = class
  strict private
    class var FRegistry: TKeywordRegistry;
    class constructor Create;
    class destructor Destroy;
    class procedure RegisterCoreKeywords; static;
    class procedure RegisterValidationKeywords; static;
    class procedure RegisterLogicalKeywords; static;
    class function GetKeywordVocabulary(const pKeyword: string): string; static;
    class function IsKeywordEnabled(const pKeyword: string; const pSchema: TJSONObject): Boolean; static;
  public
    /// <summary>Parses and compiles a JSON schema object into a set of validation rules.</summary>
    class function Parse(const pSchema: TJSONObject): ICompiledSchema;

    /// <summary>Parses a sub-schema which can be either a JSON object or a boolean value.</summary>
    class function ParseSchema(const pSchemaVal: TJSONValue): ICompiledSchema; static;

    /// <summary>Active keyword plugin registry for this draft parser.</summary>
    class property Registry: TKeywordRegistry read FRegistry;
  end;

implementation

uses
  System.SysUtils,
  JsonSchema.Core.ValidationContext,
  JsonSchema.Keywords.TypeKeyword,
  JsonSchema.Keywords.MinLength,
  JsonSchema.Keywords.Enum,
  JsonSchema.Keywords.ConstKeyword,
  JsonSchema.Keywords.Required,
  JsonSchema.Keywords.Minimum,
  JsonSchema.Keywords.Maximum,
  JsonSchema.Keywords.MaxLength,
  JsonSchema.Keywords.MinItems,
  JsonSchema.Keywords.MaxItems,
  JsonSchema.Keywords.MultipleOf,
  JsonSchema.Keywords.ExclusiveMaximum,
  JsonSchema.Keywords.ExclusiveMinimum,
  JsonSchema.Keywords.Pattern,
  JsonSchema.Keywords.UniqueItems,
  JsonSchema.Keywords.Contains,
  JsonSchema.Keywords.MaxProperties,
  JsonSchema.Keywords.MinProperties,
  JsonSchema.Keywords.PropertyNames,
  JsonSchema.Keywords.Properties,
  JsonSchema.Keywords.PatternProperties,
  JsonSchema.Keywords.Items,
  JsonSchema.Keywords.AdditionalItems,
  JsonSchema.Keywords.AdditionalProperties,
  JsonSchema.Keywords.Dependencies,
  JsonSchema.Keywords.DependentRequired,
  JsonSchema.Keywords.DependentSchemas,
  JsonSchema.Keywords.UnevaluatedProperties,
  JsonSchema.Keywords.UnevaluatedItems,
  JsonSchema.Keywords.AllOf,
  JsonSchema.Keywords.AnyOf,
  JsonSchema.Keywords.OneOf,
  JsonSchema.Keywords.NotKeyword,
  JsonSchema.Keywords.Schema,
  JsonSchema.Keywords.Id,
  JsonSchema.Keywords.Ref,
  JsonSchema.Keywords.RecursiveRef,
  JsonSchema.Keywords.Vocabulary,
  JsonSchema.Keywords.Format,
  JsonSchema.Keywords.IfThenElse,
  JsonSchema.Keywords.Comment,
  JsonSchema.Keywords.Deprecated,
  JsonSchema.Keywords.ReadOnlyWriteOnly,
  JsonSchema.Core.SchemaRegistry,
  JsonSchema.Draft6.Parser,
  JsonSchema.Draft7.Parser,
  JsonSchema.Draft2020_12.Parser;

{ TDraft2019_09Parser }

class constructor TDraft2019_09Parser.Create;
begin
  FRegistry := TKeywordRegistry.Create(TDraft2019_09Parser.ParseSchema);
  RegisterCoreKeywords;
  RegisterValidationKeywords;
  RegisterLogicalKeywords;
end;

class procedure TDraft2019_09Parser.RegisterValidationKeywords;
begin
  FRegistry.RegisterKeyword(KEYWORD_TYPE, TTypeKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_MINLENGTH, TMinLengthKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_ENUM, TEnumKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_CONST, TConstKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_REQUIRED, TRequiredKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_MINIMUM, TMinimumKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_MAXIMUM, TMaximumKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_MAXLENGTH, TMaxLengthKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_MINITEMS, TMinItemsKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_MAXITEMS, TMaxItemsKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_MULTIPLEOF, TMultipleOfKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_EXCLUSIVEMAXIMUM, TExclusiveMaximumKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_EXCLUSIVEMINIMUM, TExclusiveMinimumKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_PATTERN, TPatternKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_UNIQUEITEMS, TUniqueItemsKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_CONTAINS, TContainsKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_MAXPROPERTIES, TMaxPropertiesKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_MINPROPERTIES, TMinPropertiesKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_PROPERTYNAMES, TPropertyNamesKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_PROPERTIES, TPropertiesKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_PATTERNPROPERTIES, TPatternPropertiesKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_ITEMS, TItemsKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_ADDITIONALITEMS, TAdditionalItemsKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_ADDITIONALPROPERTIES, TAdditionalPropertiesKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_DEPENDENTREQUIRED, TDependentRequiredKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_DEPENDENTSCHEMAS, TDependentSchemasKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_DEPENDENCIES, TDependenciesKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_UNEVALUATEDPROPERTIES, TUnevaluatedPropertiesKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_UNEVALUATEDITEMS, TUnevaluatedItemsKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_FORMAT, TFormatKeyword.CreateKeywordDraft2019_09);
  FRegistry.RegisterKeyword(KEYWORD_COMMENT, TCommentKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_DEPRECATED, TDeprecatedKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_READONLY, TReadOnlyWriteOnlyKeyword.CreateReadOnlyKeyword);
  FRegistry.RegisterKeyword(KEYWORD_WRITEONLY, TReadOnlyWriteOnlyKeyword.CreateWriteOnlyKeyword);
end;

class procedure TDraft2019_09Parser.RegisterCoreKeywords;
begin
  FRegistry.RegisterKeyword(KEYWORD_SCHEMA, TSchemaKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_ID, TIdKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_REF, TRefKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_RECURSIVEREF, TRecursiveRefKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_VOCABULARY, TVocabularyKeyword.CreateKeyword);
end;

class procedure TDraft2019_09Parser.RegisterLogicalKeywords;
begin
  FRegistry.RegisterKeyword(KEYWORD_ALLOF, TAllOfKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_ANYOF, TAnyOfKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_ONEOF, TOneOfKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_NOT, TNotKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_IF, TIfThenElseKeyword.CreateKeyword);
end;

class destructor TDraft2019_09Parser.Destroy;
begin
  FRegistry.Free;
end;

class function TDraft2019_09Parser.Parse(const pSchema: TJSONObject): ICompiledSchema;
var
  lKeywords: TArray<IJsonSchemaKeyword>;
  lPair: TJSONPair;
  lKeyword: IJsonSchemaKeyword;
  lOldRoot: TJSONObject;
  lOldBaseURI: string;
begin
  lOldRoot := TSchemaRegistry.CurrentRootSchema;
  lOldBaseURI := TSchemaRegistry.CurrentBaseURI;

  if not Assigned(TSchemaRegistry.CurrentRootSchema) then
  begin
    TSchemaRegistry.CurrentRootSchema := pSchema;
    TSchemaRegistry.CurrentBaseURI := '';
    TSchemaRegistry.PreScanSchema('', pSchema);
  end;

  try
    lKeywords := [];

    // 1. Process '$id' first to establish base URI context
    lPair := pSchema.Get('$id');
    if Assigned(lPair) then
    begin
      lKeyword := FRegistry.CreateKeyword('$id', lPair.JsonValue, pSchema);
      if Assigned(lKeyword) then
      begin
        SetLength(lKeywords, Length(lKeywords) + 1);
        lKeywords[High(lKeywords)] := lKeyword;
      end;
    end;

    // 2. Process all other registered keywords (excluding unevaluated keywords)
    for lPair in pSchema do
    begin
      if (lPair.JsonString.Value <> '$id') and
         (lPair.JsonString.Value <> 'unevaluatedProperties') and
         (lPair.JsonString.Value <> 'unevaluatedItems') then
      begin
        if FRegistry.IsRegistered(lPair.JsonString.Value) then
        begin
          if IsKeywordEnabled(lPair.JsonString.Value, pSchema) then
          begin
            lKeyword := FRegistry.CreateKeyword(lPair.JsonString.Value, lPair.JsonValue, pSchema);
            if Assigned(lKeyword) then
            begin
              SetLength(lKeywords, Length(lKeywords) + 1);
              lKeywords[High(lKeywords)] := lKeyword;
            end;
          end;
        end;
      end;
    end;

    // 3. Process unevaluatedProperties and unevaluatedItems last
    lPair := pSchema.Get('unevaluatedProperties');
    if Assigned(lPair) and IsKeywordEnabled('unevaluatedProperties', pSchema) then
    begin
      lKeyword := FRegistry.CreateKeyword('unevaluatedProperties', lPair.JsonValue, pSchema);
      if Assigned(lKeyword) then
      begin
        SetLength(lKeywords, Length(lKeywords) + 1);
        lKeywords[High(lKeywords)] := lKeyword;
      end;
    end;

    lPair := pSchema.Get('unevaluatedItems');
    if Assigned(lPair) and IsKeywordEnabled('unevaluatedItems', pSchema) then
    begin
      lKeyword := FRegistry.CreateKeyword('unevaluatedItems', lPair.JsonValue, pSchema);
      if Assigned(lKeyword) then
      begin
        SetLength(lKeywords, Length(lKeywords) + 1);
        lKeywords[High(lKeywords)] := lKeyword;
      end;
    end;

    Result := TCompiledSchema.Create(lKeywords, pSchema);
  finally
    TSchemaRegistry.CurrentRootSchema := lOldRoot;
    TSchemaRegistry.CurrentBaseURI := lOldBaseURI;
  end;
end;

class function TDraft2019_09Parser.ParseSchema(const pSchemaVal: TJSONValue): ICompiledSchema;
var
  lObj: TJSONObject;
  lSchemaPair: TJSONPair;
  lSchemaURI: string;
begin
  if pSchemaVal is TJSONObject then
  begin
    lObj := TJSONObject(pSchemaVal);
    lSchemaPair := lObj.Get('$schema');
    if Assigned(lSchemaPair) and (lSchemaPair.JsonValue is TJSONString) then
    begin
      lSchemaURI := lSchemaPair.JsonValue.Value;
      if lSchemaURI.Contains('/draft-06/') then
        Exit(TDraft6Parser.Parse(lObj))
      else if lSchemaURI.Contains('/draft-07/') then
        Exit(TDraft7Parser.Parse(lObj))
      else if lSchemaURI.Contains('/draft/2019-09/') then
        Exit(TDraft2019_09Parser.Parse(lObj))
      else if lSchemaURI.Contains('/draft/2020-12/') then
        Exit(TDraft2020_12Parser.Parse(lObj));
    end;
    Result := TDraft2019_09Parser.Parse(lObj);
  end else if pSchemaVal is TJSONBool then
  begin
    if TJSONBool(pSchemaVal).AsBoolean then
      Result := TCompiledSchema.CreateTrueSchema
    else
      Result := TCompiledSchema.CreateFalseSchema;
  end else
    Result := TCompiledSchema.CreateTrueSchema;
end;

class function TDraft2019_09Parser.GetKeywordVocabulary(const pKeyword: string): string;
begin
  if (pKeyword = 'type') or (pKeyword = 'enum') or (pKeyword = 'const') or
     (pKeyword = 'multipleOf') or (pKeyword = 'maximum') or (pKeyword = 'exclusiveMaximum') or
     (pKeyword = 'minimum') or (pKeyword = 'exclusiveMinimum') or (pKeyword = 'maxLength') or
     (pKeyword = 'minLength') or (pKeyword = 'pattern') or (pKeyword = 'maxItems') or
     (pKeyword = 'minItems') or (pKeyword = 'uniqueItems') or (pKeyword = 'maxContains') or
     (pKeyword = 'minContains') or (pKeyword = 'maxProperties') or (pKeyword = 'minProperties') or
     (pKeyword = 'required') or (pKeyword = 'dependentRequired') then
    Result := 'https://json-schema.org/draft/2019-09/vocab/validation'
  else if (pKeyword = 'format') then
    Result := 'https://json-schema.org/draft/2019-09/vocab/format'
  else if (pKeyword = 'title') or (pKeyword = 'description') or (pKeyword = 'default') or
          (pKeyword = 'deprecated') or (pKeyword = 'readOnly') or (pKeyword = 'writeOnly') or
          (pKeyword = 'examples') then
    Result := 'https://json-schema.org/draft/2019-09/vocab/meta-data'
  else if (pKeyword = '$id') or (pKeyword = '$schema') or (pKeyword = '$anchor') or
          (pKeyword = '$ref') or (pKeyword = '$recursiveRef') or (pKeyword = '$recursiveAnchor') or
          (pKeyword = '$vocabulary') or (pKeyword = '$comment') or (pKeyword = '$defs') then
    Result := 'https://json-schema.org/draft/2019-09/vocab/core'
  else
    Result := 'https://json-schema.org/draft/2019-09/vocab/applicator';
end;

class function TDraft2019_09Parser.IsKeywordEnabled(const pKeyword: string; const pSchema: TJSONObject): Boolean;
var
  lMetaschemaURI: string;
  lMetaschemaVal: TJSONValue;
  lMetaschemaObj: TJSONObject;
  lVocabPair: TJSONPair;
  lVocabURI: string;
  lVocabObj: TJSONObject;
  lVal: TJSONValue;
begin
  if (pKeyword = 'format') and TValidationContext.EnforceFormats then
    Exit(True);

  Result := True;

  // Find metaschema URI
  lMetaschemaURI := '';
  if not pSchema.TryGetValue('$schema', lMetaschemaURI) then
  begin
    if Assigned(TSchemaRegistry.CurrentRootSchema) then
      TSchemaRegistry.CurrentRootSchema.TryGetValue('$schema', lMetaschemaURI);
  end;

  if lMetaschemaURI = '' then
    Exit;

  if TSchemaRegistry.FindSchema(lMetaschemaURI, lMetaschemaVal) and (lMetaschemaVal is TJSONObject) then
  begin
    lMetaschemaObj := TJSONObject(lMetaschemaVal);
    lVocabPair := lMetaschemaObj.Get('$vocabulary');
    if Assigned(lVocabPair) and (lVocabPair.JsonValue is TJSONObject) then
    begin
      lVocabObj := TJSONObject(lVocabPair.JsonValue);
      lVocabURI := GetKeywordVocabulary(pKeyword);
      lVocabPair := lVocabObj.Get(lVocabURI);
      if Assigned(lVocabPair) then
        lVal := lVocabPair.JsonValue
      else
        lVal := nil;

      if (lVal = nil) or (not (lVal is TJSONBool)) or (not TJSONBool(lVal).AsBoolean) then
      begin
        // Core vocabulary is always implicitly enabled
        if lVocabURI <> 'https://json-schema.org/draft/2019-09/vocab/core' then
          Result := False;
      end;
    end;
  end;
end;

end.
