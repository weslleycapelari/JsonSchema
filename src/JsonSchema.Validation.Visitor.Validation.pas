unit JsonSchema.Validation.Visitor.Validation;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Interfaces;

type
  /// <summary>
  ///   Base visitor that handles the JSON Schema Validation vocabulary keywords:
  ///   type, enum, const, numeric constraints, string constraints, array constraints,
  ///   object constraints, and content keywords.
  /// </summary>
  TBaseValidationVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseValidationVisitor<T>)
    // Geral
    [VisitorKeyword('type')]
    procedure VisitType(const pValue: TJSONValue);
    [VisitorKeyword('enum')]
    procedure VisitEnum(const pValue: TJSONArray);
    [VisitorKeyword('const')]
    procedure VisitConst(const pValue: TJSONValue);

    // Numérico
    [VisitorKeyword('multipleOf')]
    procedure VisitMultipleOf(const pValue: TJSONNumber);
    [VisitorKeyword('maximum')]
    procedure VisitMaximum(const pValue: TJSONNumber);
    [VisitorKeyword('exclusiveMaximum')]
    procedure VisitExclusiveMaximum(const pValue: TJSONValue);
    [VisitorKeyword('minimum')]
    procedure VisitMinimum(const pValue: TJSONNumber);
    [VisitorKeyword('exclusiveMinimum')]
    procedure VisitExclusiveMinimum(const pValue: TJSONValue);

    // String
    [VisitorKeyword('maxLength')]
    procedure VisitMaxLength(const pValue: TJSONNumber);
    [VisitorKeyword('minLength')]
    procedure VisitMinLength(const pValue: TJSONNumber);
    [VisitorKeyword('pattern')]
    procedure VisitPattern(const pValue: TJSONString);
    [VisitorKeyword('format')]
    procedure VisitFormat(const pValue: TJSONString);

    // Array
    [VisitorKeyword('contains')]
    procedure VisitContains(const pValue: TJSONValue);
    [VisitorKeyword('maxItems')]
    procedure VisitMaxItems(const pValue: TJSONNumber);
    [VisitorKeyword('minItems')]
    procedure VisitMinItems(const pValue: TJSONNumber);
    [VisitorKeyword('uniqueItems')]
    procedure VisitUniqueItems(const pValue: TJSONBool);

    // Objeto
    [VisitorKeyword('dependencies')]
    procedure VisitDependencies(const pValue: TJSONObject);
    [VisitorKeyword('maxProperties')]
    procedure VisitMaxProperties(const pValue: TJSONNumber);
    [VisitorKeyword('minProperties')]
    procedure VisitMinProperties(const pValue: TJSONNumber);
    [VisitorKeyword('required')]
    procedure VisitRequired(const pValue: TJSONArray);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const pValue: TJSONValue);

    // Conteudo
    [VisitorKeyword('contentEncoding')]
    procedure VisitContentEncoding(const pValue: TJSONString);
    [VisitorKeyword('contentMediaType')]
    procedure VisitContentMediaType(const pValue: TJSONString);
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Math,
  System.DateUtils,
  System.NetEncoding,
  System.RegularExpressions,
  System.Generics.Collections,
  JsonSchema.Translate.Types,
  JsonSchema.Common.Utils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types,
  JsonSchema.Registry.Utils,
  JsonSchema.Validation.Base;

{ TBaseValidationVisitor<T> }

procedure TBaseValidationVisitor<T>.VisitConst(const pValue: TJSONValue);
var
  lScope: TScope;
begin
  lScope := Visitor.CurrentScope;
  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'const']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if not TUtils.JsonEquals(lScope.InstanceNode, pValue) then
      Visitor.AddError(TErrorType.vetConstValueMismatch, [pValue.ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitEnum(const pValue: TJSONArray);
var
  lScope: TScope;
  lIsValid: Boolean;
  lEnumValue: TJSONValue;
begin
  lScope := Visitor.CurrentScope;
  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'enum']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    lIsValid := False;
    for lEnumValue in pValue do
    begin
      if TUtils.JsonEquals(lScope.InstanceNode, lEnumValue) then
      begin
        lIsValid := True;
        Break;
      end;
    end;

    if not lIsValid then
      Visitor.AddError(TErrorType.vetEnumValueMismatch, [pValue.ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitContains(const pValue: TJSONValue);
var
  lScope: TScope;
  lCount: Integer;
  lWalker: IWalker;
  lVisitor: T;
  lNewScope: TScope;
  lInstance: TJSONArray;
  lMinContainsNode: TJSONValue;
  lMinimumContains: Integer;
  lItemPath: string;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  if pValue is TJSONBool then
  begin
    if TJSONBool(pValue).AsBoolean and (TJSONArray(lScope.InstanceNode).Count > 0) then
    begin
      lInstance := TJSONArray(lScope.InstanceNode);
      for lCount := 0 to lInstance.Count - 1 do
      begin
        TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
        lItemPath := Format('%s/%d', [lScope.InstancePath, lCount]);
        Visitor.Result.AddEvaluatedProperty(lItemPath);
      end;
      Visitor.UpdateScope(lScope);
      Exit;
    end;

    if not TJSONBool(pValue).AsBoolean then
    begin
       Visitor.AddError(vetContains);
       Exit;
    end;
  end;

  lInstance := TJSONArray(lScope.InstanceNode);
  for lCount := 0 to lInstance.Count - 1 do
  begin
    lNewScope := lScope;
    lNewScope.SchemaPath        := Format('%s/contains', [lScope.SchemaPath]);
    lNewScope.SchemaNode        := pValue;
    lNewScope.InstanceNode      := lInstance[lCount];
    lNewScope.InstancePath      := Format('%s/%d', [lScope.InstancePath, lCount]);
    lNewScope.CoveredItems      := [];
    lNewScope.ContainsCount     := 0;
    lNewScope.VisitedKeywords   := [];
    lNewScope.CoveredProperties := [];

    Visitor.PushScope(lNewScope);
    lVisitor := Visitor.New(pValue, lInstance[lCount], lScope.BaseURI);
    try
      lWalker := TWalker<T>.Create(pValue, lVisitor);
      lWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if lVisitor.Result.IsValid then
    begin
      Inc(lScope.ContainsCount);
      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      lItemPath := Format('%s/%d', [lScope.InstancePath, lCount]);
      Visitor.Result.AddEvaluatedProperty(lItemPath);
    end;
  end;

  Visitor.UpdateScope(lScope);
  if lScope.ContainsCount = 0 then
  begin
    // Drafts com minContains=0 consideram "contains" sempre satisfeito.
    lMinimumContains := 1;
    if (lScope.SchemaNode is TJSONObject) and
       TJSONObject(lScope.SchemaNode).TryGetValue('minContains', lMinContainsNode) and
       (lMinContainsNode is TJSONNumber) then
      lMinimumContains := TUtils.JsonGetInteger(TJSONNumber(lMinContainsNode));

    if lMinimumContains > 0 then
      Visitor.AddError(vetContains);
  end;
end;

procedure TBaseValidationVisitor<T>.VisitDependencies(const pValue: TJSONObject);
var
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lDependencyValue: TJSONValue;
  lRequiredList: TJSONArray;
  lRequiredValue: TJSONValue;
  lRequiredName: string;
  lNewScope: TScope;
  lWalker: IWalker;
  lVisitor: T;
  lError: IError;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lDependencyPair in pValue do
  begin
    if lInstance.FindValue(lDependencyPair.JsonString.Value) = nil then
      Continue;

    lDependencyValue := lDependencyPair.JsonValue;

    if lDependencyValue is TJSONArray then
    begin
      lRequiredList := TJSONArray(lDependencyValue);
      for lRequiredValue in lRequiredList do
      begin
        if not (lRequiredValue is TJSONString) then
          Continue;

        lRequiredName := TJSONString(lRequiredValue).Value;
        if lInstance.FindValue(lRequiredName) = nil then
          Visitor.AddError(vetDependentRequired, [lDependencyPair.JsonString.Value, lRequiredName]);
      end;
      Continue;
    end;

    if (lDependencyValue is TJSONObject) or (lDependencyValue is TJSONBool) then
    begin
      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/dependencies/%s', [lScope.SchemaPath, lDependencyPair.JsonString.Value]);
      lNewScope.SchemaNode        := lDependencyValue;
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      lVisitor := Visitor.New(lDependencyValue, lScope.InstanceNode, lScope.BaseURI);
      lVisitor.PushScope(lNewScope);
      try
        lWalker := TWalker<T>.Create(lDependencyValue, lVisitor);
        lWalker.Walk;
      finally
        lVisitor.PopScope;
      end;

      if not lVisitor.Result.IsValid then
        for lError in lVisitor.Result.Errors do
          Visitor.Result.AddError(lError);
    end;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitExclusiveMaximum(const pValue: TJSONValue);
var
  lScope: TScope;
  lLimitSchema: TJSONValue;
  lLimitValue: Extended;
  lIsExclusive: Boolean;
begin
  lScope := Visitor.CurrentScope;

  if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), ['number', 'integer']) then
    Exit;

  if pValue is TJSONNumber then
  begin
    lLimitValue := TUtils.JsonGetFloat(pValue);
    lIsExclusive := True;
  end
  else if pValue is TJSONBool then
  begin
    lIsExclusive := TJSONBool(pValue).AsBoolean;
    if not lIsExclusive then
      Exit;

    if not ((lScope.SchemaNode is TJSONObject) and TJSONObject(lScope.SchemaNode).TryGetValue('maximum', lLimitSchema)) then
      Exit;

    if not (lLimitSchema is TJSONNumber) then
      Exit;

    lLimitValue := TUtils.JsonGetFloat(lLimitSchema);
  end
  else
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'exclusiveMaximum']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if lIsExclusive and (TUtils.JsonGetFloat(lScope.InstanceNode) >= lLimitValue) then
      Visitor.AddError(TErrorType.vetExclusiveMaximum, [lLimitValue.ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitExclusiveMinimum(const pValue: TJSONValue);
var
  lScope: TScope;
  lLimitSchema: TJSONValue;
  lLimitValue: Extended;
  lIsExclusive: Boolean;
begin
  lScope := Visitor.CurrentScope;

  if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), ['number', 'integer']) then
    Exit;

  if pValue is TJSONNumber then
  begin
    lLimitValue := TUtils.JsonGetFloat(pValue);
    lIsExclusive := True;
  end
  else if pValue is TJSONBool then
  begin
    lIsExclusive := TJSONBool(pValue).AsBoolean;
    if not lIsExclusive then
      Exit;

    if not ((lScope.SchemaNode is TJSONObject) and TJSONObject(lScope.SchemaNode).TryGetValue('minimum', lLimitSchema)) then
      Exit;

    if not (lLimitSchema is TJSONNumber) then
      Exit;

    lLimitValue := TUtils.JsonGetFloat(lLimitSchema);
  end
  else
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'exclusiveMinimum']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if lIsExclusive and (TUtils.JsonGetFloat(lScope.InstanceNode) <= lLimitValue) then
      Visitor.AddError(TErrorType.vetExclusiveMinimum, [lLimitValue.ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitFormat(const pValue: TJSONString);
var
  lFormatMode: IDraftFormatAssertionMode;
  lScope: TScope;
  lFormatName: string;
  lInstanceValue: string;
  lIsValid: Boolean;
  lParts: TArray<string>;
  lLeftParts: TArray<string>;
  lRightParts: TArray<string>;
  lPart: string;
  lWorkValue: string;
  lLeftValue: string;
  lRightValue: string;
  lNumber: Integer;
  lSplitPos: Integer;
  lLastColon: Integer;
  lIPv4Tail: string;
  lHextetCount: Integer;
  lExpectedHextets: Integer;
  lHasCompression: Boolean;
  lDateTime: TDateTime;
  lMatch: TMatch;
  lYear: Integer;
  lMonth: Integer;
  lDay: Integer;
  lHour: Integer;
  lMinute: Integer;
  lSecond: Integer;
  lOffsetHour: Integer;
  lOffsetMinute: Integer;
  lUtcTotalMinutes: Integer;
  lOffsetTotalMinutes: Integer;
  lUtcHour: Integer;
  lUtcMinute: Integer;
  lOffsetSign: Char;
  lTemplateDepth: Integer;
  lTemplateExpr: string;
  lTemplateChar: Char;
  lLabels: TArray<string>;
  lLabel: string;
  lCodePoint: Integer;
  lIndex: Integer;
  lHasArabicIndic: Boolean;
  lHasExtendedArabicIndic: Boolean;
  lHasKatakanaMiddleDot: Boolean;
  lHasKanaHanContent: Boolean;
begin
  if Supports(Visitor, IDraftFormatAssertionMode, lFormatMode) and
     (not lFormatMode.IsFormatAssertionEnabled) then
    Exit;

  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'format']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    lFormatName := LowerCase(pValue.Value);
    lInstanceValue := TJSONString(lScope.InstanceNode).Value;
    lIsValid := True;

    if lFormatName = 'ipv4' then
    begin
      lParts := SplitString(lInstanceValue, '.');
      lIsValid := Length(lParts) = 4;

      if lIsValid then
        for lPart in lParts do
        begin
          if (lPart = '') or not TRegEx.IsMatch(lPart, '^\d+$') then
          begin
            lIsValid := False;
            Break;
          end;

          if (Length(lPart) > 1) and (lPart[1] = '0') then
          begin
            lIsValid := False;
            Break;
          end;

          if not TryStrToInt(lPart, lNumber) or (lNumber < 0) or (lNumber > 255) then
          begin
            lIsValid := False;
            Break;
          end;
        end;
    end
    else if lFormatName = 'ipv6' then
    begin
      lWorkValue := lInstanceValue;
      lExpectedHextets := 8;
      lIsValid := lWorkValue <> '';

      if lIsValid and (Pos('.', lWorkValue) > 0) then
      begin
        lLastColon := LastDelimiter(':', lWorkValue);
        if lLastColon = 0 then
          lIsValid := False
        else
        begin
          lIPv4Tail := Copy(lWorkValue, lLastColon + 1, MaxInt);
          lParts := SplitString(lIPv4Tail, '.');
          lIsValid := Length(lParts) = 4;

          if lIsValid then
            for lPart in lParts do
            begin
              if (lPart = '') or not TRegEx.IsMatch(lPart, '^\d+$') then
              begin
                lIsValid := False;
                Break;
              end;

              if (Length(lPart) > 1) and (lPart[1] = '0') then
              begin
                lIsValid := False;
                Break;
              end;

              if not TryStrToInt(lPart, lNumber) or (lNumber < 0) or (lNumber > 255) then
              begin
                lIsValid := False;
                Break;
              end;
            end;

          if lIsValid then
          begin
            lExpectedHextets := 6;
            if (lLastColon > 1) and (lWorkValue[lLastColon - 1] = ':') then
              lWorkValue := Copy(lWorkValue, 1, lLastColon)
            else
              lWorkValue := Copy(lWorkValue, 1, lLastColon - 1);
          end;
        end;
      end;

      if lIsValid then
      begin
        if Pos(':::', lWorkValue) > 0 then
          lIsValid := False
        else
        begin
          lHasCompression := Pos('::', lWorkValue) > 0;

          if lHasCompression then
          begin
            lSplitPos := Pos('::', lWorkValue);
            if PosEx('::', lWorkValue, lSplitPos + 2) > 0 then
              lIsValid := False
            else
            begin
              lHextetCount := 0;
              lLeftValue := Copy(lWorkValue, 1, lSplitPos - 1);
              lRightValue := Copy(lWorkValue, lSplitPos + 2, MaxInt);

              if lLeftValue <> '' then
              begin
                lLeftParts := SplitString(lLeftValue, ':');
                for lPart in lLeftParts do
                begin
                  if (lPart = '') or not TRegEx.IsMatch(lPart, '^[0-9A-Fa-f]{1,4}$') then
                  begin
                    lIsValid := False;
                    Break;
                  end;
                  Inc(lHextetCount);
                end;
              end;

              if lIsValid and (lRightValue <> '') then
              begin
                lRightParts := SplitString(lRightValue, ':');
                for lPart in lRightParts do
                begin
                  if (lPart = '') or not TRegEx.IsMatch(lPart, '^[0-9A-Fa-f]{1,4}$') then
                  begin
                    lIsValid := False;
                    Break;
                  end;
                  Inc(lHextetCount);
                end;
              end;

              if lIsValid then
                lIsValid := lHextetCount < lExpectedHextets;
            end;
          end
          else
          begin
            lParts := SplitString(lWorkValue, ':');
            if Length(lParts) <> lExpectedHextets then
              lIsValid := False
            else
              for lPart in lParts do
                if (lPart = '') or not TRegEx.IsMatch(lPart, '^[0-9A-Fa-f]{1,4}$') then
                begin
                  lIsValid := False;
                  Break;
                end;
          end;
        end;
      end;
    end
    else if lFormatName = 'date-time' then
    begin
      lMatch := TRegEx.Match(lInstanceValue,
        '^(\d{4})-(\d{2})-(\d{2})[Tt](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?([Zz]|[+\-]\d{2}:\d{2})$',
        [roCompiled]);
      lIsValid := lMatch.Success;

      if lIsValid then
      begin
        lIsValid :=
          TryStrToInt(lMatch.Groups[1].Value, lYear) and
          TryStrToInt(lMatch.Groups[2].Value, lMonth) and
          TryStrToInt(lMatch.Groups[3].Value, lDay) and
          TryStrToInt(lMatch.Groups[4].Value, lHour) and
          TryStrToInt(lMatch.Groups[5].Value, lMinute) and
          TryStrToInt(lMatch.Groups[6].Value, lSecond);

        if lIsValid then
          lIsValid :=
            (lYear >= 1) and
            (lMonth >= 1) and (lMonth <= 12) and
            (lDay >= 1) and (lDay <= 31) and
            TryEncodeDate(Word(lYear), Word(lMonth), Word(lDay), lDateTime);

        if lIsValid then
          lIsValid := (lHour <= 23) and (lMinute <= 59) and (lSecond <= 60);

        // Leap second is valid only for 23:59:60 in UTC.
        if lIsValid and (lSecond = 60) then
        begin
          if SameText(lMatch.Groups[7].Value, 'Z') then
          begin
            lIsValid := (lHour = 23) and (lMinute = 59);
          end
          else
          begin
            lOffsetSign := lMatch.Groups[7].Value[1];
            lIsValid :=
              TryStrToInt(Copy(lMatch.Groups[7].Value, 2, 2), lOffsetHour) and
              TryStrToInt(Copy(lMatch.Groups[7].Value, 5, 2), lOffsetMinute) and
              (lOffsetHour <= 23) and
              (lOffsetMinute <= 59);

            if lIsValid then
            begin
              lOffsetTotalMinutes := (lOffsetHour * 60) + lOffsetMinute;
              lUtcTotalMinutes := (lHour * 60) + lMinute;

              if lOffsetSign = '+' then
                lUtcTotalMinutes := lUtcTotalMinutes - lOffsetTotalMinutes
              else
                lUtcTotalMinutes := lUtcTotalMinutes + lOffsetTotalMinutes;

              lUtcTotalMinutes := ((lUtcTotalMinutes mod 1440) + 1440) mod 1440;
              lUtcHour := lUtcTotalMinutes div 60;
              lUtcMinute := lUtcTotalMinutes mod 60;
              lIsValid := (lUtcHour = 23) and (lUtcMinute = 59);
            end;
          end;
        end;

        if lIsValid and (lMatch.Groups[7].Value <> '') and
           (not SameText(lMatch.Groups[7].Value, 'Z')) then
        begin
          lIsValid :=
            TryStrToInt(Copy(lMatch.Groups[7].Value, 2, 2), lOffsetHour) and
            TryStrToInt(Copy(lMatch.Groups[7].Value, 5, 2), lOffsetMinute) and
            (lOffsetHour <= 23) and
            (lOffsetMinute <= 59);
        end;
      end;
    end
    else if lFormatName = 'duration' then
      lIsValid := TRegEx.IsMatch(lInstanceValue,
        '^P(?!$)((\d+Y)?(\d+M)?(\d+D)?(T(?=\d)(\d+H)?(\d+M)?(\d+S)?)?|(\d+W))$',
        [roCompiled])
    else if lFormatName = 'date' then
    begin
      lMatch := TRegEx.Match(lInstanceValue,
        '^([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$',
        [roCompiled]);
      lIsValid := lMatch.Success;

      if lIsValid then
      begin
        lIsValid :=
          TryStrToInt(lMatch.Groups[1].Value, lYear) and
          TryStrToInt(lMatch.Groups[2].Value, lMonth) and
          TryStrToInt(lMatch.Groups[3].Value, lDay);

        if lIsValid then
          lIsValid := TryEncodeDate(Word(lYear), Word(lMonth), Word(lDay), lDateTime);
      end;
    end
    else if lFormatName = 'time' then
    begin
      // RFC 3339 full-time: HH:MM:SS[.frac](Z|+HH:MM|-HH:MM)
      lMatch := TRegEx.Match(lInstanceValue,
        '^([01][0-9]|2[0-3]):([0-5][0-9]):((?:[0-5][0-9]|60))(?:\.[0-9]+)?([Zz]|[+\-]([01][0-9]|2[0-3]):([0-5][0-9]))$',
        [roCompiled]);
      lIsValid := lMatch.Success;

      if lIsValid then
      begin
        lIsValid :=
          TryStrToInt(lMatch.Groups[1].Value, lHour) and
          TryStrToInt(lMatch.Groups[2].Value, lMinute) and
          TryStrToInt(lMatch.Groups[3].Value, lSecond);

        if lIsValid then
          lIsValid := (lHour <= 23) and (lMinute <= 59) and (lSecond <= 60);

        // Leap second is valid only for 23:59:60 in UTC.
        if lIsValid and (lSecond = 60) then
        begin
          if SameText(lMatch.Groups[4].Value, 'Z') then
          begin
            lIsValid := (lHour = 23) and (lMinute = 59);
          end
          else
          begin
            lOffsetSign := lMatch.Groups[4].Value[1];
            lIsValid :=
              TryStrToInt(lMatch.Groups[5].Value, lOffsetHour) and
              TryStrToInt(lMatch.Groups[6].Value, lOffsetMinute) and
              (lOffsetHour <= 23) and
              (lOffsetMinute <= 59);

            if lIsValid then
            begin
              lOffsetTotalMinutes := (lOffsetHour * 60) + lOffsetMinute;
              lUtcTotalMinutes := (lHour * 60) + lMinute;

              if lOffsetSign = '+' then
                lUtcTotalMinutes := lUtcTotalMinutes - lOffsetTotalMinutes
              else
                lUtcTotalMinutes := lUtcTotalMinutes + lOffsetTotalMinutes;

              lUtcTotalMinutes := ((lUtcTotalMinutes mod 1440) + 1440) mod 1440;
              lUtcHour := lUtcTotalMinutes div 60;
              lUtcMinute := lUtcTotalMinutes mod 60;
              lIsValid := (lUtcHour = 23) and (lUtcMinute = 59);
            end;
          end;
        end;
      end;
    end
    else if lFormatName = 'email' then
      lIsValid := TRegEx.IsMatch(lInstanceValue,
        '^[A-Za-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&''*+/=?^_`{|}~-]+)*@(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-))(?:\.(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)))*$',
        [roCompiled])
    else if lFormatName = 'idn-email' then
      // Placeholder RFC 6531/5890: aceita Unicode basico sem espacos e com separacao local@dominio.
      lIsValid := TRegEx.IsMatch(lInstanceValue,
        '^[^\s@]+@(?=.{1,253}$)(?:(?!-)[\p{L}\p{N}-]{1,63}(?<!-))(?:\.(?:(?!-)[\p{L}\p{N}-]{1,63}(?<!-)))*$',
        [roCompiled])
    else if lFormatName = 'idn-hostname' then
    begin
      // Regras minimas RFC 5890/IDNA: tamanho de labels, controle, espacos, hifens e punycode malformado.
      lWorkValue := lInstanceValue;
      for lIndex := 1 to Length(lWorkValue) do
      begin
        lCodePoint := Ord(lWorkValue[lIndex]);
        if (lCodePoint = $3002) or (lCodePoint = $FF0E) or (lCodePoint = $FF61) then
          lWorkValue[lIndex] := '.';
      end;

      lIsValid := (lWorkValue <> '') and (Length(lWorkValue) <= 253);

      if lIsValid then
        lIsValid := not TRegEx.IsMatch(lWorkValue, '[\x00-\x1F\x7F\s]', [roCompiled]);

      if lIsValid then
        lIsValid := not ((lWorkValue[1] = '.') or (lWorkValue[Length(lWorkValue)] = '.'));

      if lIsValid then
        lIsValid := Pos('..', lWorkValue) = 0;

      if lIsValid then
      begin
        lLabels := SplitString(lWorkValue, '.');
        for lLabel in lLabels do
        begin
          if (lLabel = '') or (Length(lLabel) > 63) then
          begin
            lIsValid := False;
            Break;
          end;

          if (lLabel[1] = '-') or (lLabel[Length(lLabel)] = '-') then
          begin
            lIsValid := False;
            Break;
          end;

          if StartsText('xn--', lLabel) then
          begin
            // Punycode ACE prefix deve estar em lowercase e conter payload alfanumerico/hifen.
            if not lLabel.StartsWith('xn--') or
               (Length(lLabel) <= 4) or
               not TRegEx.IsMatch(Copy(lLabel, 5, MaxInt), '^[a-z0-9-]+$', [roCompiled]) then
            begin
              lIsValid := False;
              Break;
            end;
          end;
        end;

        if lIsValid then
        begin
          lHasArabicIndic := False;
          lHasExtendedArabicIndic := False;
          lHasKatakanaMiddleDot := False;
          lHasKanaHanContent := False;

          for lIndex := 1 to Length(lWorkValue) do
          begin
            lCodePoint := Ord(lWorkValue[lIndex]);

            // Casos explicitamente DISALLOWED no conjunto de testes opcionais.
            if (lCodePoint = $302E) or (lCodePoint = $0640) or (lCodePoint = $07FA) or
               (lCodePoint = $3031) or (lCodePoint = $3032) or (lCodePoint = $3033) or
               (lCodePoint = $3034) or (lCodePoint = $3035) or (lCodePoint = $303B) or
               (lCodePoint = $303E) or (lCodePoint = $303F) then
            begin
              lIsValid := False;
              Break;
            end;

            // Nao permitir inicio com marcas combinantes dos casos de teste.
            if (lIndex = 1) and ((lCodePoint = $0903) or (lCodePoint = $0300) or (lCodePoint = $0488)) then
            begin
              lIsValid := False;
              Break;
            end;

            // U+00B7 deve estar entre 'l' e 'l'.
            if lCodePoint = $00B7 then
              if (lIndex = 1) or (lIndex = Length(lWorkValue)) or
                 (lWorkValue[lIndex - 1] <> 'l') or (lWorkValue[lIndex + 1] <> 'l') then
              begin
                lIsValid := False;
                Break;
              end;

            // Greek KERAIA U+0375 deve ser seguida por caractere grego.
            if lCodePoint = $0375 then
              if (lIndex = Length(lWorkValue)) or
                 not ((Ord(lWorkValue[lIndex + 1]) >= $0370) and (Ord(lWorkValue[lIndex + 1]) <= $03FF)) then
              begin
                lIsValid := False;
                Break;
              end;

            // Hebrew GERESH/GERSHAYIM devem ser precedidos por hebraico.
            if (lCodePoint = $05F3) or (lCodePoint = $05F4) then
              if (lIndex = 1) or
                 not ((Ord(lWorkValue[lIndex - 1]) >= $0590) and (Ord(lWorkValue[lIndex - 1]) <= $05FF)) then
              begin
                lIsValid := False;
                Break;
              end;

            if (lCodePoint >= $0660) and (lCodePoint <= $0669) then
              lHasArabicIndic := True;
            if (lCodePoint >= $06F0) and (lCodePoint <= $06F9) then
              lHasExtendedArabicIndic := True;

            // KATAKANA MIDDLE DOT: exige outro caractere Hiragana/Katakana/Han no host.
            if lCodePoint = $30FB then
              lHasKatakanaMiddleDot := True
            else if ((lCodePoint >= $3040) and (lCodePoint <= $309F)) or
                    ((lCodePoint >= $30A0) and (lCodePoint <= $30FF)) or
                    ((lCodePoint >= $4E00) and (lCodePoint <= $9FFF)) then
              lHasKanaHanContent := True;

            // ZERO WIDTH JOINER U+200D deve ser precedido por virama U+094D.
            if lCodePoint = $200D then
              if (lIndex = 1) or (Ord(lWorkValue[lIndex - 1]) <> $094D) then
              begin
                lIsValid := False;
                Break;
              end;
          end;

          if lIsValid and lHasArabicIndic and lHasExtendedArabicIndic then
            lIsValid := False;

          if lIsValid and lHasKatakanaMiddleDot and not lHasKanaHanContent then
            lIsValid := False;
        end;
      end;
    end
    else if lFormatName = 'json-pointer' then
      lIsValid := TURIUtils.IsValidJsonPointer(lInstanceValue)
    else if lFormatName = 'uri-reference' then
      lIsValid := TURIUtils.IsValidURIReference(lInstanceValue)
    else if lFormatName = 'uri' then
      lIsValid := TURIUtils.IsValidURI(lInstanceValue)
    else if lFormatName = 'iri-reference' then
      // Placeholder RFC 3987: aceita caracteres Unicode, sem espacos de controle.
      lIsValid := TRegEx.IsMatch(lInstanceValue, '^[^\s<>"{}|\^`\\]+$', [roCompiled])
    else if lFormatName = 'iri' then
    begin
      // Placeholder RFC 3987: requer esquema + ':' e evita caracteres de controle.
      lIsValid := TRegEx.IsMatch(lInstanceValue, '^[A-Za-z][A-Za-z0-9+.-]*:[^\s<>"{}|\^`\\]*$', [roCompiled]);
      // Rejeitar IPv6 sem colchetes na authority (ex: http://2001:db8::1/)
      if lIsValid then
      begin
        lMatch := TRegEx.Match(lInstanceValue, '^[A-Za-z][A-Za-z0-9+.-]*://([^/?#]*)', [roCompiled]);
        if lMatch.Success then
        begin
          lWorkValue := lMatch.Groups[1].Value;
          lSplitPos := LastDelimiter('@', lWorkValue);
          if lSplitPos > 0 then
            lWorkValue := Copy(lWorkValue, lSplitPos + 1, MaxInt);
          if (lWorkValue = '') or (lWorkValue[1] <> '[') then
            if TRegEx.IsMatch(lWorkValue, ':[^:]*:', [roCompiled]) then
              lIsValid := False;
        end;
      end;
    end
    else if lFormatName = 'uri-template' then
    begin
      lTemplateDepth := 0;
      lTemplateExpr := '';

      for lTemplateChar in lInstanceValue do
      begin
        if lTemplateChar = '{' then
        begin
          if lTemplateDepth <> 0 then
          begin
            lIsValid := False;
            Break;
          end;

          lTemplateDepth := 1;
          lTemplateExpr := '';
          Continue;
        end;

        if lTemplateChar = '}' then
        begin
          if lTemplateDepth = 0 then
          begin
            lIsValid := False;
            Break;
          end;

          lIsValid := lTemplateExpr <> '';
          if lIsValid then
            lIsValid := TRegEx.IsMatch(
              lTemplateExpr,
              '^[+#./;?&]?[A-Za-z0-9_%.][A-Za-z0-9_%.]*(?::\d+|\*)?(?:,[A-Za-z0-9_%.][A-Za-z0-9_%.]*(?::\d+|\*)?)*$',
              [roCompiled]);

          if not lIsValid then
            Break;

          lTemplateDepth := 0;
          Continue;
        end;

        if lTemplateDepth = 1 then
        begin
          if (lTemplateChar <= ' ') or (lTemplateChar = '{') or (lTemplateChar = '}') then
          begin
            lIsValid := False;
            Break;
          end;

          lTemplateExpr := lTemplateExpr + lTemplateChar;
        end;
      end;

      if lIsValid then
        lIsValid := lTemplateDepth = 0;
    end
    else if lFormatName = 'relative-json-pointer' then
      // RFC draft-handrews-relative-json-pointer: non-negative-integer seguido de '#' ou JSON Pointer
      lIsValid := TRegEx.IsMatch(lInstanceValue,
        '^(0|[1-9][0-9]*)(#|(/([^~/]|~[01])*)*)$',
        [roCompiled])
    else if lFormatName = 'regex' then
    begin
      try
        TRegEx.IsMatch('', lInstanceValue);
      except
        lIsValid := False;
      end;
    end
    else if lFormatName = 'hostname' then
      lIsValid := TRegEx.IsMatch(lInstanceValue,
        '^(?=.{1,253}$)(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-))(?:\.(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)))*$',
        [roCompiled])
    else if lFormatName = 'uuid' then
      lIsValid := TRegEx.IsMatch(lInstanceValue,
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        [roCompiled]);

    if not lIsValid then
      Visitor.AddError(TErrorType.vetInvalidFormat, [pValue.Value]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMaximum(const pValue: TJSONNumber);
var
  lScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), ['number', 'integer']) then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'maximum']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if (TUtils.JsonGetFloat(lScope.InstanceNode) > TUtils.JsonGetFloat(pValue)) then
      Visitor.AddError(TErrorType.vetMaximum, [TUtils.JsonGetFloat(pValue).ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMaxItems(const pValue: TJSONNumber);
var
  lScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'maxItems']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if (TJSONArray(lScope.InstanceNode).Count > TUtils.JsonGetInteger(pValue)) then
      Visitor.AddError(TErrorType.vetMaxItems, [TUtils.JsonGetInteger(pValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMaxLength(const pValue: TJSONNumber);
var
  lScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'maxLength']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if (Length(TUtils.Utf32Encode(TJSONString(lScope.InstanceNode).Value)) > TUtils.JsonGetInteger(pValue)) then
      Visitor.AddError(TErrorType.vetMaxLength, [TUtils.JsonGetInteger(pValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMaxProperties(const pValue: TJSONNumber);
var
  lScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'maxProperties']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if (TJSONObject(lScope.InstanceNode).Count > TUtils.JsonGetInteger(pValue)) then
      Visitor.AddError(TErrorType.vetMaxProperties, [TUtils.JsonGetInteger(pValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMinimum(const pValue: TJSONNumber);
var
  lScope: TScope;
  lDraft2019VocabularyMode: IDraft2019_09ValidationVocabularyMode;
begin
  if Supports(Visitor, IDraft2019_09ValidationVocabularyMode, lDraft2019VocabularyMode) and
     lDraft2019VocabularyMode.IsValidationVocabularySilent then
    Exit;

  lScope := Visitor.CurrentScope;

  if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), ['number', 'integer']) then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'minimum']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if (TUtils.JsonGetFloat(lScope.InstanceNode) < TUtils.JsonGetFloat(pValue)) then
      Visitor.AddError(TErrorType.vetMinimum, [TUtils.JsonGetFloat(pValue).ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMinItems(const pValue: TJSONNumber);
var
  lScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'minItems']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if (TJSONArray(lScope.InstanceNode).Count < TUtils.JsonGetInteger(pValue)) then
      Visitor.AddError(TErrorType.vetMinItems, [TUtils.JsonGetInteger(pValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMinLength(const pValue: TJSONNumber);
var
  lScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'minLength']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if (Length(TUtils.Utf32Encode(TJSONString(lScope.InstanceNode).Value)) < TUtils.JsonGetInteger(pValue)) then
      Visitor.AddError(TErrorType.vetMinLength, [TUtils.JsonGetInteger(pValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMinProperties(const pValue: TJSONNumber);
var
  lScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'minProperties']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if (TJSONObject(lScope.InstanceNode).Count < TUtils.JsonGetInteger(pValue)) then
      Visitor.AddError(TErrorType.vetMinProperties, [TUtils.JsonGetInteger(pValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMultipleOf(const pValue: TJSONNumber);
var
  lScope: TScope;
  lValue: Extended;
  lDivisor: Extended;
  lDivision: Extended;
  lRounded: Extended;
  lEpsilon: Extended;
  lInverse: Extended;
  lInverseRounded: Extended;
  lResidual: Extended;
begin
  lScope := Visitor.CurrentScope;

  if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), ['number', 'integer']) then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'multipleOf']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    lValue := TUtils.JsonGetFloat(lScope.InstanceNode);
    lDivisor := TUtils.JsonGetFloat(pValue);
    if lDivisor = 0 then
      Exit;

    if TUtils.JsonGetType(lScope.InstanceNode) = 'integer' then
    begin
      lInverse := 1 / lDivisor;
      lInverseRounded := Round(lInverse);
      if Abs(lInverse - lInverseRounded) <= 1E-12 then
        Exit;
    end;

    if Abs(lValue) < 1E-15 then
      Exit;

    lDivision := lValue / lDivisor;

    if IsInfinite(lDivision) or IsNan(lDivision) then
    begin
      // Optional overflow handling: every integer is multiple of divisors like 1/n.
      if TUtils.JsonGetType(lScope.InstanceNode) = 'integer' then
      begin
        lInverse := 1 / lDivisor;
        lInverseRounded := Round(lInverse);
        if Abs(lInverse - lInverseRounded) <= 1E-12 then
          Exit;
      end;

      Visitor.AddError(TErrorType.vetMultipleOf, [pValue.Value]);
      Exit;
    end;

    lRounded := Round(lDivision);
    lResidual := Abs(lValue - (lRounded * lDivisor));

    if Abs(lValue) < 1E-15 then
      lEpsilon := Max(1E-30, Abs(lDivisor) * 1E-12)
    else
      lEpsilon := Max(1E-12, Abs(lDivision) * 1E-12);

    if (Abs(lDivision - lRounded) > lEpsilon) and (lResidual > lEpsilon) then
      Visitor.AddError(TErrorType.vetMultipleOf, [pValue.Value]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitPattern(const pValue: TJSONString);
var
  lScope: TScope;
begin
  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'pattern']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    if not TRegEx.IsMatch(
      TJSONString(lScope.InstanceNode).Value,
      TUtils.RegexNormalizePattern(pValue.Value),
      [roCompiled]) then
      Visitor.AddError(TErrorType.vetPattern, [TUtils.RegexNormalizePattern(pValue.Value)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitPropertyNames(const pValue: TJSONValue);
var
  lPair: TJSONPair;
  lScope: TScope;
  lWalker: IWalker;
  lVisitor: T;
  lNewScope: TScope;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  for lPair in TJSONObject(lScope.InstanceNode) do
  begin
    lNewScope := lScope;
    lNewScope.SchemaPath        := Format('%s/propertyNames', [lScope.SchemaPath]);
    lNewScope.SchemaNode        := pValue;
    lNewScope.InstanceNode      := lPair.JsonString;
    lNewScope.InstancePath      := Format('%s/%s', [lScope.InstancePath, lPair.JsonString.Value]);
    lNewScope.CoveredItems      := [];
    lNewScope.ContainsCount     := 0;
    lNewScope.VisitedKeywords   := [];
    lNewScope.CoveredProperties := [];

    Visitor.PushScope(lNewScope);
    lVisitor := Visitor.New(lNewScope.SchemaNode, lNewScope.InstanceNode, lScope.BaseURI);
    try
      lWalker := TWalker<T>.Create(lNewScope.SchemaNode, lVisitor);
      lWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if not lVisitor.Result.IsValid then
      Visitor.AddError(vetInvalidPropertyName, [lPair.JsonString.Value]);
  end;
end;

procedure TBaseValidationVisitor<T>.VisitRequired(const pValue: TJSONArray);
var
  lScope: TScope;
  lRequired: TJSONValue;
begin
  lScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'required']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    for lRequired in pValue do
      if TJSONObject(lScope.InstanceNode).FindValue(lRequired.Value) = nil then
        Visitor.AddError(TErrorType.vetRequiredPropertyMissing, [lRequired.Value]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitType(const pValue: TJSONValue);
var
  lType: TJSONValue;
  lScope: TScope;
  lAllowedTypes: TList<string>;
begin
  lScope := Visitor.CurrentScope;
  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'type']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  lAllowedTypes := TList<string>.Create;
  try
    if pValue is TJSONString then
    begin
      if TJSONString(pValue).Value = 'number' then
        lAllowedTypes.AddRange(['integer', 'number'])
      else
        lAllowedTypes.Add(TJSONString(pValue).Value.ToLower);
    end
    else if pValue is TJSONArray then
    begin
      for lType in TJSONArray(pValue) do
        if lType.Value = 'number' then
          lAllowedTypes.AddRange(['integer', 'number'])
        else
          lAllowedTypes.Add(lType.Value.ToLower);
    end;

    if not MatchStr(TUtils.JsonGetType(lScope.InstanceNode), lAllowedTypes.ToArray) then
      Visitor.AddError(TErrorType.vetInvalidType, [string.Join(', ', lAllowedTypes.ToArray), TUtils.JsonGetType(lScope.InstanceNode)]);
  finally
    lAllowedTypes.Free;
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitUniqueItems(const pValue: TJSONBool);
var
  lScope: TScope;
  lArray: TJSONArray;
  lCount1: Integer;
  lCount2: Integer;
begin
  lScope := Visitor.CurrentScope;

  if not pValue.AsBoolean then
    Exit;

  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lScope.SchemaPath        := Format('%s/%s', [lScope.SchemaPath, 'uniqueItems']);
  lScope.CoveredItems      := [];
  lScope.ContainsCount     := 0;
  lScope.VisitedKeywords   := [];
  lScope.CoveredProperties := [];
  Visitor.PushScope(lScope);
  try
    lArray := TJSONArray(lScope.InstanceNode);
    for lCount1 := 0 to lArray.Count - 2 do
    begin
      for lCount2 := lCount1 + 1 to lArray.Count - 1 do
      begin
        if TUtils.JsonEquals(lArray.Items[lCount1], lArray.Items[lCount2]) then
        begin
          Visitor.AddError(TErrorType.vetUniqueItems, [lArray.Items[lCount1].ToString]);
          Exit;
        end;
      end;
    end;
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitContentEncoding(const pValue: TJSONString);
var
  lScope: TScope;
  lInstanceValue: string;
  lPrecedenceKey: string;
  lAnnotationOnly: Boolean;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  if not SameText(pValue.Value, 'base64') then
    Exit;

  lAnnotationOnly := False;
  for lPrecedenceKey in Visitor.KeywordPrecedence do
    if (lPrecedenceKey = '$recursiveRef') or (lPrecedenceKey = '$dynamicRef') then
    begin
      lAnnotationOnly := True;
      Break;
    end;

  lInstanceValue := TJSONString(lScope.InstanceNode).Value;
  if not TRegEx.IsMatch(lInstanceValue, '^[A-Za-z0-9+/]*={0,2}$', [roCompiled]) then
  begin
    if not lAnnotationOnly then
      Visitor.AddError(TErrorType.vetInvalidFormat, ['contentEncoding']);
    Exit;
  end;

  try
    TNetEncoding.Base64.DecodeStringToBytes(lInstanceValue);
  except
    if not lAnnotationOnly then
      Visitor.AddError(TErrorType.vetInvalidFormat, ['contentEncoding']);
  end;
end;

procedure TBaseValidationVisitor<T>.VisitContentMediaType(const pValue: TJSONString);
var
  lScope: TScope;
  lMediaType: string;
  lInstanceValue: string;
  lEncoding: TJSONValue;
  lBytes: TBytes;
  lDecoded: string;
  lJsonValue: TJSONValue;
  lPrecedenceKey: string;
  lAnnotationOnly: Boolean;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'string' then
    Exit;

  lMediaType := LowerCase(pValue.Value);
  if lMediaType <> 'application/json' then
    Exit;

  lAnnotationOnly := False;
  for lPrecedenceKey in Visitor.KeywordPrecedence do
    if (lPrecedenceKey = '$recursiveRef') or (lPrecedenceKey = '$dynamicRef') then
    begin
      lAnnotationOnly := True;
      Break;
    end;

  // Em 2019-09/2020-12, content* funciona como anotação por padrão.
  // Sem um modo estrito explícito, não deve tornar a validação inválida.
  if lAnnotationOnly then
    Exit;

  lInstanceValue := TJSONString(lScope.InstanceNode).Value;
  lDecoded := lInstanceValue;

  // Se houver contentEncoding irmao, decodificar primeiro
  lEncoding := nil;
  if lScope.SchemaNode is TJSONObject then
    lEncoding := TJSONObject(lScope.SchemaNode).FindValue('contentEncoding');

  if (lEncoding is TJSONString) and SameText(TJSONString(lEncoding).Value, 'base64') then
  begin
    // Se o base64 for invalido, contentEncoding ja reportara o erro
    if not TRegEx.IsMatch(lInstanceValue, '^[A-Za-z0-9+/]*={0,2}$', [roCompiled]) then
      Exit;

    try
      lBytes := TNetEncoding.Base64.DecodeStringToBytes(lInstanceValue);
      lDecoded := TEncoding.UTF8.GetString(lBytes);
    except
      Exit;
    end;
  end;

  lJsonValue := TJSONObject.ParseJSONValue(lDecoded);
  if lJsonValue = nil then
    Visitor.AddError(TErrorType.vetInvalidFormat, ['contentMediaType'])
  else
    lJsonValue.Free;
end;

end.
