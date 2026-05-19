unit JsonSchema.Validation.Interfaces;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Translate.Types,
  JsonSchema.Registry.Base;

type
  IError = interface;
  IValidationResult = interface;
  IRefResolutionGuard = interface;

  /// <summary>
  /// Extends IVisitor with language selection, error reporting, and access to
  /// the accumulated IValidationResult for the current validation run.
  /// </summary>
  IValidationVisitor<T> = interface(IVisitor<T>)
    ['{D694C0D9-EFB4-49D7-A620-D469E849263A}']
    function Language: TLanguage; overload;
    /// <summary>
    /// Sets the language used for error messages and returns the visitor
    /// for fluent chaining.
    /// </summary>
    function Language(const pLanguage: TLanguage): IValidationVisitor<T>; overload;
    /// <summary>
    /// Creates and records a validation error for the given error type,
    /// formatting the message using the supplied parameters.
    /// </summary>
    procedure AddError(const pErrorType: TErrorType; pParams: array of const); overload;
    /// <summary>
    /// Creates and records a validation error for the given error type
    /// with no additional message parameters.
    /// </summary>
    procedure AddError(const pErrorType: TErrorType); overload;
    /// <summary>
    /// Returns the custom hint registered for the given error type,
    /// or an empty string if none is registered.
    /// </summary>
    function FindCustomHint(pErrorType: TErrorType): string;
    function Result: IValidationResult;
    function Registry: TRegistryVisitor;
  end;

  /// <summary>
  /// Represents the accumulated outcome of a schema validation run: a list of
  /// errors, a set of evaluated property paths, and a set of keyword annotations.
  /// </summary>
  IValidationResult = interface(IInterface)
    ['{9461F9BC-C13B-4C32-816D-3C363B33163A}']
    function Errors: TArray<IError>;
    /// <summary>
    /// Appends an error to the result and returns Self for fluent chaining.
    /// </summary>
    function AddError(const pError: IError): IValidationResult;
    /// <summary>
    /// Records a keyword/value annotation pair and returns Self for fluent chaining.
    /// </summary>
    function AddAnnotation(const pKeyword, pValue: string): IValidationResult;
    /// <summary>
    /// Normalizes and records a property path as evaluated, then returns Self
    /// for fluent chaining.
    /// </summary>
    function AddEvaluatedProperty(const pProperty: string): IValidationResult;
    /// <summary>
    /// Returns True when no errors have been recorded.
    /// </summary>
    function IsValid: Boolean;
    function EvaluatedProperties: TEnumerable<string>;
  end;

  /// <summary>
  /// Represents a single validation error with full diagnostic context: root
  /// and parent JSON nodes, schema and instance paths, error type, message, and
  /// optional custom and standard hints. All setter overloads return Self to
  /// support fluent builder chains.
  /// </summary>
  IError = interface(IInterface)
    ['{C43B6EF3-45F2-4B9B-B75D-C3206965FFCF}']
    function RootNode: TJSONValue; overload;
    function RootNode(const pValue: TJSONValue): IError; overload;
    function ErrorType: TErrorType; overload;
    function ErrorType(const pValue: TErrorType): IError; overload;
    function ParentNode: TJSONValue; overload;
    function ParentNode(const pValue: TJSONValue): IError; overload;
    function CustomHint: string; overload;
    function CustomHint(const pValue: string): IError; overload;
    function SchemaPath: string; overload;
    function SchemaPath(const pValue: string): IError; overload;
    function SchemaNode: TJSONValue; overload;
    function SchemaNode(const pValue: TJSONValue): IError; overload;
    function InstanceNode: TJSONValue; overload;
    function InstanceNode(const pValue: TJSONValue): IError; overload;
    function InstancePath: string; overload;
    function InstancePath(const pValue: string): IError; overload;
    function ErrorMessage: string; overload;
    function ErrorMessage(const pValue: string): IError; overload;
    function StandardHint: string; overload;
    function StandardHint(const pValue: string): IError; overload;
    /// <summary>
    /// Returns the custom hint when set; falls back to the standard hint otherwise.
    /// </summary>
    function EffectiveHint: string;
  end;

  /// <summary>
  /// Guards against infinite loops during $ref resolution by tracking which
  /// resolved references are currently being evaluated.
  /// </summary>
  IRefResolutionGuard = interface(IInterface)
    ['{B25249A6-7EE6-4D1D-ABDE-6D564D970D00}']
    /// <summary>
    /// Attempts to enter resolution for the given ref URI. Returns True when
    /// the entry is granted; returns False and sets pReason when a cycle is detected.
    /// </summary>
    function TryEnterRefResolution(const pResolvedRef: string; out pReason: string): Boolean;
    /// <summary>
    /// Releases the resolution lock for the given ref URI, allowing it to be
    /// entered again in future traversals.
    /// </summary>
    procedure LeaveRefResolution(const pResolvedRef: string);
  end;

implementation

end.
