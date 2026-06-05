program TestSchemaValidatorConsole;

(*
--------------------------------------------------------------------------------
Console test runner for SchemaValidator integration and unit tests.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  SchemaValidator.Config in '..\..\src\SchemaValidator.Config.pas',
  SchemaValidator.Utils in '..\..\src\SchemaValidator.Utils.pas',
  SchemaValidator.Formatters in '..\..\src\SchemaValidator.Formatters.pas',
  SchemaValidator.Runner in '..\..\src\SchemaValidator.Runner.pas',
  TestSchemaValidator in '..\src\TestSchemaValidator.pas';

begin
  try
    Writeln('Running SchemaValidator Console Tests...');
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
