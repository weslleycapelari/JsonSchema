unit JsonSchema.Core.URI.Types;

(*
--------------------------------------------------------------------------------
Defines exception classes, type enums, and constant patterns for the RFC 3986 URI validation.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils;

const
  /// <summary>Standard PCRE regex pattern for parsing URI components using named groups.</summary>
  URI_PATTERN = '^((?<scheme>[^:/?#]+):)?(//(?<authority>[^/?#]*))?(?<path>[^?#]*)(\?(?<query>[^#]*))?(#(?<fragment>.*))?';

type
  /// <summary>Represents a single component of a URI reference.</summary>
  TURIComponent = (uricScheme, uricAuthority, uricUserInfo, uricHost, uricPort, uricPath, uricQuery, uricFragment);

  /// <summary>Set of URI components used for presence validation.</summary>
  TURIComponents = set of TURIComponent;

  /// <summary>Base exception class for all RFC 3986 URI parsing or validation errors.</summary>
  ERFC3986Exception = class(Exception);

  /// <summary>Raised when a URI fails to validate against configured validation rules.</summary>
  EValidationError = class(ERFC3986Exception);

  /// <summary>Raised when a required URI component is missing.</summary>
  EMissingComponentError = class(EValidationError);

  /// <summary>Raised when the authority component is invalid (e.g. port out of range).</summary>
  EInvalidAuthority = class(ERFC3986Exception);

implementation

end.
