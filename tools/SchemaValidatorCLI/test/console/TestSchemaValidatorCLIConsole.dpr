program TestSchemaValidatorCLIConsole;

(*
--------------------------------------------------------------------------------
Console test runner for SchemaValidatorCLI integration and unit tests.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  SchemaValidatorCLI.Config in '..\..\src\SchemaValidatorCLI.Config.pas',
  SchemaValidatorCLI.Utils in '..\..\src\SchemaValidatorCLI.Utils.pas',
  SchemaValidatorCLI.Formatters in '..\..\src\SchemaValidatorCLI.Formatters.pas',
  SchemaValidatorCLI.Runner in '..\..\src\SchemaValidatorCLI.Runner.pas',
  TestSchemaValidatorCLI in '..\src\TestSchemaValidatorCLI.pas';

begin
  try
    Writeln('Running SchemaValidatorCLI Console Tests...');
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
