program TestSchemaBundlerConsole;

(*
--------------------------------------------------------------------------------
Console test runner for SchemaBundler.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  SchemaBundler.Config in '..\..\src\SchemaBundler.Config.pas',
  SchemaBundler.Engine in '..\..\src\SchemaBundler.Engine.pas',
  SchemaBundler.Runner in '..\..\src\SchemaBundler.Runner.pas',
  TestSchemaBundler in '..\src\TestSchemaBundler.pas';

begin
  try
    Writeln('Running SchemaBundler Console Tests...');
    Writeln;
    with TextTestRunner.RunRegisteredTests do
      Free;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
