unit SchemaLinter.Engine;

(*
--------------------------------------------------------------------------------
Static analysis engine for JSON Schemas. Validates constraints, identifies
security issues (ReDoS), deprecated keywords, and missing documentation.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections;

{$SCOPEDENUMS ON}
type
  /// <summary>The severity level of a lint finding.</summary>
  TSeverity = (Info, Warning, Error);
{$SCOPEDENUMS OFF}

  /// <summary>Represents a single finding detected during static analysis.</summary>
  TLintFinding = record
    RuleId: string;
    Severity: TSeverity;
    Path: string;
    Message: string;
  end;

  /// <summary>Core linter engine that parses JSON Schema recursively to find issues.</summary>
  TSchemaLinter = class
  private
    FFindings: TList<TLintFinding>;
    FMinSeverity: TSeverity;

    procedure AddFinding(const pRuleId: string; pSeverity: TSeverity; const pPath, pMessage: string);
    procedure AnalyzeNode(pNode: TJSONValue; const pPath: string);
    procedure CheckLimits(pObj: TJSONObject; const pPath: string);
    procedure CheckRequiredFields(pObj: TJSONObject; const pPath: string);
    procedure CheckRegexReDoS(pObj: TJSONObject; const pPath: string);
    procedure CheckLegacyKeywords(pObj: TJSONObject; const pPath: string);
    procedure CheckDocumentation(pObj: TJSONObject; const pPath: string);
    function IsReDoSPattern(const pPattern: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Analyzes the given JSON Schema and returns an array of lint findings.</summary>
    function Analyze(pSchema: TJSONObject): TArray<TLintFinding>;

    property MinSeverity: TSeverity read FMinSeverity write FMinSeverity;
  end;

implementation

{ TSchemaLinter }

constructor TSchemaLinter.Create;
begin
  inherited Create;
  FFindings := TList<TLintFinding>.Create;
  FMinSeverity := TSeverity.Info;
end;

destructor TSchemaLinter.Destroy;
begin
  FFindings.Free;
  inherited Destroy;
end;

procedure TSchemaLinter.AddFinding(const pRuleId: string; pSeverity: TSeverity; const pPath, pMessage: string);
var
  lFinding: TLintFinding;
begin
  if Ord(pSeverity) >= Ord(FMinSeverity) then
  begin
    lFinding.RuleId := pRuleId;
    lFinding.Severity := pSeverity;
    lFinding.Path := pPath;
    lFinding.Message := pMessage;
    FFindings.Add(lFinding);
  end;
end;

function TSchemaLinter.Analyze(pSchema: TJSONObject): TArray<TLintFinding>;
begin
  FFindings.Clear;
  if Assigned(pSchema) then
  begin
    AnalyzeNode(pSchema, '/');
  end;
  Result := FFindings.ToArray;
end;

procedure TSchemaLinter.AnalyzeNode(pNode: TJSONValue; const pPath: string);
var
  lObj: TJSONObject;
  lPair: TJSONPair;
  lPairChild: TJSONPair;
  lArr: TJSONArray;
  lI: Integer;
begin
  if not Assigned(pNode) then
    Exit;

  if pNode is TJSONObject then
  begin
    lObj := TJSONObject(pNode);

    CheckLimits(lObj, pPath);
    CheckRequiredFields(lObj, pPath);
    CheckRegexReDoS(lObj, pPath);
    CheckLegacyKeywords(lObj, pPath);
    CheckDocumentation(lObj, pPath);

    for lPair in lObj do
    begin
      if lPair.JsonString.Value = 'properties' then
      begin
        if lPair.JsonValue is TJSONObject then
        begin
          for lPairChild in TJSONObject(lPair.JsonValue) do
            AnalyzeNode(lPairChild.JsonValue, pPath + 'properties/' + lPairChild.JsonString.Value);
        end;
      end
      else if lPair.JsonString.Value = 'patternProperties' then
      begin
        if lPair.JsonValue is TJSONObject then
        begin
          for lPairChild in TJSONObject(lPair.JsonValue) do
            AnalyzeNode(lPairChild.JsonValue, pPath + 'patternProperties/' + lPairChild.JsonString.Value);
        end;
      end
      else if (lPair.JsonString.Value = 'additionalProperties') or
              (lPair.JsonString.Value = 'unevaluatedProperties') or
              (lPair.JsonString.Value = 'propertyNames') or
              (lPair.JsonString.Value = 'not') or
              (lPair.JsonString.Value = 'if') or
              (lPair.JsonString.Value = 'then') or
              (lPair.JsonString.Value = 'else') then
      begin
        AnalyzeNode(lPair.JsonValue, pPath + lPair.JsonString.Value);
      end
      else if lPair.JsonString.Value = 'items' then
      begin
        if lPair.JsonValue is TJSONArray then
        begin
          lArr := TJSONArray(lPair.JsonValue);
          for lI := 0 to lArr.Count - 1 do
            AnalyzeNode(lArr.Items[lI], pPath + 'items/' + IntToStr(lI));
        end else
        begin
          AnalyzeNode(lPair.JsonValue, pPath + 'items');
        end;
      end
      else if lPair.JsonString.Value = 'prefixItems' then
      begin
        if lPair.JsonValue is TJSONArray then
        begin
          lArr := TJSONArray(lPair.JsonValue);
          for lI := 0 to lArr.Count - 1 do
            AnalyzeNode(lArr.Items[lI], pPath + 'prefixItems/' + IntToStr(lI));
        end;
      end
      else if (lPair.JsonString.Value = 'allOf') or
              (lPair.JsonString.Value = 'anyOf') or
              (lPair.JsonString.Value = 'oneOf') then
      begin
        if lPair.JsonValue is TJSONArray then
        begin
          lArr := TJSONArray(lPair.JsonValue);
          for lI := 0 to lArr.Count - 1 do
            AnalyzeNode(lArr.Items[lI], pPath + lPair.JsonString.Value + '/' + IntToStr(lI));
        end;
      end
      else if (lPair.JsonString.Value = 'definitions') or (lPair.JsonString.Value = '$defs') then
      begin
        if lPair.JsonValue is TJSONObject then
        begin
          for lPairChild in TJSONObject(lPair.JsonValue) do
            AnalyzeNode(lPairChild.JsonValue, pPath + lPair.JsonString.Value + '/' + lPairChild.JsonString.Value);
        end;
      end;
    end;
  end;
end;

procedure TSchemaLinter.CheckLimits(pObj: TJSONObject; const pPath: string);
var
  lMin, lMax: TJSONValue;
  lMinVal, lMaxVal: Double;
  lMinLen, lMaxLen: TJSONValue;
  lMinLenVal, lMaxLenVal: Integer;
  lMinItems, lMaxItems: TJSONValue;
  lMinItemsVal, lMaxItemsVal: Integer;
  lMinProps, lMaxProps: TJSONValue;
  lMinPropsVal, lMaxPropsVal: Integer;
begin
  lMin := pObj.Values['minimum'];
  if not Assigned(lMin) then
    lMin := pObj.Values['exclusiveMinimum'];
  lMax := pObj.Values['maximum'];
  if not Assigned(lMax) then
    lMax := pObj.Values['exclusiveMaximum'];

  if Assigned(lMin) and Assigned(lMax) and (lMin is TJSONNumber) and (lMax is TJSONNumber) then
  begin
    lMinVal := TJSONNumber(lMin).AsDouble;
    lMaxVal := TJSONNumber(lMax).AsDouble;
    if lMinVal > lMaxVal then
      AddFinding('LINT_MIN_MAX_CONFLICT', TSeverity.Error, pPath, 'The minimum/exclusiveMinimum limit is greater than maximum/exclusiveMaximum.');
  end;

  lMinLen := pObj.Values['minLength'];
  lMaxLen := pObj.Values['maxLength'];
  if Assigned(lMinLen) and Assigned(lMaxLen) and (lMinLen is TJSONNumber) and (lMaxLen is TJSONNumber) then
  begin
    lMinLenVal := TJSONNumber(lMinLen).AsInt;
    lMaxLenVal := TJSONNumber(lMaxLen).AsInt;
    if lMinLenVal > lMaxLenVal then
      AddFinding('LINT_LENGTH_CONFLICT', TSeverity.Error, pPath, 'minLength is greater than maxLength.');
  end;

  lMinItems := pObj.Values['minItems'];
  lMaxItems := pObj.Values['maxItems'];
  if Assigned(lMinItems) and Assigned(lMaxItems) and (lMinItems is TJSONNumber) and (lMaxItems is TJSONNumber) then
  begin
    lMinItemsVal := TJSONNumber(lMinItems).AsInt;
    lMaxItemsVal := TJSONNumber(lMaxItems).AsInt;
    if lMinItemsVal > lMaxItemsVal then
      AddFinding('LINT_ITEMS_CONFLICT', TSeverity.Error, pPath, 'minItems is greater than maxItems.');
  end;

  lMinProps := pObj.Values['minProperties'];
  lMaxProps := pObj.Values['maxProperties'];
  if Assigned(lMinProps) and Assigned(lMaxProps) and (lMinProps is TJSONNumber) and (lMaxProps is TJSONNumber) then
  begin
    lMinPropsVal := TJSONNumber(lMinProps).AsInt;
    lMaxPropsVal := TJSONNumber(lMaxProps).AsInt;
    if lMinPropsVal > lMaxPropsVal then
      AddFinding('LINT_PROPS_CONFLICT', TSeverity.Error, pPath, 'minProperties is greater than maxProperties.');
  end;
end;

procedure TSchemaLinter.CheckRequiredFields(pObj: TJSONObject; const pPath: string);
var
  lRequired: TJSONValue;
  lProperties: TJSONValue;
  lRequiredArr: TJSONArray;
  lPropertiesObj: TJSONObject;
  lI: Integer;
  lRequiredName: string;
begin
  lRequired := pObj.Values['required'];
  if Assigned(lRequired) and (lRequired is TJSONArray) then
  begin
    lRequiredArr := TJSONArray(lRequired);
    lProperties := pObj.Values['properties'];
    if Assigned(lProperties) and (lProperties is TJSONObject) then
      lPropertiesObj := TJSONObject(lProperties)
    else
      lPropertiesObj := nil;

    for lI := 0 to lRequiredArr.Count - 1 do
    begin
      lRequiredName := lRequiredArr.Items[lI].Value;
      if Assigned(lPropertiesObj) then
      begin
        if not Assigned(lPropertiesObj.Values[lRequiredName]) then
          AddFinding('LINT_REQUIRED_MISSING', TSeverity.Error, pPath, Format('Required property "%s" is not declared under "properties".', [lRequiredName]));
      end else
      begin
        AddFinding('LINT_REQUIRED_MISSING', TSeverity.Error, pPath, Format('Required property "%s" is listed, but there is no "properties" block.', [lRequiredName]));
      end;
    end;
  end;
end;

procedure TSchemaLinter.CheckRegexReDoS(pObj: TJSONObject; const pPath: string);
var
  lPattern: TJSONValue;
  lPatternProps: TJSONValue;
  lPair: TJSONPair;
begin
  lPattern := pObj.Values['pattern'];
  if Assigned(lPattern) and (lPattern is TJSONString) then
  begin
    if IsReDoSPattern(lPattern.Value) then
      AddFinding('LINT_REGEX_REDOS', TSeverity.Warning, pPath + 'pattern', 'Pattern regular expression contains nested quantifiers, making it vulnerable to ReDoS.');
  end;

  lPatternProps := pObj.Values['patternProperties'];
  if Assigned(lPatternProps) and (lPatternProps is TJSONObject) then
  begin
    for lPair in TJSONObject(lPatternProps) do
    begin
      if IsReDoSPattern(lPair.JsonString.Value) then
        AddFinding('LINT_REGEX_REDOS', TSeverity.Warning, pPath + 'patternProperties/' + lPair.JsonString.Value, 'Pattern regex in patternProperties key contains nested quantifiers, making it vulnerable to ReDoS.');
    end;
  end;
end;

procedure TSchemaLinter.CheckLegacyKeywords(pObj: TJSONObject; const pPath: string);
var
  lDefs: TJSONValue;
  lDeps: TJSONValue;
begin
  lDefs := pObj.Values['definitions'];
  if Assigned(lDefs) then
    AddFinding('LINT_DEPRECATED_KEYWORD', TSeverity.Info, pPath, 'Keyword "definitions" is deprecated in favor of "$defs" since Draft 2019-09.');

  lDeps := pObj.Values['dependencies'];
  if Assigned(lDeps) then
    AddFinding('LINT_DEPRECATED_KEYWORD', TSeverity.Info, pPath, 'Keyword "dependencies" is deprecated in favor of "dependentRequired" and "dependentSchemas" since Draft 2019-09.');
end;

procedure TSchemaLinter.CheckDocumentation(pObj: TJSONObject; const pPath: string);
var
  lTitle: TJSONValue;
  lDesc: TJSONValue;
  lProperties: TJSONValue;
  lPair: TJSONPair;
  lTypeVal: TJSONValue;
  lTypeStr: string;
begin
  if pPath = '/' then
  begin
    lTitle := pObj.Values['title'];
    if not Assigned(lTitle) or (lTitle.Value = '') then
      AddFinding('LINT_MISSING_TITLE', TSeverity.Info, pPath, 'Root schema is missing "title" metadata.');
  end;

  lProperties := pObj.Values['properties'];
  if Assigned(lProperties) and (lProperties is TJSONObject) then
  begin
    for lPair in TJSONObject(lProperties) do
    begin
      if lPair.JsonValue is TJSONObject then
      begin
        lDesc := TJSONObject(lPair.JsonValue).Values['description'];
        if not Assigned(lDesc) or (lDesc.Value = '') then
        begin
          lTypeVal := TJSONObject(lPair.JsonValue).Values['type'];
          if Assigned(lTypeVal) then
            lTypeStr := lTypeVal.Value
          else
            lTypeStr := 'unknown';

          AddFinding('LINT_MISSING_DESC', TSeverity.Info, pPath + 'properties/' + lPair.JsonString.Value, Format('Property "%s" (type: %s) is missing a description.', [lPair.JsonString.Value, lTypeStr]));
        end;
      end;
    end;
  end;
end;

function TSchemaLinter.IsReDoSPattern(const pPattern: string): Boolean;
var
  lLen: Integer;
  lI: Integer;
  lEscaped: Boolean;
  lParenthesisStack: TList<Integer>;
  lHasInnerQuantifier: Boolean;
  lChar: Char;
  lInnerQuantifierIdx: Integer;
  lGroupStartIdx: Integer;
  lNextChar: Char;
begin
  Result := False;
  lLen := Length(pPattern);
  if lLen < 5 then
    Exit;

  lParenthesisStack := TList<Integer>.Create;
  try
    lI := 1;
    lEscaped := False;
    while (lI <= lLen) and not Result do
    begin
      lChar := pPattern[lI];
      if lEscaped then
      begin
        lEscaped := False;
      end else if lChar = '\' then
      begin
        lEscaped := True;
      end else if lChar = '(' then
      begin
        lParenthesisStack.Add(lI);
      end else if lChar = ')' then
      begin
        if lParenthesisStack.Count > 0 then
        begin
          lGroupStartIdx := lParenthesisStack[lParenthesisStack.Count - 1];
          lParenthesisStack.Delete(lParenthesisStack.Count - 1);

          if lI < lLen then
          begin
            lNextChar := pPattern[lI + 1];
            if (lNextChar = '+') or (lNextChar = '*') then
            begin
              lHasInnerQuantifier := False;
              lInnerQuantifierIdx := lGroupStartIdx + 1;
              while lInnerQuantifierIdx < lI do
              begin
                if pPattern[lInnerQuantifierIdx] = '\' then
                begin
                  Inc(lInnerQuantifierIdx);
                end else if (pPattern[lInnerQuantifierIdx] = '+') or (pPattern[lInnerQuantifierIdx] = '*') then
                begin
                  lHasInnerQuantifier := True;
                end;
                Inc(lInnerQuantifierIdx);
              end;

              if lHasInnerQuantifier then
              begin
                Result := True;
              end;
            end;
          end;
        end;
      end;
      Inc(lI);
    end;
  finally
    lParenthesisStack.Free;
  end;
end;

end.
