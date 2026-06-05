unit Schema2Delphi.AST;

(*
--------------------------------------------------------------------------------
Defines the Delphi Abstract Syntax Tree (AST) representing Pascal structures
such as units, classes, records, properties, fields, and enums.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  /// <summary>Represents a private backing field within a Delphi class.</summary>
  TDelphiField = class
  public
    Name: string;
    TypeName: string;
    constructor Create(const pName, pTypeName: string);
  end;

  /// <summary>Represents a public property in a Delphi class or record.</summary>
  TDelphiProperty = class
  public
    Name: string;
    TypeName: string;
    BackingField: string;
    Attributes: TStringList;
    constructor Create(const pName, pTypeName, pBackingField: string);
    destructor Destroy; override;
  end;

  /// <summary>Represents a Delphi enumerated type.</summary>
  TDelphiEnum = class
  public
    TypeName: string;
    Members: TStringList;
    constructor Create(const pTypeName: string);
    destructor Destroy; override;
  end;

  /// <summary>Represents a Delphi class or record type definition.</summary>
  TDelphiClass = class
  public
    ClassName: string;
    IsRecord: Boolean;
    Fields: TObjectList<TDelphiField>;
    Properties: TObjectList<TDelphiProperty>;
    ConstructorLines: TStringList;
    DestructorLines: TStringList;
    constructor Create(const pClassName: string; pIsRecord: Boolean);
    destructor Destroy; override;
    function GenerateDeclaration: string;
    function GenerateImplementation: string;
  end;

  /// <summary>Represents a full Delphi unit containing enums, classes and records.</summary>
  TDelphiUnit = class
  public
    UnitName: string;
    CustomUses: string;
    Enums: TObjectList<TDelphiEnum>;
    Classes: TObjectList<TDelphiClass>;
    constructor Create(const pUnitName, pCustomUses: string);
    destructor Destroy; override;
    function GenerateSourceCode: string;
  end;

implementation

{ TDelphiField }

constructor TDelphiField.Create(const pName, pTypeName: string);
begin
  inherited Create;
  Name := pName;
  TypeName := pTypeName;
end;

{ TDelphiProperty }

constructor TDelphiProperty.Create(const pName, pTypeName, pBackingField: string);
begin
  inherited Create;
  Name := pName;
  TypeName := pTypeName;
  BackingField := pBackingField;
  Attributes := TStringList.Create;
end;

destructor TDelphiProperty.Destroy;
begin
  Attributes.Free;
  inherited;
end;

{ TDelphiEnum }

constructor TDelphiEnum.Create(const pTypeName: string);
begin
  inherited Create;
  TypeName := pTypeName;
  Members := TStringList.Create;
end;

destructor TDelphiEnum.Destroy;
begin
  Members.Free;
  inherited;
end;

{ TDelphiClass }

constructor TDelphiClass.Create(const pClassName: string; pIsRecord: Boolean);
begin
  inherited Create;
  ClassName := pClassName;
  IsRecord := pIsRecord;
  Fields := TObjectList<TDelphiField>.Create(True);
  Properties := TObjectList<TDelphiProperty>.Create(True);
  ConstructorLines := TStringList.Create;
  DestructorLines := TStringList.Create;
end;

destructor TDelphiClass.Destroy;
begin
  Fields.Free;
  Properties.Free;
  ConstructorLines.Free;
  DestructorLines.Free;
  inherited;
end;

function TDelphiClass.GenerateDeclaration: string;
var
  lBuilder: TStringBuilder;
  lField: TDelphiField;
  lProp: TDelphiProperty;
  lAttr: string;
begin
  lBuilder := TStringBuilder.Create;
  try
    if IsRecord then
    begin
      lBuilder.AppendLine(Format('  %s = record', [ClassName]));
      for lProp in Properties do
      begin
        for lAttr in lProp.Attributes do
          lBuilder.AppendLine('    ' + lAttr);
        lBuilder.AppendLine(Format('    %s: %s;', [lProp.Name, lProp.TypeName]));
      end;
      lBuilder.AppendLine('  end;');
    end else
    begin
      lBuilder.AppendLine(Format('  %s = class', [ClassName]));
      if Fields.Count > 0 then
      begin
        lBuilder.AppendLine('  strict private');
        for lField in Fields do
        begin
          lBuilder.AppendLine(Format('    %s: %s;', [lField.Name, lField.TypeName]));
        end;
      end;
      if Properties.Count > 0 then
      begin
        lBuilder.AppendLine('  public');
        for lProp in Properties do
        begin
          for lAttr in lProp.Attributes do
            lBuilder.AppendLine('    ' + lAttr);
          lBuilder.AppendLine(Format('    property %s: %s read %s write %s;',
            [lProp.Name, lProp.TypeName, lProp.BackingField, lProp.BackingField]));
        end;
      end;
      if (ConstructorLines.Count > 0) or (DestructorLines.Count > 0) then
      begin
        if Properties.Count = 0 then
          lBuilder.AppendLine('  public');
        if ConstructorLines.Count > 0 then
          lBuilder.AppendLine('    constructor Create;');
        if DestructorLines.Count > 0 then
          lBuilder.AppendLine('    destructor Destroy; override;');
      end;
      lBuilder.AppendLine('  end;');
    end;
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

function TDelphiClass.GenerateImplementation: string;
var
  lBuilder: TStringBuilder;
begin
  if IsRecord then
    Exit('');
  lBuilder := TStringBuilder.Create;
  try
    if ConstructorLines.Count > 0 then
    begin
      lBuilder.AppendLine(Format('constructor %s.Create;', [ClassName]));
      lBuilder.AppendLine('begin');
      lBuilder.Append(ConstructorLines.Text);
      lBuilder.AppendLine('end;');
      lBuilder.AppendLine;
    end;
    if DestructorLines.Count > 0 then
    begin
      lBuilder.AppendLine(Format('destructor %s.Destroy;', [ClassName]));
      lBuilder.AppendLine('begin');
      lBuilder.Append(DestructorLines.Text);
      lBuilder.AppendLine('  inherited;');
      lBuilder.AppendLine('end;');
      lBuilder.AppendLine;
    end;
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

{ TDelphiUnit }

constructor TDelphiUnit.Create(const pUnitName, pCustomUses: string);
begin
  inherited Create;
  UnitName := pUnitName;
  CustomUses := pCustomUses;
  Enums := TObjectList<TDelphiEnum>.Create(True);
  Classes := TObjectList<TDelphiClass>.Create(True);
end;

destructor TDelphiUnit.Destroy;
begin
  Enums.Free;
  Classes.Free;
  inherited;
end;

function TDelphiUnit.GenerateSourceCode: string;
var
  lBuilder: TStringBuilder;
  lEnum: TDelphiEnum;
  lClass: TDelphiClass;
  lEnumMember: string;
  lI: Integer;
begin
  lBuilder := TStringBuilder.Create;
  try
    lBuilder.AppendLine('unit ' + UnitName + ';');
    lBuilder.AppendLine;
    lBuilder.AppendLine('interface');
    lBuilder.AppendLine;
    if not CustomUses.IsEmpty then
      lBuilder.AppendLine('uses ' + CustomUses + ';');
    lBuilder.AppendLine;
    lBuilder.AppendLine('type');

    // 1. Forward declarations for classes
    for lClass in Classes do
    begin
      if not lClass.IsRecord then
        lBuilder.AppendLine(Format('  %s = class;', [lClass.ClassName]));
    end;
    if Classes.Count > 0 then
      lBuilder.AppendLine;

    // 2. Enums
    for lEnum in Enums do
    begin
      lBuilder.AppendLine(Format('  %s = (', [lEnum.TypeName]));
      for lI := 0 to lEnum.Members.Count - 1 do
      begin
        lEnumMember := lEnum.Members[lI];
        if lI < lEnum.Members.Count - 1 then
          lBuilder.AppendLine('    ' + lEnumMember + ',')
        else
          lBuilder.AppendLine('    ' + lEnumMember);
      end;
      lBuilder.AppendLine('  );');
      lBuilder.AppendLine;
    end;

    // 3. Class/Record declarations
    if Classes.Count > 0 then
    begin
      if Classes[0].IsRecord then
      begin
        for lI := Classes.Count - 1 downto 0 do
          lBuilder.Append(Classes[lI].GenerateDeclaration);
      end else
      begin
        for lI := 0 to Classes.Count - 1 do
          lBuilder.Append(Classes[lI].GenerateDeclaration);
      end;
    end;

    lBuilder.AppendLine('implementation');
    lBuilder.AppendLine;

    // 4. Implementations
    for lClass in Classes do
    begin
      lBuilder.Append(lClass.GenerateImplementation);
    end;

    lBuilder.AppendLine('end.');
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

end.
