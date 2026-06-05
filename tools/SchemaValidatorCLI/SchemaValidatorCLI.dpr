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
  SchemaValidatorCLI.Config in 'src\SchemaValidatorCLI.Config.pas',
  SchemaValidatorCLI.Utils in 'src\SchemaValidatorCLI.Utils.pas',
  SchemaValidatorCLI.Formatters in 'src\SchemaValidatorCLI.Formatters.pas',
  SchemaValidatorCLI.Runner in 'src\SchemaValidatorCLI.Runner.pas';

begin
  try
    Halt(RunSchemaValidatorCLI);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
