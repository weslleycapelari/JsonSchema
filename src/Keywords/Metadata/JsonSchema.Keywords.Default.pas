unit JsonSchema.Keywords.Default;

(*
--------------------------------------------------------------------------------
Implements the 'default' metadata keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results;

type
  /// <summary>Stores the 'default' value metadata.</summary>
  TDefaultKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FDefaultValue: TJSONValue;
    function GetKeywordName: string;
  public
    /// <summary>Initializes default keyword with target default value.</summary>
    constructor Create(const pDefaultValue: TJSONValue);
    destructor Destroy; override;

    /// <summary>Always returns valid, as 'default' acts as metadata rather than an instance constraint.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a default keyword from a JSON value.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
      const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Technical name of the keyword validator ('default').</summary>
    property KeywordName: string read GetKeywordName;

    /// <summary>Default JSON value.</summary>
    property DefaultValue: TJSONValue read FDefaultValue;
  end;

implementation

{ TDefaultKeyword }

constructor TDefaultKeyword.Create(const pDefaultValue: TJSONValue);
begin
  inherited Create;
  if Assigned(pDefaultValue) then
    FDefaultValue := pDefaultValue.Clone as TJSONValue
  else
    FDefaultValue := nil;
end;

destructor TDefaultKeyword.Destroy;
begin
  FDefaultValue.Free;
  inherited Destroy;
end;

class function TDefaultKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
  const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
begin
  Result := TDefaultKeyword.Create(pKeywordValue);
end;

function TDefaultKeyword.GetKeywordName: string;
begin
  Result := KEYWORD_DEFAULT;
end;

function TDefaultKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.ValidResult;
end;

end.
