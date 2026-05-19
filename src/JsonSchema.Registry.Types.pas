unit JsonSchema.Registry.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Identifies the individual components of a URI as defined by RFC 3986.</summary>
  TURIComponent = (uricScheme, uricUserInfo, uricHost, uricPort, uricAuthority, uricPath, uricQuery, uricFragment);

  /// <summary>Set of TURIComponent used for multi-component validation rules.</summary>
  TURIComponents = set of TURIComponent;

  /// <summary>Base class for all exceptions raised by the URI library.</summary>
  ERFC3986Exception = class(Exception);

  /// <summary>Raised when the authority component of a URI cannot be parsed into its sub-parts.</summary>
  EInvalidAuthority = class(ERFC3986Exception);

  /// <summary>Base class for errors detected by TURIValidator.</summary>
  EValidationError = class(ERFC3986Exception);

  /// <summary>Raised when a required URI component is absent during validation.</summary>
  EMissingComponentError = class(EValidationError);

  /// <summary>Raised when a relative URI cannot be resolved against a given base URI.</summary>
  EResolutionError = class(ERFC3986Exception);

const
  // Regex derived from RFC 3986, Appendix B, extended to reject backslashes.
  URI_PATTERN = '^(?:(?<scheme>[A-Za-z][A-Za-z0-9+\-.]*):)?(?:\/\/(?<authority>[^\/?#\\]*))?(?<path>[^?#\\]*)(?:\?(?<query>[^#\\]*))?(?:#(?<fragment>[^\\]*))?$';

implementation

end.
