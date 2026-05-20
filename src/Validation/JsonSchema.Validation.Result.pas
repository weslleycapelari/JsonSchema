unit JsonSchema.Validation.Result;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Types,
  JsonSchema.Interfaces,
  JsonSchema.JsonPathUtils;

type
  /// <summary>
  ///   Collects errors and annotations produced during a single schema validation run.
  ///   Implements IValidationResult with fluent builder methods for error accumulation,
  ///   annotation recording, and evaluated property tracking.
  /// </summary>
  TValidationResult = class(TInterfacedObject, IValidationResult)
  private
    FErrors: TArray<IError>;
    FAnnotations: THashSet<string>;
    FEvaluatedProperties: THashSet<string>;
  public
    constructor Create;
    destructor Destroy; override;

    function Errors: TArray<IError>;
    function AddError(const pError: IError): IValidationResult;
    function AddAnnotation(const pKeyword, pValue: string): IValidationResult;
    function AddEvaluatedProperty(const pProperty: string): IValidationResult;
    function IsValid: Boolean;
    function EvaluatedProperties: TEnumerable<string>;
  end;

  /// <summary>
  ///   Represents a single validation error with full diagnostic context:
  ///   root and parent JSON nodes, schema and instance paths, error type,
  ///   message, and optional custom and standard hints.
  ///   All setters return Self to support fluent builder chains.
  /// </summary>
  TError = class(TInterfacedObject, IError)
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
    function EffectiveHint: string;
  end;

implementation

uses
  System.SysUtils;

{ TValidationResult }

constructor TValidationResult.Create;
begin
  inherited Create;
  FAnnotations := THashSet<string>.Create;
  FEvaluatedProperties := THashSet<string>.Create;
end;

destructor TValidationResult.Destroy;
begin
  FAnnotations.Free;
  FEvaluatedProperties.Free;
  inherited;
end;

function TValidationResult.Errors: TArray<IError>;
begin
  Result := FErrors;
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
    lCanonicalPath := TJsonPathUtils.NormalizeToCanonical(pProperty);
    FEvaluatedProperties.Add(lCanonicalPath);
  end;
end;

function TValidationResult.IsValid: Boolean;
begin
  Result := Length(FErrors) = 0;
end;

function TValidationResult.EvaluatedProperties: TEnumerable<string>;
begin
  Result := FEvaluatedProperties;
end;

{ TError }

function TError.RootNode: TJSONValue;
begin
  Result := FRootNode;
end;

function TError.RootNode(const pValue: TJSONValue): IError;
begin
  Result := Self;
  FRootNode := pValue;
end;

function TError.ErrorType: TErrorType;
begin
  Result := FErrorType;
end;

function TError.ErrorType(const pValue: TErrorType): IError;
begin
  Result := Self;
  FErrorType := pValue;
end;

function TError.ParentNode: TJSONValue;
begin
  Result := FParentNode;
end;

function TError.ParentNode(const pValue: TJSONValue): IError;
begin
  Result := Self;
  FParentNode := pValue;
end;

function TError.CustomHint: string;
begin
  Result := FCustomHint;
end;

function TError.CustomHint(const pValue: string): IError;
begin
  Result := Self;
  FCustomHint := pValue;
end;

function TError.SchemaPath: string;
begin
  Result := FSchemaPath;
end;

function TError.SchemaPath(const pValue: string): IError;
begin
  Result := Self;
  FSchemaPath := pValue;
end;

function TError.SchemaNode: TJSONValue;
begin
  Result := FSchemaNode;
end;

function TError.SchemaNode(const pValue: TJSONValue): IError;
begin
  Result := Self;
  FSchemaNode := pValue;
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

function TError.ErrorMessage: string;
begin
  Result := FErrorMessage;
end;

function TError.ErrorMessage(const pValue: string): IError;
begin
  Result := Self;
  FErrorMessage := pValue;
end;

function TError.StandardHint: string;
begin
  Result := FStandardHint;
end;

function TError.StandardHint(const pValue: string): IError;
begin
  Result := Self;
  FStandardHint := pValue;
end;

function TError.EffectiveHint: string;
begin
  if not FCustomHint.IsEmpty then
    Result := FCustomHint
  else
    Result := FStandardHint;
end;

end.
