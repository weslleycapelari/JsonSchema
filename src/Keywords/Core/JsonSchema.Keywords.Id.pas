unit JsonSchema.Keywords.Id;

(*
--------------------------------------------------------------------------------
Implements the '$id' and legacy 'id' core keywords, updating the URI base context.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Core.SchemaRegistry,
  JsonSchema.Results;

type
  /// <summary>Implements the validation rule/context registration for $id and id keywords.</summary>
  TIdKeyword = class(TInterfacedObject, IJsonSchemaKeyword)
  strict private
    FKeywordName: string;
    FIdValue: string;
    function GetKeywordName: string;
  public
    constructor Create(const pKeywordName, pIdValue: string);

    /// <summary>No-op validation. $id properties do not affect validation of instances.</summary>
    function Validate(const pInstance: TJSONValue): IValidationResult;

    /// <summary>Creates a standard '$id' keyword validator and registers schema URI.</summary>
    class function CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject; const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Creates a legacy 'id' keyword validator.</summary>
    class function CreateLegacyKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject; const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword; static;

    /// <summary>Combines base and relative URIs following standard reference routing.</summary>
    class function CombineURI(const pBase, pRelative: string): string; static;

    /// <summary>Technical name of the keyword validator ('$id' or 'id').</summary>
    property KeywordName: string read GetKeywordName;
  end;

implementation

{ TIdKeyword }

constructor TIdKeyword.Create(const pKeywordName, pIdValue: string);
begin
  inherited Create;
  FKeywordName := pKeywordName;
  FIdValue := pIdValue;
end;

class function TIdKeyword.CombineURI(const pBase, pRelative: string): string;
begin
  Result := TSchemaRegistry.CombineURI(pBase, pRelative);
end;

class function TIdKeyword.CreateKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject; const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
var
  lIdStr: string;
  lAbsoluteURI: string;
begin
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
  begin
    lIdStr := pKeywordValue.Value;
    // Combine with current base URI
    lAbsoluteURI := CombineURI(TSchemaRegistry.CurrentBaseURI, lIdStr);
    
    // Register the parent schema in the global schema registry under this URI
    TSchemaRegistry.RegisterSchema(lAbsoluteURI, pParentSchema);
    
    // Update the base URI context for nested compile calls
    TSchemaRegistry.CurrentBaseURI := lAbsoluteURI;

    Result := TIdKeyword.Create(KEYWORD_ID, lIdStr);
  end else
    Result := TIdKeyword.Create(KEYWORD_ID, '');
end;

class function TIdKeyword.CreateLegacyKeyword(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject; const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;
var
  lIdStr: string;
  lAbsoluteURI: string;
begin
  // Legacy 'id' used in Draft 6/7
  if Assigned(pKeywordValue) and (pKeywordValue is TJSONString) then
  begin
    lIdStr := pKeywordValue.Value;
    if not lIdStr.StartsWith('#') then
    begin
      lAbsoluteURI := CombineURI(TSchemaRegistry.CurrentBaseURI, lIdStr);
      TSchemaRegistry.RegisterSchema(lAbsoluteURI, pParentSchema);
      TSchemaRegistry.CurrentBaseURI := lAbsoluteURI;
    end;
    Result := TIdKeyword.Create(KEYWORD_ID_LEGACY, lIdStr);
  end else
    Result := TIdKeyword.Create(KEYWORD_ID_LEGACY, '');
end;

function TIdKeyword.GetKeywordName: string;
begin
  Result := FKeywordName;
end;

function TIdKeyword.Validate(const pInstance: TJSONValue): IValidationResult;
begin
  Result := TValidationResult.ValidResult;
end;

end.
