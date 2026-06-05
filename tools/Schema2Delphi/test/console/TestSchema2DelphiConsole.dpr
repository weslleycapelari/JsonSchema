program TestSchema2DelphiConsole;

(*
--------------------------------------------------------------------------------
Console DUnit test runner executing Schema2Delphi AST-based generator tests.
--------------------------------------------------------------------------------
*)

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  TestSchema2Delphi in '..\src\TestSchema2Delphi.pas',
  Schema2Delphi.AST in '..\..\src\Schema2Delphi.AST.pas',
  Schema2Delphi.AttributeProcessor in '..\..\src\Schema2Delphi.AttributeProcessor.pas',
  Schema2Delphi.Common in '..\..\src\Schema2Delphi.Common.pas',
  Schema2Delphi.Sanitizer in '..\..\src\Schema2Delphi.Sanitizer.pas',
  Schema2Delphi.TypeMapper in '..\..\src\Schema2Delphi.TypeMapper.pas',
  Schema2Delphi.Utils in '..\..\src\Schema2Delphi.Utils.pas',
  Schema2Delphi.Visitor in '..\..\src\Schema2Delphi.Visitor.pas';

begin
  try
    WriteLn('Running Schema2Delphi Console Tests...');
    WriteLn;
    with TextTestRunner.RunRegisteredTests do
      Free;
  except
    on E: Exception do
    begin
      WriteLn(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
