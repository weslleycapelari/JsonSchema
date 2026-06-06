program TestSchemaLinterConsole;

(*
--------------------------------------------------------------------------------
Console test runner for SchemaLinter.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  SchemaLinter.Config in '..\..\src\SchemaLinter.Config.pas',
  SchemaLinter.Engine in '..\..\src\SchemaLinter.Engine.pas',
  SchemaLinter.Runner in '..\..\src\SchemaLinter.Runner.pas',
  TestSchemaLinter in '..\src\TestSchemaLinter.pas';

begin
  try
    Writeln('Running SchemaLinter Console Tests...');
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
