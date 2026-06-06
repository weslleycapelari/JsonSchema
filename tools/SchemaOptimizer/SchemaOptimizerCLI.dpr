program SchemaOptimizerCLI;

{$APPTYPE CONSOLE}

(*
--------------------------------------------------------------------------------
SchemaOptimizer CLI Console Entry Point.
--------------------------------------------------------------------------------
*)

uses
  System.SysUtils,
  SchemaOptimizer.Config in 'src\SchemaOptimizer.Config.pas',
  SchemaOptimizer.Engine in 'src\SchemaOptimizer.Engine.pas',
  SchemaOptimizer.Runner in 'src\SchemaOptimizer.Runner.pas';

var
  lExitCode: Integer;
begin
  try
    lExitCode := RunSchemaOptimizer;
    ExitCode := lExitCode;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal CLI Error: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
