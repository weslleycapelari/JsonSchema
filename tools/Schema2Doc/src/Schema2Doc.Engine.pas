unit Schema2Doc.Engine;

(*
--------------------------------------------------------------------------------
Schema2Doc Engine - Translates JSON Schema into Markdown or HTML.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections;

type
  /// <summary>Supported documentation output formats.</summary>
  TDocFormat = (dfMarkdown, dfHTML);

  /// <summary>Options configuration for the Schema2Doc generator.</summary>
  TSchema2DocOptions = record
    Format: TDocFormat;
    TitleOverride: string;
  end;

  /// <summary>Inference engine converting JSON Schema into structured documentation.</summary>
  TSchema2DocGenerator = class
  private
    FOptions: TSchema2DocOptions;

    function DescribeType(pProp: TJSONValue): string;
    function DescribeRequired(pSchema: TJSONObject; const pPropName: string): string;
    function DescribeDefault(pProp: TJSONValue): string;
    function DescribeDescription(pProp: TJSONValue): string;

    // Markdown builders
    procedure BuildMarkdownTable(pObj: TJSONObject; pBuilder: TStringBuilder; const pSectionPrefix: string);
    function GenerateMarkdown(pSchema: TJSONObject): string;

    // HTML builders
    procedure BuildHTMLTable(pObj: TJSONObject; pBuilder: TStringBuilder; const pSectionPrefix: string);
    function GenerateHTML(pSchema: TJSONObject): string;
  public
    constructor Create;

    /// <summary>Generates the complete documentation contents based on configured options.</summary>
    function GenerateDoc(pSchema: TJSONObject): string;

    property Options: TSchema2DocOptions read FOptions write FOptions;
  end;

implementation

{ TSchema2DocGenerator }

constructor TSchema2DocGenerator.Create;
begin
  inherited Create;
  FOptions.Format := dfMarkdown;
  FOptions.TitleOverride := '';
end;

function TSchema2DocGenerator.DescribeType(pProp: TJSONValue): string;
var
  lTypeVal: TJSONValue;
  lArr: TJSONArray;
  lItem: TJSONValue;
  lItemsList: TStringList;
begin
  Result := 'any';
  if not Assigned(pProp) then
    Exit;

  if pProp is TJSONObject then
  begin
    lTypeVal := TJSONObject(pProp).Values['type'];
    if Assigned(lTypeVal) then
    begin
      if lTypeVal is TJSONArray then
      begin
        lArr := TJSONArray(lTypeVal);
        lItemsList := TStringList.Create;
        try
          for lItem in lArr do
            lItemsList.Add(lItem.Value);
          Result := string.Join(', ', lItemsList.ToStringArray);
        finally
          lItemsList.Free;
        end;
      end
      else
        Result := lTypeVal.Value;
    end
    else if Assigned(TJSONObject(pProp).Values['$ref']) then
      Result := 'reference (' + TJSONObject(pProp).Values['$ref'].Value + ')'
    else if Assigned(TJSONObject(pProp).Values['properties']) then
      Result := 'object'
    else if Assigned(TJSONObject(pProp).Values['items']) then
      Result := 'array';
  end
  else
    Result := pProp.Value;
end;

function TSchema2DocGenerator.DescribeRequired(pSchema: TJSONObject; const pPropName: string): string;
var
  lReqVal: TJSONValue;
  lArr: TJSONArray;
  lItem: TJSONValue;
begin
  Result := 'No';
  if not Assigned(pSchema) or (pPropName = '') then
    Exit;

  lReqVal := pSchema.Values['required'];
  if Assigned(lReqVal) and (lReqVal is TJSONArray) then
  begin
    lArr := TJSONArray(lReqVal);
    for lItem in lArr do
    begin
      if SameText(lItem.Value, pPropName) then
        Exit('Yes');
    end;
  end;
end;

function TSchema2DocGenerator.DescribeDefault(pProp: TJSONValue): string;
var
  lDefVal: TJSONValue;
begin
  Result := '-';
  if not Assigned(pProp) or not (pProp is TJSONObject) then
    Exit;

  lDefVal := TJSONObject(pProp).Values['default'];
  if Assigned(lDefVal) then
    Result := lDefVal.ToString;
end;

function TSchema2DocGenerator.DescribeDescription(pProp: TJSONValue): string;
var
  lDescVal: TJSONValue;
begin
  Result := '';
  if not Assigned(pProp) or not (pProp is TJSONObject) then
    Exit;

  lDescVal := TJSONObject(pProp).Values['description'];
  if Assigned(lDescVal) then
    Result := lDescVal.Value;
end;

procedure TSchema2DocGenerator.BuildMarkdownTable(pObj: TJSONObject; pBuilder: TStringBuilder; const pSectionPrefix: string);
var
  lPropsVal: TJSONValue;
  lPropsObj: TJSONObject;
  lPair: TJSONPair;
  lPropName: string;
  lPropVal: TJSONValue;
  lTypeStr, lReqStr, lFormatStr, lDefaultStr, lDescStr: string;
  lNestedObjs: TList<TJSONPair>;
  lNestedPair: TJSONPair;
begin
  if not Assigned(pObj) then
    Exit;

  lPropsVal := pObj.Values['properties'];
  if not Assigned(lPropsVal) or not (lPropsVal is TJSONObject) then
    Exit;

  lPropsObj := TJSONObject(lPropsVal);
  lNestedObjs := TList<TJSONPair>.Create;
  try
    pBuilder.AppendLine('| Property | Type | Required | Format | Default | Description |');
    pBuilder.AppendLine('| -------- | ---- | -------- | ------ | ------- | ----------- |');

    for lPair in lPropsObj do
    begin
      lPropName := lPair.JsonString.Value;
      lPropVal := lPair.JsonValue;

      lTypeStr := DescribeType(lPropVal);
      lReqStr := DescribeRequired(pObj, lPropName);

      lFormatStr := '-';
      if (lPropVal is TJSONObject) and Assigned(TJSONObject(lPropVal).Values['format']) then
        lFormatStr := TJSONObject(lPropVal).Values['format'].Value;

      lDefaultStr := DescribeDefault(lPropVal);
      lDescStr := DescribeDescription(lPropVal);
      if lDescStr = '' then
        lDescStr := 'No description provided.';

      pBuilder.AppendLine(Format('| **%s** | `%s` | %s | %s | %s | %s |', [
        lPropName, lTypeStr, lReqStr, lFormatStr, lDefaultStr, lDescStr
      ]));

      // Queue nested objects for separate sections
      if (lPropVal is TJSONObject) and Assigned(TJSONObject(lPropVal).Values['properties']) then
        lNestedObjs.Add(lPair);
    end;

    pBuilder.AppendLine;

    // Render nested objects recursively
    for lNestedPair in lNestedObjs do
    begin
      pBuilder.AppendLine(Format('### %s%s Properties', [pSectionPrefix, lNestedPair.JsonString.Value]));
      pBuilder.AppendLine;
      BuildMarkdownTable(TJSONObject(lNestedPair.JsonValue), pBuilder, pSectionPrefix + lNestedPair.JsonString.Value + '.');
    end;

  finally
    lNestedObjs.Free;
  end;
end;

function TSchema2DocGenerator.GenerateMarkdown(pSchema: TJSONObject): string;
var
  lBuilder: TStringBuilder;
  lTitle: string;
  lDesc: string;
begin
  lBuilder := TStringBuilder.Create;
  try
    lTitle := FOptions.TitleOverride;
    if lTitle = '' then
    begin
      if Assigned(pSchema.Values['title']) then
        lTitle := pSchema.Values['title'].Value
      else
        lTitle := 'JSON Schema Documentation';
    end;

    lBuilder.AppendLine('# ' + lTitle);
    lBuilder.AppendLine;

    if Assigned(pSchema.Values['description']) then
    begin
      lDesc := pSchema.Values['description'].Value;
      lBuilder.AppendLine(lDesc);
      lBuilder.AppendLine;
    end;

    lBuilder.AppendLine('## Schema Structure');
    lBuilder.AppendLine;

    BuildMarkdownTable(pSchema, lBuilder, '');

    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

procedure TSchema2DocGenerator.BuildHTMLTable(pObj: TJSONObject; pBuilder: TStringBuilder; const pSectionPrefix: string);
var
  lPropsVal: TJSONValue;
  lPropsObj: TJSONObject;
  lPair: TJSONPair;
  lPropName: string;
  lPropVal: TJSONValue;
  lTypeStr, lReqStr, lFormatStr, lDefaultStr, lDescStr: string;
  lNestedObjs: TList<TJSONPair>;
  lNestedPair: TJSONPair;
  lBadgeClass: string;
begin
  if not Assigned(pObj) then
    Exit;

  lPropsVal := pObj.Values['properties'];
  if not Assigned(lPropsVal) or not (lPropsVal is TJSONObject) then
    Exit;

  lPropsObj := TJSONObject(lPropsVal);
  lNestedObjs := TList<TJSONPair>.Create;
  try
    pBuilder.AppendLine('<table>');
    pBuilder.AppendLine('  <thead>');
    pBuilder.AppendLine('    <tr>');
    pBuilder.AppendLine('      <th>Property</th>');
    pBuilder.AppendLine('      <th>Type</th>');
    pBuilder.AppendLine('      <th>Required</th>');
    pBuilder.AppendLine('      <th>Format</th>');
    pBuilder.AppendLine('      <th>Default</th>');
    pBuilder.AppendLine('      <th>Description</th>');
    pBuilder.AppendLine('    </tr>');
    pBuilder.AppendLine('  </thead>');
    pBuilder.AppendLine('  <tbody>');

    for lPair in lPropsObj do
    begin
      lPropName := lPair.JsonString.Value;
      lPropVal := lPair.JsonValue;

      lTypeStr := DescribeType(lPropVal);
      lReqStr := DescribeRequired(pObj, lPropName);

      lFormatStr := '-';
      if (lPropVal is TJSONObject) and Assigned(TJSONObject(lPropVal).Values['format']) then
        lFormatStr := TJSONObject(lPropVal).Values['format'].Value;

      lDefaultStr := DescribeDefault(lPropVal);
      lDescStr := DescribeDescription(lPropVal);
      if lDescStr = '' then
        lDescStr := 'No description provided.';

      // Determine badge class for nice HTML styling
      lBadgeClass := 'badge-other';
      if SameText(lTypeStr, 'string') then lBadgeClass := 'badge-string'
      else if SameText(lTypeStr, 'integer') or SameText(lTypeStr, 'number') then lBadgeClass := 'badge-number'
      else if SameText(lTypeStr, 'boolean') then lBadgeClass := 'badge-boolean'
      else if SameText(lTypeStr, 'object') then lBadgeClass := 'badge-object'
      else if SameText(lTypeStr, 'array') then lBadgeClass := 'badge-array';

      pBuilder.AppendLine('    <tr>');
      pBuilder.AppendLine(Format('      <td class="prop-name">%s</td>', [lPropName]));
      pBuilder.AppendLine(Format('      <td><span class="badge %s">%s</span></td>', [lBadgeClass, lTypeStr]));
      pBuilder.AppendLine(Format('      <td><span class="req-%s">%s</span></td>', [lReqStr.ToLower, lReqStr]));
      pBuilder.AppendLine(Format('      <td><code>%s</code></td>', [lFormatStr]));
      pBuilder.AppendLine(Format('      <td><code>%s</code></td>', [lDefaultStr]));
      pBuilder.AppendLine(Format('      <td class="prop-desc">%s</td>', [lDescStr]));
      pBuilder.AppendLine('    </tr>');

      if (lPropVal is TJSONObject) and Assigned(TJSONObject(lPropVal).Values['properties']) then
        lNestedObjs.Add(lPair);
    end;

    pBuilder.AppendLine('  </tbody>');
    pBuilder.AppendLine('</table>');
    pBuilder.AppendLine('<br/>');

    // Recursively append child sections
    for lNestedPair in lNestedObjs do
    begin
      pBuilder.AppendLine(Format('<h3>%s%s Properties</h3>', [pSectionPrefix, lNestedPair.JsonString.Value]));
      BuildHTMLTable(TJSONObject(lNestedPair.JsonValue), pBuilder, pSectionPrefix + lNestedPair.JsonString.Value + '.');
    end;

  finally
    lNestedObjs.Free;
  end;
end;

function TSchema2DocGenerator.GenerateHTML(pSchema: TJSONObject): string;
var
  lBuilder: TStringBuilder;
  lTitle: string;
  lDesc: string;
begin
  lBuilder := TStringBuilder.Create;
  try
    lTitle := FOptions.TitleOverride;
    if lTitle = '' then
    begin
      if Assigned(pSchema.Values['title']) then
        lTitle := pSchema.Values['title'].Value
      else
        lTitle := 'JSON Schema Documentation';
    end;

    lDesc := '';
    if Assigned(pSchema.Values['description']) then
      lDesc := pSchema.Values['description'].Value;

    lBuilder.AppendLine('<!DOCTYPE html>');
    lBuilder.AppendLine('<html>');
    lBuilder.AppendLine('<head>');
    lBuilder.AppendLine('  <meta charset="utf-8">');
    lBuilder.AppendLine(Format('  <title>%s</title>', [lTitle]));
    lBuilder.AppendLine('  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">');
    lBuilder.AppendLine('  <style>');
    lBuilder.AppendLine('    body {');
    lBuilder.AppendLine('      font-family: ''Inter'', sans-serif;');
    lBuilder.AppendLine('      background-color: #f8fafc;');
    lBuilder.AppendLine('      color: #1e293b;');
    lBuilder.AppendLine('      margin: 0;');
    lBuilder.AppendLine('      padding: 40px 20px;');
    lBuilder.AppendLine('      line-height: 1.6;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    .container {');
    lBuilder.AppendLine('      max-width: 1000px;');
    lBuilder.AppendLine('      margin: 0 auto;');
    lBuilder.AppendLine('      background: #ffffff;');
    lBuilder.AppendLine('      padding: 40px;');
    lBuilder.AppendLine('      border-radius: 12px;');
    lBuilder.AppendLine('      box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05), 0 2px 4px -2px rgb(0 0 0 / 0.05);');
    lBuilder.AppendLine('      border: 1px solid #e2e8f0;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    h1 {');
    lBuilder.AppendLine('      font-size: 2.25rem;');
    lBuilder.AppendLine('      font-weight: 700;');
    lBuilder.AppendLine('      color: #0f172a;');
    lBuilder.AppendLine('      margin-top: 0;');
    lBuilder.AppendLine('      margin-bottom: 8px;');
    lBuilder.AppendLine('      border-bottom: 2px solid #f1f5f9;');
    lBuilder.AppendLine('      padding-bottom: 16px;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    h2 {');
    lBuilder.AppendLine('      font-size: 1.5rem;');
    lBuilder.AppendLine('      font-weight: 600;');
    lBuilder.AppendLine('      color: #1e293b;');
    lBuilder.AppendLine('      margin-top: 32px;');
    lBuilder.AppendLine('      margin-bottom: 16px;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    h3 {');
    lBuilder.AppendLine('      font-size: 1.15rem;');
    lBuilder.AppendLine('      font-weight: 600;');
    lBuilder.AppendLine('      color: #475569;');
    lBuilder.AppendLine('      margin-top: 24px;');
    lBuilder.AppendLine('      margin-bottom: 12px;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    .description {');
    lBuilder.AppendLine('      font-size: 1.05rem;');
    lBuilder.AppendLine('      color: #475569;');
    lBuilder.AppendLine('      margin-bottom: 32px;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    table {');
    lBuilder.AppendLine('      width: 100%;');
    lBuilder.AppendLine('      border-collapse: collapse;');
    lBuilder.AppendLine('      margin-top: 8px;');
    lBuilder.AppendLine('      font-size: 0.9rem;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    th, td {');
    lBuilder.AppendLine('      padding: 12px 16px;');
    lBuilder.AppendLine('      text-align: left;');
    lBuilder.AppendLine('      border-bottom: 1px solid #f1f5f9;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    th {');
    lBuilder.AppendLine('      background-color: #f8fafc;');
    lBuilder.AppendLine('      font-weight: 600;');
    lBuilder.AppendLine('      color: #475569;');
    lBuilder.AppendLine('      text-transform: uppercase;');
    lBuilder.AppendLine('      font-size: 0.75rem;');
    lBuilder.AppendLine('      letter-spacing: 0.05em;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    tr:hover {');
    lBuilder.AppendLine('      background-color: #fafafa;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    .prop-name {');
    lBuilder.AppendLine('      font-weight: 600;');
    lBuilder.AppendLine('      color: #0f172a;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    .prop-desc {');
    lBuilder.AppendLine('      color: #475569;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    .badge {');
    lBuilder.AppendLine('      display: inline-block;');
    lBuilder.AppendLine('      padding: 2px 8px;');
    lBuilder.AppendLine('      font-size: 0.75rem;');
    lBuilder.AppendLine('      font-weight: 500;');
    lBuilder.AppendLine('      border-radius: 4px;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    .badge-string { background-color: #dbeafe; color: #1e40af; }');
    lBuilder.AppendLine('    .badge-number { background-color: #dcfce7; color: #15803d; }');
    lBuilder.AppendLine('    .badge-boolean { background-color: #fef9c3; color: #854d0e; }');
    lBuilder.AppendLine('    .badge-object { background-color: #f3e8ff; color: #6b21a8; }');
    lBuilder.AppendLine('    .badge-array { background-color: #ffedd5; color: #9a3412; }');
    lBuilder.AppendLine('    .badge-other { background-color: #f1f5f9; color: #334155; }');
    lBuilder.AppendLine('    .req-yes {');
    lBuilder.AppendLine('      color: #dc2626;');
    lBuilder.AppendLine('      font-weight: 600;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    .req-no {');
    lBuilder.AppendLine('      color: #94a3b8;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('    code {');
    lBuilder.AppendLine('      font-family: Consolas, monospace;');
    lBuilder.AppendLine('      background-color: #f1f5f9;');
    lBuilder.AppendLine('      padding: 2px 4px;');
    lBuilder.AppendLine('      border-radius: 4px;');
    lBuilder.AppendLine('      font-size: 0.85rem;');
    lBuilder.AppendLine('    }');
    lBuilder.AppendLine('  </style>');
    lBuilder.AppendLine('</head>');
    lBuilder.AppendLine('<body>');
    lBuilder.AppendLine('  <div class="container">');
    lBuilder.AppendLine(Format('    <h1>%s</h1>', [lTitle]));

    if lDesc <> '' then
      lBuilder.AppendLine(Format('    <div class="description">%s</div>', [lDesc]));

    lBuilder.AppendLine('    <h2>Schema Structure</h2>');

    BuildHTMLTable(pSchema, lBuilder, '');

    lBuilder.AppendLine('  </div>');
    lBuilder.AppendLine('</body>');
    lBuilder.AppendLine('</html>');

    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

function TSchema2DocGenerator.GenerateDoc(pSchema: TJSONObject): string;
begin
  Result := '';
  if not Assigned(pSchema) then
    Exit;

  case FOptions.Format of
    dfMarkdown:
      Result := GenerateMarkdown(pSchema);
    dfHTML:
      Result := GenerateHTML(pSchema);
  end;
end;

end.
