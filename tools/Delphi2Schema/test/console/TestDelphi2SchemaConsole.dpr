program TestDelphi2SchemaConsole;

(*
--------------------------------------------------------------------------------
Console test runner for Delphi2Schema integration and unit tests.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  Delphi2Schema.Config in '..\..\src\Delphi2Schema.Config.pas',
  Delphi2Schema.Attributes in '..\..\src\Delphi2Schema.Attributes.pas',
  Delphi2Schema.Engine in '..\..\src\Delphi2Schema.Engine.pas',
  Delphi2Schema.Samples in '..\..\src\Delphi2Schema.Samples.pas',
  TestDelphi2Schema in '..\src\TestDelphi2Schema.pas';

begin
  try
    Writeln('Running Delphi2Schema Console Tests...');
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
