unit TestJsonSchema.Types;

(*
--------------------------------------------------------------------------------
Defines test records, types, and mock structures for the validation suites.
--------------------------------------------------------------------------------
*)


interface

uses
  System.SysUtils;

type
  { Record responsvel por transportar exclusivamente os dados de uma falha de validao.
    Atende ao Princpio da Responsabilidade nica (SRP) e KISS (record simples). }
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

  { Assinaturas de Callbacks usadas pelos Runners para notificar a UI ou Relatrios.
    Norma aplicada: Parmetros iniciados em 'p' e delimitadores juntos ao token anterior. }
  TJsonSchemaProgressCallback = reference to procedure(const pProcessed, pTotal, pPassed, pFailed: Integer);

  TJsonSchemaFailureCallback = reference to procedure(const pFailure: TJsonSchemaFailure);

implementation

end.
