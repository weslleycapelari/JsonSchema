program Delphi2SchemaCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) utility for exporting JSON Schema files from
compiled Delphi types using RTTI reflection.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Delphi2Schema.Config in 'src\Delphi2Schema.Config.pas',
  Delphi2Schema.Attributes in 'src\Delphi2Schema.Attributes.pas',
  Delphi2Schema.Engine in 'src\Delphi2Schema.Engine.pas',
  Delphi2Schema.Runner in 'src\Delphi2Schema.Runner.pas',
  Delphi2Schema.Samples in 'src\Delphi2Schema.Samples.pas';

begin
  try
    Halt(RunDelphi2Schema);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
