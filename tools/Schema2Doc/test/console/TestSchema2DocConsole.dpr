program TestSchema2DocConsole;

(*
--------------------------------------------------------------------------------
Console test runner for Schema2Doc.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  Schema2Doc.Config in '..\..\src\Schema2Doc.Config.pas',
  Schema2Doc.Engine in '..\..\src\Schema2Doc.Engine.pas',
  Schema2Doc.Runner in '..\..\src\Schema2Doc.Runner.pas',
  TestSchema2Doc in '..\src\TestSchema2Doc.pas';

begin
  try
    Writeln('Running Schema2Doc Console Tests...');
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
