unit JsonSchema.CollectionUtils;

interface

uses
  System.Generics.Collections,
  System.Generics.Defaults;

type
  /// <summary>
  ///   Static utilities for efficient operations on collections using hash sets.
  ///   Offers array merging with deduplication and conditional addition without repetitive loop allocations.
  /// </summary>
  /// <remarks>
  ///   All methods are static and do not maintain state. The class does not need to be instantiated. No method is thread-safe on its own;
  ///   external synchronization is the caller's responsibility when necessary.
  ///   The caller is responsible for releasing any object returned by the methods of this class (e.g., <c>ToHashSet</c>).
  /// </remarks>
  TCollectionUtils = class
  public
    /// <summary>
    ///   Merges multiple arrays into a single array containing only unique values,
    ///   using the default equality comparator of <typeparamref name="T"/>.
    /// </summary>
    /// <remarks>
    ///   The order of the elements in the result reflects the internal order of the <c>THashSet</c>
    ///   and is not guaranteed to be the order of first occurrence.
    /// </remarks>
    /// <typeparam name="T">Array element types.</typeparam>
    /// <param name="pArrays">Array of arrays to be merged.</param>
    /// <returns>Array with unique elements derived from all input arrays.</returns>
    class function MergeUnique<T>(const pArrays: array of TArray<T>): TArray<T>; static;

    /// <summary>Merges multiple arrays into a single array containing only unique values, using a custom equality comparator.</summary>
    /// <param name="pComparer">Equality comparator to be used.</param>
    /// <param name="pArrays">Array of arrays to be merged.</param>
    /// <returns>Array with unique elements according to the provided comparator.</returns>
    class function MergeUniqueWithComparer<T>(const pComparer: IEqualityComparer<T>; const pArrays: array of TArray<T>): TArray<T>; static;

    /// <summary>
    ///   Add <paramref name="pValue"/> to <paramref name="pArray"/> only if it is
    ///   not already present, according to the specified comparator.
    /// </summary>
    /// <param name="pArray">Array to be modified (passed by reference).</param>
    /// <param name="pValue">Value to be added, if unique.</param>
    /// <param name="pComparer">Optional equality comparator. When <c>nil</c>, uses the default comparator for the type.</param>
    /// <returns><c>True</c> if the value was added; <c>False</c> if it was already present.</returns>
    class function AddUnique<T>(var pArray: TArray<T>; const pValue: T; const pComparer: IEqualityComparer<T> = nil): Boolean; static;

    /// <summary>
    ///   Converts a dynamic array into a <c>THashSet</c> for searches and
    ///   set operations that are more efficient than linear search.
    /// </summary>
    /// <remarks>
    ///   The caller is responsible for releasing the returned <c>THashSet</c>.
    ///   If an exception occurs during the addition of elements, the object is released
    ///   and the exception is rethrown.
    /// </remarks>
    /// <param name="pArray">Source array.</param>
    /// <param name="pComparer">Optional equality comparator. When <c>nil</c>, uses the default comparator for the type.</param>
    /// <returns>New <c>THashSet</c> containing all the elements of the array.</returns>
    class function ToHashSet<T>(const pArray: TArray<T>; const pComparer: IEqualityComparer<T> = nil): THashSet<T>; static;
  end;

implementation

{ TCollectionUtils }

class function TCollectionUtils.MergeUnique<T>(const pArrays: array of TArray<T>): TArray<T>;
begin
  Result := MergeUniqueWithComparer<T>(TEqualityComparer<T>.Default, pArrays);
end;

class function TCollectionUtils.MergeUniqueWithComparer<T>(const pComparer: IEqualityComparer<T>; const pArrays: array of TArray<T>): TArray<T>;
var
  lHashSet: THashSet<T>;
  lArray: TArray<T>;
  lValue: T;
  lIndex: Integer;
begin
  lHashSet := THashSet<T>.Create(pComparer);
  try
    for lArray in pArrays do
    begin
      for lValue in lArray do
        lHashSet.Add(lValue);
    end;

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

class function TCollectionUtils.AddUnique<T>(var pArray: TArray<T>; const pValue: T; const pComparer: IEqualityComparer<T>): Boolean;
var
  lEffectiveComparer: IEqualityComparer<T>;
  lIndex: Integer;
  lValueExists: Boolean;
begin
  if Assigned(pComparer) then
    lEffectiveComparer := pComparer
  else
    lEffectiveComparer := TEqualityComparer<T>.Default;

  lIndex := 0;
  lValueExists := False;

  // Linear search with double stop condition to avoid using Break.
  while not lValueExists and (lIndex < Length(pArray)) do
  begin
    lValueExists := lEffectiveComparer.Equals(pArray[lIndex], pValue);
    Inc(lIndex);
  end;

  Result := not lValueExists;

  if Result then
  begin
    SetLength(pArray, Length(pArray) + 1);
    pArray[High(pArray)] := pValue;
  end;
end;

class function TCollectionUtils.ToHashSet<T>(const pArray: TArray<T>; const pComparer: IEqualityComparer<T>): THashSet<T>;
var
  lValue: T;
begin
  if Assigned(pComparer) then
    Result := THashSet<T>.Create(pComparer)
  else
    Result := THashSet<T>.Create(TEqualityComparer<T>.Default);

  // Protects against leaks in the event of an exception. Add a bid.
  try
    for lValue in pArray do
      Result.Add(lValue);
  except
    Result.Free;
    raise;
  end;
end;

end.
