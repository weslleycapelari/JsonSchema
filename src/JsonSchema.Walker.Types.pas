unit JsonSchema.Walker.Types;

interface

type
  /// <summary>
  ///   Identifies the JSON Schema draft version of a given schema document.
  ///   Used to select the correct visitor when cross-draft $ref resolution is needed.
  /// </summary>
  TDraftVersion = (
    dvUnknown,
    dvDraft6,
    dvDraft7,
    dvDraft2019_09,
    dvDraft2020_12
  );

  /// <summary>
  ///   Helper methods for converting between TDraftVersion and the canonical $schema URI string.
  /// </summary>
  TDraftVersionHelper = record helper for TDraftVersion
    /// <summary>Parses the $schema URI and returns the matching draft version.</summary>
    /// <param name="pSchema">The $schema URI value from a JSON Schema document.</param>
    class function FromSchema(const pSchema: string): TDraftVersion; static;

    /// <summary>Returns the canonical $schema URI for this draft version.</summary>
    function ToSchema: string;
  end;

implementation

uses
  System.SysUtils;

{ TDraftVersionHelper }

class function TDraftVersionHelper.FromSchema(const pSchema: string): TDraftVersion;
var
  lSchema: string;
begin
  lSchema := LowerCase(Trim(pSchema));
  if lSchema.EndsWith('#') then
    lSchema := lSchema.Substring(0, lSchema.Length - 1);
  if lSchema.EndsWith('/') then
    lSchema := lSchema.Substring(0, lSchema.Length - 1);

  if (lSchema = 'https://json-schema.org/draft-06/schema') or
    (lSchema = 'http://json-schema.org/draft-06/schema') then
  begin
    Result := TDraftVersion.dvDraft6;
  end else if (lSchema = 'https://json-schema.org/draft-07/schema') or
    (lSchema = 'http://json-schema.org/draft-07/schema') then
  begin
    Result := TDraftVersion.dvDraft7;
  end else if (lSchema = 'https://json-schema.org/draft/2019-09/schema') or
    (lSchema = 'http://json-schema.org/draft/2019-09/schema') then
  begin
    Result := TDraftVersion.dvDraft2019_09;
  end else if (lSchema = 'https://json-schema.org/draft/2020-12/schema') or
    (lSchema = 'http://json-schema.org/draft/2020-12/schema') then
  begin
    Result := TDraftVersion.dvDraft2020_12;
  end else
  begin
    Result := TDraftVersion.dvUnknown;
  end;
end;

function TDraftVersionHelper.ToSchema: string;
begin
  case Self of
    dvUnknown:
      Result := '';
    dvDraft6:
      Result := 'https://json-schema.org/draft-06/schema';
    dvDraft7:
      Result := 'https://json-schema.org/draft-07/schema';
    dvDraft2019_09:
      Result := 'https://json-schema.org/draft/2019-09/schema';
    dvDraft2020_12:
      Result := 'https://json-schema.org/draft/2020-12/schema';
  end;
end;

end.
