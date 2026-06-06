program TestSchemaMigratorConsole;

(*
--------------------------------------------------------------------------------
Console test runner for SchemaMigrator.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  SchemaMigrator.Config in '..\..\src\SchemaMigrator.Config.pas',
  SchemaMigrator.Engine in '..\..\src\SchemaMigrator.Engine.pas',
  SchemaMigrator.Runner in '..\..\src\SchemaMigrator.Runner.pas',
  TestSchemaMigrator in '..\src\TestSchemaMigrator.pas';

begin
  try
    Writeln('Running SchemaMigrator Console Tests...');
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
