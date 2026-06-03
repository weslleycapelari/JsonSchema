unit TestJsonSchema.Utils.DraftResolver;

interface

uses
  System.SysUtils,
  System.StrUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces;

/// <summary>Resolves the folder name for a draft (e.g. 'draft6' for '6' or 'draft6').</summary>
function ResolveDraftFolderName(const pDraft: string): string;

/// <summary>Resolves the TDraftVersion enum from a draft string.</summary>
function ResolveDraftVersion(const pDraft: string): TDraftVersion;

implementation

function ResolveDraftFolderName(const pDraft: string): string;
var
  lValue: string;
begin
  lValue := Trim(LowerCase(pDraft));

  if lValue = '' then
    Result := ''
  else if StartsText('draft', lValue) then
    Result := lValue
  else
    Result := 'draft' + lValue;
end;

function ResolveDraftVersion(const pDraft: string): TDraftVersion;
var
  lValue: string;
begin
  lValue := Trim(LowerCase(pDraft));

  if (lValue = 'draft6') or (lValue = '6') then
    Result := TDraftVersion.dvDraft6
  else if (lValue = 'draft7') or (lValue = '7') then
    Result := TDraftVersion.dvDraft7
  else if (lValue = 'draft2019-09') or (lValue = '2019-09') then
    Result := TDraftVersion.dvDraft2019_09
  else if (lValue = 'draft2020-12') or (lValue = '2020-12') then
    Result := TDraftVersion.dvDraft2020_12
  else
    Result := TDraftVersion.dvUnknown;
end;

end.
