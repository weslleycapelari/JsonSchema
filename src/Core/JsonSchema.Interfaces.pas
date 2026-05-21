unit JsonSchema.Interfaces;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Types;

type
  IError = interface;
  IValidationResult = interface;
  IRefResolutionGuard = interface;
  IResultProvider = interface;

  /// <summary>
  ///   Represents a single validation error with full diagnostic context:
  ///   root and parent JSON nodes, schema and instance paths, error type,
  ///   message, and optional custom and standard hints.
  ///   All setters return Self to support fluent builder chains.
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

    /// <summary>Returns the custom hint when set; falls back to the standard hint otherwise.</summary>
    function EffectiveHint: string;
  end;

  /// <summary>
  ///   Represents the accumulated outcome of a schema validation run:
  ///   a list of errors, a set of evaluated property paths, and a set
  ///   of keyword annotations.
  /// </summary>
  IValidationResult = interface(IInterface)
    ['{9461F9BC-C13B-4C32-816D-3C363B33163A}']
    function Errors: TArray<IError>;
    /// <summary>Appends an error and returns Self for fluent chaining.</summary>
    function AddError(const pError: IError): IValidationResult;
    /// <summary>Records a keyword/value annotation pair and returns Self.</summary>
    function AddAnnotation(const pKeyword, pValue: string): IValidationResult;
    /// <summary>Normalizes and records a property path as evaluated, then returns Self.</summary>
    function AddEvaluatedProperty(const pProperty: string): IValidationResult;
    /// <summary>Returns True when no errors have been recorded.</summary>
    function IsValid: Boolean;
    function EvaluatedProperties: TEnumerable<string>;
  end;

  /// <summary>
  ///   Guards against infinite loops during $ref resolution by tracking which
  ///   resolved references are currently being evaluated.
  /// </summary>
  IRefResolutionGuard = interface(IInterface)
    ['{B25249A6-7EE6-4D1D-ABDE-6D564D970D00}']
    /// <summary>
    ///   Attempts to enter resolution for the given ref URI.
    ///   Returns True when entry is granted; returns False and sets pReason
    ///   when a cycle is detected.
    /// </summary>
    function TryEnterRefResolution(const pResolvedRef: string; out pReason: string): Boolean;
    /// <summary>
    ///   Releases the resolution lock for the given ref URI, allowing it to be
    ///   entered again in future traversals.
    /// </summary>
    procedure LeaveRefResolution(const pResolvedRef: string);
  end;

  /// <summary>
  ///   Exposes the validation result from a visitor or walker without requiring
  ///   a generic type parameter. Used by IWalker to retrieve results.
  /// </summary>
  IResultProvider = interface(IInterface)
    ['{8B4D9C2A-1E5F-4A3B-97D6-0C8E7F2B5A41}']
    function GetValidationResult: IValidationResult;
  end;

implementation

end.
