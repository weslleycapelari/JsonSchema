unit TestJsonSchema.RemoteFiles;

interface

uses
  IdHTTPServer,
  IdCustomHTTPServer,
  IdContext,
  IdGlobal,
  IdSocketHandle,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  TestJsonSchema.Paths;

type
  TFileServer = class
  private
    FServer: TIdHTTPServer;

    function GetFolderPath: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure OnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure StartFileServer(APort: Integer);
    procedure StopFileServer;
  end;

implementation

constructor TFileServer.Create;
begin
  FServer := TIdHTTPServer.Create(nil);
end;

destructor TFileServer.Destroy;
begin
  FServer.Free;
  inherited;
end;

function TFileServer.GetFolderPath: string;
begin
  Result := GetSchemasRemotesRootPath;
end;

procedure TFileServer.OnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LFilePath: string;
begin
  LFilePath := IncludeTrailingPathDelimiter(GetFolderPath) + ARequestInfo.Document;

  if DirectoryExists(LFilePath) then
    LFilePath := IncludeTrailingPathDelimiter(LFilePath) + 'index.html';

  if FileExists(LFilePath) then
  begin
    AResponseInfo.ContentStream := TFileStream.Create(LFilePath, fmOpenRead or fmShareDenyWrite);
    AResponseInfo.ContentType := 'application/json';
    AResponseInfo.FreeContentStream := True;
    AResponseInfo.ResponseNo := 200;
  end
  else
  begin
    AResponseInfo.ResponseNo := 404;
    AResponseInfo.ContentText := 'Arquivo nao encontrado';
  end;
end;

procedure TFileServer.StartFileServer(APort: Integer);
begin
  FServer.DefaultPort := APort;
  FServer.OnCommandGet := OnCommandGet;
  FServer.Active := True;
end;

procedure TFileServer.StopFileServer;
begin
  FServer.Active := False;
end;

end.
