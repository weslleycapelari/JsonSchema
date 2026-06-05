unit Schema2DDL.Engine;

(*
--------------------------------------------------------------------------------
Schema2DDL Engine - Translates JSON Schema documents to relational SQL DDL.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections, Schema2DDL.Dialects;

type
  /// <summary>Translates JSON Schema objects into database table DDL statements.</summary>
  TSchema2DDLGenerator = class
  private
    FDialect: ISQLDialect;
    FGenerateDropTable: Boolean;
    FAutoIncPk: Boolean;
    FQuoteIdentifiers: Boolean;
    FGeneratedTables: TStringList;

    procedure ProcessSchemaObject(const pTableName: string; pSchema: TJSONObject; pOutputList: TStringList);
    function IsPropertyRequired(pSchema: TJSONObject; const pPropName: string): Boolean;
    function CleanTableName(const pName: string): string;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Generates complete DDL script from a JSON Schema.</summary>
    function GenerateDDL(pSchema: TJSONObject; const pMainTableName: string): string;

    property Dialect: ISQLDialect read FDialect write FDialect;
    property GenerateDropTable: Boolean read FGenerateDropTable write FGenerateDropTable;
    property AutoIncPk: Boolean read FAutoIncPk write FAutoIncPk;
    property QuoteIdentifiers: Boolean read FQuoteIdentifiers write FQuoteIdentifiers;
  end;

implementation

{ TSchema2DDLGenerator }

constructor TSchema2DDLGenerator.Create;
begin
  inherited Create;
  FDialect := TDialectFactory.CreateDialect('PostgreSQL'); // Default
  FGenerateDropTable := False;
  FAutoIncPk := True;
  FQuoteIdentifiers := False;
  FGeneratedTables := TStringList.Create;
end;

destructor TSchema2DDLGenerator.Destroy;
begin
  FGeneratedTables.Free;
  inherited Destroy;
end;

function TSchema2DDLGenerator.CleanTableName(const pName: string): string;
begin
  Result := pName.Replace(' ', '_').Replace('-', '_');
end;

function TSchema2DDLGenerator.IsPropertyRequired(pSchema: TJSONObject; const pPropName: string): Boolean;
var
  lReqArray: TJSONArray;
  lI: Integer;
begin
  Result := False;
  lReqArray := pSchema.GetValue('required') as TJSONArray;
  if Assigned(lReqArray) then
  begin
    for lI := 0 to lReqArray.Count - 1 do
    begin
      if SameText(lReqArray.Items[lI].Value, pPropName) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function GetStringProp(pObj: TJSONObject; const pPropName: string; const pDefault: string = ''): string;
var
  lVal: TJSONValue;
begin
  Result := pDefault;
  if Assigned(pObj) then
  begin
    lVal := pObj.GetValue(pPropName);
    if Assigned(lVal) then
      Result := lVal.Value;
  end;
end;

function GetIntProp(pObj: TJSONObject; const pPropName: string; pDefault: Integer = 0): Integer;
var
  lVal: TJSONValue;
begin
  Result := pDefault;
  if Assigned(pObj) then
  begin
    lVal := pObj.GetValue(pPropName);
    if Assigned(lVal) and (lVal is TJSONNumber) then
      Result := TJSONNumber(lVal).AsInt;
  end;
end;

function GetBoolProp(pObj: TJSONObject; const pPropName: string; pDefault: Boolean = False): Boolean;
var
  lVal: TJSONValue;
begin
  Result := pDefault;
  if Assigned(pObj) then
  begin
    lVal := pObj.GetValue(pPropName);
    if Assigned(lVal) then
    begin
      if lVal is TJSONBool then
        Result := TJSONBool(lVal).AsBoolean
      else
        Result := SameText(lVal.Value, 'true') or (lVal.Value = '1');
    end;
  end;
end;

procedure TSchema2DDLGenerator.ProcessSchemaObject(const pTableName: string; pSchema: TJSONObject; pOutputList: TStringList);
var
  lCleanTableName: string;
  lProperties: TJSONObject;
  lPropPair: TJSONPair;
  lPropObj: TJSONObject;
  lPropType: string;
  lFormat: string;
  lMaxLength: Integer;
  lColumnName: string;
  lSqlType: string;
  lColumnDef: string;
  lColumnsList: TStringList;
  lForeignKeys: TStringList;
  lRequired: Boolean;
  lHasPk: Boolean;
  lPkColumn: string;
  lDefaultVal: TJSONValue;
  lChildTableName: string;
  lReqArray: TJSONArray;
  lI: Integer;
  lSql: string;
begin
  if not Assigned(pSchema) then
    Exit;

  lCleanTableName := CleanTableName(pTableName);
  if FGeneratedTables.IndexOf(lCleanTableName) <> -1 then
    Exit; // Prevent duplicate generation

  FGeneratedTables.Add(lCleanTableName);

  lProperties := pSchema.GetValue('properties') as TJSONObject;
  if not Assigned(lProperties) then
    Exit;

  lColumnsList := TStringList.Create;
  lForeignKeys := TStringList.Create;
  try
    lHasPk := False;
    lPkColumn := '';

    // First scan for explicitly defined primary keys
    for lPropPair in lProperties do
    begin
      if lPropPair.JsonValue is TJSONObject then
      begin
        lPropObj := lPropPair.JsonValue as TJSONObject;
        if SameText(lPropPair.JsonString.Value, 'id') or GetBoolProp(lPropObj, 'x-pk', False) then
        begin
          lHasPk := True;
          lPkColumn := lPropPair.JsonString.Value;
          Break;
        end;
      end;
    end;

    // If no PK was found, default to adding an autoincrement ID column
    if not lHasPk then
    begin
      lPkColumn := 'id';
      lSqlType := FDialect.MapType('integer', 0, '', FAutoIncPk);
      lColumnDef := Format('  %s %s %s', [
        FDialect.FormatIdentifier(lPkColumn),
        lSqlType,
        FDialect.GetPrimaryKeyClause(FAutoIncPk)
      ]);
      lColumnsList.Add(lColumnDef);
    end;

    // Process all properties
    for lPropPair in lProperties do
    begin
      if not (lPropPair.JsonValue is TJSONObject) then
        Continue;

      lPropObj := lPropPair.JsonValue as TJSONObject;
      lColumnName := lPropPair.JsonString.Value;
      lPropType := GetStringProp(lPropObj, 'type', 'string');
      lFormat := GetStringProp(lPropObj, 'format');
      lMaxLength := GetIntProp(lPropObj, 'maxLength', 0);
      lRequired := IsPropertyRequired(pSchema, lColumnName) or SameText(lColumnName, lPkColumn);

      // Handle nested Object (Many-to-One / Reference relationship)
      if SameText(lPropType, 'object') then
      begin
        lChildTableName := lCleanTableName + '_' + lColumnName;
        // Generate child table DDL first
        ProcessSchemaObject(lChildTableName, lPropObj, pOutputList);

        // Add FK column to parent table referencing child table
        lSqlType := FDialect.MapType('integer', 0, '', False);
        lColumnDef := Format('  %s %s', [
          FDialect.FormatIdentifier(lColumnName + '_id'),
          lSqlType
        ]);
        if lRequired then
          lColumnDef := lColumnDef + ' NOT NULL';

        lColumnsList.Add(lColumnDef);

        // FK constraint definition
        lForeignKeys.Add(Format('  CONSTRAINT fk_%s_%s FOREIGN KEY (%s) REFERENCES %s (%s)', [
          lCleanTableName,
          lColumnName,
          FDialect.FormatIdentifier(lColumnName + '_id'),
          FDialect.FormatIdentifier(lChildTableName),
          FDialect.FormatIdentifier('id')
        ]));
        Continue;
      end;

      // Handle array of items
      if SameText(lPropType, 'array') then
      begin
        // If items are objects, this represents a One-to-Many relationship.
        // The child table needs to refer to the parent table.
        lPropObj := lPropObj.GetValue('items') as TJSONObject;
        if Assigned(lPropObj) and SameText(GetStringProp(lPropObj, 'type'), 'object') then
        begin
          lChildTableName := lCleanTableName + '_' + lColumnName;
          
          // Generate child table later. But we need to add the parent's foreign key to the child table!
          // We can accomplish this by recursively generating the child table.
          // Wait, let's create a temporary structure where parent id FK is injected.
          lPropObj := lPropObj.Clone as TJSONObject;
          try
            // Inject parent reference properties
            lProperties := lPropObj.GetValue('properties') as TJSONObject;
            if Assigned(lProperties) then
            begin
              // Add ForeignKey property definition: parent_id
              lProperties.AddPair(lCleanTableName + '_id', TJSONObject.Create(
                TJSONPair.Create('type', 'integer')
              ));
              
              // Mark as required
              lReqArray := lPropObj.GetValue('required') as TJSONArray;
              if not Assigned(lReqArray) then
              begin
                lReqArray := TJSONArray.Create;
                lPropObj.AddPair('required', lReqArray);
              end;
              lReqArray.Add(lCleanTableName + '_id');
            end;

            ProcessSchemaObject(lChildTableName, lPropObj, pOutputList);
          finally
            lPropObj.Free;
          end;
        end;
        Continue;
      end;

      // Regular columns
      lSqlType := FDialect.MapType(lPropType, lMaxLength, lFormat, SameText(lColumnName, lPkColumn) and FAutoIncPk);
      
      lColumnDef := Format('  %s %s', [
        FDialect.FormatIdentifier(lColumnName),
        lSqlType
      ]);

      // If it's a primary key, add primary key clause (if it wasn't added automatically)
      if SameText(lColumnName, lPkColumn) then
      begin
        lColumnDef := lColumnDef + ' ' + FDialect.GetPrimaryKeyClause(FAutoIncPk);
      end
      else
      begin
        // Apply default value
        lDefaultVal := lPropObj.GetValue('default');
        if Assigned(lDefaultVal) then
        begin
          lColumnDef := lColumnDef + ' DEFAULT ' + FDialect.GetDefaultValueString(lDefaultVal.Value, lPropType);
        end;

        // Apply mandatory constraint
        if lRequired then
          lColumnDef := lColumnDef + ' NOT NULL';
      end;

      lColumnsList.Add(lColumnDef);
    end;

    // Combine columns and foreign keys
    if lForeignKeys.Count > 0 then
    begin
      lColumnsList.AddStrings(lForeignKeys);
    end;

    // Construct CREATE TABLE statement
    lColumnDef := '';
    if FGenerateDropTable then
    begin
      lColumnDef := Format('DROP TABLE IF EXISTS %s;' + sLineBreak, [
        FDialect.FormatIdentifier(lCleanTableName)
      ]);
    end;

    lColumnDef := lColumnDef + Format('CREATE TABLE %s (' + sLineBreak, [
      FDialect.FormatIdentifier(lCleanTableName)
    ]);

    lSql := '';
    for lI := 0 to lColumnsList.Count - 1 do
    begin
      if lI > 0 then
        lSql := lSql + ',' + sLineBreak;
      lSql := lSql + lColumnsList[lI];
    end;
    lColumnDef := lColumnDef + lSql;
    lColumnDef := lColumnDef + sLineBreak + ');' + sLineBreak;

    pOutputList.Add(lColumnDef);

  finally
    lColumnsList.Free;
    lForeignKeys.Free;
  end;
end;

function TSchema2DDLGenerator.GenerateDDL(pSchema: TJSONObject; const pMainTableName: string): string;
var
  lOutput: TStringList;
  lMainName: string;
begin
  Result := '';
  if not Assigned(pSchema) then
    Exit;

  FDialect.QuoteIdentifiers := FQuoteIdentifiers;
  FGeneratedTables.Clear;

  lMainName := pMainTableName;
  if lMainName = '' then
    lMainName := GetStringProp(pSchema, 'title', 'main_table');

  lOutput := TStringList.Create;
  try
    ProcessSchemaObject(lMainName, pSchema, lOutput);
    // Join generated table DDLs. Relational child tables were processed first so they are at the top,
    // which handles foreign key references cleanly in standard DDL execution!
    Result := lOutput.Text;
  finally
    lOutput.Free;
  end;
end;

end.
