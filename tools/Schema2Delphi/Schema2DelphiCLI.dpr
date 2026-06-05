program Schema2DelphiCLI;

(*
--------------------------------------------------------------------------------
Command-Line Interface (CLI) utility for generating Delphi DTO units
from JSON Schemas using the shared code generation AST engine.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Schema2Delphi.Config in 'src\Schema2Delphi.Config.pas',
  Schema2Delphi.Runner in 'src\Schema2Delphi.Runner.pas',
  Schema2Delphi.Common in 'src\Schema2Delphi.Common.pas',
  Schema2Delphi.Sanitizer in 'src\Schema2Delphi.Sanitizer.pas',
  Schema2Delphi.TypeMapper in 'src\Schema2Delphi.TypeMapper.pas',
  Schema2Delphi.AttributeProcessor in 'src\Schema2Delphi.AttributeProcessor.pas',
  Schema2Delphi.Visitor in 'src\Schema2Delphi.Visitor.pas',
  Schema2Delphi.Utils in 'src\Schema2Delphi.Utils.pas',
  Schema2Delphi.AST in 'src\Schema2Delphi.AST.pas';

begin
  try
    Halt(RunSchema2Delphi);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Fatal error: ' + E.Message);
      Halt(2);
    end;
  end;
end.
