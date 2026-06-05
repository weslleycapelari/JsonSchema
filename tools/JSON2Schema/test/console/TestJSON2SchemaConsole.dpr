program TestJSON2SchemaConsole;

(*
--------------------------------------------------------------------------------
Console test runner for JSON2Schema.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  JSON2Schema.Config in '..\..\src\JSON2Schema.Config.pas',
  JSON2Schema.Engine in '..\..\src\JSON2Schema.Engine.pas',
  JSON2Schema.Runner in '..\..\src\JSON2Schema.Runner.pas',
  TestJSON2Schema in '..\src\TestJSON2Schema.pas';

begin
  try
    Writeln('Running JSON2Schema Console Tests...');
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
