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
  TValidationResult = class(TInterfacedPersistent, IValidationResult)
  private
    FErrors: TArray<IError>;
    FAnnotations: THashSet<string>;
    FEvaluatedProperties: THashSet<string>;
  public
    constructor Create;
    destructor Destroy; override;
    function Errors: TArray<IError>;
    function AddError(const AError: IError): IValidationResult;
    function AddAnnotation(const AKeyword, AValue: string): IValidationResult;
    function AddEvaluatedProperty(const AProperty: string): IValidationResult;
    function IsValid: Boolean;
    function EvaluatedProperties: TEnumerable<string>;
  end;

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

implementation

uses
  System.SysUtils,
  System.StrUtils;

function NormalizeEvaluatedPath(const APath: string): string;
begin
  Result := Trim(APath);

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

function TValidationResult.AddError(const AError: IError): IValidationResult;
begin
  Result := Self;
  SetLength(FErrors, Length(FErrors) + 1);
  FErrors[Length(FErrors) - 1] := AError;
end;

function TValidationResult.AddAnnotation(const AKeyword, AValue: string): IValidationResult;
begin
  Result := Self;
  if not AKeyword.IsEmpty then
    FAnnotations.Add(AKeyword + #0 + AValue);
end;

function TValidationResult.AddEvaluatedProperty(const AProperty: string): IValidationResult;
var
  LCanonicalPath: string;
begin
  Result := Self;
  if not AProperty.IsEmpty then
  begin
    LCanonicalPath := NormalizeEvaluatedPath(AProperty);
    FEvaluatedProperties.Add(LCanonicalPath);
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

function TError.CustomHint(const AValue: string): IError;
begin
  Result := Self;
  FCustomHint := AValue;
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

function TError.ErrorMessage(const AValue: string): IError;
begin
  Result := Self;
  FErrorMessage := AValue;
end;

function TError.ErrorType(const AValue: TErrorType): IError;
begin
  Result := Self;
  FErrorType := AValue;
end;

function TError.ErrorType: TErrorType;
begin
  Result := FErrorType;
end;

function TError.InstanceNode: TJSONValue;
begin
  Result := FInstanceNode;
end;

function TError.InstanceNode(const AValue: TJSONValue): IError;
begin
  Result := Self;
  FInstanceNode := AValue;
end;

function TError.InstancePath: string;
begin
  Result := FInstancePath;
end;

function TError.InstancePath(const AValue: string): IError;
begin
  Result := Self;
  FInstancePath := AValue;
end;

function TError.ParentNode(const AValue: TJSONValue): IError;
begin
  Result := Self;
  FParentNode := AValue;
end;

function TError.RootNode(const AValue: TJSONValue): IError;
begin
  Result := Self;
  FRootNode := AValue;
end;

function TError.RootNode: TJSONValue;
begin
  Result := FRootNode;
end;

function TError.ParentNode: TJSONValue;
begin
  Result := FParentNode;
end;

function TError.SchemaNode(const AValue: TJSONValue): IError;
begin
  Result := Self;
  FSchemaNode := AValue;
end;

function TError.SchemaNode: TJSONValue;
begin
  Result := FSchemaNode;
end;

function TError.SchemaPath(const AValue: string): IError;
begin
  Result := Self;
  FSchemaPath := AValue;
end;

function TError.SchemaPath: string;
begin
  Result := FSchemaPath;
end;

function TError.StandardHint(const AValue: string): IError;
begin
  Result := Self;
  FStandardHint := AValue;
end;

function TError.StandardHint: string;
begin
  Result := FStandardHint;
end;

end.
