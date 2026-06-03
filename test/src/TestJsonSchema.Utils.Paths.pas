unit TestJsonSchema.Utils.Paths;

(*
--------------------------------------------------------------------------------
Contains path utility tests, checking correct directory navigation, relative schema lookups, and system configurations.
--------------------------------------------------------------------------------
*)


interface

uses
  System.IOUtils,
  System.SysUtils;

function GetTestRootPath: string;
function GetSchemasRootPath: string;
function GetSchemasTestsRootPath: string;
function GetSchemasRemotesRootPath: string;

implementation

function GetTestRootPath: string;
var
  lExePath: string;
  lPath: string;
begin
  lExePath := ExtractFilePath(ParamStr(0));
  
  if TDirectory.Exists(TPath.Combine(lExePath, 'schemas')) then
  begin
    Exit(TPath.GetFullPath(lExePath));
  end;
    
  lPath := TPath.Combine(lExePath, '..');
  if TDirectory.Exists(TPath.Combine(lPath, 'schemas')) then
  begin
    Exit(TPath.GetFullPath(lPath));
  end;

  lPath := TPath.Combine(lExePath, '..', '..');
  if TDirectory.Exists(TPath.Combine(lPath, 'schemas')) then
  begin
    Exit(TPath.GetFullPath(lPath));
  end;

  Result := TPath.GetFullPath(TPath.Combine(lExePath, '..', '..'));
end;

function GetSchemasRootPath: string;
begin
  Result := TPath.Combine(GetTestRootPath, 'schemas');
end;

function GetSchemasTestsRootPath: string;
begin
  Result := TPath.Combine(GetSchemasRootPath, 'tests');
end;

function GetSchemasRemotesRootPath: string;
begin
  Result := TPath.Combine(GetSchemasRootPath, 'remotes');
end;

end.
