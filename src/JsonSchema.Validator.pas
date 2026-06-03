unit JsonSchema.Validator;

(*
--------------------------------------------------------------------------------
Provides the primary public interface facade for compiling and validating JSON Schemas.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.CompiledSchema,
  JsonSchema.Draft6.Parser,
  JsonSchema.Localization.Enums,
  JsonSchema.Localization.Interfaces,
  JsonSchema.Localization;

type
  /// <summary>Public facade class responsible for schema validation and localization.</summary>
  TJsonSchemaValidator = class
  strict private
    FLocale: TLocale;
    FEngine: TLocalizationEngine;
  public
    /// <summary>Creates a validator instance. Registers default translations (EnUS and PtBR).</summary>
    /// <param name="pLocale">The default active locale. If omitted, defaults to TLocale.EnUS.</param>
    constructor Create(const pLocale: TLocale = TLocale.EnUS);
    destructor Destroy; override;

    /// <summary>Compiles the schema and validates the JSON instance against it.</summary>
    /// <param name="pSchema">The JSON schema object. Must be a TJSONObject instance.</param>
    /// <param name="pInstance">The JSON value to validate against the schema constraints.</param>
    /// <returns>A consolidated validation result containing any localized errors.</returns>
    /// <exception cref="EArgumentException">Raised when pSchema is not a TJSONObject.</exception>
    function Validate(const pSchema, pInstance: TJSONValue): IValidationResult; overload;

    /// <summary>Compiles the schema using the specified draft and validates the JSON instance against it.</summary>
    /// <param name="pSchema">The JSON schema object. Must be a TJSONObject instance.</param>
    /// <param name="pInstance">The JSON value to validate against the schema constraints.</param>
    /// <param name="pDraft">The target draft version for parsing the schema.</param>
    /// <returns>A consolidated validation result containing any localized errors.</returns>
    /// <exception cref="EArgumentException">Raised when pSchema is not a TJSONObject.</exception>
    function Validate(const pSchema, pInstance: TJSONValue; const pDraft: TDraftVersion): IValidationResult; overload;

    /// <summary>Active locale for formatting validation error messages.</summary>
    property Locale: TLocale read FLocale write FLocale;

    /// <summary>Active localization registry engine.</summary>
    property Engine: TLocalizationEngine read FEngine;
  end;

implementation

uses
  JsonSchema.Localization.EnUS,
  JsonSchema.Localization.PtBR,
  JsonSchema.Draft7.Parser,
  JsonSchema.Draft2019_09.Parser,
  JsonSchema.Draft2020_12.Parser,
  JsonSchema.Core.SchemaRegistry;

{ TJsonSchemaValidator }

constructor TJsonSchemaValidator.Create(const pLocale: TLocale = TLocale.EnUS);
begin
  inherited Create;
  FLocale := pLocale;
  FEngine := TLocalizationEngine.Create;

  // Register default localizations
  FEngine.RegisterLocalization(TLocalizationEnUS.Create);
  FEngine.RegisterLocalization(TLocalizationPtBR.Create);
end;

destructor TJsonSchemaValidator.Destroy;
begin
  FEngine.Free;
  inherited Destroy;
end;

function TJsonSchemaValidator.Validate(const pSchema, pInstance: TJSONValue): IValidationResult;
begin
  Result := Validate(pSchema, pInstance, TDraftVersion.dvDraft6);
end;

function TJsonSchemaValidator.Validate(const pSchema, pInstance: TJSONValue; const pDraft: TDraftVersion): IValidationResult;
var
  lCompiled: ICompiledSchema;
  lError: IValidationError;
  lLocalization: ILocalization;
  lTranslation: TTranslation;
begin
  // Reset global base URI before each top-level compilation to avoid cross-test contamination
  TSchemaRegistry.CurrentBaseURI := '';

  // Accept schema as either a JSON object or a boolean literal
  if pSchema is TJSONObject then
  begin
    case pDraft of
      TDraftVersion.dvDraft6:
        lCompiled := TDraft6Parser.Parse(TJSONObject(pSchema));
      TDraftVersion.dvDraft7:
        lCompiled := TDraft7Parser.Parse(TJSONObject(pSchema));
      TDraftVersion.dvDraft2019_09:
        lCompiled := TDraft2019_09Parser.Parse(TJSONObject(pSchema));
      TDraftVersion.dvDraft2020_12:
        lCompiled := TDraft2020_12Parser.Parse(TJSONObject(pSchema));
    else
      lCompiled := TDraft6Parser.Parse(TJSONObject(pSchema));
    end;
  end else if pSchema is TJSONBool then
  begin
    // Boolean schemas are handled by the specific parser's ParseSchema method
    case pDraft of
      TDraftVersion.dvDraft6:
        lCompiled := TDraft6Parser.ParseSchema(pSchema);
      TDraftVersion.dvDraft7:
        lCompiled := TDraft7Parser.ParseSchema(pSchema);
      TDraftVersion.dvDraft2019_09:
        lCompiled := TDraft2019_09Parser.ParseSchema(pSchema);
      TDraftVersion.dvDraft2020_12:
        lCompiled := TDraft2020_12Parser.ParseSchema(pSchema);
    else
      lCompiled := TDraft6Parser.ParseSchema(pSchema);
    end;
  end else
    raise EArgumentException.Create('Schema must be a JSON object or a boolean literal');

  Result := lCompiled.Validate(pInstance);

  // Localize error messages if the validation result contains errors
  if not Result.IsValid then
  begin
    lLocalization := FEngine.Resolve(FLocale);
    for lError in Result.Errors do
    begin
      lTranslation := lLocalization.Translate(lError);
      lError.Message := lTranslation.Message;
      lError.Resolution := lTranslation.Resolution;
    end;
  end;
end;

end.
