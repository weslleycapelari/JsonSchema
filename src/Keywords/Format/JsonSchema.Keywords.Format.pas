unit JsonSchema.Keywords.Format;

(*
--------------------------------------------------------------------------------
Implements the validation rule for the 'format' keyword across all JSON Schema drafts
using a dynamic plugin registry pattern and draft-aware compliance checks.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  System.RegularExpressions,
  System.Generics.Collections,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Delegate format validator function type.</summary>
  TFormatValidatorFunc = reference to function(const pValue: string): Boolean;

  /// <summary>Extensible format validation registry supporting standard and custom formats.</summary>
  TFormatRegistry = class
  strict private
    class var FValidators: TDictionary<string, TFormatValidatorFunc>;
    class var FStandardFormats: TDictionary<string, TDraftVersion>;
    class constructor Create;
    class destructor Destroy;
  public
    /// <summary>Registers a custom format validator.</summary>
    class procedure RegisterFormat(const pFormatName: string; const pValidator: TFormatValidatorFunc); static;

    /// <summary>Helper method to register regular expression validation rules.</summary>
    class procedure RegisterRegexFormat(const pFormatName, pPattern: string); static;

    /// <summary>Validates a string against a registered format.</summary>
    class function ValidateFormat(const pFormatName, pValue: string; const pDraft: TDraftVersion;
      out pFound: Boolean): Boolean; static;

    /// <summary>Checks whether a format name is part of standard draft specifications.</summary>
    class function IsStandardFormat(const pFormatName: string): Boolean; static;

    /// <summary>Checks if the standard format is supported under the specified draft version.</summary>
    class function IsFormatSupported(const pFormatName: string; const pDraft: TDraftVersion): Boolean; static;
  end;

  /// <summary>Validates string values against semantic format constraints (e.g. date-time, email, etc).</summary>
  TFormatKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FFormat: string;
    FDraft: TDraftVersion;
    function GetKeywordName: string;
  public
    /// <summary>Initializes format keyword with target constraint format name.</summary>
    constructor Create(const pFormat: string; const pDraft: TDraftVersion);

    /// <summary>Validates the JSON string instance against the format rules.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a format keyword validator from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Factory method to create Draft 6 compliant format keywords.</summary>
    class function CreateKeywordDraft6(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Factory method to create Draft 7 compliant format keywords.</summary>
    class function CreateKeywordDraft7(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Factory method to create Draft 2019-09 compliant format keywords.</summary>
    class function CreateKeywordDraft2019_09(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Factory method to create Draft 2020-12 compliant format keywords.</summary>
    class function CreateKeywordDraft2020_12(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('format').</summary>
    property KeywordName: string read GetKeywordName;

    /// <summary>Target format name.</summary>
    property FormatStr: string read FFormat;

    /// <summary>The draft version this keyword was compiled under.</summary>
    property Draft: TDraftVersion read FDraft;
  end;

implementation

uses
  JsonSchema.JSONHelper,
  JsonSchema.Core.URI.Utils,
  JsonSchema.Keywords.Format.Constants,
  JsonSchema.Keywords.Format.IPv6,
  JsonSchema.Keywords.Format.DateTime,
  JsonSchema.Keywords.Format.Iri,
  JsonSchema.Keywords.Format.UriTemplate;

/// <summary>Exception-safe check to determine if a string is a valid regex pattern.</summary>
function IsValidRegex(const pValue: string): Boolean;
begin
  try
    TRegEx.IsMatch('', pValue);
    Result := True;
  except
    Result := False;
  end;
end;

{ TFormatRegistry }

class constructor TFormatRegistry.Create;
begin
  FValidators := TDictionary<string, TFormatValidatorFunc>.Create;
  FStandardFormats := TDictionary<string, TDraftVersion>.Create;

  // Populate Standard Formats Map (enables draft-aware validation)
  FStandardFormats.Add('date-time', TDraftVersion.dvDraft6);
  FStandardFormats.Add('email', TDraftVersion.dvDraft6);
  FStandardFormats.Add('hostname', TDraftVersion.dvDraft6);
  FStandardFormats.Add('ipv4', TDraftVersion.dvDraft6);
  FStandardFormats.Add('ipv6', TDraftVersion.dvDraft6);
  FStandardFormats.Add('uri', TDraftVersion.dvDraft6);
  FStandardFormats.Add('uri-reference', TDraftVersion.dvDraft6);
  FStandardFormats.Add('uri-template', TDraftVersion.dvDraft6);
  FStandardFormats.Add('json-pointer', TDraftVersion.dvDraft6);

  FStandardFormats.Add('date', TDraftVersion.dvDraft7);
  FStandardFormats.Add('time', TDraftVersion.dvDraft7);
  FStandardFormats.Add('iri', TDraftVersion.dvDraft7);
  FStandardFormats.Add('iri-reference', TDraftVersion.dvDraft7);
  FStandardFormats.Add('idn-email', TDraftVersion.dvDraft7);
  FStandardFormats.Add('idn-hostname', TDraftVersion.dvDraft7);
  FStandardFormats.Add('relative-json-pointer', TDraftVersion.dvDraft7);
  FStandardFormats.Add('regex', TDraftVersion.dvDraft7);

  FStandardFormats.Add('uuid', TDraftVersion.dvDraft2019_09);
  FStandardFormats.Add('duration', TDraftVersion.dvDraft2019_09);

  // Register Regex Validators
  RegisterRegexFormat('ipv4', REGEX_IPV4);
  RegisterRegexFormat('duration', REGEX_DURATION);
  RegisterRegexFormat('email', REGEX_EMAIL);
  RegisterRegexFormat('idn-email', REGEX_IDN_EMAIL);
  RegisterRegexFormat('idn-hostname', REGEX_IDN_HOSTNAME);
  RegisterRegexFormat('iri-reference', REGEX_IRI_REFERENCE);
  RegisterRegexFormat('relative-json-pointer', REGEX_RELATIVE_JSON_POINTER);
  RegisterRegexFormat('hostname', REGEX_HOSTNAME);
  RegisterRegexFormat('uuid', REGEX_UUID);

  // Register Function Validators
  RegisterFormat('ipv6', IsValidIPv6);
  RegisterFormat('date-time', IsValidDateTime);
  RegisterFormat('date', IsValidDate);
  RegisterFormat('time', IsValidTime);
  RegisterFormat('iri', IsValidIri);
  RegisterFormat('uri-template', IsValidUriTemplate);
  RegisterFormat('json-pointer', TURIUtils.IsValidJsonPointer);
  RegisterFormat('uri-reference', TURIUtils.IsValidURIReference);
  RegisterFormat('uri', TURIUtils.IsValidURI);
  RegisterFormat('regex', IsValidRegex);
end;

class destructor TFormatRegistry.Destroy;
begin
  FStandardFormats.Free;
  FValidators.Free;
end;

class procedure TFormatRegistry.RegisterFormat(const pFormatName: string; const pValidator: TFormatValidatorFunc);
begin
  FValidators.AddOrSetValue(LowerCase(pFormatName), pValidator);
end;

class procedure TFormatRegistry.RegisterRegexFormat(const pFormatName, pPattern: string);
begin
  RegisterFormat(pFormatName,
    function(const pValue: string): Boolean
    begin
      Result := TRegEx.IsMatch(pValue, pPattern, [roCompiled]);
    end);
end;

class function TFormatRegistry.IsStandardFormat(const pFormatName: string): Boolean;
begin
  Result := FStandardFormats.ContainsKey(LowerCase(pFormatName));
end;

class function TFormatRegistry.IsFormatSupported(const pFormatName: string; const pDraft: TDraftVersion): Boolean;
var
  lMinDraft: TDraftVersion;
begin
  if FStandardFormats.TryGetValue(LowerCase(pFormatName), lMinDraft) then
  begin
    Result := Ord(pDraft) >= Ord(lMinDraft);
  end else
    Result := False;
end;

class function TFormatRegistry.ValidateFormat(const pFormatName, pValue: string; const pDraft: TDraftVersion;
  out pFound: Boolean): Boolean;
var
  lValidator: TFormatValidatorFunc;
begin
  pFound := FValidators.TryGetValue(LowerCase(pFormatName), lValidator);
  if pFound then
  begin
    if IsStandardFormat(pFormatName) and (not IsFormatSupported(pFormatName, pDraft)) then
    begin
      Result := True; // Unsupported standard format in this draft passes validation
      Exit;
    end;

    if Assigned(lValidator) then
      Result := lValidator(pValue)
    else
      Result := True;
  end else
    Result := True; // Unknown formats pass validation
end;

{ TFormatKeyword }

constructor TFormatKeyword.Create(const pFormat: string; const pDraft: TDraftVersion);
begin
  inherited Create;
  FFormat := pFormat;
  FDraft := pDraft;
end;

class function TFormatKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := CreateKeywordDraft6(pKeywordValue, pParentSchema, pCompileFunc);
end;

class function TFormatKeyword.CreateKeywordDraft6(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
    Result := TFormatKeyword.Create(pKeywordValue.Value, TDraftVersion.dvDraft6)
  else
    Result := TFormatKeyword.Create('', TDraftVersion.dvDraft6);
end;

class function TFormatKeyword.CreateKeywordDraft7(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
    Result := TFormatKeyword.Create(pKeywordValue.Value, TDraftVersion.dvDraft7)
  else
    Result := TFormatKeyword.Create('', TDraftVersion.dvDraft7);
end;

class function TFormatKeyword.CreateKeywordDraft2019_09(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
    Result := TFormatKeyword.Create(pKeywordValue.Value, TDraftVersion.dvDraft2019_09)
  else
    Result := TFormatKeyword.Create('', TDraftVersion.dvDraft2019_09);
end;

class function TFormatKeyword.CreateKeywordDraft2020_12(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
    Result := TFormatKeyword.Create(pKeywordValue.Value, TDraftVersion.dvDraft2020_12)
  else
    Result := TFormatKeyword.Create('', TDraftVersion.dvDraft2020_12);
end;

function TFormatKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_FORMAT;
end;

function TFormatKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
var
  lValue: string;
  lIsValid: Boolean;
  lFound: Boolean;
  lContext: TJSONObject;
begin
  // format validation only applies to JSON strings. Other types are ignored (valid).
  if not pInstance.IsJSONString then
  begin
    Result := TValidationResult.ValidResult;
    Exit;
  end;

  lValue := TJSONString(pInstance).Value;
  lIsValid := TFormatRegistry.ValidateFormat(FFormat, lValue, FDraft, lFound);

  if lIsValid then
    Result := TValidationResult.ValidResult
  else
  begin
    lContext := TJSONObject.Create;
    try
      lContext.AddPair('format', TJSONString.Create(FFormat));
      lContext.AddPair('actual', TJSONString.Create(lValue));
      Result := TValidationResult.InvalidResult(GetKeywordName, lContext);
    finally
      lContext.Free;
    end;
  end;
end;

end.
