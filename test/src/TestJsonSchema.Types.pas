unit TestJsonSchema.Types;

interface

uses
  System.SysUtils;

type
  { Record responsável por transportar exclusivamente os dados de uma falha de validação.
    Atende ao Princípio da Responsabilidade Única (SRP) e KISS (record simples). }
  TJsonSchemaFailure = record
    DraftName: string;
    FilePath: string;
    TestDescription: string;
    SchemaPath: string;
    InstancePath: string;
    ErrorMessage: string;
    ExpectedValid: Boolean;
    ActualValid: Boolean;
  end;

  { Assinaturas de Callbacks usadas pelos Runners para notificar a UI ou Relatórios.
    Norma aplicada: Parâmetros iniciados em 'p' e delimitadores juntos ao token anterior. }
  TJsonSchemaProgressCallback = reference to procedure(const pProcessed, pTotal, pPassed, pFailed: Integer);

  TJsonSchemaFailureCallback = reference to procedure(const pFailure: TJsonSchemaFailure);

implementation

end.
