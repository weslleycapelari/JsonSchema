unit JsonSchema.CollectionUtils;

interface

uses
  System.Generics.Collections,
  System.Generics.Defaults;

type
  /// <summary>
  ///   Utility class for efficient collection operations using hash sets.
  ///   Provides methods for merging arrays and adding unique values without
  ///   repetitive allocations.
  /// </summary>
  TCollectionUtils = class
  public
    /// <summary>
    ///   Merges multiple arrays into a single array containing unique values.
    ///   Preserves the order of first occurrence.
    /// </summary>
    /// <typeparam name="T">Type of the array elements.</typeparam>
    /// <param name="pArrays">Array of arrays to merge.</param>
    /// <returns>An array of unique elements from all input arrays.</returns>
    class function MergeUnique<T>(const pArrays: array of TArray<T>): TArray<T>;

    /// <summary>
    ///   Merges multiple arrays into a single array containing unique values,
    ///   using a custom equality comparer.
    /// </summary>
    class function MergeUniqueWithComparer<T>(const pComparer: IEqualityComparer<T>;
      const pArrays: array of TArray<T>): TArray<T>;

    /// <summary>
    ///   Adds a value to a dynamic array if it does not already exist.
    ///   Returns True if the value was added, False if it was already present.
    /// </summary>
    class function AddUnique<T>(var pArray: TArray<T>; const pValue: T;
      const pComparer: IEqualityComparer<T> = nil): Boolean;

    /// <summary>
    ///   Converts a dynamic array to a HashSet for more efficient operations.
    /// </summary>
    class function ToHashSet<T>(const pArray: TArray<T>;
      const pComparer: IEqualityComparer<T> = nil): THashSet<T>;
  end;

implementation

{ TCollectionUtils }

class function TCollectionUtils.MergeUnique<T>(const pArrays: array of TArray<T>): TArray<T>;
begin
  Result := MergeUniqueWithComparer<T>(TEqualityComparer<T>.Default, pArrays);
end;

class function TCollectionUtils.MergeUniqueWithComparer<T>(
  const pComparer: IEqualityComparer<T>;
  const pArrays: array of TArray<T>): TArray<T>;
var
  lHashSet: THashSet<T>;
  lArray: TArray<T>;
  lValue: T;
  lIndex: Integer;
begin
  lHashSet := THashSet<T>.Create(pComparer);
  try
    for lArray in pArrays do
      for lValue in lArray do
        lHashSet.Add(lValue);

    Result := [];
    SetLength(Result, lHashSet.Count);
    lIndex := 0;
    for lValue in lHashSet do
    begin
      Result[lIndex] := lValue;
      Inc(lIndex);
    end;
  finally
    lHashSet.Free;
  end;
end;

class function TCollectionUtils.AddUnique<T>(var pArray: TArray<T>;
  const pValue: T; const pComparer: IEqualityComparer<T>): Boolean;
var
  lLocalComparer: IEqualityComparer<T>;
  lValue: T;
begin
  if pComparer = nil then
    lLocalComparer := TEqualityComparer<T>.Default
  else
    lLocalComparer := pComparer;

  for lValue in pArray do
    if lLocalComparer.Equals(lValue, pValue) then
      Exit(False);

  SetLength(pArray, Length(pArray) + 1);
  pArray[High(pArray)] := pValue;
  Result := True;
end;

class function TCollectionUtils.ToHashSet<T>(const pArray: TArray<T>;
  const pComparer: IEqualityComparer<T>): THashSet<T>;
var
  lValue: T;
begin
  if pComparer = nil then
    Result := THashSet<T>.Create(TEqualityComparer<T>.Default)
  else
    Result := THashSet<T>.Create(pComparer);

  for lValue in pArray do
    Result.Add(lValue);
end;

end.
