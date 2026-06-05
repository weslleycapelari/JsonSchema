unit Schema2Delphi.Visitor;

(*
--------------------------------------------------------------------------------
AST traversal and code generation engine converting compiled JSON Schema objects
into Delphi Code AST units.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Core.Interfaces,
  Schema2Delphi.AST,
  Schema2Delphi.Common;

type
  /// <summary>Represents a metadata info class to generate.</summary>
  TClassToGenerate = class
  public
    ClassName: string;
    Compiled: ICompiledSchema;
    constructor Create(const pClassName: string; const pCompiled: ICompiledSchema);
  end;

  /// <summary>Code generator implementing context interface for modular mapping helpers.</summary>
  TJsonSchemaCodeGenerator = class(TInterfacedObject, IGenerationContext)
  private
    FConfig: TCodeGeneratorConfig;
    FGenerationQueue: TQueue<TClassToGenerate>;
    FProcessedSchemas: TDictionary<ICompiledSchema, string>;
    FGeneratedClassNames: TStringList;
    FProcessedEnums: TDictionary<ICompiledSchema, string>;
    FUnit: TDelphiUnit;

    // IGenerationContext Implementation
    function GetConfig: TCodeGeneratorConfig;
    function GetUnit: TDelphiUnit;
    function HasClassNameBeenGenerated(const pClassName: string): Boolean;
    procedure EnqueueClass(const pClassName: string; pCompiled: ICompiledSchema);
    function TryGetProcessedClass(pCompiled: ICompiledSchema; out pClassName: string): Boolean;
    procedure RegisterProcessedClass(pCompiled: ICompiledSchema; const pClassName: string);
    function TryGetProcessedEnum(pCompiled: ICompiledSchema; out pTypeName: string): Boolean;
    procedure RegisterProcessedEnum(pCompiled: ICompiledSchema; const pTypeName: string);
    function GenerateCode(pRootSchema: TJSONObject; const pRootClassName, pUnitName, pRootBaseURI: string): string;

    // Private AST Generation Helpers
    procedure ProcessClassProperty(pDelphiClass: TDelphiClass; const pPropKey, pPropName, pTypeName: string; pType: TType);
    procedure ProcessRecordProperty(pDelphiClass: TDelphiClass; const pPropKey, pPropName, pTypeName: string);
    procedure PopulatePropertyAttributes(pDelphiProp: TDelphiProperty; pPropSchema: ICompiledSchema; const pPropKey: string;
      pRequiredArray: TJSONArray);
    procedure GenerateSingleClass(pClassInfo: TClassToGenerate);
  public
    constructor Create(const pConfig: TCodeGeneratorConfig);
    destructor Destroy; override;
  end;

implementation

uses
  JsonSchema.Keywords.Properties,
  JsonSchema.Keywords.Required,
  JsonSchema.CompiledSchema,
  JsonSchema.Draft6.Parser,
  JsonSchema.Draft7.Parser,
  JsonSchema.Draft2019_09.Parser,
  JsonSchema.Draft2020_12.Parser,
  Schema2Delphi.Sanitizer,
  Schema2Delphi.TypeMapper,
  Schema2Delphi.AttributeProcessor;

{ TClassToGenerate }

constructor TClassToGenerate.Create(const pClassName: string; const pCompiled: ICompiledSchema);
begin
  inherited Create;
  ClassName := pClassName;
  Compiled := pCompiled;
end;

{ TJsonSchemaCodeGenerator }

constructor TJsonSchemaCodeGenerator.Create(const pConfig: TCodeGeneratorConfig);
begin
  inherited Create;
  FConfig := pConfig;
  FGenerationQueue := TQueue<TClassToGenerate>.Create;
  FProcessedSchemas := TDictionary<ICompiledSchema, string>.Create;
  FGeneratedClassNames := TStringList.Create;
  FProcessedEnums := TDictionary<ICompiledSchema, string>.Create;
  FUnit := nil;
end;

destructor TJsonSchemaCodeGenerator.Destroy;
begin
  FGenerationQueue.Free;
  FProcessedSchemas.Free;
  FGeneratedClassNames.Free;
  FProcessedEnums.Free;
  if Assigned(FUnit) then
    FUnit.Free;
  inherited;
end;

function TJsonSchemaCodeGenerator.GetConfig: TCodeGeneratorConfig;
begin
  Result := FConfig;
end;

function TJsonSchemaCodeGenerator.GetUnit: TDelphiUnit;
begin
  Result := FUnit;
end;

function TJsonSchemaCodeGenerator.HasClassNameBeenGenerated(const pClassName: string): Boolean;
begin
  Result := FGeneratedClassNames.Contains(pClassName);
end;

procedure TJsonSchemaCodeGenerator.EnqueueClass(const pClassName: string; pCompiled: ICompiledSchema);
begin
  FGenerationQueue.Enqueue(TClassToGenerate.Create(pClassName, pCompiled));
  FGeneratedClassNames.Add(pClassName);
end;

function TJsonSchemaCodeGenerator.TryGetProcessedClass(pCompiled: ICompiledSchema; out pClassName: string): Boolean;
begin
  Result := FProcessedSchemas.TryGetValue(pCompiled, pClassName);
end;

procedure TJsonSchemaCodeGenerator.RegisterProcessedClass(pCompiled: ICompiledSchema; const pClassName: string);
begin
  FProcessedSchemas.Add(pCompiled, pClassName);
end;

function TJsonSchemaCodeGenerator.TryGetProcessedEnum(pCompiled: ICompiledSchema; out pTypeName: string): Boolean;
begin
  Result := FProcessedEnums.TryGetValue(pCompiled, pTypeName);
end;

procedure TJsonSchemaCodeGenerator.RegisterProcessedEnum(pCompiled: ICompiledSchema; const pTypeName: string);
begin
  FProcessedEnums.Add(pCompiled, pTypeName);
end;

function TJsonSchemaCodeGenerator.GenerateCode(pRootSchema: TJSONObject; const pRootClassName, pUnitName, pRootBaseURI: string): string;
var
  lRootCompiled: ICompiledSchema;
  lRootInfo, lCurrentClassInfo: TClassToGenerate;
begin
  // --- PASSO 1: Limpar estado ---
  FGenerationQueue.Clear;
  FProcessedSchemas.Clear;
  FGeneratedClassNames.Clear;
  FProcessedEnums.Clear;
  if Assigned(FUnit) then
    FreeAndNil(FUnit);

  FUnit := TDelphiUnit.Create(pUnitName, FConfig.CustomUses);

  // --- PASSO 2: Compilar o Schema JSON utilizando o Parser adequado ---
  case FConfig.DraftVersion of
    TDraftVersion.dvDraft6: lRootCompiled := TDraft6Parser.Parse(pRootSchema);
    TDraftVersion.dvDraft7: lRootCompiled := TDraft7Parser.Parse(pRootSchema);
    TDraftVersion.dvDraft2019_09: lRootCompiled := TDraft2019_09Parser.Parse(pRootSchema);
    TDraftVersion.dvDraft2020_12: lRootCompiled := TDraft2020_12Parser.Parse(pRootSchema);
  else
    lRootCompiled := TDraft2020_12Parser.Parse(pRootSchema);
  end;

  // --- PASSO 3: Enfileirar a Classe Raiz ---
  lRootInfo := TClassToGenerate.Create(pRootClassName, lRootCompiled);
  FGenerationQueue.Enqueue(lRootInfo);
  FProcessedSchemas.Add(lRootCompiled, pRootClassName);
  FGeneratedClassNames.Add(pRootClassName);

  // --- PASSO 4: Processar a Fila de Geração ---
  while FGenerationQueue.Count > 0 do
  begin
    lCurrentClassInfo := FGenerationQueue.Dequeue;
    try
      GenerateSingleClass(lCurrentClassInfo);
    finally
      lCurrentClassInfo.Free;
    end;
  end;

  // --- PASSO 5: Obter código serializado ---
  Result := FUnit.GenerateSourceCode;
end;

procedure TJsonSchemaCodeGenerator.ProcessClassProperty(pDelphiClass: TDelphiClass; const pPropKey, pPropName, pTypeName:
  string; pType: TType);
var
  lFieldName: string;
begin
  lFieldName := 'F' + pPropName;
  pDelphiClass.Fields.Add(TDelphiField.Create(lFieldName, pTypeName));
  pDelphiClass.Properties.Add(TDelphiProperty.Create(pPropName, pTypeName, lFieldName));

  if pType = tpClass then
  begin
    pDelphiClass.ConstructorLines.Add(Format('  %s := %s.Create;', [lFieldName, pTypeName]));
    pDelphiClass.DestructorLines.Add(Format('  %s.Free;', [lFieldName]));
  end else if pType = tpArray then
  begin
    if pTypeName.StartsWith('TArray<T') and not pTypeName.Contains('TDateTime') and not pTypeName.Contains('TGuid') then
    begin
      pDelphiClass.DestructorLines.Add(Format('  if Assigned(%s) then', [lFieldName]));
      pDelphiClass.DestructorLines.Add('  begin');
      pDelphiClass.DestructorLines.Add(Format('    for var lI := 0 to Length(%s) - 1 do', [lFieldName]));
      pDelphiClass.DestructorLines.Add(Format('      %s[lI].Free;', [lFieldName]));
      pDelphiClass.DestructorLines.Add('  end;');
    end;
    pDelphiClass.DestructorLines.Add(Format('  Finalize(%s);', [lFieldName]));
  end;
end;

procedure TJsonSchemaCodeGenerator.ProcessRecordProperty(pDelphiClass: TDelphiClass; const pPropKey, pPropName, pTypeName: string);
begin
  pDelphiClass.Properties.Add(TDelphiProperty.Create(pPropName, pTypeName, ''));
end;

procedure TJsonSchemaCodeGenerator.PopulatePropertyAttributes(pDelphiProp: TDelphiProperty; pPropSchema: ICompiledSchema;
  const pPropKey: string; pRequiredArray: TJSONArray);
var
  lReqValue: TJSONValue;
  lCompiled: TCompiledSchema;
begin
  if pDelphiProp.Name <> pPropKey then
    pDelphiProp.Attributes.Add(Format('[JSONName(''%s'')]', [pPropKey]));

  if Assigned(pRequiredArray) then
  begin
    for lReqValue in pRequiredArray do
    begin
      if lReqValue.Value = pPropKey then
      begin
        pDelphiProp.Attributes.Add('[JsonSchema_Required]');
        break;
      end;
    end;
  end;

  if (pPropSchema as TObject) is TCompiledSchema then
  begin
    lCompiled := pPropSchema as TCompiledSchema;
    if Assigned(lCompiled.SchemaObj) then
      ProcessPropertyAttributes(lCompiled.SchemaObj, pDelphiProp);
  end;
end;

procedure TJsonSchemaCodeGenerator.GenerateSingleClass(pClassInfo: TClassToGenerate);
var
  lDelphiClass: TDelphiClass;
  lPropertiesKeyword: TPropertiesKeyword;
  lRequiredKeyword: TRequiredKeyword;
  lKeyword: TObject;
  lPropKey: string;
  lPropSchema: ICompiledSchema;
  lPropName, lTypeName: string;
  lRequiredArray: TJSONArray;
  lType: TType;
  lIsRecord: Boolean;
  lDelphiProp: TDelphiProperty;
begin
  lIsRecord := FConfig.GenerationMode = gmRecord;
  lDelphiClass := TDelphiClass.Create(pClassInfo.ClassName, lIsRecord);
  try
    lKeyword := TSchemaTypeMapper.FindKeyword(pClassInfo.Compiled, TPropertiesKeyword);
    if Assigned(lKeyword) then
    begin
      lPropertiesKeyword := TPropertiesKeyword(lKeyword);
      
      lRequiredKeyword := TRequiredKeyword(TSchemaTypeMapper.FindKeyword(pClassInfo.Compiled, TRequiredKeyword));
      if Assigned(lRequiredKeyword) then
        lRequiredArray := lRequiredKeyword.RequiredProperties
      else
        lRequiredArray := nil;

      for lPropKey in lPropertiesKeyword.Properties.Keys do
      begin
        lPropSchema := lPropertiesKeyword.Properties[lPropKey];
        lPropName := SanitizePropertyName(lPropKey);

        lTypeName := TSchemaTypeMapper.GetDelphiTypeForSchema(lPropSchema, lPropName, lType, Self);

        if lIsRecord then
          ProcessRecordProperty(lDelphiClass, lPropKey, lPropName, lTypeName)
        else
          ProcessClassProperty(lDelphiClass, lPropKey, lPropName, lTypeName, lType);

        // Process property validation/metadata attributes
        lDelphiProp := lDelphiClass.Properties[lDelphiClass.Properties.Count - 1];
        PopulatePropertyAttributes(lDelphiProp, lPropSchema, lPropKey, lRequiredArray);
      end;
    end;
    FUnit.Classes.Add(lDelphiClass);
  except
    lDelphiClass.Free;
    raise;
  end;
end;

end.
