unit Schema2Delphi.Common;

(*
--------------------------------------------------------------------------------
Defines shared configuration types, enumeration categories, and interfaces
used across the Schema2Delphi generation architecture.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  JsonSchema.Core.Interfaces,
  Schema2Delphi.AST;

type
  /// <summary>Defines whether to output Pascal classes or records.</summary>
  TGenerationMode = (gmClass, gmRecord);

  /// <summary>Configures the output Pascal unit, usages, and nullable settings.</summary>
  TCodeGeneratorConfig = record
  public
    GenerationMode: TGenerationMode;
    CustomUses: string;
    UseNullableTypes: Boolean;
    NullableTypeTemplate: string;
    DraftVersion: TDraftVersion;
    class function DefaultConfig: TCodeGeneratorConfig; static;
  end;

  /// <summary>Categories of target Delphi types mapped from schemas.</summary>
  TType = (tpClass, tpArray, tpNumber, tpString, tpEnum, tpBoolean, tpNull, tpDateTime, tpUuid);

  /// <summary>Exposes the generation context API for modular helpers to interact with.</summary>
  IGenerationContext = interface
    ['{8E7A0C38-8D2A-443B-B03A-A6C1C13E7DC7}']
    function GetConfig: TCodeGeneratorConfig;
    function GetUnit: TDelphiUnit;
    function HasClassNameBeenGenerated(const pClassName: string): Boolean;
    procedure EnqueueClass(const pClassName: string; pCompiled: ICompiledSchema);
    function TryGetProcessedClass(pCompiled: ICompiledSchema; out pClassName: string): Boolean;
    procedure RegisterProcessedClass(pCompiled: ICompiledSchema; const pClassName: string);
    function TryGetProcessedEnum(pCompiled: ICompiledSchema; out pTypeName: string): Boolean;
    procedure RegisterProcessedEnum(pCompiled: ICompiledSchema; const pTypeName: string);
    function GenerateCode(pRootSchema: TJSONObject; const pRootClassName, pUnitName, pRootBaseURI: string): string;
  end;

implementation

{ TCodeGeneratorConfig }

class function TCodeGeneratorConfig.DefaultConfig: TCodeGeneratorConfig;
begin
  Result.GenerationMode := gmClass;
  Result.CustomUses := 'System.JSON, Rest.JsonReflect, System.Generics.Collections';
  Result.UseNullableTypes := False;
  Result.NullableTypeTemplate := 'TNullableValue<%s>';
  Result.DraftVersion := TDraftVersion.dvDraft2020_12;
end;

end.
