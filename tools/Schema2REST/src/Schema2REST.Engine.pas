unit Schema2REST.Engine;

(*
--------------------------------------------------------------------------------
Schema2REST Engine - Generates validated REST Router/Controller units.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, Schema2REST.Templates;

type
  /// <summary>Supported REST frameworks.</summary>
  TRESTFramework = (rfHorse, rfDMVC);

  /// <summary>Generates Horse/DMVC REST endpoint units from JSON Schema.</summary>
  TSchema2RESTGenerator = class
  private
    FFramework: TRESTFramework;
    FEntityName: string;

    function EscapeJSONString(pSchema: TJSONObject): string;
  public
    constructor Create;

    /// <summary>Generates the complete Delphi router/controller unit.</summary>
    function GenerateRESTCode(pSchemaJson: TJSONObject; const pEntityName: string): string;

    property Framework: TRESTFramework read FFramework write FFramework;
    property EntityName: string read FEntityName write FEntityName;
  end;

implementation

{ TSchema2RESTGenerator }

constructor TSchema2RESTGenerator.Create;
begin
  inherited Create;
  FFramework := rfHorse; // Default
  FEntityName := 'MyEntity';
end;

function TSchema2RESTGenerator.EscapeJSONString(pSchema: TJSONObject): string;
var
  lRawJson: string;
begin
  if not Assigned(pSchema) then
    Exit('''''');

  lRawJson := pSchema.ToString;
  // Double single quotes to make it a valid Delphi string constant
  lRawJson := lRawJson.Replace('''', '''''');
  Result := '''' + lRawJson + '''';
end;

function TSchema2RESTGenerator.GenerateRESTCode(pSchemaJson: TJSONObject; const pEntityName: string): string;
var
  lEntity: string;
  lEntityLower: string;
  lEscapedSchema: string;
  lTemplate: string;
begin
  Result := '';
  if not Assigned(pSchemaJson) then
    Exit;

  lEntity := pEntityName;
  if lEntity = '' then
  begin
    lEntity := pSchemaJson.GetValue('title').Value;
    if lEntity = '' then
      lEntity := 'MyEntity';
  end;
  lEntity := lEntity.Replace(' ', '').Replace('-', ''); // Remove invalid chars for unit name

  lEntityLower := lEntity.ToLower;
  lEscapedSchema := EscapeJSONString(pSchemaJson);

  case FFramework of
    rfHorse:
      lTemplate := HORSE_TEMPLATE;
    rfDMVC:
      lTemplate := DMVC_TEMPLATE;
  else
    lTemplate := HORSE_TEMPLATE;
  end;

  Result := Format(lTemplate, [lEntity, lEscapedSchema, lEntityLower]);
end;

end.
