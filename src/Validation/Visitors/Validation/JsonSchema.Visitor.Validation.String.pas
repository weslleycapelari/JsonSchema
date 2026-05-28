unit JsonSchema.Visitor.Validation.&String;

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
  JsonSchema.FormatValidator,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

type
  /// <summary>
  ///   Visitor for string validation keywords: maxLength, minLength, pattern, format.
  ///   This class is meant to be composed into a full validation visitor.
  /// </summary>
  TStringValidationVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IStringValidationVisitor<T>)
  private
    function GetValidationVisitor: IValidationVisitor<T>;
    function GetFormatAssertionEnabled: Boolean;
  public
    [VisitorKeyword('maxLength')]
    procedure VisitMaxLength(const pValue: TJSONNumber);

    [VisitorKeyword('minLength')]
    procedure VisitMinLength(const pValue: TJSONNumber);

    [VisitorKeyword('pattern')]
    procedure VisitPattern(const pValue: TJSONString);

    [VisitorKeyword('format')]
    procedure VisitFormat(const pValue: TJSONString);

  end;

implementation

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonSchema.JsonPathUtils;

{ TStringValidationVisitor<T> }

function TStringValidationVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

function TStringValidationVisitor<T>.GetFormatAssertionEnabled: Boolean;
var
  lMode: IDraftFormatAssertionMode;
begin
  Result := True; // default for drafts before 2020-12
  if Supports(Visitor, IDraftFormatAssertionMode, lMode) then
    Result := lMode.IsFormatAssertionEnabled;
end;

procedure TStringValidationVisitor<T>.VisitMaxLength(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMax: Integer;
  lInstance: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  lInstance := lScope.InstanceNode;

  if TUtils.JsonGetType(lInstance) <> 'string' then
    Exit;

  lMax := TUtils.JsonGetInteger(pValue);
  if Length(TUtils.Utf32Encode(TJSONString(lInstance).Value)) > lMax then
    lVisitor.AddError(TErrorType.vetMaxLength, [lMax]);
end;

procedure TStringValidationVisitor<T>.VisitMinLength(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lMin: Integer;
  lInstance: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  lInstance := lScope.InstanceNode;

  if TUtils.JsonGetType(lInstance) <> 'string' then
    Exit;

  lMin := TUtils.JsonGetInteger(pValue);
  if Length(TUtils.Utf32Encode(TJSONString(lInstance).Value)) < lMin then
    lVisitor.AddError(TErrorType.vetMinLength, [lMin]);
end;

procedure TStringValidationVisitor<T>.VisitPattern(const pValue: TJSONString);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lPattern: string;
  lInstance: TJSONValue;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  lInstance := lScope.InstanceNode;

  if TUtils.JsonGetType(lInstance) <> 'string' then
    Exit;

  lPattern := TUtils.RegexNormalizePattern(pValue.Value);
  if not TRegEx.IsMatch(TJSONString(lInstance).Value, lPattern, [roCompiled]) then
    lVisitor.AddError(TErrorType.vetPattern, [lPattern]);
end;

procedure TStringValidationVisitor<T>.VisitFormat(const pValue: TJSONString);
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

  // If format assertion is disabled (e.g., Draft 2020-12 without the vocabulary), treat as annotation only
  if not GetFormatAssertionEnabled then
    Exit;

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



end.
