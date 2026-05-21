unit JsonSchema.Visitor.Validation.Format;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Common.Utils,
  JsonSchema.FormatValidator;

type
  /// <summary>
  ///   Visitor for the 'format' validation keyword.
  ///   Delegates the actual format checking to TFormatValidator.
  ///   Respects the format-assertion mode (enabled/disabled) and
  ///   validation vocabulary silent mode.
  /// </summary>
  TFormatValidationVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseValidationVisitor<T>)
  private
    function GetValidationVisitor: IValidationVisitor<T>;
    function GetSilentMode: Boolean;
    function GetFormatAssertionEnabled: Boolean;
  public
    [VisitorKeyword('format')]
    procedure VisitFormat(const pValue: TJSONString);

    // Unsupported validation methods – no‑op to satisfy the interface
    procedure VisitType(const pValue: TJSONValue); virtual;
    procedure VisitEnum(const pValue: TJSONArray); virtual;
    procedure VisitConst(const pValue: TJSONValue); virtual;
    procedure VisitMultipleOf(const pValue: TJSONNumber); virtual;
    procedure VisitMaximum(const pValue: TJSONNumber); virtual;
    procedure VisitExclusiveMaximum(const pValue: TJSONValue); virtual;
    procedure VisitMinimum(const pValue: TJSONNumber); virtual;
    procedure VisitExclusiveMinimum(const pValue: TJSONValue); virtual;
    procedure VisitMaxLength(const pValue: TJSONNumber); virtual;
    procedure VisitMinLength(const pValue: TJSONNumber); virtual;
    procedure VisitPattern(const pValue: TJSONString); virtual;
    procedure VisitMaxItems(const pValue: TJSONNumber); virtual;
    procedure VisitMinItems(const pValue: TJSONNumber); virtual;
    procedure VisitUniqueItems(const pValue: TJSONBool); virtual;
    procedure VisitMaxProperties(const pValue: TJSONNumber); virtual;
    procedure VisitMinProperties(const pValue: TJSONNumber); virtual;
    procedure VisitRequired(const pValue: TJSONArray); virtual;
  end;

implementation

uses
  System.SysUtils;

{ TFormatValidationVisitor<T> }

function TFormatValidationVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

function TFormatValidationVisitor<T>.GetSilentMode: Boolean;
var
  lMode: IDraft2019_09ValidationVocabularyMode;
begin
  Result := False;
  if Supports(Visitor, IDraft2019_09ValidationVocabularyMode, lMode) then
    Result := lMode.IsValidationVocabularySilent;
end;

function TFormatValidationVisitor<T>.GetFormatAssertionEnabled: Boolean;
var
  lMode: IDraftFormatAssertionMode;
begin
  Result := True; // default for drafts before 2020-12
  if Supports(Visitor, IDraftFormatAssertionMode, lMode) then
    Result := lMode.IsFormatAssertionEnabled;
end;

procedure TFormatValidationVisitor<T>.VisitFormat(const pValue: TJSONString);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lFormatName: string;
  lInstanceValue: string;
  lIsValid: Boolean;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  // If validation vocabulary is silent, skip entirely (no annotation, no assertion)
  if GetSilentMode then
    Exit;

  // If format assertion is disabled, treat as annotation only (record but don't validate)
  if not GetFormatAssertionEnabled then
  begin
    lScope := lVisitor.CurrentScope;
    if TUtils.JsonGetType(lScope.InstanceNode) = 'string' then
      lVisitor.Result.AddAnnotation('format', pValue.Value);
    Exit;
  end;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  lFormatName := LowerCase(pValue.Value);
  lInstanceValue := TJSONString(lScope.InstanceNode).Value;
  lIsValid := True;

  if lFormatName = 'ipv4' then
    lIsValid := TFormatValidator.IsIPv4(lInstanceValue)
  else if lFormatName = 'ipv6' then
    lIsValid := TFormatValidator.IsIPv6(lInstanceValue)
  else if lFormatName = 'date-time' then
    lIsValid := TFormatValidator.IsDateTime(lInstanceValue)
  else if lFormatName = 'duration' then
    lIsValid := TFormatValidator.IsDuration(lInstanceValue)
  else if lFormatName = 'date' then
    lIsValid := TFormatValidator.IsDate(lInstanceValue)
  else if lFormatName = 'time' then
    lIsValid := TFormatValidator.IsTime(lInstanceValue)
  else if lFormatName = 'email' then
    lIsValid := TFormatValidator.IsEmail(lInstanceValue)
  else if lFormatName = 'idn-email' then
    lIsValid := TFormatValidator.IsIDNEmail(lInstanceValue)
  else if lFormatName = 'idn-hostname' then
    lIsValid := TFormatValidator.IsIDNHostname(lInstanceValue)
  else if lFormatName = 'json-pointer' then
    lIsValid := TFormatValidator.IsJSONPointer(lInstanceValue)
  else if lFormatName = 'uri-reference' then
    lIsValid := TFormatValidator.IsURIReference(lInstanceValue)
  else if lFormatName = 'uri' then
    lIsValid := TFormatValidator.IsURI(lInstanceValue)
  else if lFormatName = 'iri-reference' then
    lIsValid := TFormatValidator.IsIRIReference(lInstanceValue)
  else if lFormatName = 'iri' then
    lIsValid := TFormatValidator.IsIRI(lInstanceValue)
  else if lFormatName = 'uri-template' then
    lIsValid := TFormatValidator.IsURITemplate(lInstanceValue)
  else if lFormatName = 'relative-json-pointer' then
    lIsValid := TFormatValidator.IsRelativeJSONPointer(lInstanceValue)
  else if lFormatName = 'regex' then
    lIsValid := TFormatValidator.IsRegex(lInstanceValue)
  else if lFormatName = 'hostname' then
    lIsValid := TFormatValidator.IsHostname(lInstanceValue)
  else if lFormatName = 'uuid' then
    lIsValid := TFormatValidator.IsUUID(lInstanceValue);

  if not lIsValid then
    lVisitor.AddError(TErrorType.vetInvalidFormat, [pValue.Value]);
end;

// Unsupported methods – no‑op to satisfy the interface

procedure TFormatValidationVisitor<T>.VisitType(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle 'type' keyword
end;

procedure TFormatValidationVisitor<T>.VisitEnum(const pValue: TJSONArray);
begin
  // Empty - this visitor does not handle 'enum' keyword
end;

procedure TFormatValidationVisitor<T>.VisitConst(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle 'const' keyword
end;

procedure TFormatValidationVisitor<T>.VisitMultipleOf(const pValue: TJSONNumber);
begin
  // Empty - this visitor does not handle 'multipleOf' keyword
end;

procedure TFormatValidationVisitor<T>.VisitMaximum(const pValue: TJSONNumber);
begin
  // Empty - this visitor does not handle 'maximum' keyword
end;

procedure TFormatValidationVisitor<T>.VisitExclusiveMaximum(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle 'exclusiveMaximum' keyword
end;

procedure TFormatValidationVisitor<T>.VisitMinimum(const pValue: TJSONNumber);
begin
  // Empty - this visitor does not handle 'minimum' keyword
end;

procedure TFormatValidationVisitor<T>.VisitExclusiveMinimum(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle 'exclusiveMinimum' keyword
end;

procedure TFormatValidationVisitor<T>.VisitMaxLength(const pValue: TJSONNumber);
begin
  // Empty - this visitor does not handle 'maxLength' keyword
end;

procedure TFormatValidationVisitor<T>.VisitMinLength(const pValue: TJSONNumber);
begin
  // Empty - this visitor does not handle 'minLength' keyword
end;

procedure TFormatValidationVisitor<T>.VisitPattern(const pValue: TJSONString);
begin
  // Empty - this visitor does not handle 'pattern' keyword
end;

procedure TFormatValidationVisitor<T>.VisitMaxItems(const pValue: TJSONNumber);
begin
  // Empty - this visitor does not handle 'maxItems' keyword
end;

procedure TFormatValidationVisitor<T>.VisitMinItems(const pValue: TJSONNumber);
begin
  // Empty - this visitor does not handle 'minItems' keyword
end;

procedure TFormatValidationVisitor<T>.VisitUniqueItems(const pValue: TJSONBool);
begin
  // Empty - this visitor does not handle 'uniqueItems' keyword
end;

procedure TFormatValidationVisitor<T>.VisitMaxProperties(const pValue: TJSONNumber);
begin
  // Empty - this visitor does not handle 'maxProperties' keyword
end;

procedure TFormatValidationVisitor<T>.VisitMinProperties(const pValue: TJSONNumber);
begin
  // Empty - this visitor does not handle 'minProperties' keyword
end;

procedure TFormatValidationVisitor<T>.VisitRequired(const pValue: TJSONArray);
begin
  // Empty - this visitor does not handle 'required' keyword
end;

end.
