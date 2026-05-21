unit JsonSchema.Translate.Utils;

interface

uses
  JsonSchema.Translate.Types,
  JsonSchema.Translate.Interfaces;

type
  /// <summary>
  /// Factory for obtaining a translation provider for the given language.
  /// </summary>
  TTranslateUtils = class
    /// <summary>Returns an ITranslate implementation for the requested language.</summary>
    /// <param name="pLanguage">The target language.</param>
    class function GetTranslation(const pLanguage: TLanguage): ITranslate; static;
  end;

implementation

uses
  System.SysUtils,
  JsonSchema.Translate.enUS,
  JsonSchema.Translate.ptBR;

{ TTranslateUtils }

class function TTranslateUtils.GetTranslation(const pLanguage: TLanguage): ITranslate;
begin
  case pLanguage of
    TLanguage.lang_enUS:
      Result := TTranslate_enUS.Create;
    TLanguage.lang_ptBR:
      Result := TTranslate_ptBR.Create;
  else
    raise Exception.Create('Unsupported language: ' + IntToStr(Integer(pLanguage)));
  end;
end;

end.
