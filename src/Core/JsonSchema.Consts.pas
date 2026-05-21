unit JsonSchema.Consts;

interface

const
  /// <summary>Default maximum depth for $ref resolution to prevent infinite recursion.</summary>
  DEFAULT_MAX_REF_DEPTH = 100;

  /// <summary>Default minimum number of matching items for the "contains" keyword when not specified.</summary>
  DEFAULT_MIN_CONTAINS = 1;

  /// <summary>Validation vocabulary URI for Draft 2019-09.</summary>
  DRAFT2019_09_VALIDATION_VOCABULARY_URI = 'https://json-schema.org/draft/2019-09/vocab/validation';

  /// <summary>Validation vocabulary URI for Draft 2020-12.</summary>
  DRAFT2020_12_VALIDATION_VOCABULARY_URI = 'https://json-schema.org/draft/2020-12/vocab/validation';

  /// <summary>Format-assertion vocabulary URI for Draft 2020-12.</summary>
  DRAFT2020_12_FORMAT_ASSERTION_VOCABULARY_URI = 'https://json-schema.org/draft/2020-12/vocab/format-assertion';

  /// <summary>Metaschema URI that indicates validation vocabulary is silent (no validation).</summary>
  META_SCHEMA_NO_VALIDATION_URI = 'https://json-schema.org/metaschema-no-validation.json';

  /// <summary>Array of known standard vocabularies for Draft 2019-09 compatibility.</summary>
  DRAFT2019_09_KNOWN_VOCABULARIES: array[0..6] of string = (
    'https://json-schema.org/draft/2019-09/vocab/core',
    'https://json-schema.org/draft/2019-09/vocab/applicator',
    'https://json-schema.org/draft/2019-09/vocab/validation',
    'https://json-schema.org/draft/2019-09/vocab/meta-data',
    'https://json-schema.org/draft/2019-09/vocab/format',
    'https://json-schema.org/draft/2019-09/vocab/content',
    'https://json-schema.org/draft/2019-09/vocab/hyper-schema'
  );

  /// <summary>Canonical base URI for test server (used in test suites).</summary>
  LOCAL_TEST_SERVER_BASE_URI = 'http://localhost:1234/';

implementation

end.
