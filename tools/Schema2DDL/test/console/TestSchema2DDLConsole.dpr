program TestSchema2DDLConsole;

(*
--------------------------------------------------------------------------------
Console test runner for Schema2DDL.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  Schema2DDL.Config in '..\..\src\Schema2DDL.Config.pas',
  Schema2DDL.Dialects in '..\..\src\Schema2DDL.Dialects.pas',
  Schema2DDL.Engine in '..\..\src\Schema2DDL.Engine.pas',
  Schema2DDL.Runner in '..\..\src\Schema2DDL.Runner.pas',
  TestSchema2DDL in '..\src\TestSchema2DDL.pas';

begin
  try
    Writeln('Running Schema2DDL Console Tests...');
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
