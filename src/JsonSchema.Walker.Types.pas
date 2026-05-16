unit JsonSchema.Walker.Types;

interface

type
  TDraftVersion = (
    dvUnknown,
    dvDraft6,
    dvDraft7,
    dvDraft2019_09,
    dvDraft2020_12
  );

  TDraftVersionHelper = record helper for TDraftVersion
    class function FromSchema(const ASchema: string): TDraftVersion; static;
    function ToSchema: string;
  end;

implementation

uses
  System.SysUtils;

{ TDraftVersionHelper }

class function TDraftVersionHelper.FromSchema(const ASchema: string): TDraftVersion;
var
  LSchema: string;
begin
  LSchema := LowerCase(Trim(ASchema));
  if LSchema.EndsWith('#') then
    LSchema := LSchema.Substring(0, LSchema.Length - 1);
  if LSchema.EndsWith('/') then
    LSchema := LSchema.Substring(0, LSchema.Length - 1);

  if      (LSchema = 'https://json-schema.org/draft-06/schema') or (LSchema = 'http://json-schema.org/draft-06/schema') then Result := TDraftVersion.dvDraft6
  else if (LSchema = 'https://json-schema.org/draft-07/schema') or (LSchema = 'http://json-schema.org/draft-07/schema') then Result := TDraftVersion.dvDraft7
  else if (LSchema = 'https://json-schema.org/draft/2019-09/schema') or (LSchema = 'http://json-schema.org/draft/2019-09/schema') then Result := TDraftVersion.dvDraft2019_09
  else if (LSchema = 'https://json-schema.org/draft/2020-12/schema') then Result := TDraftVersion.dvDraft2020_12
  else                                                                          Result := TDraftVersion.dvUnknown;
end;

function TDraftVersionHelper.ToSchema: string;
begin
  case Self of
    dvUnknown:      Result := '';
    dvDraft6:       Result := 'https://json-schema.org/draft-06/schema';
    dvDraft7:       Result := 'https://json-schema.org/draft-07/schema';
    dvDraft2019_09: Result := 'https://json-schema.org/draft/2019-09/schema';
    dvDraft2020_12: Result := 'https://json-schema.org/draft/2020-12/schema';
  end;
end;

end.
