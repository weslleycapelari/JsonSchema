unit JsonSchema.Validation.RefResolver;

interface

uses
  System.JSON,
  JsonSchema.Types,
  JsonSchema.Interfaces,
  JsonSchema.Registry.Base,
  JsonSchema.Registry.Uri,
  JsonSchema.Visitors.Types;

type
  TRefResolutionResult = record
    Success: Boolean;
    TargetSchema: TJSONValue;
    ResolvedBaseURI: string;
    ErrorMessage: string;
  end;

  TRefResolver = class
  public
    constructor Create(const pValidationVisitor: IInterface;
      const pRegistry: TObject; const pRefGuard: IRefResolutionGuard);
    destructor Destroy; override;

    function Resolve(const pRefString: string; const pCurrentBaseURI: string;
      out pResult: TRefResolutionResult): Boolean;
  end;

implementation

{ TRefResolver }

constructor TRefResolver.Create(const pValidationVisitor: IInterface;
  const pRegistry: TObject; const pRefGuard: IRefResolutionGuard);
begin
  inherited Create;
end;

destructor TRefResolver.Destroy;
begin
  inherited;
end;

function TRefResolver.Resolve(const pRefString, pCurrentBaseURI: string;
  out pResult: TRefResolutionResult): Boolean;
begin
  pResult.Success := False;
  pResult.TargetSchema := nil;
  pResult.ErrorMessage := 'Not implemented';
  Result := False;
end;

end.
