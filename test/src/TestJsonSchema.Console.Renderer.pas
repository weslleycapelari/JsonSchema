unit TestJsonSchema.Console.Renderer;

interface

uses
  System.Math,
  System.SysUtils,
  Winapi.Windows,
  TestJsonSchema.Types;

type
  TConsoleRenderer = class
  strict private
    FConsoleHandle: THandle;
    FDefaultAttributes: Word;

    { Métodos Privados de Desenho e Cor }
    procedure SetColor(const pColor: Word);
    procedure ResetColor;
    function BuildBar(const pPercent: Double; const pWidth: Integer; const pChar: Char): string;
    procedure WriteAtPos(const pX, pY: SmallInt; const pText: string; const pColor: Word = 0);
  public
    constructor Create;

    procedure RenderBars(const pProcessed, pTotal, pPassed, pFailed: Integer);
    procedure PrintFailure(const pFailure: TJsonSchemaFailure);
  end;

implementation

{ Cores do Windows Console }
const
  C_RED    = FOREGROUND_RED or FOREGROUND_INTENSITY;
  C_GREEN  = FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  C_YELLOW = FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  C_CYAN   = FOREGROUND_GREEN or FOREGROUND_BLUE or FOREGROUND_INTENSITY;
  C_WHITE  = FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE or FOREGROUND_INTENSITY;

constructor TConsoleRenderer.Create;
var
  lInfo: TConsoleScreenBufferInfo;
begin
  FConsoleHandle := GetStdHandle(STD_OUTPUT_HANDLE);

  if GetConsoleScreenBufferInfo(FConsoleHandle, lInfo) then
    FDefaultAttributes := lInfo.wAttributes
  else
    FDefaultAttributes := 7; // Default cinza/branco
end;

procedure TConsoleRenderer.SetColor(const pColor: Word);
begin
  SetConsoleTextAttribute(FConsoleHandle, pColor);
end;

procedure TConsoleRenderer.ResetColor;
begin
  SetConsoleTextAttribute(FConsoleHandle, FDefaultAttributes);
end;

function TConsoleRenderer.BuildBar(const pPercent: Double; const pWidth: Integer; const pChar: Char): string;
var
  lPercent: Double;
  lFilled: Integer;
begin
  lPercent := EnsureRange(pPercent, 0, 100);
  lFilled := Round((lPercent / 100) * pWidth);

  // Usando preenchimento visual clássico ou blocos conforme pChar
  Result := StringOfChar(pChar, lFilled) + StringOfChar('.', pWidth - lFilled);
end;

procedure TConsoleRenderer.WriteAtPos(const pX, pY: SmallInt; const pText: string; const pColor: Word);
var
  lCoord: TCoord;
  lWritten: DWORD;
  lInfo: TConsoleScreenBufferInfo;
begin
  if not GetConsoleScreenBufferInfo(FConsoleHandle, lInfo) then
    Exit;

  lCoord.X := pX;
  lCoord.Y := pY;

  // Limpa a linha antes de escrever para não deixar rastros
  FillConsoleOutputCharacter(FConsoleHandle, ' ', lInfo.dwSize.X, lCoord, lWritten);

  if pColor <> 0 then
    SetColor(pColor);

  SetConsoleCursorPosition(FConsoleHandle, lCoord);
  Write(pText);

  if pColor <> 0 then
    ResetColor;
end;

procedure TConsoleRenderer.RenderBars(const pProcessed, pTotal, pPassed, pFailed: Integer);
var
  lInfo: TConsoleScreenBufferInfo;
  lGeneralPercent, lPassPercent: Double;
  lFooterLine1, lFooterLine2: SmallInt;
  lRestore: TCoord;
begin
  if not GetConsoleScreenBufferInfo(FConsoleHandle, lInfo) then
    Exit;

  lRestore := lInfo.dwCursorPosition;

  { Cálculos de Percentual }
  if pTotal > 0 then
    lGeneralPercent := (pProcessed / pTotal) * 100
  else
    lGeneralPercent := 0;

  if pProcessed > 0 then
    lPassPercent := (pPassed / pProcessed) * 100
  else
    lPassPercent := 100;

  { Posicionamento no Rodapé (Sticky Footer) }
  // O rodapé fica sempre nas duas últimas linhas da JANELA visível
  lFooterLine1 := lInfo.srWindow.Bottom - 1;
  lFooterLine2 := lInfo.srWindow.Bottom;

  // Linha 1: Progresso Geral (Cyan/White)
  WriteAtPos(0, lFooterLine1,
    Format(' Progresso: %s %6.2f%% (%d/%d)',
    [BuildBar(lGeneralPercent, 40, '#'), lGeneralPercent, pProcessed, pTotal]), C_CYAN);

  // Linha 2: Taxa de Sucesso (Verde se 100%, Amarelo se tiver falhas)
  WriteAtPos(0, lFooterLine2,
    Format(' Sucesso:   %s %6.2f%% (OK: %d | FALHAS: %d)',
    [BuildBar(lPassPercent, 40, '#'), lPassPercent, pPassed, pFailed]),
    IfThen(pFailed > 0, C_YELLOW, C_GREEN));

  { Restaura o cursor para a área de LOG (acima do rodapé) }
  if lRestore.Y >= lFooterLine1 then
    lRestore.Y := lFooterLine1 - 1;

  SetConsoleCursorPosition(FConsoleHandle, lRestore);
end;

procedure TConsoleRenderer.PrintFailure(const pFailure: TJsonSchemaFailure);
var
  lInfo: TConsoleScreenBufferInfo;

  procedure PrintInformation(const pTitle, pValue: string);
  begin
    SetColor(C_RED);
    Write(Format('%s: ', [pTitle]));
    ResetColor;
    Writeln(pValue);
  end;
begin
  if not GetConsoleScreenBufferInfo(FConsoleHandle, lInfo) then
    Exit;

  { Garante que o Log não atropele o rodapé }
  if lInfo.dwCursorPosition.Y >= (lInfo.srWindow.Bottom - 2) then
  begin
    Writeln; // Provoca o scroll do console
    // Recalcula posição após o scroll
    GetConsoleScreenBufferInfo(FConsoleHandle, lInfo);
  end;

  SetColor(C_RED);
  Writeln('-------------------------------------------------------------------------------------------------');
  Writeln('[FALHA]                                                                                          ');
  PrintInformation('Draft', pFailure.DraftName);
  PrintInformation('Arquivo', pFailure.FilePath);
  PrintInformation('Teste', pFailure.TestDescription);
  PrintInformation('Erro', pFailure.ErrorMessage);
  PrintInformation('Schema Path', pFailure.SchemaPath);
  PrintInformation('Instance Path', pFailure.InstancePath);
  Writeln('-------------------------------------------------------------------------------------------------');
  ResetColor;
  Writeln;
end;

end.
