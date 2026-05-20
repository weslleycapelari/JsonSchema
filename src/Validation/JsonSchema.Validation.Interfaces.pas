unit JsonSchema.Validation.Interfaces;

interface

uses
  System.JSON,
  JsonSchema.Types,
  JsonSchema.Interfaces,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Registry.Base;

type
  /// <summary>
  ///   Extends IVisitor with language selection, error reporting, and access to
  ///   the accumulated IValidationResult for the current validation run.
  /// </summary>
  IValidationVisitor<T> = interface(IVisitor<T>)
    ['{F7E2A1D4-8C3B-4E9F-9A2D-5B6C7D8E9F0A}']
    function Language: TLanguage; overload;
    function Language(const pLanguage: TLanguage): IValidationVisitor<T>; overload;
    procedure AddError(const pErrorType: TErrorType; pParams: array of const); overload;
    procedure AddError(const pErrorType: TErrorType); overload;
    function FindCustomHint(pErrorType: TErrorType): string;
    function Result: IValidationResult;
    function Registry: TRegistryVisitor;
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): T;
  end;

implementation

end.
