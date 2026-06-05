program TestSchemaMockGenConsole;

(*
--------------------------------------------------------------------------------
Console test runner for SchemaMockGen integration and unit tests.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  SchemaMockGen.Config in '..\..\src\SchemaMockGen.Config.pas',
  SchemaMockGen.Utils in '..\..\src\SchemaMockGen.Utils.pas',
  SchemaMockGen.Generator in '..\..\src\SchemaMockGen.Generator.pas',
  SchemaMockGen.Runner in '..\..\src\SchemaMockGen.Runner.pas',
  TestSchemaMockGen in '..\src\TestSchemaMockGen.pas';

begin
  try
    Writeln('Running SchemaMockGen Console Tests...');
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
