unit JsonSchema.Keywords.Format.Constants;

(*
--------------------------------------------------------------------------------
Provides central definition of regular expression constants for format validation rules.
--------------------------------------------------------------------------------
*)

interface

const
  /// <summary>Matches standard IPv4 addresses in dotted decimal notation.</summary>
  REGEX_IPV4 = '^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}' +
    '(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$';

  /// <summary>Helper regex to isolate and pre-validate IPv4 suffix sequences inside IPv6 addresses.</summary>
  REGEX_IPV4_CANDIDATE = '^(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)' +
    '(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)){3}$';

  /// <summary>Matches ISO 8601 / RFC 3339 full date-time strings including timezone offsets.</summary>
  REGEX_DATETIME = '(*UCP)^\d{4}-\d{2}-\d{2}T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?' +
    '(?:(Z)|([+-])(\d{2}):(\d{2}))$';

  /// <summary>Matches ISO 8601 duration sequences (e.g. P3D, PT12H).</summary>
  REGEX_DURATION = '^P(?!$)((\d+Y)?(\d+M)?(\d+D)?(T(?=\d)(\d+H)?(\d+M)?(\d+S)?)?|(\d+W))$';

  /// <summary>Matches full-date format (YYYY-MM-DD).</summary>
  REGEX_DATE = '^\d{4}-\d{2}-\d{2}$';

  /// <summary>Matches full-time format (hh:mm:ss) with optional fractional seconds and timezone.</summary>
  REGEX_TIME = '^(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:(Z)|([+-])(\d{2}):(\d{2}))$';

  /// <summary>Matches RFC 5322 email addresses.</summary>
  REGEX_EMAIL = '(*UCP)^(?:[a-zA-Z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&''*+/=?^_`{|}~-]+)*|"(?:[^"\\]|\\.)*")' +
    '@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*|\[(?:[^\]\\]|\\.)*\])$';

  /// <summary>Matches RFC 6531 internationalized email addresses.</summary>
  REGEX_IDN_EMAIL = '^[^\s@]+@(?=.{1,253}$)(?:(?!-)[\p{L}\p{N}-]{1,63}' +
    '(?<!-))(?:\.(?:(?!-)[\p{L}\p{N}-]{1,63}(?<!-)))*$';

  /// <summary>Matches RFC 5890 internationalized hostnames.</summary>
  REGEX_IDN_HOSTNAME = '^(?=.{1,253}$)(?:(?!-)[\p{L}\p{N}-]{1,63}' +
    '(?<!-))(?:\.(?:(?!-)[\p{L}\p{N}-]{1,63}(?<!-)))*$';

  /// <summary>Matches RFC 3987 Internationalized Resource Identifier (IRI) references.</summary>
  REGEX_IRI_REFERENCE = '^[^\s<>"{}\|\\\^`\\]+$';

  /// <summary>Matches relative JSON pointers (e.g. 1/foo, 0#).</summary>
  REGEX_RELATIVE_JSON_POINTER = '^(0|[1-9][0-9]*)(#|(/([^~/]|~[01])*)*)$';

  /// <summary>Matches RFC 1034 hostnames.</summary>
  REGEX_HOSTNAME = '^(?=.{1,253}$)(?:(?!-)[A-Za-z0-9-]{1,63}' +
    '(?<!-))(?:\.(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)))*$';

  /// <summary>Matches standard 36-character UUID representation.</summary>
  REGEX_UUID = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

implementation

end.
