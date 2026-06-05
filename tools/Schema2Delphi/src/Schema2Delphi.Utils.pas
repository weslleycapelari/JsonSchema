unit Schema2Delphi.Utils;

(*
--------------------------------------------------------------------------------
High-level utility functions to coordinate JSON Schema compilation and code
generation.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  Schema2Delphi.Visitor,
  Schema2Delphi.Common;

/// <summary>Generates Delphi source code from a JSON Schema using default settings.</summary>
/// <param name="pSchema">The raw JSON schema object.</param>
/// <param name="pClassName">The root class/record name.</param>
/// <param name="pUnitName">The output unit name.</param>
/// <returns>The generated Pascal source code.</returns>
function GenerateClassFromSchema(const pSchema: TJSONObject; const pClassName, pUnitName: string): string; overload;

/// <summary>Generates Delphi source code from a JSON Schema with custom configuration.</summary>
/// <param name="pSchema">The raw JSON schema object.</param>
/// <param name="pClassName">The root class/record name.</param>
/// <param name="pUnitName">The output unit name.</param>
/// <param name="pConfig">The code generator settings.</param>
/// <returns>The generated Pascal source code.</returns>
function GenerateClassFromSchema(const pSchema: TJSONObject; const pClassName, pUnitName: string;
  const pConfig: TCodeGeneratorConfig): string; overload;

implementation

uses
  System.SysUtils;

function GenerateClassFromSchema(const pSchema: TJSONObject; const pClassName, pUnitName: string): string;
begin
  Result := GenerateClassFromSchema(pSchema, pClassName, pUnitName, TCodeGeneratorConfig.DefaultConfig);
end;

function GenerateClassFromSchema(const pSchema: TJSONObject; const pClassName, pUnitName: string;
  const pConfig: TCodeGeneratorConfig): string;
var
  lCodeGenerator: IGenerationContext;
  lBaseURI: string;
  lIdValue: TJSONValue;
begin
  lBaseURI := 'urn:uuid:' + TGuid.NewGuid.ToString;
  if (pSchema is TJSONObject) and pSchema.TryGetValue('$id', lIdValue) and (lIdValue is TJSONString) then
  begin
    lBaseURI := (lIdValue as TJSONString).Value;
  end;

  lCodeGenerator := TJsonSchemaCodeGenerator.Create(pConfig);
  Result := lCodeGenerator.GenerateCode(pSchema, 'T' + pClassName, pUnitName, lBaseURI);
end;

end.
