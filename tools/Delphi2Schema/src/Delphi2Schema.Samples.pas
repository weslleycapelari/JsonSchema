unit Delphi2Schema.Samples;

(*
--------------------------------------------------------------------------------
Sample class declarations annotated with custom schema attributes for demo scans.
--------------------------------------------------------------------------------
*)

interface

{$M+}

uses
  System.SysUtils,
  Delphi2Schema.Attributes;

type
  /// <summary>Sample status enumeration.</summary>
  TSimpleEnum = (sePending, seApproved, seRejected);

  /// <summary>Sample Address class to demonstrate nested object mapping.</summary>
  [JSONSchemaTitle('SampleAddress')]
  [JSONSchemaDescription('Represents a customer physical address')]
  TSampleAddress = class
  private
    FStreet: string;
    FCity: string;
    FPostalCode: string;
  published
    [JSONSchemaRequired]
    [JSONSchemaMinLength(3)]
    property Street: string read FStreet write FStreet;

    [JSONSchemaRequired]
    property City: string read FCity write FCity;

    [JSONSchemaPattern('^\d{5}-\d{3}$')]
    property PostalCode: string read FPostalCode write FPostalCode;
  end;

  /// <summary>Sample User class demonstrating comprehensive mappings.</summary>
  [JSONSchemaTitle('SampleUser')]
  [JSONSchemaDescription('A user profile containing registration details')]
  TSampleUser = class
  private
    FId: Integer;
    FName: string;
    FEmail: string;
    FIsActive: Boolean;
    FCreatedAt: TDateTime;
    FStatus: TSimpleEnum;
    FAddress: TSampleAddress;
    FTags: TArray<string>;
  published
    [JSONSchemaRequired]
    [JSONSchemaMinimum(1)]
    property Id: Integer read FId write FId;

    [JSONSchemaRequired]
    [JSONSchemaMaxLength(50)]
    property Name: string read FName write FName;

    [JSONSchemaRequired]
    [JSONSchemaFormat('email')]
    property Email: string read FEmail write FEmail;

    property IsActive: Boolean read FIsActive write FIsActive;

    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;

    [JSONSchemaEnumNames('Pendente, Aprovado, Rejeitado')]
    property Status: TSimpleEnum read FStatus write FStatus;

    property Address: TSampleAddress read FAddress write FAddress;

    property Tags: TArray<string> read FTags write FTags;
  end;

implementation

initialization
  TSampleUser.ClassName;
  TSampleAddress.ClassName;

end.
