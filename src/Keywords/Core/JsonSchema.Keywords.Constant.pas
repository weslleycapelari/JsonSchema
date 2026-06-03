unit JsonSchema.Keywords.Constant;

interface

uses
  System.JSON,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Core.Classes;

type
  /// <summary>Keyword that validates a schema that is a literal (boolean, number, string, null).</summary>
  TConstantKeyword = class(TInterfacedObject, IKeyword)
  private
    FValue: TJSONValue;
  public
    constructor Create(const AValue: TJSONValue);
    destructor Destroy; override;
    /// <summary>Validates the instance against the constant literal.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;
    /// <summary>Keyword is applicable only when the schema node is a literal.</summary>
    function IsApplicable(const pSchemaNode: TJSONValue): Boolean;
  end;

implementation

uses
  JsonSchema.Core.Results;

{ TConstantKeyword }

constructor TConstantKeyword.Create(const AValue: TJSONValue);
begin
  inherited Create;
  // clone to avoid sharing the original JSON value
  FValue := AValue.Clone as TJSONValue;
end;

destructor TConstantKeyword.Destroy;
begin
  FValue.Free;
  inherited;
end;

function TConstantKeyword.IsApplicable(const pSchemaNode: TJSONValue): Boolean;
begin
  // This keyword is used only for literal schemas, so we always return True here.
  // The parser ensures it is only created for nonâ€'object schemas.
  Result := True;
end;

function TConstantKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  // Comparison follows the same semantics used throughout the project (JsonHelper.IsSame)
  if (pInstance <> nil) and (pInstance.ClassType = FValue.ClassType) then
  begin
    if pInstance is TJSONBool then
      Result := TValidationResult.Create((pInstance as TJSONBool).AsBoolean =
        (FValue as TJSONBool).AsBoolean)
    else if pInstance is TJSONNumber then
      Result := TValidationResult.Create((pInstance as TJSONNumber).AsDouble =
        (FValue as TJSONNumber).AsDouble)
    else
      Result := TValidationResult.Create(pInstance.ToString = FValue.ToString);
  end
  else
    Result := TValidationResult.Create(False);
end;

end.
