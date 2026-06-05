unit Schema2Delphi.AttributeProcessor;

(*
--------------------------------------------------------------------------------
Extracts JSON Schema validation and metadata properties, mapping them to
Delphi custom attributes on AST properties.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  Schema2Delphi.AST;

/// <summary>Parses schema constraints from JSON and adds matching Delphi attributes.</summary>
procedure ProcessPropertyAttributes(pSchemaObj: TJSONObject; pProperty: TDelphiProperty);

implementation

uses
  System.SysUtils;

procedure ProcessPropertyAttributes(pSchemaObj: TJSONObject; pProperty: TDelphiProperty);
var
  lPair: TJSONPair;
  lKeyword, lValueStr: string;
begin
  if not Assigned(pSchemaObj) or not Assigned(pProperty) then
    Exit;

  for lPair in pSchemaObj do
  begin
    lKeyword := lPair.JsonString.Value;
    if (lPair.JsonValue is TJSONObject) or (lPair.JsonValue is TJSONArray) or (lPair.JsonValue is TJSONNull) then
      Continue;

    lValueStr := lPair.JsonValue.Value;

    if lKeyword = 'title' then
      pProperty.Attributes.Add(Format('[TJsonSchemaTitle(''%s'')]', [lValueStr]))
    else if lKeyword = 'description' then
      pProperty.Attributes.Add(Format('[TJsonSchemaDescription(''%s'')]', [lValueStr]))
    else if lKeyword = 'maxLength' then
      pProperty.Attributes.Add(Format('[TJsonSchemaMaxLength(%s)]', [lValueStr]))
    else if lKeyword = 'minLength' then
      pProperty.Attributes.Add(Format('[TJsonSchemaMinLength(%s)]', [lValueStr]))
    else if lKeyword = 'pattern' then
      pProperty.Attributes.Add(Format('[TJsonSchemaPattern(''%s'')]', [lValueStr]))
    else if lKeyword = 'format' then
      pProperty.Attributes.Add(Format('[TJsonSchemaFormat(''%s'')]', [lValueStr]))
    else if lKeyword = 'maximum' then
      pProperty.Attributes.Add(Format('[TJsonSchemaMaximum(%s)]', [lValueStr]))
    else if lKeyword = 'minimum' then
      pProperty.Attributes.Add(Format('[TJsonSchemaMinimum(%s)]', [lValueStr]))
    else if lKeyword = 'multipleOf' then
      pProperty.Attributes.Add(Format('[TJsonSchemaMultipleOf(%s)]', [lValueStr]))
    else if lKeyword = 'deprecated' then
    begin
      if SameText(lValueStr, 'true') then
        pProperty.Attributes.Add('[TJsonSchemaDeprecated]');
    end else if lKeyword = 'readOnly' then
    begin
      if SameText(lValueStr, 'true') then
        pProperty.Attributes.Add('[TJsonSchemaReadOnly]');
    end else if lKeyword = 'writeOnly' then
    begin
      if SameText(lValueStr, 'true') then
        pProperty.Attributes.Add('[TJsonSchemaWriteOnly]');
    end;
  end;
end;

end.
