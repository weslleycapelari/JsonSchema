unit TestJsonSchema.Paths;

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
begin
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..', '..'));
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
