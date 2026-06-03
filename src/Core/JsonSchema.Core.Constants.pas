unit JsonSchema.Core.Constants;

(*
--------------------------------------------------------------------------------
Defines all global constants, including JSON Schema validation/metadata keywords.
--------------------------------------------------------------------------------
*)

interface

const
  /// <summary>Validation keyword for instance type validation.</summary>
  KEYWORD_TYPE = 'type';

  /// <summary>Validation keyword for minimum string length validation.</summary>
  KEYWORD_MINLENGTH = 'minLength';

  /// <summary>Validation keyword for enumeration validation.</summary>
  KEYWORD_ENUM = 'enum';

  /// <summary>Validation keyword for constant validation.</summary>
  KEYWORD_CONST = 'const';

  /// <summary>Validation keyword for required properties validation.</summary>
  KEYWORD_REQUIRED = 'required';

  /// <summary>Validation keyword for minimum numeric limit validation.</summary>
  KEYWORD_MINIMUM = 'minimum';

  /// <summary>Validation keyword for maximum numeric limit validation.</summary>
  KEYWORD_MAXIMUM = 'maximum';

  /// <summary>Validation keyword for maximum string length validation.</summary>
  KEYWORD_MAXLENGTH = 'maxLength';

  /// <summary>Validation keyword for minimum array items count validation.</summary>
  KEYWORD_MINITEMS = 'minItems';

  /// <summary>Validation keyword for maximum array items count validation.</summary>
  KEYWORD_MAXITEMS = 'maxItems';

  /// <summary>Validation keyword for numeric multipleOf validation.</summary>
  KEYWORD_MULTIPLEOF = 'multipleOf';

  /// <summary>Validation keyword for exclusiveMaximum validation.</summary>
  KEYWORD_EXCLUSIVEMAXIMUM = 'exclusiveMaximum';

  /// <summary>Validation keyword for exclusiveMinimum validation.</summary>
  KEYWORD_EXCLUSIVEMINIMUM = 'exclusiveMinimum';

  /// <summary>Validation keyword for string regex pattern validation.</summary>
  KEYWORD_PATTERN = 'pattern';

  /// <summary>Applicator keyword for array subschema items validation.</summary>
  KEYWORD_ITEMS = 'items';

  /// <summary>Applicator keyword for additional array items validation.</summary>
  KEYWORD_ADDITIONALITEMS = 'additionalItems';

  /// <summary>Validation keyword for unique array items validation.</summary>
  KEYWORD_UNIQUEITEMS = 'uniqueItems';

  /// <summary>Applicator keyword for contains subschema validation.</summary>
  KEYWORD_CONTAINS = 'contains';

  /// <summary>Validation keyword for maximum object properties count.</summary>
  KEYWORD_MAXPROPERTIES = 'maxProperties';

  /// <summary>Validation keyword for minimum object properties count.</summary>
  KEYWORD_MINPROPERTIES = 'minProperties';

  /// <summary>Applicator keyword for object properties subschemas.</summary>
  KEYWORD_PROPERTIES = 'properties';

  /// <summary>Applicator keyword for pattern properties subschemas.</summary>
  KEYWORD_PATTERNPROPERTIES = 'patternProperties';

  /// <summary>Applicator keyword for additional object properties.</summary>
  KEYWORD_ADDITIONALPROPERTIES = 'additionalProperties';

  /// <summary>Applicator keyword for property or schema dependencies.</summary>
  KEYWORD_DEPENDENCIES = 'dependencies';

  /// <summary>Applicator keyword for object property names validation.</summary>
  KEYWORD_PROPERTYNAMES = 'propertyNames';

  /// <summary>Logical combiner keyword for allOf subschemas.</summary>
  KEYWORD_ALLOF = 'allOf';

  /// <summary>Logical combiner keyword for anyOf subschemas.</summary>
  KEYWORD_ANYOF = 'anyOf';

  /// <summary>Logical combiner keyword for oneOf subschemas.</summary>
  KEYWORD_ONEOF = 'oneOf';

  /// <summary>Logical combiner keyword for negating a subschema.</summary>
  KEYWORD_NOT = 'not';

  /// <summary>Metadata keyword declaring the JSON Schema dialect URI.</summary>
  KEYWORD_SCHEMA = '$schema';

  /// <summary>Metadata keyword declaring the unique identifier of a schema.</summary>
  KEYWORD_ID = '$id';

  /// <summary>Legacy metadata keyword declaring the schema identifier.</summary>
  KEYWORD_ID_LEGACY = 'id';

  /// <summary>Applicator keyword referencing an external or local subschema.</summary>
  KEYWORD_REF = '$ref';

  /// <summary>Metadata keyword providing a short title for the schema.</summary>
  KEYWORD_TITLE = 'title';

  /// <summary>Metadata keyword providing a description for the schema.</summary>
  KEYWORD_DESCRIPTION = 'description';

  /// <summary>Metadata keyword providing a default value for the schema.</summary>
  KEYWORD_DEFAULT = 'default';

  /// <summary>Metadata keyword providing example values for the schema.</summary>
  KEYWORD_EXAMPLES = 'examples';

  /// <summary>Validation keyword validating string formats (date-time, email, etc).</summary>
  KEYWORD_FORMAT = 'format';

  /// <summary>Applicator keyword for conditional evaluation.</summary>
  KEYWORD_IF = 'if';

  /// <summary>Applicator keyword for positive conditional match.</summary>
  KEYWORD_THEN = 'then';

  /// <summary>Applicator keyword for negative conditional match.</summary>
  KEYWORD_ELSE = 'else';

  /// <summary>Metadata keyword for schema comments.</summary>
  KEYWORD_COMMENT = '$comment';

implementation

end.
