unit JsonSchema.Validation.ErrorHandler;

interface

uses
  System.SysUtils,
  System.JSON,
  JsonSchema.Types,
  JsonSchema.Interfaces,
  JsonSchema.Translate.Interfaces,
  JsonSchema.Visitors.Types;

type
  /// <summary>
  ///   Responsible for creating and recording validation errors.
  ///   Handles error message translation, custom hints, and parent node resolution.
  ///   Separated from the main validation visitor to respect Single Responsibility Principle.
  /// </summary>
  TValidationErrorHandler = class
  private
    FResult: IValidationResult;
    FTranslation: ITranslate;
    FCustomHint: TJSONValue;
    FCurrentScopeProvider: TFunc<TScope>;
    FDataRootNode: TJSONValue;

    function GetParentNode(const pCurrentScope: TScope): TJSONValue;
    function FindCustomHint(const pErrorType: TErrorType; const pScope: TScope): string;
    function TraverseCustomHintPath(const pRoot: TJSONValue; const pPathSegments: TArray<string>): TJSONValue;
    function ExtractKeywordHint(const pNode: TJSONValue; const pErrorType: TErrorType): string;
  public
    constructor Create(const pResult: IValidationResult; const pTranslation: ITranslate;
      const pCustomHint: TJSONValue; const pCurrentScopeProvider: TFunc<TScope>;
      const pDataRootNode: TJSONValue);
    destructor Destroy; override;

    /// <summary>Creates and records an error with parameters.</summary>
    procedure AddError(const pErrorType: TErrorType; const pParams: array of const); overload;

    /// <summary>Creates and records an error without parameters.</summary>
    procedure AddError(const pErrorType: TErrorType); overload;

    /// <summary>Changes the translation provider (e.g., when language changes).</summary>
    procedure SetTranslation(const pTranslation: ITranslate);
  end;

implementation

uses
  System.TypInfo,
  JsonSchema.Common.Utils,
  JsonSchema.JsonPathUtils,
  JsonSchema.Validation.Result;

{ TValidationErrorHandler }

constructor TValidationErrorHandler.Create(const pResult: IValidationResult;
  const pTranslation: ITranslate; const pCustomHint: TJSONValue;
  const pCurrentScopeProvider: TFunc<TScope>; const pDataRootNode: TJSONValue);
begin
  inherited Create;
  FResult := pResult;
  FTranslation := pTranslation;
  FCustomHint := pCustomHint;
  FCurrentScopeProvider := pCurrentScopeProvider;
  FDataRootNode := pDataRootNode;
end;

destructor TValidationErrorHandler.Destroy;
begin
  // No owned objects
  inherited;
end;

procedure TValidationErrorHandler.SetTranslation(const pTranslation: ITranslate);
begin
  FTranslation := pTranslation;
end;

function TValidationErrorHandler.GetParentNode(const pCurrentScope: TScope): TJSONValue;
begin
  // Try to get parent node from scope stack (depth 2)
  // Implementation depends on how scope provider works; simplified here:
  // In practice, the provider should give access to parent scopes.
  // For now, return the instance node of current scope as fallback.
  Result := pCurrentScope.InstanceNode;
  // This would need proper scope stack access. In actual implementation,
  // the provider could return a function that receives an offset.
end;

function TValidationErrorHandler.TraverseCustomHintPath(const pRoot: TJSONValue;
  const pPathSegments: TArray<string>): TJSONValue;
var
  lSegment: string;
  lNext: TJSONValue;
  lObj: TJSONObject;
begin
  Result := pRoot;
  for lSegment in pPathSegments do
  begin
    if not (Result is TJSONObject) then
      Exit(nil);

    lObj := Result as TJSONObject;
    if lObj.TryGetValue(lSegment, lNext) then
      Result := lNext
    else if lObj.TryGetValue(GetEnumName(TypeInfo(TErrorType), Ord(TErrorType.vetUnknown)), lNext) then
    begin
      Result := lNext;
      Break;
    end
    else
      Exit(nil);
  end;
end;

function TValidationErrorHandler.ExtractKeywordHint(const pNode: TJSONValue;
  const pErrorType: TErrorType): string;
var
  lErrorKeyword: string;
  lHintValue: TJSONValue;
begin
  Result := '';
  if pNode is TJSONObject then
  begin
    lErrorKeyword := GetEnumName(TypeInfo(TErrorType), Ord(pErrorType));
    if TJSONObject(pNode).TryGetValue(lErrorKeyword, lHintValue) and (lHintValue is TJSONString) then
      Result := TJSONString(lHintValue).Value;
  end
  else if pNode is TJSONString then
    Result := TJSONString(pNode).Value;
end;

function TValidationErrorHandler.FindCustomHint(const pErrorType: TErrorType;
  const pScope: TScope): string;
var
  lPathSegments: TArray<string>;
  lTargetNode: TJSONValue;
begin
  Result := '';
  if not Assigned(FCustomHint) or pScope.InstancePath.IsEmpty then
    Exit;

  lPathSegments := TUtils.ParseInstancePath(pScope.InstancePath);
  lTargetNode := TraverseCustomHintPath(FCustomHint, lPathSegments);
  if not Assigned(lTargetNode) then
    Exit;

  Result := ExtractKeywordHint(lTargetNode, pErrorType);
end;

procedure TValidationErrorHandler.AddError(const pErrorType: TErrorType; const pParams: array of const);
var
  lScope: TScope;
  lMessage: TErrorMessage;
  lCustomHint: string;
  lParentNode: TJSONValue;
begin
  lScope := FCurrentScopeProvider();
  lMessage := FTranslation.GetMessage(pErrorType);
  lCustomHint := FindCustomHint(pErrorType, lScope);
  lParentNode := GetParentNode(lScope);

  FResult.AddError(
    TError.Create
      .RootNode(FDataRootNode)
      .ErrorType(pErrorType)
      .ParentNode(lParentNode)
      .SchemaNode(lScope.SchemaNode)
      .SchemaPath(lScope.SchemaPath)
      .InstanceNode(lScope.InstanceNode)
      .InstancePath(lScope.InstancePath)
      .ErrorMessage(Format(lMessage.Error, pParams))
      .StandardHint(Format(lMessage.Hint, pParams))
      .CustomHint(lCustomHint)
  );
end;

procedure TValidationErrorHandler.AddError(const pErrorType: TErrorType);
begin
  AddError(pErrorType, []);
end;

end.
