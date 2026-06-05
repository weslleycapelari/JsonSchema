unit Schema2Delphi.TypeMapper;

(*
--------------------------------------------------------------------------------
Provides schema-to-Delphi type mapping logic, resolving references ($ref), enums,
primitive types, format types, and array item subschemas.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils,
  System.JSON,
  JsonSchema.Core.Interfaces,
  Schema2Delphi.AST,
  Schema2Delphi.Common;

type
  /// <summary>Responsible for evaluating JSON Schema definitions and mapping them to Delphi types.</summary>
  TSchemaTypeMapper = class
  public
    /// <summary>Finds a specific compiled keyword class instance in a compiled schema.</summary>
    class function FindKeyword(pCompiled: ICompiledSchema; pClass: TClass): TObject; static;
    
    /// <summary>Retrieves the primary JSON type name defined in the type keyword.</summary>
    class function GetPrimaryType(pCompiled: ICompiledSchema): string; static;
    
    /// <summary>Checks if the schema allows null values.</summary>
    class function IsSchemaNullable(pCompiled: ICompiledSchema): Boolean; static;
    
    /// <summary>Wraps primitive type names in a nullable template if applicable.</summary>
    class function WrapNullable(const pTypeName: string; pCompiled: ICompiledSchema; const pConfig: TCodeGeneratorConfig): string; static;
    
    /// <summary>Generates and registers an enum type based on enum values in the schema.</summary>
    class procedure GenerateEnumFromSchema(pCompiled: ICompiledSchema; const pTypeName: string; const pContext: IGenerationContext); static;
    
    /// <summary>Determines the best Delphi type name and type category for a given subschema.</summary>
    class function GetDelphiTypeForSchema(pCompiled: ICompiledSchema; const pPropName: string; out pType: TType;
      const pContext: IGenerationContext): string; static;
  end;

implementation

uses
  System.Generics.Collections,
  JsonSchema.CompiledSchema,
  JsonSchema.Keywords.Ref,
  JsonSchema.Keywords.Properties,
  JsonSchema.Keywords.Enum,
  JsonSchema.Keywords.Items,
  JsonSchema.Keywords.TypeKeyword,
  Schema2Delphi.Sanitizer;

{ TSchemaTypeMapper }

class function TSchemaTypeMapper.FindKeyword(pCompiled: ICompiledSchema; pClass: TClass): TObject;
var
  lCompiled: TCompiledSchema;
  lKeyword: IJsonSchemaKeyword;
begin
  Result := nil;
  if not Assigned(pCompiled) then
    Exit;
  if (pCompiled as TObject) is TCompiledSchema then
  begin
    lCompiled := pCompiled as TCompiledSchema;
    for lKeyword in lCompiled.Keywords do
    begin
      if (lKeyword as TObject) is pClass then
        Exit(lKeyword as TObject);
    end;
  end;
end;

class function TSchemaTypeMapper.GetPrimaryType(pCompiled: ICompiledSchema): string;
var
  lKeyword: TObject;
  lTypeKeyword: TTypeKeyword;
  lExpected: string;
begin
  Result := 'object';
  lKeyword := FindKeyword(pCompiled, TTypeKeyword);
  if Assigned(lKeyword) then
  begin
    lTypeKeyword := TTypeKeyword(lKeyword);
    for lExpected in lTypeKeyword.ExpectedTypes do
    begin
      if not SameText(lExpected, 'null') then
        Exit(lExpected);
    end;
  end;
end;

class function TSchemaTypeMapper.IsSchemaNullable(pCompiled: ICompiledSchema): Boolean;
var
  lCompiled: TCompiledSchema;
  lKeyword: TObject;
  lTypeKeyword: TTypeKeyword;
  lExpected: string;
  lNullableVal: TJSONValue;
begin
  Result := False;
  if not Assigned(pCompiled) then
    Exit;
  if (pCompiled as TObject) is TCompiledSchema then
  begin
    lCompiled := pCompiled as TCompiledSchema;
    if Assigned(lCompiled.SchemaObj) then
    begin
      if lCompiled.SchemaObj.TryGetValue('nullable', lNullableVal) then
        Exit(lNullableVal is TJSONTrue);
    end;

    lKeyword := FindKeyword(pCompiled, TTypeKeyword);
    if Assigned(lKeyword) then
    begin
      lTypeKeyword := TTypeKeyword(lKeyword);
      for lExpected in lTypeKeyword.ExpectedTypes do
      begin
        if SameText(lExpected, 'null') then
          Exit(True);
      end;
    end;
  end;
end;

class function TSchemaTypeMapper.WrapNullable(const pTypeName: string; pCompiled: ICompiledSchema;
  const pConfig: TCodeGeneratorConfig): string;
begin
  if pConfig.UseNullableTypes and IsSchemaNullable(pCompiled) then
  begin
    if SameText(pTypeName, 'Integer') or SameText(pTypeName, 'Double') or
       SameText(pTypeName, 'Boolean') or SameText(pTypeName, 'TDateTime') or
       SameText(pTypeName, 'TDate') or SameText(pTypeName, 'TTime') or
       SameText(pTypeName, 'TGuid') then
    begin
      Exit(Format(pConfig.NullableTypeTemplate, [pTypeName]));
    end;
  end;
  Result := pTypeName;
end;

class procedure TSchemaTypeMapper.GenerateEnumFromSchema(pCompiled: ICompiledSchema; const pTypeName: string;
  const pContext: IGenerationContext);
var
  lKeyword: TObject;
  lEnumKeyword: TEnumKeyword;
  lEnumValues: TJSONArray;
  lJsonVal: TJSONValue;
  lVal, lEnumIdent: string;
  lPrefix: string;
  lDelphiEnum: TDelphiEnum;
begin
  lKeyword := FindKeyword(pCompiled, TEnumKeyword);
  if not Assigned(lKeyword) then
    Exit;

  lEnumKeyword := TEnumKeyword(lKeyword);
  lEnumValues := lEnumKeyword.EnumValues;

  lPrefix := Copy(pTypeName, 2, MaxInt);
  lDelphiEnum := TDelphiEnum.Create(pTypeName);
  try
    for lJsonVal in lEnumValues do
    begin
      lVal := lJsonVal.Value;
      lEnumIdent := SanitizeForEnumIdentifier(lVal, lPrefix);
      if lJsonVal is TJSONNumber then
        lDelphiEnum.Members.Add(Format('%s = %s', [lEnumIdent, lVal]))
      else
        lDelphiEnum.Members.Add(lEnumIdent);
    end;
    pContext.GetUnit.Enums.Add(lDelphiEnum);
  except
    lDelphiEnum.Free;
    raise;
  end;
end;

class function TSchemaTypeMapper.GetDelphiTypeForSchema(pCompiled: ICompiledSchema; const pPropName: string; out pType: TType;
  const pContext: IGenerationContext): string;
var
  lKeyword: TObject;
  lRefKeyword: TRefKeyword;
  lItemsKeyword: TItemsKeyword;
  lTypeName, lClassName: string;
  lCount: Integer;
  lJsonType, lJsonFormat: string;
  lCompiledSchema: TCompiledSchema;
  lRefStr: string;
  lRefName: TArray<string>;
  lItemType: string;
begin
  pType := tpClass;
  if not Assigned(pCompiled) then
  begin
    Result := 'TObject';
    Exit;
  end;

  // --- PASSO 1: Lidar com $ref ---
  lKeyword := FindKeyword(pCompiled, TRefKeyword);
  if Assigned(lKeyword) then
  begin
    lRefKeyword := TRefKeyword(lKeyword);
    if Assigned(lRefKeyword.ResolvedSchema) then
    begin
      lRefStr := lRefKeyword.RefPath;
      lRefName := lRefStr.Split(['/']);
      lTypeName := ToPascalCase(lRefName[High(lRefName)]);

      if not pContext.TryGetProcessedClass(lRefKeyword.ResolvedSchema, lClassName) then
      begin
        lCount := 1;
        while pContext.HasClassNameBeenGenerated(lTypeName) do
        begin
          lTypeName := ToPascalCase(lRefName[High(lRefName)]) + IntToStr(lCount);
          Inc(lCount);
        end;
        pContext.RegisterProcessedClass(lRefKeyword.ResolvedSchema, lTypeName);
        pContext.EnqueueClass(lTypeName, lRefKeyword.ResolvedSchema);
      end else
        lTypeName := lClassName;

      Result := lTypeName;
      Exit;
    end;
  end;

  // --- PASSO 2: Verificar se é um ENUM ---
  lKeyword := FindKeyword(pCompiled, TEnumKeyword);
  if Assigned(lKeyword) then
  begin
    pType := tpEnum;
    if SameText(GetPrimaryType(pCompiled), 'string') then
    begin
      pType := tpString;
      Exit(WrapNullable('string', pCompiled, pContext.GetConfig));
    end;

    if pContext.TryGetProcessedEnum(pCompiled, lTypeName) then
      Exit(WrapNullable(lTypeName, pCompiled, pContext.GetConfig));

    lTypeName := 'T' + ToPascalCase(pPropName);
    lCount := 1;
    while pContext.HasClassNameBeenGenerated(lTypeName) do
    begin
      lTypeName := 'T' + ToPascalCase(pPropName) + IntToStr(lCount);
      Inc(lCount);
    end;

    GenerateEnumFromSchema(pCompiled, lTypeName, pContext);
    pContext.RegisterProcessedEnum(pCompiled, lTypeName);
    Exit(WrapNullable(lTypeName, pCompiled, pContext.GetConfig));
  end;

  // --- PASSO 3: Verificar se já processamos ---
  if pContext.TryGetProcessedClass(pCompiled, lClassName) then
    Exit(lClassName);

  // --- PASSO 4: Determinar o tipo Delphi ---
  lJsonType := GetPrimaryType(pCompiled).ToLower;
  lJsonFormat := '';
  if (pCompiled as TObject) is TCompiledSchema then
  begin
    lCompiledSchema := pCompiled as TCompiledSchema;
    if Assigned(lCompiledSchema.SchemaObj) then
      lCompiledSchema.SchemaObj.TryGetValue<string>('format', lJsonFormat);
  end;

  if lJsonFormat = 'date-time' then
  begin
    pType := tpDateTime;
    Exit(WrapNullable('TDateTime', pCompiled, pContext.GetConfig));
  end;

  if lJsonFormat = 'date' then
  begin
    pType := tpDateTime;
    Exit(WrapNullable('TDate', pCompiled, pContext.GetConfig));
  end;

  if lJsonFormat = 'time' then
  begin
    pType := tpDateTime;
    Exit(WrapNullable('TTime', pCompiled, pContext.GetConfig));
  end;

  if lJsonFormat = 'uuid' then
  begin
    pType := tpUuid;
    Exit(WrapNullable('TGuid', pCompiled, pContext.GetConfig));
  end;

  if lJsonType = 'string' then
  begin
    pType := tpString;
    Result := 'string';
  end else if lJsonType = 'integer' then
  begin
    pType := tpNumber;
    Result := 'Integer';
  end else if lJsonType = 'number' then
  begin
    pType := tpNumber;
    Result := 'Double';
  end else if lJsonType = 'boolean' then
  begin
    pType := tpBoolean;
    Result := 'Boolean';
  end else if lJsonType = 'null' then
  begin
    pType := tpNull;
    Result := 'TObject';
  end else if (lJsonType = 'object') or Assigned(FindKeyword(pCompiled, TPropertiesKeyword)) then
  begin
    lClassName := 'T' + ToPascalCase(pPropName);
    lCount := 1;
    while pContext.HasClassNameBeenGenerated(lClassName) do
    begin
      lClassName := 'T' + ToPascalCase(pPropName) + IntToStr(lCount);
      Inc(lCount);
    end;
    Result := lClassName;
    pType := tpClass;

    pContext.RegisterProcessedClass(pCompiled, lClassName);
    pContext.EnqueueClass(lClassName, pCompiled);
  end else if lJsonType = 'array' then
  begin
    lKeyword := FindKeyword(pCompiled, TItemsKeyword);
    if Assigned(lKeyword) then
    begin
      lItemsKeyword := TItemsKeyword(lKeyword);
      if Assigned(lItemsKeyword.SingleSchema) then
      begin
        lItemType := GetDelphiTypeForSchema(lItemsKeyword.SingleSchema, pPropName, pType, pContext);
        pType := tpArray;
        Result := Format('TArray<%s>', [lItemType]);
      end else
        Result := 'TJSONArray';
    end else
      Result := 'TJSONArray';
  end else
    Result := 'TObject';

  Result := WrapNullable(Result, pCompiled, pContext.GetConfig);
end;

end.
