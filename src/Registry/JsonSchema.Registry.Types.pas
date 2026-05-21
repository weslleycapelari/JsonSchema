unit JsonSchema.Registry.Types;

interface

uses
  JsonSchema.Exceptions;

type
  /// <summary>Identifies the individual components of a URI as defined by RFC 3986.</summary>
  TURIComponent = (
    uricScheme,
    uricUserInfo,
    uricHost,
    uricPort,
    uricAuthority,
    uricPath,
    uricQuery,
    uricFragment
  );

  /// <summary>Set of TURIComponent used for multi-component validation rules.</summary>
  TURIComponents = set of TURIComponent;

const
  /// <summary>
  ///   Regex derived from RFC 3986, Appendix B, extended to reject backslashes.
  /// </summary>
  URI_PATTERN = '^(?:(?<scheme>[A-Za-z][A-Za-z0-9+\-.]*):)?(?:\/\/(?<authority>[^\/?#\\]*))?(?<path>[^?#\\]*)(?:\?(?<query>[^#\\]*))?(?:#(?<fragment>[^\\]*))?$';

implementation

end.
