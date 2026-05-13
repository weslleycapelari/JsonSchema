unit Schema2Delphi.Utils;

interface

uses System.JSON;

function GenerateClassFromSchema(const ASchema: TJSONObject; const AClassName, AUnitName: string): string;

implementation

uses System.Classes, System.SysUtils, Schema2Delphi.Visitor, JsonSchema.Registry.Base;

function GenerateClassFromSchema(const ASchema: TJSONObject; const AClassName, AUnitName: string): string;
var
  LCodeGenerator: TJsonSchemaCodeGenerator;
  LRegistry: TRegistryVisitor;
  LBaseURI: string;
  LIdValue: TJSONValue;
  LBuilder: TStringBuilder;
begin
  // A URI base é crucial para resolver referências corretamente
  LBaseURI := 'urn:uuid:' + TGuid.NewGuid.ToString; // Gera uma URI anônima
  if (ASchema is TJSONObject) and ASchema.TryGetValue('$id', LIdValue) and (LIdValue is TJSONString) then
  begin
    LBaseURI := (LIdValue as TJSONString).Value;
  end;

  // --- PASSO 1: Criar e popular o Registry ---
  LRegistry := TRegistryVisitor.Create(ASchema, nil, LBaseURI);

  // --- PASSO 2: Instanciar e executar o gerador de código ---
  LCodeGenerator := TJsonSchemaCodeGenerator.Create(LRegistry);
  try
    LBuilder := TStringBuilder.Create;
    try
      LBuilder.AppendLine('unit ' + AUnitName + ';');
      LBuilder.AppendLine;
      LBuilder.AppendLine('interface');
      LBuilder.AppendLine;
      LBuilder.AppendLine('uses STS.API.Utils, STS.API.Types, Rest.JsonReflect;'); // Adicionar units necessárias
      LBuilder.AppendLine;
      LBuilder.AppendLine('type');
      // A chamada ao GenerateCode agora orquestra todo o processo de geração
      LBuilder.AppendLine(LCodeGenerator.GenerateCode(ASchema, 'T' + AClassName, LBaseURI).TrimRight);
      LBuilder.AppendLine;
      LBuilder.AppendLine('end.');
      Result := LBuilder.ToString;
    finally
      LBuilder.Free;
    end;
  finally
    LCodeGenerator.Free;
  end;
end;

end.
