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
  /// <summary>Compiler for Draft 2019-09 schemas. Leverages a registry to dynamically register keyword plugins.</summary>
  TDraft2019_09Parser = class
  strict private
    class var FRegistry: TKeywordRegistry;
    class constructor Create;
    class destructor Destroy;
    class procedure RegisterCoreKeywords; static;
    class procedure RegisterValidationKeywords; static;
    class procedure RegisterLogicalKeywords; static;
  public
    /// <summary>Parses and compiles a JSON schema object into a set of validation rules.</summary>
    /// <param name="pSchema">The raw JSON schema object containing keyword definitions.</param>
    /// <returns>ICompiledSchema instance containing compiled keyword validators.</returns>
    class function Parse(const pSchema: TJSONObject): ICompiledSchema;

    /// <summary>Parses a sub-schema which can be either a JSON object or a boolean value.</summary>
    class function ParseSchema(const pSchemaVal: TJSONValue): ICompiledSchema; static;

    /// <summary>Active keyword plugin registry for this draft parser.</summary>
    class property Registry: TKeywordRegistry read FRegistry;
  end;

implementation

uses
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
  JsonSchema.Keywords.AllOf,
  JsonSchema.Keywords.AnyOf,
  JsonSchema.Keywords.OneOf,
  JsonSchema.Keywords.NotKeyword,
  JsonSchema.Keywords.Schema,
  JsonSchema.Keywords.Id,
  JsonSchema.Keywords.Ref,
  JsonSchema.Keywords.Format,
  JsonSchema.Keywords.IfThenElse,
  JsonSchema.Keywords.Comment,
  JsonSchema.Core.SchemaRegistry;

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
  FRegistry.RegisterKeyword(KEYWORD_DEPENDENCIES, TDependenciesKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_FORMAT, TFormatKeyword.CreateKeywordDraft2019_09);
  FRegistry.RegisterKeyword(KEYWORD_COMMENT, TCommentKeyword.CreateKeyword);
end;

class procedure TDraft2019_09Parser.RegisterCoreKeywords;
begin
  FRegistry.RegisterKeyword(KEYWORD_SCHEMA, TSchemaKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_ID, TIdKeyword.CreateKeyword);
  FRegistry.RegisterKeyword(KEYWORD_REF, TRefKeyword.CreateKeyword);
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

    // 2. Process all other registered keywords
    for lPair in pSchema do
    begin
      if lPair.JsonString.Value <> '$id' then
      begin
        if FRegistry.IsRegistered(lPair.JsonString.Value) then
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

    Result := TCompiledSchema.Create(lKeywords);
  finally
    TSchemaRegistry.CurrentRootSchema := lOldRoot;
    TSchemaRegistry.CurrentBaseURI := lOldBaseURI;
  end;
end;

class function TDraft2019_09Parser.ParseSchema(const pSchemaVal: TJSONValue): ICompiledSchema;
begin
  if pSchemaVal is TJSONObject then
    Result := TDraft2019_09Parser.Parse(TJSONObject(pSchemaVal))
  else if pSchemaVal is TJSONBool then
  begin
    if TJSONBool(pSchemaVal).AsBoolean then
      Result := TCompiledSchema.CreateTrueSchema
    else
      Result := TCompiledSchema.CreateFalseSchema;
  end else
    Result := TCompiledSchema.CreateTrueSchema;
end;

end.
