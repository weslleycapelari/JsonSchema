unit JsonSchema.Exceptions;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Base exception for all JSON Schema library errors.
  /// </summary>
  EJsonSchemaError = class(Exception);

  /// <summary>
  ///   Raised when an invalid or unsupported JSON Schema draft version is specified.
  /// </summary>
  EUnsupportedDraft = class(EJsonSchemaError);

  /// <summary>
  ///   Raised when a required URI component is missing during validation.
  /// </summary>
  EMissingComponentError = class(EJsonSchemaError);

  /// <summary>
  ///   Raised when a relative URI cannot be resolved against a given base URI.
  /// </summary>
  EResolutionError = class(EJsonSchemaError);

  /// <summary>
  ///   Raised when the authority component of a URI cannot be parsed into its sub-parts.
  /// </summary>
  EInvalidAuthority = class(EJsonSchemaError);

  /// <summary>
  ///   Raised when a URI fails validation against defined rules (e.g., missing required components).
  /// </summary>
  EValidationError = class(EJsonSchemaError);

  /// <summary>
  ///   Raised when a $ref points to a resource or fragment that cannot be found.
  /// </summary>
  EReferenceNotFound = class(EJsonSchemaError);

  /// <summary>
  ///   Raised when a cyclic reference is detected during $ref resolution.
  /// </summary>
  ECyclicReference = class(EJsonSchemaError);

  /// <summary>
  ///   Raised when a required vocabulary is not supported by the validator.
  /// </summary>
  EUnsupportedVocabulary = class(EJsonSchemaError);

  /// <summary>
  ///   Raised when a JSON value does not conform to the expected structure
  ///   (e.g., invalid type for a keyword).
  /// </summary>
  EInvalidSchema = class(EJsonSchemaError);

implementation

end.
