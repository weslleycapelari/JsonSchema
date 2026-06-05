unit SchemaMockGen.Utils;

(*
--------------------------------------------------------------------------------
Utility classes and helpers for file I/O and seeded pseudo-random number generation.
--------------------------------------------------------------------------------
*)

interface

uses
  System.Classes,
  System.SysUtils;

type
  /// <summary>
  ///   Linear Congruential Generator (LCG) for cross-platform, deterministic,
  ///   seeded pseudo-random number generation.
  /// </summary>
  TSeededRandom = class
  strict private
    FState: UInt64;
  public
    /// <summary>Creates a generator with a specific Int64 seed.</summary>
    /// <param name="pSeed">Seed value.</param>
    constructor Create(const pSeed: Int64);

    /// <summary>Generates the next random UInt64 value.</summary>
    function Next64: UInt64;

    /// <summary>Generates a random integer within a range [pMin, pMax] (inclusive).</summary>
    function NextInt(const pMin, pMax: Integer): Integer;

    /// <summary>Generates a random double in the range [0.0, 1.0).</summary>
    function NextDouble: Double;

    /// <summary>Generates a random boolean value.</summary>
    function NextBool: Boolean;

    /// <summary>Selects a random character from a given alphabet string.</summary>
    function NextChar(const pAlphabet: string): Char;
  end;

/// <summary>Reads entire content from a UTF-8 text file.</summary>
function ReadFileContent(const pPath: string): string;

/// <summary>Writes entire content to a UTF-8 text file.</summary>
procedure WriteFileContent(const pPath, pContent: string);

implementation

{ TSeededRandom }

constructor TSeededRandom.Create(const pSeed: Int64);
begin
  inherited Create;
  // If seed is negative/invalid, mix it or use a default
  if pSeed < 0 then
    FState := UInt64(TThread.GetTickCount)
  else
    FState := UInt64(pSeed);
end;

function TSeededRandom.Next64: UInt64;
begin
  {$Q-}
  // Knuth's MMIX LCG parameters
  FState := FState * UInt64(6364136223846793005) + UInt64(1442695040888963407);
  {$Q+}
  Result := FState;
end;

function TSeededRandom.NextInt(const pMin, pMax: Integer): Integer;
var
  lRange: UInt64;
begin
  if pMin >= pMax then
    Exit(pMin);
  lRange := UInt64(pMax - pMin + 1);
  Result := pMin + Integer(Next64 mod lRange);
end;

function TSeededRandom.NextDouble: Double;
begin
  // Scale down a 53-bit fraction
  Result := (Next64 and $1FFFFFFFFFFFFF) / 9007199254740992.0;
end;

function TSeededRandom.NextBool: Boolean;
begin
  Result := (Next64 and 1) <> 0;
end;

function TSeededRandom.NextChar(const pAlphabet: string): Char;
var
  lIndex: Integer;
begin
  if pAlphabet.IsEmpty then
    Exit(#0);
  lIndex := NextInt(1, pAlphabet.Length);
  Result := pAlphabet[lIndex];
end;

{ File Utilities }

function ReadFileContent(const pPath: string): string;
var
  lFile: TStringList;
begin
  lFile := TStringList.Create;
  try
    lFile.LoadFromFile(pPath, TEncoding.UTF8);
    Result := lFile.Text;
  finally
    lFile.Free;
  end;
end;

procedure WriteFileContent(const pPath, pContent: string);
var
  lFile: TStringList;
begin
  lFile := TStringList.Create;
  try
    lFile.Text := pContent;
    lFile.SaveToFile(pPath, TEncoding.UTF8);
  finally
    lFile.Free;
  end;
end;

end.
