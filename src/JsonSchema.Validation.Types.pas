unit JsonSchema.Validation.Types;

interface

uses
  System.JSON,
  System.Classes,
  System.Generics.Collections,
  JsonSchema.Translate.Types,
  JsonSchema.Visitors.Base,
  JsonSchema.Validation.Interfaces;

type
  /// <summary>
  /// Collects errors and annotations produced during a single schema validation
  /// run. Implements IValidationResult with fluent builder methods for error
  /// accumulation, annotation recording, and evaluated property tracking.
  /// </summary>
  TValidationResult = class(TInterfacedPersistent, IValidationResult)
  private
    FErrors: TArray<IError>;
    FAnnotations: THashSet<string>;
    FEvaluatedProperties: THashSet<string>;
  public
    constructor Create;
    destructor Destroy; override;
    function Errors: TArray<IError>;
    /// <summary>
    /// Appends an error to the error list and returns Self for fluent chaining.
    /// </summary>
    function AddError(const pError: IError): IValidationResult;
    /// <summary>
    /// Records a keyword/value annotation pair and returns Self for fluent chaining.
    /// Has no effect when pKeyword is empty.
    /// </summary>
    function AddAnnotation(const pKeyword, pValue: string): IValidationResult;
    /// <summary>
    /// Normalizes and records a property path as evaluated, then returns Self
    /// for fluent chaining. Has no effect when pProperty is empty.
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
  TError = class sealed(TInterfacedPersistent, IError)
  private
    FRootNode: TJSONValue;
    FErrorType: TErrorType;
    FParentNode: TJSONValue;
    FCustomHint: string;
    FSchemaNode: TJSONValue;
    FSchemaPath: string;
    FInstanceNode: TJSONValue;
    FInstancePath: string;
    FErrorMessage: string;
    FStandardHint: string;
  public
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

implementation

uses
  System.SysUtils,
  System.StrUtils;

function NormalizeEvaluatedPath(const pPath: string): string;
begin
  Result := Trim(pPath);

  if Result.IsEmpty or (Result = '#') then
    Exit('/');

  if Result.StartsWith('##') then
    Result := Result.Substring(1);

  if Result.StartsWith('#/') then
    Result := Result.Substring(1)
  else if Result.StartsWith('#.') then
    Result := '/' + StringReplace(Result.Substring(2), '.', '/', [rfReplaceAll])
  else if Result.StartsWith('.') then
    Result := '/' + StringReplace(Result.Substring(1), '.', '/', [rfReplaceAll])
  else if Result.StartsWith('#') then
    Result := '/' + Result.Substring(1)
  else if not Result.StartsWith('/') then
    Result := '/' + Result;

  while Pos('//', Result) > 0 do
    Result := StringReplace(Result, '//', '/', [rfReplaceAll]);

  if Result.EndsWith('/') and (Result <> '/') then
    Delete(Result, Length(Result), 1);
end;

{ TValidationResult }

constructor TValidationResult.Create;
begin
  inherited;
  FAnnotations := THashSet<string>.Create;
  FEvaluatedProperties := THashSet<string>.Create;
end;

destructor TValidationResult.Destroy;
begin
  FAnnotations.Free;
  FEvaluatedProperties.Free;
  inherited;
end;

function TValidationResult.AddError(const pError: IError): IValidationResult;
begin
  Result := Self;
  SetLength(FErrors, Length(FErrors) + 1);
  FErrors[Length(FErrors) - 1] := pError;
end;

function TValidationResult.AddAnnotation(const pKeyword, pValue: string): IValidationResult;
begin
  Result := Self;
  if not pKeyword.IsEmpty then
    FAnnotations.Add(pKeyword + #0 + pValue);
end;

function TValidationResult.AddEvaluatedProperty(const pProperty: string): IValidationResult;
var
  lCanonicalPath: string;
begin
  Result := Self;
  if not pProperty.IsEmpty then
  begin
    lCanonicalPath := NormalizeEvaluatedPath(pProperty);
    FEvaluatedProperties.Add(lCanonicalPath);
  end;
end;

function TValidationResult.EvaluatedProperties: TEnumerable<string>;
begin
  Result := FEvaluatedProperties;
end;

function TValidationResult.Errors: TArray<IError>;
begin
  Result := FErrors;
end;

function TValidationResult.IsValid: Boolean;
begin
  Result := Length(FErrors) = 0;
end;

{ TError }

function TError.CustomHint(const pValue: string): IError;
begin
  Result := Self;
  FCustomHint := pValue;
end;

function TError.CustomHint: string;
begin
  Result := FCustomHint;
end;

function TError.EffectiveHint: string;
begin
  if not FCustomHint.IsEmpty then
    Result := FCustomHint
  else
    Result := FStandardHint;
end;

function TError.ErrorMessage: string;
begin
  Result := FErrorMessage
end;

function TError.ErrorMessage(const pValue: string): IError;
begin
  Result := Self;
  FErrorMessage := pValue;
end;

function TError.ErrorType(const pValue: TErrorType): IError;
begin
  Result := Self;
  FErrorType := pValue;
end;

function TError.ErrorType: TErrorType;
begin
  Result := FErrorType;
end;

function TError.InstanceNode: TJSONValue;
begin
  Result := FInstanceNode;
end;

function TError.InstanceNode(const pValue: TJSONValue): IError;
begin
  Result := Self;
  FInstanceNode := pValue;
end;

function TError.InstancePath: string;
begin
  Result := FInstancePath;
end;

function TError.InstancePath(const pValue: string): IError;
begin
  Result := Self;
  FInstancePath := pValue;
end;

function TError.ParentNode(const pValue: TJSONValue): IError;
begin
  Result := Self;
  FParentNode := pValue;
end;

function TError.RootNode(const pValue: TJSONValue): IError;
begin
  Result := Self;
  FRootNode := pValue;
end;

function TError.RootNode: TJSONValue;
begin
  Result := FRootNode;
end;

function TError.ParentNode: TJSONValue;
begin
  Result := FParentNode;
end;

function TError.SchemaNode(const pValue: TJSONValue): IError;
begin
  Result := Self;
  FSchemaNode := pValue;
end;

function TError.SchemaNode: TJSONValue;
begin
  Result := FSchemaNode;
end;

function TError.SchemaPath(const pValue: string): IError;
begin
  Result := Self;
  FSchemaPath := pValue;
end;

function TError.SchemaPath: string;
begin
  Result := FSchemaPath;
end;

function TError.StandardHint(const pValue: string): IError;
begin
  Result := Self;
  FStandardHint := pValue;
end;

function TError.StandardHint: string;
begin
  Result := FStandardHint;
end;

end.
