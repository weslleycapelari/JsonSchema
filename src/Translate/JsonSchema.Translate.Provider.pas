unit JsonSchema.Translate.Provider;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Translate.Interfaces,
  JsonSchema.Translate.Types;

type
  /// <summary>
  ///   Factory function type for creating a translation provider instance.
  /// </summary>
  TTranslateFactory = reference to function: ITranslate;

  /// <summary>
  ///   Provider registry for obtaining localized translation services.
  ///   Follows the Open/Closed principle: new languages can be added without
  ///   modifying this class, by calling RegisterLanguage.
  /// </summary>
  TTranslateProvider = class
  private
    class var FRegistry: TDictionary<TLanguage, TTranslateFactory>;
    class var FLock: TObject;
    class procedure InitializeRegistry; static;
    class function GetTranslationFactory(const pLanguage: TLanguage): TTranslateFactory; static;
  public
    /// <summary>
    ///   Registers a factory function for a specific language.
    ///   If a factory already exists for the language, it is replaced.
    /// </summary>
    class procedure RegisterLanguage(const pLanguage: TLanguage; const pFactory: TTranslateFactory); static;

    /// <summary>
    ///   Returns an ITranslate instance for the requested language.
    ///   Raises ETranslationNotFound if no factory is registered for the language.
    /// </summary>
    class function GetTranslation(const pLanguage: TLanguage): ITranslate; static;
  end;

  /// <summary>Exception raised when no translation provider is registered for a language.</summary>
  ETranslationNotFound = class(Exception);

implementation

uses
  JsonSchema.Translate.enUS,
  JsonSchema.Translate.ptBR;

{ TTranslateProvider }

class procedure TTranslateProvider.InitializeRegistry;
begin
  if FRegistry = nil then
  begin
    FRegistry := TDictionary<TLanguage, TTranslateFactory>.Create;
    // Register default languages
    FRegistry.Add(TLanguage.lang_enUS,
      (function: ITranslate
      begin
        Result := TTranslate_enUS.Create;
      end));
    FRegistry.Add(TLanguage.lang_ptBR,
      (function: ITranslate
      begin
        Result := TTranslate_ptBR.Create;
      end));
  end;
end;

class function TTranslateProvider.GetTranslationFactory(const pLanguage: TLanguage): TTranslateFactory;
begin
  if FRegistry = nil then
  begin
    TMonitor.Enter(FLock);
    try
      if FRegistry = nil then
        InitializeRegistry;
    finally
      TMonitor.Exit(FLock);
    end;
  end;

  if not FRegistry.TryGetValue(pLanguage, Result) then
    Result := nil;
end;

class procedure TTranslateProvider.RegisterLanguage(const pLanguage: TLanguage; const pFactory: TTranslateFactory);
begin
  if pFactory = nil then
    raise EArgumentNilException.Create('pFactory cannot be nil');

  TMonitor.Enter(FLock);
  try
    if FRegistry = nil then
      InitializeRegistry;
    FRegistry.AddOrSetValue(pLanguage, pFactory);
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function TTranslateProvider.GetTranslation(const pLanguage: TLanguage): ITranslate;
var
  lFactory: TTranslateFactory;
begin
  lFactory := GetTranslationFactory(pLanguage);
  if not Assigned(lFactory) then
    raise ETranslationNotFound.CreateFmt(
      'No translation provider registered for language code %d', [Ord(pLanguage)]);
  Result := lFactory();
end;

initialization
  TTranslateProvider.FLock := TObject.Create;

finalization
  TTranslateProvider.FRegistry.Free;
  TTranslateProvider.FLock.Free;

end.
