unit TestJsonSchema.Mock.HttpServer;

interface

uses
  System.Classes,
  System.SysUtils,
  IdContext,
  IdCustomHTTPServer,
  IdGlobal,
  IdHTTPServer,
  IdSocketHandle;

type
  TMockHttpServer = class
  strict private
    FServer: TIdHTTPServer;

    procedure OnCommandGet(pContext: TIdContext; pRequestInfo: TIdHTTPRequestInfo;
      pResponseInfo: TIdHTTPResponseInfo);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start(const pPort: Integer);
    procedure Stop;
  end;

implementation

uses
  TestJsonSchema.Utils.Paths;

constructor TMockHttpServer.Create;
begin
  FServer := TIdHTTPServer.Create(nil);
end;

destructor TMockHttpServer.Destroy;
begin
  FServer.Free;
  inherited;
end;

procedure TMockHttpServer.OnCommandGet(pContext: TIdContext; pRequestInfo: TIdHTTPRequestInfo;
  pResponseInfo: TIdHTTPResponseInfo);
var
  lFilePath: string;
begin
  lFilePath := IncludeTrailingPathDelimiter(GetSchemasRemotesRootPath) + pRequestInfo.Document;

  // Apenas uma linha após o comando if, omitindo o begin..end conforme a norma
  if DirectoryExists(lFilePath) then
    lFilePath := IncludeTrailingPathDelimiter(lFilePath) + 'index.html';

  // Par begin..end obrigatório por ter múltiplas linhas
  // Uso do 'end else begin' na mesma linha, de acordo com as normas
  if FileExists(lFilePath) then
  begin
    pResponseInfo.ContentStream := TFileStream.Create(lFilePath, fmOpenRead or fmShareDenyWrite);
    pResponseInfo.ContentType := 'application/json';
    pResponseInfo.FreeContentStream := True;
    pResponseInfo.ResponseNo := 200;
  end else
  begin
    pResponseInfo.ResponseNo := 404;
    pResponseInfo.ContentText := 'Arquivo não encontrado';
  end;
end;

procedure TMockHttpServer.Start(const pPort: Integer);
begin
  FServer.DefaultPort := pPort;
  FServer.OnCommandGet := OnCommandGet;
  FServer.Active := True;
end;

procedure TMockHttpServer.Stop;
begin
  FServer.Active := False;
end;

end.
