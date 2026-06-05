program SchemaValidatorCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) utility for validating JSON instance files
against JSON schemas using the core validation engine.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  SchemaValidator.Config in 'src\SchemaValidator.Config.pas',
  SchemaValidator.Utils in 'src\SchemaValidator.Utils.pas',
  SchemaValidator.Formatters in 'src\SchemaValidator.Formatters.pas',
  SchemaValidator.Runner in 'src\SchemaValidator.Runner.pas';

begin
  try
    Halt(RunSchemaValidator);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
