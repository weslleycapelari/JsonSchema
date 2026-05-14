unit JsonSchema.Validation.Interfaces;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Translate.Types,
  JsonSchema.Registry.Base;

type
  IError = interface;
  IValidationResult = interface;
  IRefResolutionGuard = interface;

  IValidationVisitor<T> = interface(IVisitor<T>)
    ['{D694C0D9-EFB4-49D7-A620-D469E849263A}']
    function Language: TLanguage; overload;
    function Language(const ALanguage: TLanguage): IValidationVisitor<T>; overload;
    procedure AddError(const AErrorType: TErrorType; AParams: array of const); overload;
    procedure AddError(const AErrorType: TErrorType); overload;
    function FindCustomHint(AErrorType: TErrorType): string;
    function Result: IValidationResult;
    function Registry: TRegistryVisitor;
  end;

  IValidationResult = interface(IInterface)
    ['{9461F9BC-C13B-4C32-816D-3C363B33163A}']
    function Errors: TArray<IError>;
    function AddError(const AError: IError): IValidationResult;
    function IsValid: Boolean;
  end;

  IError = interface(IInterface)
    ['{C43B6EF3-45F2-4B9B-B75D-C3206965FFCF}']
    function RootNode: TJSONValue; overload;
    function RootNode(const AValue: TJSONValue): IError; overload;
    function ErrorType: TErrorType; overload;
    function ErrorType(const AValue: TErrorType): IError; overload;
    function ParentNode: TJSONValue; overload;
    function ParentNode(const AValue: TJSONValue): IError; overload;
    function CustomHint: string; overload;
    function CustomHint(const AValue: string): IError; overload;
    function SchemaPath: string; overload;
    function SchemaPath(const AValue: string): IError; overload;
    function SchemaNode: TJSONValue; overload;
    function SchemaNode(const AValue: TJSONValue): IError; overload;
    function InstanceNode: TJSONValue; overload;
    function InstanceNode(const AValue: TJSONValue): IError; overload;
    function InstancePath: string; overload;
    function InstancePath(const AValue: string): IError; overload;
    function ErrorMessage: string; overload;
    function ErrorMessage(const AValue: string): IError; overload;
    function StandardHint: string; overload;
    function StandardHint(const AValue: string): IError; overload;
    function EffectiveHint: string;
  end;

  IRefResolutionGuard = interface(IInterface)
    ['{B25249A6-7EE6-4D1D-ABDE-6D564D970D00}']
    function TryEnterRefResolution(const AResolvedRef: string; out AReason: string): Boolean;
    procedure LeaveRefResolution(const AResolvedRef: string);
  end;

implementation

end.
