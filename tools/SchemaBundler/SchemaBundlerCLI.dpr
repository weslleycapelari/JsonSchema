program SchemaBundlerCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) program for bundling split JSON Schema files
into a single self-contained document.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  SchemaBundler.Config in 'src\SchemaBundler.Config.pas',
  SchemaBundler.Engine in 'src\SchemaBundler.Engine.pas',
  SchemaBundler.Runner in 'src\SchemaBundler.Runner.pas';

{$R *.res}

begin
  try
    Halt(RunSchemaBundler);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
