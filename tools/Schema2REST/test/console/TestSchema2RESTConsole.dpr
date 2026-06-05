program TestSchema2RESTConsole;

(*
--------------------------------------------------------------------------------
Console test runner for Schema2REST.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  Schema2REST.Config in '..\..\src\Schema2REST.Config.pas',
  Schema2REST.Templates in '..\..\src\Schema2REST.Templates.pas',
  Schema2REST.Engine in '..\..\src\Schema2REST.Engine.pas',
  Schema2REST.Runner in '..\..\src\Schema2REST.Runner.pas',
  TestSchema2REST in '..\src\TestSchema2REST.pas';

begin
  try
    Writeln('Running Schema2REST Console Tests...');
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
