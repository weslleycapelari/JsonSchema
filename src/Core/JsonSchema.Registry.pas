unit JsonSchema.Registry;

(*
--------------------------------------------------------------------------------
Provides registry and factory instantiation routines for schema keywords.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces;

type
  /// <summary>Factory function delegate used to parse and instantiate schema keywords.</summary>
  TKeywordFactoryFunc = reference to function(const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject;
    const pCompileFunc: TCompileSchemaFunc): IJsonSchemaKeyword;

  /// <summary>Central registry class storing factory functions for validation keywords.</summary>
  TKeywordRegistry = class
  strict private
    FCompileFunc: TCompileSchemaFunc;
    FFactories: TDictionary<string, TKeywordFactoryFunc>;
  public
    constructor Create(const pCompileFunc: TCompileSchemaFunc);
    destructor Destroy; override;

    /// <summary>Registers a keyword and its factory delegate.</summary>
    /// <param name="pKeywordName">Technical name of the keyword (e.g., 'type', 'minLength').</param>
    /// <param name="pFactory">Factory delegate to initialize the keyword validator.</param>
    procedure RegisterKeyword(const pKeywordName: string; pFactory: TKeywordFactoryFunc);

    /// <summary>Instantiates a registered keyword with its parsed value.</summary>
    /// <param name="pKeywordName">Technical name of the keyword.</param>
    /// <param name="pKeywordValue">Parsed JSON value representing the keyword constraints.</param>
    /// <param name="pParentSchema">The parent schema containing the keyword.</param>
    /// <returns>The keyword validator instance, or nil if the keyword is not registered.</returns>
    function CreateKeyword(const pKeywordName: string; const pKeywordValue: TJSONValue;
      const pParentSchema: TJSONObject): IJsonSchemaKeyword;

    /// <summary>Checks whether a keyword is registered in the current context.</summary>
    function IsRegistered(const pKeywordName: string): Boolean;
  end;

implementation

{ TKeywordRegistry }

constructor TKeywordRegistry.Create(const pCompileFunc: TCompileSchemaFunc);
begin
  inherited Create;
  FCompileFunc := pCompileFunc;
  FFactories := TDictionary<string, TKeywordFactoryFunc>.Create;
end;

destructor TKeywordRegistry.Destroy;
begin
  FFactories.Free;
  inherited Destroy;
end;

procedure TKeywordRegistry.RegisterKeyword(const pKeywordName: string; pFactory: TKeywordFactoryFunc);
begin
  FFactories.AddOrSetValue(pKeywordName, pFactory);
end;

function TKeywordRegistry.CreateKeyword(const pKeywordName: string; const pKeywordValue: TJSONValue; const pParentSchema: TJSONObject): IJsonSchemaKeyword;
var
  lFactory: TKeywordFactoryFunc;
begin
  Result := nil;
  if FFactories.TryGetValue(pKeywordName, lFactory) then
  begin
    if Assigned(lFactory) then
      Result := lFactory(pKeywordValue, pParentSchema, FCompileFunc);
  end;
end;

function TKeywordRegistry.IsRegistered(const pKeywordName: string): Boolean;
begin
  Result := FFactories.ContainsKey(pKeywordName);
end;

end.
