unit Delphi2Schema.Engine;

(*
--------------------------------------------------------------------------------
Delphi2Schema Engine - Scans Delphi types via RTTI and generates JSON Schema.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils,
  System.Rtti,
  System.JSON,
  System.Classes,
  System.TypInfo,
  Delphi2Schema.Attributes;

type
  /// <summary>Generates JSON Schema from Delphi types using RTTI.</summary>
  TDelphi2SchemaGenerator = class
  private
    FRttiContext: TRttiContext;
    FScanFields: Boolean;
    FScanProperties: Boolean;
    FUseEnumNames: Boolean;
    FProcessedTypes: TStringList;

    function ProcessType(pType: TRttiType): TJSONObject;
    function ProcessClassOrRecord(pType: TRttiType): TJSONObject;
    function ProcessEnum(pType: TRttiType): TJSONObject;
    function ProcessArray(pType: TRttiType): TJSONObject;

    procedure ApplyAttributes(pAnnotated: TRttiObject; pTarget: TJSONObject; var pRequired: Boolean);
    function HasIgnoreAttribute(pAnnotated: TRttiObject): Boolean;
    procedure CopyPairs(pSrc, pDest: TJSONObject);
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Generates a complete JSON Schema for a given TypeInfo pointer.</summary>
    function GenerateSchema(pTypeInfo: Pointer): TJSONObject;

    property ScanFields: Boolean read FScanFields write FScanFields;
    property ScanProperties: Boolean read FScanProperties write FScanProperties;
    property UseEnumNames: Boolean read FUseEnumNames write FUseEnumNames;
  end;

implementation

constructor TDelphi2SchemaGenerator.Create;
begin
  inherited Create;
  FRttiContext := TRttiContext.Create;
  FScanFields := False;
  FScanProperties := True; // Default to scanning properties (public/published interface)
  FUseEnumNames := True;
  FProcessedTypes := TStringList.Create;
  FProcessedTypes.Sorted := True;
  FProcessedTypes.Duplicates := dupIgnore;
end;

destructor TDelphi2SchemaGenerator.Destroy;
begin
  FProcessedTypes.Free;
  FRttiContext.Free;
  inherited Destroy;
end;

procedure TDelphi2SchemaGenerator.CopyPairs(pSrc, pDest: TJSONObject);
var
  lPair: TJSONPair;
begin
  if Assigned(pSrc) and Assigned(pDest) then
  begin
    for lPair in pSrc do
    begin
      if not Assigned(pDest.Get(lPair.JsonString.Value)) then
        pDest.AddPair(lPair.JsonString.Value, lPair.JsonValue.Clone as TJSONValue);
    end;
  end;
end;

function TDelphi2SchemaGenerator.GenerateSchema(pTypeInfo: Pointer): TJSONObject;
var
  lType: TRttiType;
  lSchemaObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  lType := FRttiContext.GetType(pTypeInfo);
  if not Assigned(lType) then
  begin
    Result.AddPair('type', 'null');
    Result.AddPair('description', 'Error: TypeInfo not found in RTTI context.');
    Exit;
  end;

  FProcessedTypes.Clear;
  lSchemaObj := ProcessType(lType);
  try
    Result.AddPair('$schema', 'http://json-schema.org/draft-07/schema#');
    CopyPairs(lSchemaObj, Result);
  finally
    lSchemaObj.Free;
  end;
end;

function TDelphi2SchemaGenerator.ProcessType(pType: TRttiType): TJSONObject;
var
  lObj: TJSONObject;
  lKind: TTypeKind;
  lName: string;
begin
  lObj := TJSONObject.Create;
  lKind := pType.TypeKind;
  lName := pType.Name;

  case lKind of
    tkInteger, tkInt64:
      lObj.AddPair('type', 'integer');

    tkFloat:
      begin
        if SameText(lName, 'TDateTime') or SameText(lName, 'TDate') or SameText(lName, 'TTime') then
        begin
          lObj.AddPair('type', 'string');
          if SameText(lName, 'TDateTime') then
            lObj.AddPair('format', 'date-time')
          else if SameText(lName, 'TDate') then
            lObj.AddPair('format', 'date')
          else
            lObj.AddPair('format', 'time');
        end else
          lObj.AddPair('type', 'number');
      end;

    tkChar, tkWChar, tkString, tkLString, tkWString, tkUString:
      lObj.AddPair('type', 'string');

    tkEnumeration:
      begin
        if SameText(lName, 'Boolean') then
          lObj.AddPair('type', 'boolean')
        else
        begin
          lObj.Free;
          lObj := ProcessEnum(pType);
        end;
      end;

    tkClass, tkRecord:
      begin
        lObj.Free;
        lObj := ProcessClassOrRecord(pType);
      end;

    tkArray, tkDynArray:
      begin
        lObj.Free;
        lObj := ProcessArray(pType);
      end;
  else
    lObj.AddPair('type', 'null');
  end;

  Result := lObj;
end;

function TDelphi2SchemaGenerator.ProcessEnum(pType: TRttiType): TJSONObject;
var
  lObj: TJSONObject;
  lEnum: TRttiEnumerationType;
  lArray: TJSONArray;
  lI: Integer;
  lName: string;
begin
  lObj := TJSONObject.Create;
  if pType is TRttiEnumerationType then
  begin
    lEnum := TRttiEnumerationType(pType);
    if FUseEnumNames then
    begin
      lObj.AddPair('type', 'string');
      lArray := TJSONArray.Create;
      for lI := lEnum.MinValue to lEnum.MaxValue do
      begin
        lName := GetEnumName(lEnum.Handle, lI);
        lArray.Add(lName);
      end;
      lObj.AddPair('enum', lArray);
    end else
    begin
      lObj.AddPair('type', 'integer');
      lObj.AddPair('minimum', TJSONNumber.Create(lEnum.MinValue));
      lObj.AddPair('maximum', TJSONNumber.Create(lEnum.MaxValue));
    end;
  end;
  Result := lObj;
end;

function TDelphi2SchemaGenerator.ProcessArray(pType: TRttiType): TJSONObject;
var
  lObj: TJSONObject;
  lElement: TRttiType;
  lSubSchema: TJSONObject;
begin
  lObj := TJSONObject.Create;
  lObj.AddPair('type', 'array');
  lElement := nil;

  if pType is TRttiArrayType then
    lElement := TRttiArrayType(pType).ElementType
  else if pType is TRttiDynamicArrayType then
    lElement := TRttiDynamicArrayType(pType).ElementType;

  if Assigned(lElement) then
  begin
    lSubSchema := ProcessType(lElement);
    lObj.AddPair('items', lSubSchema);
  end;

  Result := lObj;
end;

function TDelphi2SchemaGenerator.ProcessClassOrRecord(pType: TRttiType): TJSONObject;
var
  lObj: TJSONObject;
  lProps: TJSONObject;
  lReqs: TJSONArray;
  lField: TRttiField;
  lProp: TRttiProperty;
  lSub: TJSONObject;
  lRequired: Boolean;
  lDummyReq: Boolean;
begin
  // Handle recursion
  if FProcessedTypes.IndexOf(pType.QualifiedName) <> -1 then
  begin
    lObj := TJSONObject.Create;
    lObj.AddPair('type', 'object');
    lObj.AddPair('description', 'Recursive reference to ' + pType.Name);
    Exit(lObj);
  end;

  FProcessedTypes.Add(pType.QualifiedName);
  try
    lObj := TJSONObject.Create;
    lObj.AddPair('type', 'object');

    lProps := TJSONObject.Create;
    lReqs := TJSONArray.Create;

    // Scan fields if option enabled
    if FScanFields then
    begin
      for lField in pType.GetFields do
      begin
        if not HasIgnoreAttribute(lField) and Assigned(lField.FieldType) then
        begin
          lSub := ProcessType(lField.FieldType);
          lRequired := False;
          ApplyAttributes(lField, lSub, lRequired);

          if lRequired then
            lReqs.Add(lField.Name);

          lProps.AddPair(lField.Name, lSub);
        end;
      end;
    end;

    // Scan properties if option enabled
    if FScanProperties then
    begin
      for lProp in pType.GetProperties do
      begin
        if not HasIgnoreAttribute(lProp) and Assigned(lProp.PropertyType) then
        begin
          lSub := ProcessType(lProp.PropertyType);
          lRequired := False;
          ApplyAttributes(lProp, lSub, lRequired);

          if lRequired then
            lReqs.Add(lProp.Name);

          lProps.AddPair(lProp.Name, lSub);
        end;
      end;
    end;

    lObj.AddPair('properties', lProps);

    if lReqs.Count > 0 then
      lObj.AddPair('required', lReqs)
    else
      lReqs.Free;

    // Apply type level attributes
    lDummyReq := False;
    ApplyAttributes(pType, lObj, lDummyReq);
  finally
    FProcessedTypes.Delete(FProcessedTypes.IndexOf(pType.QualifiedName));
  end;

  Result := lObj;
end;

function TDelphi2SchemaGenerator.HasIgnoreAttribute(pAnnotated: TRttiObject): Boolean;
var
  lAttr: TCustomAttribute;
begin
  Result := False;
  for lAttr in pAnnotated.GetAttributes do
  begin
    if lAttr is JSONSchemaIgnoreAttribute then
      Exit(True);
  end;
end;

procedure TDelphi2SchemaGenerator.ApplyAttributes(pAnnotated: TRttiObject; pTarget: TJSONObject; var pRequired: Boolean);
var
  lAttr: TCustomAttribute;
  lEnumArray: TJSONArray;
  lName: string;
begin
  if not Assigned(pAnnotated) or not Assigned(pTarget) then
    Exit;

  for lAttr in pAnnotated.GetAttributes do
  begin
    if lAttr is JSONSchemaTitleAttribute then
      pTarget.AddPair('title', JSONSchemaTitleAttribute(lAttr).Value)
    else if lAttr is JSONSchemaDescriptionAttribute then
      pTarget.AddPair('description', JSONSchemaDescriptionAttribute(lAttr).Value)
    else if lAttr is JSONSchemaRequiredAttribute then
      pRequired := True
    else if lAttr is JSONSchemaMinimumAttribute then
      pTarget.AddPair('minimum', TJSONNumber.Create(JSONSchemaMinimumAttribute(lAttr).Value))
    else if lAttr is JSONSchemaMaximumAttribute then
      pTarget.AddPair('maximum', TJSONNumber.Create(JSONSchemaMaximumAttribute(lAttr).Value))
    else if lAttr is JSONSchemaMinLengthAttribute then
      pTarget.AddPair('minLength', TJSONNumber.Create(JSONSchemaMinLengthAttribute(lAttr).Value))
    else if lAttr is JSONSchemaMaxLengthAttribute then
      pTarget.AddPair('maxLength', TJSONNumber.Create(JSONSchemaMaxLengthAttribute(lAttr).Value))
    else if lAttr is JSONSchemaPatternAttribute then
      pTarget.AddPair('pattern', JSONSchemaPatternAttribute(lAttr).Value)
    else if lAttr is JSONSchemaFormatAttribute then
      pTarget.AddPair('format', JSONSchemaFormatAttribute(lAttr).Value)
    else if lAttr is JSONSchemaEnumNamesAttribute then
    begin
      // Override default enum or add names
      lEnumArray := TJSONArray.Create;
      for lName in JSONSchemaEnumNamesAttribute(lAttr).Value.Split([',']) do
        lEnumArray.Add(Trim(lName));
      
      // Remove previous enum list if present and add new one
      pTarget.RemovePair('enum').Free;
      pTarget.AddPair('enum', lEnumArray);
    end;
  end;
end;

end.
