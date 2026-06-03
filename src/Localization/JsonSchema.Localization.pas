unit JsonSchema.Localization;

(*
--------------------------------------------------------------------------------
Manages registration and lookup of localization plugins.
--------------------------------------------------------------------------------
*)

interface

uses
  System.Generics.Collections,
  JsonSchema.Localization.Enums,
  JsonSchema.Localization.Interfaces;

type
  /// <summary>Engine that registers and resolves active ILocalization instances by TLocale.</summary>
  TLocalizationEngine = class
  strict private
    FRegistry: TDictionary<TLocale, ILocalization>;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Registers a localization provider.</summary>
    /// <param name="pLocalization">The localization provider instance.</param>
    procedure RegisterLocalization(const pLocalization: ILocalization);

    /// <summary>Resolves a registered localization instance for a specific locale.</summary>
    /// <param name="pLocale">The locale to resolve.</param>
    /// <returns>The resolved localization provider instance.</returns>
    function Resolve(const pLocale: TLocale): ILocalization;

    /// <summary>Checks if a locale is registered in the engine.</summary>
    function IsRegistered(const pLocale: TLocale): Boolean;
  end;

implementation

uses
  System.SysUtils;

{ TLocalizationEngine }

constructor TLocalizationEngine.Create;
begin
  inherited Create;
  FRegistry := TDictionary<TLocale, ILocalization>.Create;
end;

destructor TLocalizationEngine.Destroy;
begin
  FRegistry.Free;
  inherited Destroy;
end;

procedure TLocalizationEngine.RegisterLocalization(const pLocalization: ILocalization);
begin
  if Assigned(pLocalization) then
    FRegistry.AddOrSetValue(pLocalization.Locale, pLocalization);
end;

function TLocalizationEngine.Resolve(const pLocale: TLocale): ILocalization;
begin
  if not FRegistry.TryGetValue(pLocale, Result) then
    raise Exception.CreateFmt('Localization for locale %d is not registered', [Ord(pLocale)]);
end;

function TLocalizationEngine.IsRegistered(const pLocale: TLocale): Boolean;
begin
  Result := FRegistry.ContainsKey(pLocale);
end;

end.
