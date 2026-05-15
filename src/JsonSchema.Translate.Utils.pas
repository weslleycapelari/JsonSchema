unit JsonSchema.Translate.Utils;

interface

uses
  JsonSchema.Translate.Types,
  JsonSchema.Translate.Interfaces;

type
  TTranslateUtils = class
    class function GetTranslation(const ALanguage: TLanguage): ITranslate; static;
  end;

implementation

uses
  System.SysUtils,
  JsonSchema.Translate.enUS,
  JsonSchema.Translate.ptBR;

{ TTranslateUtils }

class function TTranslateUtils.GetTranslation(const ALanguage: TLanguage): ITranslate;
begin
  case ALanguage of
    TLanguage.lang_enUS:
      Result := TTranslate_enUS.Create;
    TLanguage.lang_ptBR:
      Result := TTranslate_ptBR.Create;
  else
    raise Exception.Create('Unsupported language: ' + IntToStr(Integer(ALanguage)));
  end;
end;

end.
