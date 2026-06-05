unit Delphi2Schema.Attributes;

(*
--------------------------------------------------------------------------------
Custom attributes for annotating Delphi classes/records to map to JSON Schema.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils;

type
  /// <summary>Ignore this field or property during schema generation.</summary>
  JSONSchemaIgnoreAttribute = class(TCustomAttribute);

  /// <summary>Set title metadata for the type or member.</summary>
  JSONSchemaTitleAttribute = class(TCustomAttribute)
  private
    FValue: string;
  public
    constructor Create(const pValue: string);
    property Value: string read FValue;
  end;

  /// <summary>Set description metadata for the type or member.</summary>
  JSONSchemaDescriptionAttribute = class(TCustomAttribute)
  private
    FValue: string;
  public
    constructor Create(const pValue: string);
    property Value: string read FValue;
  end;

  /// <summary>Mark this field or property as a required member.</summary>
  JSONSchemaRequiredAttribute = class(TCustomAttribute);

  /// <summary>Specify a minimum numeric value constraint.</summary>
  JSONSchemaMinimumAttribute = class(TCustomAttribute)
  private
    FValue: Double;
  public
    constructor Create(pValue: Double);
    property Value: Double read FValue;
  end;

  /// <summary>Specify a maximum numeric value constraint.</summary>
  JSONSchemaMaximumAttribute = class(TCustomAttribute)
  private
    FValue: Double;
  public
    constructor Create(pValue: Double);
    property Value: Double read FValue;
  end;

  /// <summary>Specify a minimum string length constraint.</summary>
  JSONSchemaMinLengthAttribute = class(TCustomAttribute)
  private
    FValue: Integer;
  public
    constructor Create(pValue: Integer);
    property Value: Integer read FValue;
  end;

  /// <summary>Specify a maximum string length constraint.</summary>
  JSONSchemaMaxLengthAttribute = class(TCustomAttribute)
  private
    FValue: Integer;
  public
    constructor Create(pValue: Integer);
    property Value: Integer read FValue;
  end;

  /// <summary>Specify a regular expression pattern constraint.</summary>
  JSONSchemaPatternAttribute = class(TCustomAttribute)
  private
    FValue: string;
  public
    constructor Create(const pValue: string);
    property Value: string read FValue;
  end;

  /// <summary>Specify a standard format keyword constraint (e.g., email, uuid).</summary>
  JSONSchemaFormatAttribute = class(TCustomAttribute)
  private
    FValue: string;
  public
    constructor Create(const pValue: string);
    property Value: string read FValue;
  end;

  /// <summary>Override default enumeration names in schema.</summary>
  JSONSchemaEnumNamesAttribute = class(TCustomAttribute)
  private
    FValue: string;
  public
    constructor Create(const pValue: string);
    property Value: string read FValue;
  end;

implementation

constructor JSONSchemaTitleAttribute.Create(const pValue: string);
begin
  FValue := pValue;
end;

constructor JSONSchemaDescriptionAttribute.Create(const pValue: string);
begin
  FValue := pValue;
end;

constructor JSONSchemaMinimumAttribute.Create(pValue: Double);
begin
  FValue := pValue;
end;

constructor JSONSchemaMaximumAttribute.Create(pValue: Double);
begin
  FValue := pValue;
end;

constructor JSONSchemaMinLengthAttribute.Create(pValue: Integer);
begin
  FValue := pValue;
end;

constructor JSONSchemaMaxLengthAttribute.Create(pValue: Integer);
begin
  FValue := pValue;
end;

constructor JSONSchemaPatternAttribute.Create(const pValue: string);
begin
  FValue := pValue;
end;

constructor JSONSchemaFormatAttribute.Create(const pValue: string);
begin
  FValue := pValue;
end;

constructor JSONSchemaEnumNamesAttribute.Create(const pValue: string);
begin
  FValue := pValue;
end;

end.
