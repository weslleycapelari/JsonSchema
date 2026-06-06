unit SchemaOptimizer.Engine;

(*
--------------------------------------------------------------------------------
Optimization and Simplification engine for JSON Schemas.
Removes unused definitions, flattens allOf constraints, and prunes empty schemas.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections;

type
  /// <summary>Core optimizer settings.</summary>
  TOptimizerOptions = record
    RemoveUnused: Boolean;
    MergeAllOf: Boolean;
    PruneEmpty: Boolean;
    Minify: Boolean;
  end;

  /// <summary>Core optimizer class that simplifies JSON Schemas.</summary>
  TSchemaOptimizer = class
  private
    FOptions: TOptimizerOptions;
    
    // Unused definition pruning
    procedure CollectRefs(pNode: TJSONValue; pRefs: THashSet<string>);
    function PruneUnusedDefs(pRoot: TJSONObject; pRefs: THashSet<string>): Integer;
    function PruneUnusedDefsOnObject(pObj: TJSONObject; const pDefName: string; pRefs: THashSet<string>): Integer;
    function PruneUnusedDefsRecursively(pNode: TJSONValue; pRefs: THashSet<string>): Integer;

    // Node optimization
    procedure OptimizeNode(pNode: TJSONValue);
    
    // allOf flattening and merging
    procedure FlattenAllOf(pObj: TJSONObject);
    procedure MergeAllOfItems(pObj: TJSONObject; pFlatArray, pRemainingArray: TJSONArray);
    function HasConflictBetweenObjects(pObj1, pObj2: TJSONObject): Boolean;
    procedure MergeObjects(pTarget, pSource: TJSONObject);
    procedure MergeRequiredArrays(pTarget, pSource: TJSONArray);
    
    // Pruning and Deduplication
    procedure PruneDuplicatesAndEmpty(pObj: TJSONObject);
    
    // Helper methods
    function IsEmptyObject(pValue: TJSONValue): Boolean;
    function SameJSONValues(pVal1, pVal2: TJSONValue): Boolean;
  public
    /// <summary>Initializes a new instance of the TSchemaOptimizer with specified options.</summary>
    constructor Create(const pOptions: TOptimizerOptions);
    destructor Destroy; override;

    /// <summary>Optimizes the JSON Schema and returns the simplified JSON string.</summary>
    function Optimize(pSchema: TJSONObject; out pBytesSaved: Int64; out pDefsRemoved: Integer): string;
  end;

implementation

{ TSchemaOptimizer }

constructor TSchemaOptimizer.Create(const pOptions: TOptimizerOptions);
begin
  inherited Create;
  FOptions := pOptions;
end;

destructor TSchemaOptimizer.Destroy;
begin
  inherited Destroy;
end;

procedure TSchemaOptimizer.CollectRefs(pNode: TJSONValue; pRefs: THashSet<string>);
var
  lObj: TJSONObject;
  lArr: TJSONArray;
  lPair: TJSONPair;
  lI: Integer;
begin
  if not Assigned(pNode) then
    Exit;

  if pNode is TJSONObject then
  begin
    lObj := TJSONObject(pNode);
    lPair := lObj.Get('$ref');
    if Assigned(lPair) and (lPair.JsonValue is TJSONString) then
    begin
      pRefs.Add(lPair.JsonValue.Value);
    end;

    for lPair in lObj do
    begin
      CollectRefs(lPair.JsonValue, pRefs);
    end;
  end else if pNode is TJSONArray then
  begin
    lArr := TJSONArray(pNode);
    for lI := 0 to lArr.Count - 1 do
    begin
      CollectRefs(lArr.Items[lI], pRefs);
    end;
  end;
end;

function TSchemaOptimizer.PruneUnusedDefs(pRoot: TJSONObject; pRefs: THashSet<string>): Integer;
var
  lRemoved: Integer;
begin
  lRemoved := PruneUnusedDefsOnObject(pRoot, '$defs', pRefs) +
              PruneUnusedDefsOnObject(pRoot, 'definitions', pRefs) +
              PruneUnusedDefsRecursively(pRoot, pRefs);
  Result := lRemoved;
end;

function TSchemaOptimizer.PruneUnusedDefsOnObject(pObj: TJSONObject; const pDefName: string; pRefs: THashSet<string>): Integer;
var
  lDefsVal: TJSONValue;
  lDefsObj: TJSONObject;
  lPair: TJSONPair;
  lKeysToRemove: TList<string>;
  lKey: string;
  lPointer: string;
  lRemoved: Integer;
begin
  lRemoved := 0;
  lDefsVal := pObj.Values[pDefName];
  if Assigned(lDefsVal) and (lDefsVal is TJSONObject) then
  begin
    lDefsObj := TJSONObject(lDefsVal);
    lKeysToRemove := TList<string>.Create;
    try
      for lPair in lDefsObj do
      begin
        lKey := lPair.JsonString.Value;
        lPointer := '#/' + pDefName + '/' + lKey;
        if not pRefs.Contains(lPointer) then
        begin
          lKeysToRemove.Add(lKey);
        end;
      end;

      for lKey in lKeysToRemove do
      begin
        lDefsObj.RemovePair(lKey).Free;
        Inc(lRemoved);
      end;
    finally
      lKeysToRemove.Free;
    end;

    if lDefsObj.Count = 0 then
    begin
      pObj.RemovePair(pDefName).Free;
    end;
  end;
  Result := lRemoved;
end;

function TSchemaOptimizer.PruneUnusedDefsRecursively(pNode: TJSONValue; pRefs: THashSet<string>): Integer;
var
  lObj: TJSONObject;
  lArr: TJSONArray;
  lPair: TJSONPair;
  lI: Integer;
  lRemoved: Integer;
begin
  lRemoved := 0;
  if not Assigned(pNode) then
    Exit(0);

  if pNode is TJSONObject then
  begin
    lObj := TJSONObject(pNode);
    for lPair in lObj do
    begin
      if not (lPair.JsonString.Value = '$defs') and not (lPair.JsonString.Value = 'definitions') then
      begin
        lRemoved := lRemoved + PruneUnusedDefsOnObject(lObj, '$defs', pRefs);
        lRemoved := lRemoved + PruneUnusedDefsOnObject(lObj, 'definitions', pRefs);
        lRemoved := lRemoved + PruneUnusedDefsRecursively(lPair.JsonValue, pRefs);
      end;
    end;
  end else if pNode is TJSONArray then
  begin
    lArr := TJSONArray(pNode);
    for lI := 0 to lArr.Count - 1 do
    begin
      lRemoved := lRemoved + PruneUnusedDefsRecursively(lArr.Items[lI], pRefs);
    end;
  end;
  Result := lRemoved;
end;

procedure TSchemaOptimizer.OptimizeNode(pNode: TJSONValue);
var
  lObj: TJSONObject;
  lArr: TJSONArray;
  lPair: TJSONPair;
  lI: Integer;
  lChildren: TList<TJSONValue>;
begin
  if not Assigned(pNode) then
    Exit;

  if pNode is TJSONObject then
  begin
    lObj := TJSONObject(pNode);

    if FOptions.MergeAllOf then
    begin
      FlattenAllOf(lObj);
    end;

    if FOptions.PruneEmpty then
    begin
      PruneDuplicatesAndEmpty(lObj);
    end;

    lChildren := TList<TJSONValue>.Create;
    try
      for lPair in lObj do
      begin
        lChildren.Add(lPair.JsonValue);
      end;
      for lI := 0 to lChildren.Count - 1 do
      begin
        OptimizeNode(lChildren[lI]);
      end;
    finally
      lChildren.Free;
    end;
  end else if pNode is TJSONArray then
  begin
    lArr := TJSONArray(pNode);
    for lI := 0 to lArr.Count - 1 do
    begin
      OptimizeNode(lArr.Items[lI]);
    end;
  end;
end;

procedure TSchemaOptimizer.FlattenAllOf(pObj: TJSONObject);
var
  lAllOfVal: TJSONValue;
  lAllOfArray: TJSONArray;
  lFlatArray: TJSONArray;
  lItem: TJSONValue;
  lSubItem: TJSONValue;
  lNestedAllOf: TJSONArray;
  lI, lJ: Integer;
  lNewAllOf: TJSONArray;
begin
  lAllOfVal := pObj.Values['allOf'];
  if not Assigned(lAllOfVal) or not (lAllOfVal is TJSONArray) then
    Exit;

  lAllOfArray := TJSONArray(lAllOfVal);
  lFlatArray := TJSONArray.Create;
  try
    for lI := 0 to lAllOfArray.Count - 1 do
    begin
      lItem := lAllOfArray.Items[lI];
      if (lItem is TJSONObject) and Assigned(TJSONObject(lItem).Values['allOf']) and (TJSONObject(lItem).Values['allOf'] is TJSONArray) then
      begin
        lNestedAllOf := TJSONArray(TJSONObject(lItem).Values['allOf']);
        for lJ := 0 to lNestedAllOf.Count - 1 do
        begin
          lFlatArray.AddElement(lNestedAllOf.Items[lJ].Clone as TJSONValue);
        end;

        if TJSONObject(lItem).Count > 1 then
        begin
          lSubItem := lItem.Clone as TJSONValue;
          TJSONObject(lSubItem).RemovePair('allOf').Free;
          if TJSONObject(lSubItem).Count > 0 then
            lFlatArray.AddElement(lSubItem)
          else
            lSubItem.Free;
        end;
      end
      else
      begin
        lFlatArray.AddElement(lItem.Clone as TJSONValue);
      end;
    end;

    lNewAllOf := TJSONArray.Create;
    try
      MergeAllOfItems(pObj, lFlatArray, lNewAllOf);

      pObj.RemovePair('allOf').Free;
      if lNewAllOf.Count > 0 then
      begin
        pObj.AddPair('allOf', lNewAllOf.Clone as TJSONValue);
      end;
    finally
      lNewAllOf.Free;
    end;
  finally
    lFlatArray.Free;
  end;
end;

procedure TSchemaOptimizer.MergeAllOfItems(pObj: TJSONObject; pFlatArray, pRemainingArray: TJSONArray);
var
  lI: Integer;
  lItem: TJSONValue;
  lItemObj: TJSONObject;
  lPair: TJSONPair;
  lKey: string;
  lParentVal: TJSONValue;
  lCanMerge: Boolean;
begin
  for lI := 0 to pFlatArray.Count - 1 do
  begin
    lItem := pFlatArray.Items[lI];

    if not IsEmptyObject(lItem) then
    begin
      if lItem is TJSONObject then
      begin
        lItemObj := TJSONObject(lItem);
        lCanMerge := True;

        for lPair in lItemObj do
        begin
          if lCanMerge then
          begin
            lKey := lPair.JsonString.Value;
            lParentVal := pObj.Values[lKey];
            if Assigned(lParentVal) then
            begin
              if (lParentVal is TJSONObject) and (lPair.JsonValue is TJSONObject) then
              begin
                if HasConflictBetweenObjects(TJSONObject(lParentVal), TJSONObject(lPair.JsonValue)) then
                  lCanMerge := False;
              end
              else if (lParentVal is TJSONArray) and (lPair.JsonValue is TJSONArray) then
              begin
                if not (lKey = 'required') then
                begin
                  if not SameJSONValues(lParentVal, lPair.JsonValue) then
                    lCanMerge := False;
                end;
              end
              else
              begin
                if not SameJSONValues(lParentVal, lPair.JsonValue) then
                  lCanMerge := False;
              end;
            end;
          end;
        end;

        if lCanMerge then
        begin
          for lPair in lItemObj do
          begin
            lKey := lPair.JsonString.Value;
            lParentVal := pObj.Values[lKey];
            if Assigned(lParentVal) then
            begin
              if (lParentVal is TJSONObject) and (lPair.JsonValue is TJSONObject) then
              begin
                MergeObjects(TJSONObject(lParentVal), TJSONObject(lPair.JsonValue));
              end
              else if (lParentVal is TJSONArray) and (lPair.JsonValue is TJSONArray) and (lKey = 'required') then
              begin
                MergeRequiredArrays(TJSONArray(lParentVal), TJSONArray(lPair.JsonValue));
              end;
            end
            else
            begin
              pObj.AddPair(lKey, lPair.JsonValue.Clone as TJSONValue);
            end;
          end;
        end
        else
        begin
          pRemainingArray.AddElement(lItem.Clone as TJSONValue);
        end;
      end
      else
      begin
        pRemainingArray.AddElement(lItem.Clone as TJSONValue);
      end;
    end;
  end;
end;

function TSchemaOptimizer.HasConflictBetweenObjects(pObj1, pObj2: TJSONObject): Boolean;
var
  lPair: TJSONPair;
  lVal1, lVal2: TJSONValue;
  lKey: string;
  lConflict: Boolean;
begin
  lConflict := False;
  for lPair in pObj2 do
  begin
    if not lConflict then
    begin
      lKey := lPair.JsonString.Value;
      lVal1 := pObj1.Values[lKey];
      lVal2 := lPair.JsonValue;
      if Assigned(lVal1) then
      begin
        if (lVal1 is TJSONObject) and (lVal2 is TJSONObject) then
        begin
          if HasConflictBetweenObjects(TJSONObject(lVal1), TJSONObject(lVal2)) then
            lConflict := True;
        end
        else if (lVal1 is TJSONArray) and (lVal2 is TJSONArray) then
        begin
          if not SameJSONValues(lVal1, lVal2) then
            lConflict := True;
        end
        else
        begin
          if not SameJSONValues(lVal1, lVal2) then
            lConflict := True;
        end;
      end;
    end;
  end;
  Result := lConflict;
end;

procedure TSchemaOptimizer.MergeObjects(pTarget, pSource: TJSONObject);
var
  lPair: TJSONPair;
  lKey: string;
  lTargetVal: TJSONValue;
begin
  for lPair in pSource do
  begin
    lKey := lPair.JsonString.Value;
    lTargetVal := pTarget.Values[lKey];
    if Assigned(lTargetVal) then
    begin
      if (lTargetVal is TJSONObject) and (lPair.JsonValue is TJSONObject) then
      begin
        MergeObjects(TJSONObject(lTargetVal), TJSONObject(lPair.JsonValue));
      end;
    end
    else
    begin
      pTarget.AddPair(lKey, lPair.JsonValue.Clone as TJSONValue);
    end;
  end;
end;

procedure TSchemaOptimizer.MergeRequiredArrays(pTarget, pSource: TJSONArray);
var
  lI, lJ: Integer;
  lItem: TJSONValue;
  lFound: Boolean;
begin
  for lI := 0 to pSource.Count - 1 do
  begin
    lItem := pSource.Items[lI];
    lFound := False;
    lJ := 0;
    while (lJ < pTarget.Count) and not lFound do
    begin
      if pTarget.Items[lJ].Value = lItem.Value then
      begin
        lFound := True;
      end;
      Inc(lJ);
    end;

    if not lFound then
    begin
      pTarget.AddElement(lItem.Clone as TJSONValue);
    end;
  end;
end;

procedure TSchemaOptimizer.PruneDuplicatesAndEmpty(pObj: TJSONObject);
var
  lArraysToClean: TArray<string>;
  lArrayName: string;
  lVal: TJSONValue;
  lArr: TJSONArray;
  lNewArr: TJSONArray;
  lI, lJ: Integer;
  lItem: TJSONValue;
  lIsDup: Boolean;
begin
  lArraysToClean := TArray<string>.Create('allOf', 'anyOf', 'oneOf');
  for lArrayName in lArraysToClean do
  begin
    lVal := pObj.Values[lArrayName];
    if Assigned(lVal) and (lVal is TJSONArray) then
    begin
      lArr := TJSONArray(lVal);
      lNewArr := TJSONArray.Create;
      try
        for lI := 0 to lArr.Count - 1 do
        begin
          lItem := lArr.Items[lI];

          if not ((lArrayName = 'allOf') and IsEmptyObject(lItem)) then
          begin
            lIsDup := False;
            lJ := 0;
            while (lJ < lNewArr.Count) and not lIsDup do
            begin
              if SameJSONValues(lNewArr.Items[lJ], lItem) then
              begin
                lIsDup := True;
              end;
              Inc(lJ);
            end;

            if not lIsDup then
            begin
              lNewArr.AddElement(lItem.Clone as TJSONValue);
            end;
          end;
        end;

        pObj.RemovePair(lArrayName).Free;
        if lNewArr.Count > 0 then
        begin
          pObj.AddPair(lArrayName, lNewArr.Clone as TJSONValue);
        end;
      finally
        lNewArr.Free;
      end;
    end;
  end;

  lVal := pObj.Values['type'];
  if Assigned(lVal) and (lVal is TJSONArray) then
  begin
    lArr := TJSONArray(lVal);
    lNewArr := TJSONArray.Create;
    try
      for lI := 0 to lArr.Count - 1 do
      begin
        lItem := lArr.Items[lI];
        lIsDup := False;
        lJ := 0;
        while (lJ < lNewArr.Count) and not lIsDup do
        begin
          if lNewArr.Items[lJ].Value = lItem.Value then
          begin
            lIsDup := True;
          end;
          Inc(lJ);
        end;

        if not lIsDup then
          lNewArr.AddElement(lItem.Clone as TJSONValue);
      end;

      pObj.RemovePair('type').Free;
      if lNewArr.Count = 1 then
      begin
        pObj.AddPair('type', lNewArr.Items[0].Clone as TJSONValue);
      end
      else if lNewArr.Count > 1 then
      begin
        pObj.AddPair('type', lNewArr.Clone as TJSONValue);
      end;
    finally
      lNewArr.Free;
    end;
  end;
end;

function TSchemaOptimizer.IsEmptyObject(pValue: TJSONValue): Boolean;
begin
  Result := Assigned(pValue) and (pValue is TJSONObject) and (TJSONObject(pValue).Count = 0);
end;

function TSchemaOptimizer.SameJSONValues(pVal1, pVal2: TJSONValue): Boolean;
begin
  if not Assigned(pVal1) or not Assigned(pVal2) then
    Exit(pVal1 = pVal2);
  Result := pVal1.ToString = pVal2.ToString;
end;

function TSchemaOptimizer.Optimize(pSchema: TJSONObject; out pBytesSaved: Int64; out pDefsRemoved: Integer): string;
var
  lOriginalSize: Int64;
  lOptimizedSize: Int64;
  lOriginalStr: string;
  lOptimizedStr: string;
  lRefs: THashSet<string>;
  lRemovedCount: Integer;
  lPassRemoved: Integer;
  lReordered: TJSONObject;
  lPair: TJSONPair;
  lKey: string;
  lVal: TJSONValue;
  lTopKeys: TArray<string>;
  lTopKey: string;
begin
  pBytesSaved := 0;
  pDefsRemoved := 0;
  if not Assigned(pSchema) then
    Exit('');

  lOriginalStr := pSchema.ToString;
  lOriginalSize := Length(lOriginalStr);

  if FOptions.MergeAllOf or FOptions.PruneEmpty then
  begin
    OptimizeNode(pSchema);
  end;

  if FOptions.RemoveUnused then
  begin
    lRemovedCount := 0;
    repeat
      lRefs := THashSet<string>.Create;
      try
        CollectRefs(pSchema, lRefs);
        lPassRemoved := PruneUnusedDefs(pSchema, lRefs);
        Inc(lRemovedCount, lPassRemoved);
      finally
        lRefs.Free;
      end;
    until lPassRemoved = 0;
    pDefsRemoved := lRemovedCount;
  end;

  lReordered := TJSONObject.Create;
  try
    lTopKeys := TArray<string>.Create('$schema', '$id', 'title', 'description', 'type');

    for lTopKey in lTopKeys do
    begin
      lVal := pSchema.Values[lTopKey];
      if Assigned(lVal) then
      begin
        lReordered.AddPair(lTopKey, lVal.Clone as TJSONValue);
      end;
    end;

    for lPair in pSchema do
    begin
      lKey := lPair.JsonString.Value;
      if not (lKey = '$schema') and not (lKey = '$id') and not (lKey = 'title') and not (lKey = 'description') and not (lKey = 'type') then
      begin
        lReordered.AddPair(lKey, lPair.JsonValue.Clone as TJSONValue);
      end;
    end;

    if FOptions.Minify then
      lOptimizedStr := lReordered.ToString
    else
      lOptimizedStr := lReordered.Format(2);
  finally
    lReordered.Free;
  end;

  lOptimizedSize := Length(lOptimizedStr);
  pBytesSaved := lOriginalSize - lOptimizedSize;
  if pBytesSaved < 0 then
    pBytesSaved := 0;

  Result := lOptimizedStr;
end;

end.
