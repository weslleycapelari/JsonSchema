unit JsonSchema.Results;

(*
--------------------------------------------------------------------------------
Contains concrete implementations of validation errors and results.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces;

type
  /// <summary>Concrete implementation of IValidationError to manage validation error details.</summary>
  TValidationError = class(TInterfacedObject, IValidationError)
  strict private
    FKeyword: string;
    FMessage: string;
    FResolution: string;
    FContext: TJSONObject;
  private
    function GetKeyword: string;
    function GetMessage: string;
    function GetResolution: string;
    function GetContext: TJSONObject;
    procedure SetMessage(const pMessage: string);
    procedure SetResolution(const pResolution: string);
  public
    /// <summary>Creates a new validation error. Clones the passed context for memory isolation.</summary>
    /// <param name="pKeyword">The keyword name that triggered the error.</param>
    /// <param name="pContext">Technical context containing expected and actual values.</param>
    constructor Create(const pKeyword: string; pContext: TJSONObject = nil);
    destructor Destroy; override;
  end;

  /// <summary>Concrete implementation of IValidationResult consolidating the final validation outcome.</summary>
  TValidationResult = class(TInterfacedObject, IValidationResult)
  strict private
    FIsValid: Boolean;
    FErrors: TArray<IValidationError>;
  private
    function GetIsValid: Boolean;
    function GetErrors: TArray<IValidationError>;
  public
    constructor Create(const pIsValid: Boolean; const pErrors: TArray<IValidationError>);

    /// <summary>Returns a successful validation result with no errors.</summary>
    class function ValidResult: IValidationResult;

    /// <summary>Creates an invalid validation result containing a single error.</summary>
    /// <param name="pKeyword">The keyword name causing the validation failure.</param>
    /// <param name="pContext">Technical details of the failure.</param>
    class function InvalidResult(const pKeyword: string; pContext: TJSONObject = nil): IValidationResult;

    /// <summary>Combines multiple validation results into a single consolidated result.</summary>
    class function Combined(const pResults: TArray<IValidationResult>): IValidationResult;
  end;

implementation

{ TValidationError }

constructor TValidationError.Create(const pKeyword: string; pContext: TJSONObject = nil);
begin
  inherited Create;
  FKeyword := pKeyword;
  FMessage := '';
  FResolution := '';

  // We clone the context to decouple its memory lifecycle from the caller
  if Assigned(pContext) then
    FContext := TJSONObject(pContext.Clone)
  else
    FContext := TJSONObject.Create;
end;

destructor TValidationError.Destroy;
begin
  FContext.Free;
  inherited Destroy;
end;

function TValidationError.GetKeyword: string;
begin
  Result := FKeyword;
end;

function TValidationError.GetMessage: string;
begin
  Result := FMessage;
end;

function TValidationError.GetResolution: string;
begin
  Result := FResolution;
end;

function TValidationError.GetContext: TJSONObject;
begin
  Result := FContext;
end;

procedure TValidationError.SetMessage(const pMessage: string);
begin
  FMessage := pMessage;
end;

procedure TValidationError.SetResolution(const pResolution: string);
begin
  FResolution := pResolution;
end;

{ TValidationResult }

constructor TValidationResult.Create(const pIsValid: Boolean; const pErrors: TArray<IValidationError>);
begin
  inherited Create;
  FIsValid := pIsValid;
  FErrors := pErrors;
end;

function TValidationResult.GetIsValid: Boolean;
begin
  Result := FIsValid;
end;

function TValidationResult.GetErrors: TArray<IValidationError>;
begin
  Result := FErrors;
end;

class function TValidationResult.ValidResult: IValidationResult;
begin
  Result := TValidationResult.Create(True, nil);
end;

class function TValidationResult.InvalidResult(const pKeyword: string; pContext: TJSONObject = nil): IValidationResult;
var
  lError: IValidationError;
begin
  lError := TValidationError.Create(pKeyword, pContext);
  Result := TValidationResult.Create(False, [lError]);
end;

class function TValidationResult.Combined(const pResults: TArray<IValidationResult>): IValidationResult;
var
  lErrors: TArray<IValidationError>;
  lResult: IValidationResult;
  lError: IValidationError;
begin
  lErrors := nil;

  for lResult in pResults do
  begin
    if not lResult.IsValid then
    begin
      for lError in lResult.Errors do
      begin
        SetLength(lErrors, Length(lErrors) + 1);
        lErrors[High(lErrors)] := lError;
      end;
    end;
  end;

  if Length(lErrors) = 0 then
    Result := TValidationResult.ValidResult
  else
    Result := TValidationResult.Create(False, lErrors);
end;

end.
