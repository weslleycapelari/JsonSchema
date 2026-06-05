unit Schema2DDL.Dialects;

(*
--------------------------------------------------------------------------------
SQL Dialects implementations for Schema2DDL generator.
Supports PostgreSQL, Firebird, SQLite, and SQL Server.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>Interface governing database DDL dialect specifics.</summary>
  ISQLDialect = interface
    ['{69A458D0-E7A9-418E-9876-CE3A5D5A504B}']
    function GetDialectName: string;
    function MapType(const pJsonType: string; pMaxLength: Integer; const pFormat: string; pAutoInc: Boolean): string;
    function FormatIdentifier(const pIdentifier: string): string;
    function GetDefaultValueString(const pValue: string; const pJsonType: string): string;
    function GetPrimaryKeyClause(pAutoInc: Boolean): string;
    function GetQuoteIdentifiers: Boolean;
    procedure SetQuoteIdentifiers(pValue: Boolean);

    property DialectName: string read GetDialectName;
    property QuoteIdentifiers: Boolean read GetQuoteIdentifiers write SetQuoteIdentifiers;
  end;

  /// <summary>Abstract base implementation of ISQLDialect.</summary>
  TSQLDialectBase = class(TInterfacedObject, ISQLDialect)
  protected
    FQuoteIdentifiers: Boolean;
    function GetDialectName: string; virtual; abstract;
    function MapType(const pJsonType: string; pMaxLength: Integer; const pFormat: string; pAutoInc: Boolean): string; virtual; abstract;
    function FormatIdentifier(const pIdentifier: string): string; virtual;
    function GetDefaultValueString(const pValue: string; const pJsonType: string): string; virtual;
    function GetPrimaryKeyClause(pAutoInc: Boolean): string; virtual; abstract;
    function GetQuoteIdentifiers: Boolean;
    procedure SetQuoteIdentifiers(pValue: Boolean);
  public
    constructor Create; virtual;
  end;

  /// <summary>PostgreSQL Dialect.</summary>
  TPostgreSQLDialect = class(TSQLDialectBase)
  protected
    function GetDialectName: string; override;
    function MapType(const pJsonType: string; pMaxLength: Integer; const pFormat: string; pAutoInc: Boolean): string; override;
    function GetPrimaryKeyClause(pAutoInc: Boolean): string; override;
  end;

  /// <summary>Firebird Dialect.</summary>
  TFirebirdDialect = class(TSQLDialectBase)
  protected
    function GetDialectName: string; override;
    function MapType(const pJsonType: string; pMaxLength: Integer; const pFormat: string; pAutoInc: Boolean): string; override;
    function GetPrimaryKeyClause(pAutoInc: Boolean): string; override;
  end;

  /// <summary>SQLite Dialect.</summary>
  TSQLiteDialect = class(TSQLDialectBase)
  protected
    function GetDialectName: string; override;
    function MapType(const pJsonType: string; pMaxLength: Integer; const pFormat: string; pAutoInc: Boolean): string; override;
    function GetPrimaryKeyClause(pAutoInc: Boolean): string; override;
  end;

  /// <summary>Microsoft SQL Server Dialect.</summary>
  TSQLServerDialect = class(TSQLDialectBase)
  protected
    function GetDialectName: string; override;
    function MapType(const pJsonType: string; pMaxLength: Integer; const pFormat: string; pAutoInc: Boolean): string; override;
    function GetPrimaryKeyClause(pAutoInc: Boolean): string; override;
    function FormatIdentifier(const pIdentifier: string): string; override;
    function GetDefaultValueString(const pValue: string; const pJsonType: string): string; override;
  end;

  /// <summary>Dialect Factory helper.</summary>
  TDialectFactory = class
  public
    class function CreateDialect(const pName: string): ISQLDialect;
  end;

implementation

{ TSQLDialectBase }

constructor TSQLDialectBase.Create;
begin
  inherited Create;
  FQuoteIdentifiers := False;
end;

function TSQLDialectBase.FormatIdentifier(const pIdentifier: string): string;
begin
  if FQuoteIdentifiers then
    Result := '"' + pIdentifier + '"'
  else
    Result := pIdentifier;
end;

function TSQLDialectBase.GetDefaultValueString(const pValue: string; const pJsonType: string): string;
begin
  if SameText(pJsonType, 'string') then
    Result := '''' + pValue.Replace('''', '''''') + ''''
  else if SameText(pJsonType, 'boolean') then
  begin
    if SameText(pValue, 'true') or (pValue = '1') then
      Result := 'TRUE'
    else
      Result := 'FALSE';
  end
  else
    Result := pValue;
end;

function TSQLDialectBase.GetQuoteIdentifiers: Boolean;
begin
  Result := FQuoteIdentifiers;
end;

procedure TSQLDialectBase.SetQuoteIdentifiers(pValue: Boolean);
begin
  FQuoteIdentifiers := pValue;
end;

{ TPostgreSQLDialect }

function TPostgreSQLDialect.GetDialectName: string;
begin
  Result := 'PostgreSQL';
end;

function TPostgreSQLDialect.MapType(const pJsonType: string; pMaxLength: Integer; const pFormat: string; pAutoInc: Boolean): string;
begin
  if SameText(pJsonType, 'integer') then
  begin
    if pAutoInc then
      Exit('SERIAL');
    Exit('INTEGER');
  end;

  if SameText(pJsonType, 'bigint') then
  begin
    if pAutoInc then
      Exit('BIGSERIAL');
    Exit('BIGINT');
  end;

  if SameText(pJsonType, 'number') then
  begin
    if SameText(pFormat, 'double') then
      Exit('DOUBLE PRECISION');
    Exit('NUMERIC');
  end;

  if SameText(pJsonType, 'boolean') then
    Exit('BOOLEAN');

  if SameText(pJsonType, 'string') then
  begin
    if SameText(pFormat, 'date-time') then
      Exit('TIMESTAMP')
    else if SameText(pFormat, 'date') then
      Exit('DATE')
    else if SameText(pFormat, 'time') then
      Exit('TIME')
    else if pMaxLength > 0 then
      Exit(Format('VARCHAR(%d)', [pMaxLength]));
    Exit('TEXT');
  end;

  Result := 'VARCHAR(255)';
end;

function TPostgreSQLDialect.GetPrimaryKeyClause(pAutoInc: Boolean): string;
begin
  // SERIAL handles auto-increment automatically in PG
  Result := 'PRIMARY KEY';
end;

{ TFirebirdDialect }

function TFirebirdDialect.GetDialectName: string;
begin
  Result := 'Firebird';
end;

function TFirebirdDialect.MapType(const pJsonType: string; pMaxLength: Integer; const pFormat: string; pAutoInc: Boolean): string;
begin
  if SameText(pJsonType, 'integer') or SameText(pJsonType, 'bigint') then
  begin
    if SameText(pJsonType, 'bigint') then
      Exit('BIGINT');
    Exit('INTEGER');
  end;

  if SameText(pJsonType, 'number') then
    Exit('DOUBLE PRECISION');

  if SameText(pJsonType, 'boolean') then
    Exit('BOOLEAN');

  if SameText(pJsonType, 'string') then
  begin
    if SameText(pFormat, 'date-time') then
      Exit('TIMESTAMP')
    else if SameText(pFormat, 'date') then
      Exit('DATE')
    else if SameText(pFormat, 'time') then
      Exit('TIME')
    else if pMaxLength > 0 then
      Exit(Format('VARCHAR(%d)', [pMaxLength]));
    Exit('BLOB SUB_TYPE TEXT');
  end;

  Result := 'VARCHAR(255)';
end;

function TFirebirdDialect.GetPrimaryKeyClause(pAutoInc: Boolean): string;
begin
  if pAutoInc then
    Result := 'GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY'
  else
    Result := 'PRIMARY KEY';
end;

{ TSQLiteDialect }

function TSQLiteDialect.GetDialectName: string;
begin
  Result := 'SQLite';
end;

function TSQLiteDialect.MapType(const pJsonType: string; pMaxLength: Integer; const pFormat: string; pAutoInc: Boolean): string;
begin
  if SameText(pJsonType, 'integer') or SameText(pJsonType, 'bigint') then
    Exit('INTEGER');

  if SameText(pJsonType, 'number') then
    Exit('REAL');

  if SameText(pJsonType, 'boolean') then
    Exit('INTEGER');

  if SameText(pJsonType, 'string') then
    Exit('TEXT');

  Result := 'TEXT';
end;

function TSQLiteDialect.GetPrimaryKeyClause(pAutoInc: Boolean): string;
begin
  if pAutoInc then
    Result := 'PRIMARY KEY AUTOINCREMENT'
  else
    Result := 'PRIMARY KEY';
end;

{ TSQLServerDialect }

function TSQLServerDialect.GetDialectName: string;
begin
  Result := 'SQLServer';
end;

function TSQLServerDialect.MapType(const pJsonType: string; pMaxLength: Integer; const pFormat: string; pAutoInc: Boolean): string;
begin
  if SameText(pJsonType, 'integer') then
    Exit('INT');

  if SameText(pJsonType, 'bigint') then
    Exit('BIGINT');

  if SameText(pJsonType, 'number') then
    Exit('DECIMAL(18,4)');

  if SameText(pJsonType, 'boolean') then
    Exit('BIT');

  if SameText(pJsonType, 'string') then
  begin
    if SameText(pFormat, 'date-time') then
      Exit('DATETIME2')
    else if SameText(pFormat, 'date') then
      Exit('DATE')
    else if SameText(pFormat, 'time') then
      Exit('TIME')
    else if pMaxLength > 0 then
      Exit(Format('VARCHAR(%d)', [pMaxLength]));
    Exit('VARCHAR(MAX)');
  end;

  Result := 'VARCHAR(255)';
end;

function TSQLServerDialect.GetPrimaryKeyClause(pAutoInc: Boolean): string;
begin
  if pAutoInc then
    Result := 'IDENTITY(1,1) PRIMARY KEY'
  else
    Result := 'PRIMARY KEY';
end;

function TSQLServerDialect.FormatIdentifier(const pIdentifier: string): string;
begin
  if FQuoteIdentifiers then
    Result := '[' + pIdentifier + ']'
  else
    Result := pIdentifier;
end;

function TSQLServerDialect.GetDefaultValueString(const pValue: string; const pJsonType: string): string;
begin
  if SameText(pJsonType, 'boolean') then
  begin
    if SameText(pValue, 'true') or (pValue = '1') then
      Result := '1'
    else
      Result := '0';
  end
  else
    inherited GetDefaultValueString(pValue, pJsonType);
end;

{ TDialectFactory }

class function TDialectFactory.CreateDialect(const pName: string): ISQLDialect;
begin
  if SameText(pName, 'PostgreSQL') or SameText(pName, 'pg') then
    Result := TPostgreSQLDialect.Create
  else if SameText(pName, 'Firebird') or SameText(pName, 'fb') then
    Result := TFirebirdDialect.Create
  else if SameText(pName, 'SQLite') or SameText(pName, 'sqlite') then
    Result := TSQLiteDialect.Create
  else if SameText(pName, 'SQLServer') or SameText(pName, 'mssql') then
    Result := TSQLServerDialect.Create
  else
    Result := TPostgreSQLDialect.Create; // Default
end;

end.
