unit JsonSchema.Core.Interfaces;

(*
--------------------------------------------------------------------------------
Defines all core interfaces, records, and constants for the JSON Schema validator.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  JsonSchema.Core.Constants;

type
  /// <summary>Enumeration of supported JSON Schema draft versions.</summary>
  TDraftVersion = (dvUnknown, dvDraft6, dvDraft7, dvDraft2019_09, dvDraft2020_12);

  /// <summary>Helper structure to expose utility methods on TDraftVersion.</summary>
  TDraftVersionHelper = record helper for TDraftVersion
    function ToSchema: string;
  end;

  /// <summary>Represents a specific validation error found in the JSON document.</summary>
  IValidationError = interface
    ['{A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D}']
    function GetKeyword: string;
    function GetMessage: string;
    function GetResolution: string;
    function GetContext: TJSONObject;
    procedure SetMessage(const pMessage: string);
    procedure SetResolution(const pResolution: string);

    /// <summary>Identifies which keyword (e.g. 'type', 'minLength') triggered the error.</summary>
    property Keyword: string read GetKeyword;

    /// <summary>User-friendly translated error message.</summary>
    property Message: string read GetMessage write SetMessage;

    /// <summary>Recommended steps to fix the validation error.</summary>
    property Resolution: string read GetResolution write SetResolution;

    /// <summary>JSON object containing technical error details (e.g., expected and actual values).</summary>
    property Context: TJSONObject read GetContext;
  end;

  /// <summary>Stores the consolidated validation result of a JSON instance against a schema.</summary>
  IValidationResult = interface
    ['{B2C3D4E5-F6A7-4B8C-9D0E-1F2A3B4C5D6E}']
    function GetIsValid: Boolean;
    function GetErrors: TArray<IValidationError>;

    /// <summary>Indicates whether the JSON instance passed all validation rules successfully.</summary>
    property IsValid: Boolean read GetIsValid;

    /// <summary>List of all validation errors encountered.</summary>
    property Errors: TArray<IValidationError> read GetErrors;
  end;

  /// <summary>Represents a compiled JSON schema containing keyword validators.</summary>
  ICompiledSchema = interface
    ['{D3E4F5A6-B7C8-4D9E-0F1A-2B3C4D5E6F7A}']
    function Validate(const pInstance: TJSONValue): IValidationResult;
  end;

  /// <summary>Delegate type used to parse and compile nested sub-schemas.</summary>
  TCompileSchemaFunc = reference to function(const pSchema: TJSONValue): ICompiledSchema;

  /// <summary>Common contract for all schema keyword validators.</summary>
  IJsonSchemaKeyword = interface
    ['{C3D4E5F6-A7B8-4C9D-0E1F-2A3B4C5D6E7F}']
    function GetKeywordName: string;

    /// <summary>Validates a JSON value against this keyword's specific validation rule.</summary>
    /// <param name="pInstance">The JSON value to validate.</param>
    /// <returns>Validation result containing any errors.</returns>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Technical name of the keyword.</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

function TDraftVersionHelper.ToSchema: string;
begin
  case Self of
    dvDraft6:
      Result := 'http://json-schema.org/draft-06/schema#';
    dvDraft7:
      Result := 'http://json-schema.org/draft-07/schema#';
    dvDraft2019_09:
      Result := 'http://json-schema.org/draft/2019-09/schema#';
    dvDraft2020_12:
      Result := 'http://json-schema.org/draft/2020-12/schema#';
  else
    Result := 'unknown';
  end;
end;

end.
