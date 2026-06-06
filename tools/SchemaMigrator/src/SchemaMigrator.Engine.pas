unit SchemaMigrator.Engine;

(*
--------------------------------------------------------------------------------
Migration and Dialect Upgrade engine for JSON Schemas.
Converts Draft 4/6/7 schemas up to Draft 2020-12 specifications.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections;

type
  /// <summary>Core migrator class that performs keyword upgrades in JSON Schemas.</summary>
  TSchemaMigrator = class
  private
    procedure MigrateNode(pNode: TJSONValue);
    procedure MigrateDialect(pObj: TJSONObject);
    procedure MigrateDefinitions(pObj: TJSONObject);
    procedure MigrateDependencies(pObj: TJSONObject);
    procedure MigrateItems(pObj: TJSONObject);
    procedure MigrateId(pObj: TJSONObject);
    procedure RewriteRefs(pNode: TJSONValue);
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Migrates the legacy JSON Schema and returns the upgraded JSON string.</summary>
    function Migrate(pSchema: TJSONObject): string;
  end;

implementation

{ TSchemaMigrator }

constructor TSchemaMigrator.Create;
begin
  inherited Create;
end;

destructor TSchemaMigrator.Destroy;
begin
  inherited Destroy;
end;

procedure TSchemaMigrator.MigrateNode(pNode: TJSONValue);
var
  lObj: TJSONObject;
  lArr: TJSONArray;
  lI: Integer;
  lChildren: TList<TJSONValue>;
  lPair: TJSONPair;
begin
  if not Assigned(pNode) then
    Exit;

  if pNode is TJSONObject then
  begin
    lObj := TJSONObject(pNode);

    MigrateDialect(lObj);
    MigrateId(lObj);
    MigrateDefinitions(lObj);
    MigrateDependencies(lObj);
    MigrateItems(lObj);

    lChildren := TList<TJSONValue>.Create;
    try
      for lPair in lObj do
      begin
        lChildren.Add(lPair.JsonValue);
      end;

      for lI := 0 to lChildren.Count - 1 do
      begin
        MigrateNode(lChildren[lI]);
      end;
    finally
      lChildren.Free;
    end;
  end else if pNode is TJSONArray then
  begin
    lArr := TJSONArray(pNode);
    for lI := 0 to lArr.Count - 1 do
    begin
      MigrateNode(lArr.Items[lI]);
    end;
  end;
end;

procedure TSchemaMigrator.MigrateDialect(pObj: TJSONObject);
var
  lSchemaPair: TJSONPair;
begin
  lSchemaPair := pObj.Get('$schema');
  if Assigned(lSchemaPair) and (lSchemaPair.JsonValue is TJSONString) then
  begin
    pObj.RemovePair('$schema').Free;
    pObj.AddPair('$schema', 'https://json-schema.org/draft/2020-12/schema');
  end;
end;

procedure TSchemaMigrator.MigrateId(pObj: TJSONObject);
var
  lIdPair: TJSONPair;
  lVal: TJSONValue;
begin
  lIdPair := pObj.Get('id');
  if Assigned(lIdPair) and not (lIdPair.JsonString.Value = '$id') then
  begin
    lVal := lIdPair.JsonValue.Clone as TJSONValue;
    pObj.RemovePair('id').Free;
    if not Assigned(pObj.Values['$id']) then
      pObj.AddPair('$id', lVal)
    else
      lVal.Free;
  end;
end;

procedure TSchemaMigrator.MigrateDefinitions(pObj: TJSONObject);
var
  lDefsPair: TJSONPair;
  lVal: TJSONValue;
begin
  lDefsPair := pObj.Get('definitions');
  if Assigned(lDefsPair) then
  begin
    lVal := lDefsPair.JsonValue.Clone as TJSONValue;
    pObj.RemovePair('definitions').Free;
    if not Assigned(pObj.Values['$defs']) then
      pObj.AddPair('$defs', lVal)
    else
      lVal.Free;
  end;
end;

procedure TSchemaMigrator.MigrateDependencies(pObj: TJSONObject);
var
  lDeps: TJSONValue;
  lDepsObj: TJSONObject;
  lPair: TJSONPair;
  lDepRequired: TJSONObject;
  lDepSchemas: TJSONObject;
begin
  lDeps := pObj.Values['dependencies'];
  if Assigned(lDeps) and (lDeps is TJSONObject) then
  begin
    lDepsObj := TJSONObject(lDeps);
    lDepRequired := nil;
    lDepSchemas := nil;

    for lPair in lDepsObj do
    begin
      if lPair.JsonValue is TJSONArray then
      begin
        if not Assigned(lDepRequired) then
          lDepRequired := TJSONObject.Create;
        lDepRequired.AddPair(lPair.JsonString.Value, lPair.JsonValue.Clone as TJSONValue);
      end else if lPair.JsonValue is TJSONObject then
      begin
        if not Assigned(lDepSchemas) then
          lDepSchemas := TJSONObject.Create;
        lDepSchemas.AddPair(lPair.JsonString.Value, lPair.JsonValue.Clone as TJSONValue);
      end;
    end;

    pObj.RemovePair('dependencies').Free;

    if Assigned(lDepRequired) then
      pObj.AddPair('dependentRequired', lDepRequired);
    if Assigned(lDepSchemas) then
      pObj.AddPair('dependentSchemas', lDepSchemas);
  end;
end;

procedure TSchemaMigrator.MigrateItems(pObj: TJSONObject);
var
  lItemsPair: TJSONPair;
  lItemsVal: TJSONValue;
  lAddPair: TJSONPair;
  lAddVal: TJSONValue;
begin
  lItemsPair := pObj.Get('items');
  if Assigned(lItemsPair) and (lItemsPair.JsonValue is TJSONArray) then
  begin
    lItemsVal := lItemsPair.JsonValue.Clone as TJSONValue;
    pObj.RemovePair('items').Free;
    pObj.AddPair('prefixItems', lItemsVal);

    lAddPair := pObj.Get('additionalItems');
    if Assigned(lAddPair) then
    begin
      lAddVal := lAddPair.JsonValue.Clone as TJSONValue;
      pObj.RemovePair('additionalItems').Free;
      pObj.AddPair('items', lAddVal);
    end;
  end;
end;

procedure TSchemaMigrator.RewriteRefs(pNode: TJSONValue);
var
  lObj: TJSONObject;
  lArr: TJSONArray;
  lPair: TJSONPair;
  lI: Integer;
  lRefStr: string;
  lHashIdx: Integer;
  lPathPart: string;
begin
  if not Assigned(pNode) then
    Exit;

  if pNode is TJSONObject then
  begin
    lObj := TJSONObject(pNode);
    lPair := lObj.Get('$ref');
    if Assigned(lPair) and (lPair.JsonValue is TJSONString) then
    begin
      lRefStr := lPair.JsonValue.Value;
      lHashIdx := lRefStr.IndexOf('#');
      if lHashIdx >= 0 then
      begin
        lPathPart := Copy(lRefStr, lHashIdx + 2, Length(lRefStr));
        lPathPart := StringReplace(lPathPart, 'definitions/', '$defs/', [rfReplaceAll]);
        lObj.RemovePair('$ref').Free;
        lObj.AddPair('$ref', Copy(lRefStr, 1, lHashIdx + 1) + lPathPart);
      end;
    end;

    for lPair in lObj do
      RewriteRefs(lPair.JsonValue);
  end else if pNode is TJSONArray then
  begin
    lArr := TJSONArray(pNode);
    for lI := 0 to lArr.Count - 1 do
      RewriteRefs(lArr.Items[lI]);
  end;
end;

function TSchemaMigrator.Migrate(pSchema: TJSONObject): string;
var
  lReordered: TJSONObject;
  lPair: TJSONPair;
  lKey: string;
  lVal: TJSONValue;
  lTopKeys: TArray<string>;
  lTopKey: string;
begin
  if not Assigned(pSchema) then
    Exit('');

  MigrateNode(pSchema);
  RewriteRefs(pSchema);

  lReordered := TJSONObject.Create;
  try
    lTopKeys := TArray<string>.Create('$schema', '$id', 'title', 'description', 'type');

    for lTopKey in lTopKeys do
    begin
      lVal := pSchema.Values[lTopKey];
      if Assigned(lVal) then
      begin
        lReordered.AddPair(lTopKey, lVal.Clone as TJSONValue);
      end;
    end;

    for lPair in pSchema do
    begin
      lKey := lPair.JsonString.Value;
      if not (lKey = '$schema') and not (lKey = '$id') and not (lKey = 'title') and not (lKey = 'description') and not (lKey = 'type') then
      begin
        lReordered.AddPair(lKey, lPair.JsonValue.Clone as TJSONValue);
      end;
    end;

    Result := lReordered.Format(2);
  finally
    lReordered.Free;
  end;
end;

end.
