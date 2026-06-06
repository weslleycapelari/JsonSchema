program TestSchemaOptimizerConsole;

(*
--------------------------------------------------------------------------------
Console test runner for SchemaOptimizer.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  SchemaOptimizer.Config in '..\..\src\SchemaOptimizer.Config.pas',
  SchemaOptimizer.Engine in '..\..\src\SchemaOptimizer.Engine.pas',
  SchemaOptimizer.Runner in '..\..\src\SchemaOptimizer.Runner.pas',
  TestSchemaOptimizer in '..\src\TestSchemaOptimizer.pas';

begin
  try
    Writeln('Running SchemaOptimizer Console Tests...');
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
