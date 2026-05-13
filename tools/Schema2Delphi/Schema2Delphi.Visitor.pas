unit Schema2Delphi.Visitor;

{
  ********************************************************************************

  Unidade do Gerador de Código da Biblioteca Delphi JSON Schema

  Copyright (c) 2025 [Seu Nome/Sua Empresa]

  Esta unidade contém a classe TJsonSchemaCodeGenerator, que implementa
  IJsonSchemaVisitor para gerar código fonte de uma classe Delphi a partir
  de um JSON Schema.

  O processo é o inverso do SchemaGenerator: o walker percorre o schema JSON
  e o CodeGenerator constrói uma string com a declaração de uma classe,
  incluindo propriedades e os atributos customizados da biblioteca.

  Esta funcionalidade é ideal para consumir schemas de fontes externas,
  gerando automaticamente os modelos de dados (DTOs - Data Transfer Objects)
  fortemente tipados para serem usados na aplicação.

  @version(1.0.0)
  @author(Seu Nome)
  @link(URL do seu repositório/documentação)

  ********************************************************************************
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Registry.Base;

type
  TClassToGenerate = class
  public
    ClassName: string;
    Schema: TJSONObject;
    BaseURI: string;
  end;

  TType = (tpClass, tpArray, tpNumber, tpString, tpEnum, tpBoolean, tpNull, tpDateTime, tpUuid);

  /// <summary>
  ///   Gera o código fonte de uma ou mais classes Delphi a partir de um JSON Schema.
  /// </summary>
  TJsonSchemaCodeGenerator = class
  private
    FRegistry: TRegistryVisitor;
    FGenerationQueue: TQueue<TClassToGenerate>;
    // Mapeia uma instância de TJSONObject para o nome da classe Delphi gerada
    FProcessedSchemas: TDictionary<TJSONObject, string>;
    // Mantém a lista de todas as classes geradas para criar forward declarations
    FGeneratedClassNames: TStringList;
    FTypesBuilder: TStringBuilder;
    FProcessedEnums: TDictionary<TJSONObject, string>;

    function ToPascalCase(const AValue: string): string;
    function SanitizeForEnumIdentifier(const ADescription: string; const APrefix: string = 'e'): string;
    procedure GenerateEnumFromSchema(ASchema: TJSONObject; const ATypeName: string);

    function GetDelphiTypeForSchema(APropSchema: TJSONObject; const APropName, ACurrentBaseURI: string; out AType: TType): string;
    procedure GenerateSingleClass(AClassInfo: TClassToGenerate; const ACodeBuilder, AImplBuilder: TStringBuilder);
    procedure ProcessPropertyAttributes(APropSchema: TJSONObject; const AAttributes: TStrings);
  public
    constructor Create(ARegistry: TRegistryVisitor);
    destructor Destroy; override;

    /// <summary>
    ///   Método principal que orquestra a geração do código.
    /// </summary>
    /// <param name="ARootSchema">O schema JSON a partir do qual gerar.</param>
    /// <param name="ARootClassName">O nome desejado para a classe raiz.</param>
    /// <param name="ARootBaseURI">A URI base do documento de schema raiz.</param>
    /// <returns>Uma string contendo o código Delphi gerado.</returns>
    function GenerateCode(ARootSchema: TJSONObject; const ARootClassName, ARootBaseURI: string): string;
  end;

implementation

uses
  System.StrUtils,
  System.RegularExpressions,
  JsonSchema.Walker,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Resource,
  JsonSchema.Common.Utils;

{ TJsonSchemaCodeGenerator }

constructor TJsonSchemaCodeGenerator.Create(ARegistry: TRegistryVisitor);
begin
  inherited Create;
  FRegistry := ARegistry;
  FGenerationQueue := TQueue<TClassToGenerate>.Create;
  FProcessedSchemas := TDictionary<TJSONObject, string>.Create;
  FGeneratedClassNames := TStringList.Create;
  FTypesBuilder := TStringBuilder.Create;
  FProcessedEnums := TDictionary<TJSONObject, string>.Create;
end;

destructor TJsonSchemaCodeGenerator.Destroy;
begin
  FGenerationQueue.Free;
  FProcessedSchemas.Free;
  FGeneratedClassNames.Free;
  FTypesBuilder.Free;
  FProcessedEnums.Free;
  inherited;
end;

function TJsonSchemaCodeGenerator.GenerateCode(ARootSchema: TJSONObject; const ARootClassName, ARootBaseURI: string): string;
var
  LForwardBuilder, LClassesBuilder, LImplBuilder: TStringBuilder;
  LRootInfo, LCurrentClassInfo: TClassToGenerate;
  LClassName: string;
begin
  // --- PASSO 1: Limpar estado e Popular o Registry ---
  FGenerationQueue.Clear;
  FProcessedSchemas.Clear;
  FGeneratedClassNames.Clear;
  FTypesBuilder.Clear;
  FProcessedEnums.Clear;
  // A própria fachada (TJsonSchema) já deve ter registrado o schema.
  // FRegistry.RegisterSchema(ARootSchema, ARootBaseURI); // Garante que o registry está pronto

  // --- PASSO 2: Enfileirar a Classe Raiz ---
  LRootInfo := TClassToGenerate.Create;
  LRootInfo.ClassName := ARootClassName;
  LRootInfo.Schema := ARootSchema;
  LRootInfo.BaseURI := ARootBaseURI;
  FGenerationQueue.Enqueue(LRootInfo);
  FProcessedSchemas.Add(ARootSchema, ARootClassName); // Marca o schema raiz como processado
  FGeneratedClassNames.Add(ARootClassName);

  // --- PASSO 3: Processar a Fila de Geração ---
  LImplBuilder := TStringBuilder.Create;
  LClassesBuilder := TStringBuilder.Create;
  try
    LImplBuilder.AppendLine('implementation')
      .AppendLine;

    while FGenerationQueue.Count > 0 do
    begin
      LCurrentClassInfo := FGenerationQueue.Dequeue;
      try
        GenerateSingleClass(LCurrentClassInfo, LClassesBuilder, LImplBuilder);
      finally
        LCurrentClassInfo.Free;
      end;
    end;

    // --- PASSO 4: Montar o Código Final com Forward Declarations ---
    LForwardBuilder := TStringBuilder.Create;
    try
      // Adiciona as declarações "TMyClass = class;" para todas as classes geradas
      for LClassName in FGeneratedClassNames do
      begin
        LForwardBuilder.AppendLine(Format('  %s = class;', [LClassName]));
      end;
      LForwardBuilder.AppendLine;

      // Concatena as forward declarations com o corpo das classes
      Result := FTypesBuilder.ToString + LForwardBuilder.ToString + LClassesBuilder.ToString + LImplBuilder.ToString;
    finally
      LForwardBuilder.Free;
    end;
  finally
    LImplBuilder.Free;
    LClassesBuilder.Free;
  end;
end;

procedure TJsonSchemaCodeGenerator.GenerateEnumFromSchema(ASchema: TJSONObject; const ATypeName: string);
var
  LExamples: TJSONArray;
  LEnumValues: TJSONArray;
  LValueMap: TDictionary<string, string>;
  LExample, LEnumMember, LValue, LDescription, LEnumIdent: string;
  LParts: TArray<string>;
begin
  FTypesBuilder.AppendLine(Format('  %s = Integer;', [ATypeName]));
  Exit;

  // Tenta obter 'examples' para os nomes e 'enum' para os valores
  if not ASchema.TryGetValue<TJSONArray>('examples', LExamples) or
     not ASchema.TryGetValue<TJSONArray>('enum', LEnumValues) then
    Exit; // Não é possível gerar o enum sem examples ou a lista de enum

  LValueMap := TDictionary<string, string>.Create;
  try
    // PASSO 1: Mapear valor para descrição a partir de 'examples'
    for var LJsonExample in LExamples do
    begin
      LExample := LJsonExample.Value;
      LParts := LExample.Split(['=']);
      if Length(LParts) = 2 then
        LValueMap.AddOrSetValue(LParts[0].Trim, LParts[1].Trim);
    end;

    // PASSO 2: Construir a string de declaração do enum
    FTypesBuilder.AppendLine(Format('  %s = (', [ATypeName]));
    var LEnumMembers := TStringList.Create;
    try
      for var LJsonValue in LEnumValues do
      begin
        LValue := LJsonValue.Value;
        // Tenta encontrar a descrição correspondente.
        if LValueMap.TryGetValue(LValue, LDescription) then
        begin
          LEnumIdent := SanitizeForEnumIdentifier(LDescription, Copy(ATypeName, 2, MaxInt));
          LEnumMember := Format('    %s = %s', [LEnumIdent, LValue]);
          LEnumMembers.Add(LEnumMember);
        end
        else
        begin
          // Fallback: Se não houver exemplo para este valor, geramos um nome genérico
          LEnumIdent := Format('value%s', [LValue]);
          LEnumMember := Format('    %s = %s', [LEnumIdent, LValue]);
          LEnumMembers.Add(LEnumMember);
        end;
      end;
      FTypesBuilder.AppendLine(LEnumMembers.Text.TrimRight.Replace(#13#10, ','#13#10));
    finally
      LEnumMembers.Free;
    end;
    FTypesBuilder.AppendLine('  );');
    FTypesBuilder.AppendLine;

  finally
    LValueMap.Free;
  end;
end;

procedure TJsonSchemaCodeGenerator.GenerateSingleClass(AClassInfo: TClassToGenerate; const ACodeBuilder, AImplBuilder: TStringBuilder);
var
  LFieldsBuilder, LPropsBuilder, LConstBuilder, LDestBuilder: TStringBuilder;
  LProperties: TJSONObject;
  LPropPair: TJSONPair;
  LPropSchema: TJSONObject;
  LPropName, LFieldName, LTypeName: string;
  LRequiredArray: TJSONArray;
  LAttributes: TStringList;
  LType: TType;
begin
  LAttributes := TStringList.Create;
  LDestBuilder := TStringBuilder.Create;
  LConstBuilder := TStringBuilder.Create;
  LPropsBuilder := TStringBuilder.Create;
  LFieldsBuilder := TStringBuilder.Create;
  try
    ACodeBuilder.AppendLine(Format('  %s = class', [AClassInfo.ClassName]));

    // Gera atributos no nível da classe
    ProcessPropertyAttributes(AClassInfo.Schema, LAttributes);
    //ACodeBuilder.Insert(ACodeBuilder.Length - AClassInfo.ClassName.Length - 10,
    //  LAttributes.Text.Trim.Replace(#13#10, #13#10'  ') + #13#10'  ');
    LAttributes.Clear;

    if AClassInfo.Schema.TryGetValue<TJSONObject>('properties', LProperties) then
    begin
      // Obtém a lista de propriedades obrigatórias
      AClassInfo.Schema.TryGetValue<TJSONArray>('required', LRequiredArray);

      for LPropPair in LProperties do
      begin
        LAttributes.Clear;
        if not (LPropPair.JsonValue is TJSONObject) then continue;

        LPropSchema := LPropPair.JsonValue as TJSONObject;
        LPropName := LPropPair.JsonString.Value;
        LFieldName := 'F' + LPropName;

        // Adiciona o atributo [TJsonSchemaProperty] se o nome da propriedade Delphi for diferente
        //if LPropName <> LPropPair.JsonString.Value then
        //  LAttributes.Add(Format('[TJsonSchemaProperty(''%s'')]', [LPropPair.JsonString.Value]));

        // Adiciona o atributo [JsonSchema_Required]
        if Assigned(LRequiredArray) then
        begin
          for var LReqValue in LRequiredArray do
            if LReqValue.Value = LPropPair.JsonString.Value then
            begin
              LAttributes.Add('[JsonSchema_Required]');
              break;
            end;
        end;

        // Processa todos os outros atributos da propriedade
        //ProcessPropertyAttributes(LPropSchema, LAttributes);

        // Obtém o tipo Delphi. Esta chamada pode enfileirar novas classes.
        LTypeName := GetDelphiTypeForSchema(LPropSchema, LPropName, AClassInfo.BaseURI, LType);

        case LType of
          tpClass: LConstBuilder.AppendLine(Format('  %s := %s.Create;', [LPropName, LTypeName]));
          tpArray: LConstBuilder.AppendLine(Format('  %s := [];', [LPropName]));
        end;

        case LType of
          tpClass: LDestBuilder.AppendLine(Format('  %s.Free;', [LPropName]));
          tpArray: LDestBuilder.AppendLine(Format('  Finalize(%s);', [LPropName]));
        end;

        //LFieldsBuilder.AppendLine(Format('    %s: %s;', [LFieldName, LTypeName]));

        if LAttributes.Count > 0 then
          LPropsBuilder.AppendLine('    ' + LAttributes.Text.Trim.Replace(#13#10, #13#10 + '    '));

        //LPropsBuilder.AppendLine(Format('    property %s: %s read %s write %s;', [LPropName, LTypeName, LFieldName, LFieldName]));
        LPropsBuilder.AppendLine(Format('    %s: %s;', [LPropName, LTypeName]));
      end;
    end;

    if not LFieldsBuilder.ToString.IsEmpty then
    begin
      ACodeBuilder.AppendLine('  private');
      ACodeBuilder.Append(LFieldsBuilder.ToString);
    end;

    if not LPropsBuilder.ToString.IsEmpty then
      ACodeBuilder.Append(LPropsBuilder.ToString);

    if (not LConstBuilder.ToString.IsEmpty) or (not LDestBuilder.ToString.IsEmpty) or (not LPropsBuilder.ToString.IsEmpty) then
      ACodeBuilder.AppendLine('  public');

    if not LConstBuilder.ToString.IsEmpty then
      ACodeBuilder.AppendLine('    constructor Create;');

    if not LDestBuilder.ToString.IsEmpty then
      ACodeBuilder.AppendLine('    destructor Destroy; override;');

    ACodeBuilder.AppendLine('  end;');
    ACodeBuilder.AppendLine;

    if not LConstBuilder.ToString.IsEmpty then
    begin
      AImplBuilder.AppendLine(Format('constructor %s.Create;', [AClassInfo.ClassName]));
      AImplBuilder.AppendLine('begin');
      AImplBuilder.AppendLine(LConstBuilder.ToString.TrimRight);
      AImplBuilder.AppendLine('end;');
      AImplBuilder.AppendLine;
    end;

    if not LDestBuilder.ToString.IsEmpty then
    begin
      AImplBuilder.AppendLine(Format('destructor %s.Destroy;', [AClassInfo.ClassName]));
      AImplBuilder.AppendLine('begin');
      AImplBuilder.AppendLine(LDestBuilder.ToString.TrimRight);
      AImplBuilder.AppendLine('  inherited;');
      AImplBuilder.AppendLine('end;');
      AImplBuilder.AppendLine;
    end;

  finally
    LAttributes.Free;
    LDestBuilder.Free;
    LConstBuilder.Free;
    LPropsBuilder.Free;
    LFieldsBuilder.Free;
  end;
end;

function TJsonSchemaCodeGenerator.GetDelphiTypeForSchema(APropSchema: TJSONObject; const APropName, ACurrentBaseURI: string;
  out AType: TType): string;
var
  LJsonType, LJsonFormat, LItemType, LClassName, LRefStr: string;
  LItemsSchema, LResolvedValue, LNullable: TJSONValue;
  LNewClassInfo: TClassToGenerate;
  LRefName: TArray<string>;
  LTypeName: string;
  LCount: Integer;
  LFinalURI: TURIReference;
  LTargetResource: TResource;
begin
  AType := tpClass;
  // --- PASSO 1: Lidar com $ref ---
  if APropSchema.TryGetValue<string>('$ref', LRefStr) then
  begin
    LFinalURI := TURIReference.From(LRefStr).ResolveWith(TURIReference.From(ACurrentBaseURI));
    if FRegistry.TryFindResource(LFinalURI.Unsplit, LTargetResource) then
    begin
      LResolvedValue := LTargetResource.ResolveFragment(LFinalURI.Fragment);
      if Assigned(LResolvedValue) and (LResolvedValue is TJSONObject) then
      begin
        APropSchema := LResolvedValue as TJSONObject;
        // Deriva um nome para a classe a partir do final da referência
        LRefName := LRefStr.Split(['/']);
        Result := ToPascalCase(LRefName[High(LRefName)]);
      end
      else
      begin
        Result := 'TObject'; // Falha ao resolver, fallback
        Exit;
      end;
    end;
  end;

  // --- PASSO 2: Verificar se é um ENUM que podemos gerar ---
  if APropSchema.TryGetValue('enum', LNullable) then
  begin
    AType := tpEnum;

    if APropSchema.TryGetValue('type', LJsonType) and (LJsonType.ToLower = 'string') then
    begin
      AType := tpString;
      Exit('string');
    end;

    if not APropSchema.TryGetValue('examples', LNullable) then
      Exit('Integer');

    // Verifica se já processamos este enum
    if FProcessedEnums.TryGetValue(APropSchema, LTypeName) then
      Exit(LTypeName);

    // É um novo enum para gerar!
    LTypeName := 'T' + ToPascalCase(APropName);
    LCount := 1;
    while (FProcessedEnums.ContainsValue(LTypeName)) do
    begin
      LTypeName := 'T' + ToPascalCase(APropName) + IntToStr(LCount);
      Inc(LCount);
    end;

    GenerateEnumFromSchema(APropSchema, LTypeName); // Gera o código do tipo enum
    FProcessedEnums.Add(APropSchema, LTypeName); // Marca como processado
    Exit(LTypeName); // Retorna o nome do nosso novo tipo enum
  end;

  // --- PASSO 3: Verificar se já processamos este schema ---
  if FProcessedSchemas.TryGetValue(APropSchema, LClassName) then
    Exit(LClassName);

  // --- PASSO 4: Determinar o tipo Delphi ---
  LJsonType := APropSchema.GetValue<string>('type', 'object').ToLower;
  LJsonFormat := APropSchema.GetValue<string>('format', '');

  if LJsonFormat = 'date-time' then
  begin
    AType := tpDateTime;
    Exit('TDateTime');
  end;

  if LJsonFormat = 'date' then
  begin
    AType := tpDateTime;
    Exit('TDate');
  end;

  if LJsonFormat = 'time' then
  begin
    AType := tpDateTime;
    Exit('TTime');
  end;

  if LJsonFormat = 'uuid' then
  begin
    AType := tpUuid;
    Exit('TGuid');
  end;

  if LJsonType = 'string' then
  begin
    AType := tpString;
    Result := 'string';
  end
  else if LJsonType = 'integer' then
  begin
    AType := tpNumber;
    Result := 'Integer';
  end
  else if LJsonType = 'number' then
  begin
    AType := tpNumber;
    Result := 'Double';
  end
  else if LJsonType = 'boolean' then
  begin
    AType := tpBoolean;
    Result := 'Boolean';
  end
  else if LJsonType = 'null' then
  begin
    AType := tpNull;
    Result := 'TObject';
  end
  else if LJsonType = 'object' then
  begin
    // --- É um novo objeto. Precisamos gerar uma classe para ele. ---
    LClassName := 'T' + ToPascalCase(APropName);
    LCount := 1;
    while (FProcessedSchemas.ContainsValue(LClassName)) do
    begin
      LClassName := 'T' + ToPascalCase(APropName) + IntToStr(LCount);
      Inc(LCount);
    end;
    Result := LClassName;
    AType := tpClass;

    // Adiciona na fila para ser gerado depois
    LNewClassInfo := TClassToGenerate.Create;
    LNewClassInfo.ClassName := LClassName;
    LNewClassInfo.Schema := APropSchema;
    LNewClassInfo.BaseURI := ACurrentBaseURI; // Propaga a URI base
    FGenerationQueue.Enqueue(LNewClassInfo);

    FProcessedSchemas.Add(APropSchema, LClassName); // Marca como agendado/processado
    FGeneratedClassNames.Add(LClassName);
  end
  else if LJsonType = 'array' then
  begin
    if APropSchema.TryGetValue('items', LItemsSchema) and (LItemsSchema is TJSONObject) then
    begin
      // Chamada recursiva para obter o tipo do item do array
      LItemType := GetDelphiTypeForSchema(LItemsSchema as TJSONObject, APropName, ACurrentBaseURI, AType);
      AType := tpArray;
      Result := Format('TArray<%s>', [LItemType]);
    end
    else
      Result := 'TJSONArray'; // Fallback se 'items' não for um schema de objeto
  end
  else
    Result := 'TObject'; // Fallback
end;

function TJsonSchemaCodeGenerator.SanitizeForEnumIdentifier(const ADescription: string; const APrefix: string = 'e'): string;
var
  LCleanDesc: string;
begin
  // 1. Remove caracteres especiais e substitui espaços
  LCleanDesc := TRegEx.Replace(ADescription, '[^a-zA-Z0-9_\-]', '').ToLower;
  LCleanDesc := ToPascalCase(LCleanDesc); // Usa a função existente para capitalização

  // 2. Garante que não comece com um número e adiciona um prefixo
  if LCleanDesc.IsEmpty then
    Result := APrefix + 'Unknown'
  else
    Result := APrefix + LCleanDesc;
end;

procedure TJsonSchemaCodeGenerator.ProcessPropertyAttributes(APropSchema: TJSONObject; const AAttributes: TStrings);
var
  LPair: TJSONPair;
  LKeyword, LValueStr: string;
begin
  for LPair in APropSchema do
  begin
    LKeyword := LPair.JsonString.Value;
    LValueStr := LPair.JsonValue.Value; // Simplificação, funciona para string/number/bool

    if LKeyword = 'title' then
      AAttributes.Add(Format('[TJsonSchemaTitle(''%s'')]', [LValueStr]))
    else if LKeyword = 'description' then
      AAttributes.Add(Format('[TJsonSchemaDescription(''%s'')]', [LValueStr]))
    else if LKeyword = 'maxLength' then
      AAttributes.Add(Format('[TJsonSchemaMaxLength(%s)]', [LValueStr]))
    else if LKeyword = 'minLength' then
      AAttributes.Add(Format('[TJsonSchemaMinLength(%s)]', [LValueStr]))
    else if LKeyword = 'pattern' then
      AAttributes.Add(Format('[TJsonSchemaPattern(''%s'')]', [LValueStr]))
    else if LKeyword = 'format' then
      AAttributes.Add(Format('[TJsonSchemaFormat(''%s'')]', [LValueStr]))
    else if LKeyword = 'maximum' then
      AAttributes.Add(Format('[TJsonSchemaMaximum(%s)]', [LValueStr]))
    else if LKeyword = 'minimum' then
      AAttributes.Add(Format('[TJsonSchemaMinimum(%s)]', [LValueStr]))
    else if LKeyword = 'multipleOf' then
      AAttributes.Add(Format('[TJsonSchemaMultipleOf(%s)]', [LValueStr]))
    else if LKeyword = 'deprecated' then
      if SameText(LValueStr, 'true') then AAttributes.Add('[TJsonSchemaDeprecated]')
    else if LKeyword = 'readOnly' then
      if SameText(LValueStr, 'true') then AAttributes.Add('[TJsonSchemaReadOnly]')
    else if LKeyword = 'writeOnly' then
      if SameText(LValueStr, 'true') then AAttributes.Add('[TJsonSchemaWriteOnly]');
    // Adicionar outros atributos aqui conforme necessário...
  end;
end;

function TJsonSchemaCodeGenerator.ToPascalCase(const AValue: string): string;
var
  I: Integer;
  IsNewWord: Boolean;
begin
  if AValue.IsEmpty then Exit('');

  Result := '';
  IsNewWord := True;

  for I := 1 to Length(AValue) do
  begin
    if CharInSet(AValue[I], [' ', '_', '-']) then
    begin
      IsNewWord := True;
    end
    else if IsNewWord then
    begin
      Result := Result + UpperCase(AValue[I]);
      IsNewWord := False;
    end
    else
    begin
      Result := Result + AValue[I];
    end;
  end;
end;

end.
