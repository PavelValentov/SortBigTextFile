// Модуль описания наших 100 методов сортировки
unit SortMethods;

interface

Uses
  System.Types, System.Generics.Collections, System.Generics.Defaults;

type
  TLogEvent = procedure(msg: String) of object;

  // Методы сортировки должны быть вида TSorting<T>
  TSorting<T> = reference to function(var Values: array of T; const Comparer: IComparer<T>;
    Index, Count: Integer): Integer;

  // Основной класс, содержит все 100 методов сортировки
  TAllSort = class
  private
    class var FLastLogTime: cardinal;
    class var FOnLog: TLogEvent;

    class procedure Log(aMsg: string);

    // *** Set the flat to True for stop sorting
    class var FStopFlag: Boolean;

    // *** Пирамидальная сортировка вспомогательная процедура
    class function HeapSortSink<T>(var Values: array of T; const Comparer: IComparer<T>;
      Index, Arraylength: Integer): Integer;

    class procedure Swap<T>(var Values: array of T; aPos1, aPos2: UInt64);
  public
    class procedure Init();
    class procedure Stop();

    class property OnLog: TLogEvent read FOnLog write FOnLog;

    // *** Сортировка пузырьковым методом
    class function BubbleSort<T>(var Values: array of T; const Comparer: IComparer<T>;
      Index, Count: Integer): Integer;

    // *** Быстрая сортировка
    class function QuickSort<T>(var Values: array of T; const Comparer: IComparer<T>;
      Index, Count: Integer): Integer;
    class function QuickSort2<T>(var Values: array of T; const Comparer: IComparer<T>;
      Index, Count: Integer): Integer;

    // *** Пирамидальная сортировка
    class function HeapSort<T>(var Values: array of T; const Comparer: IComparer<T>;
      Index, Count: Integer): Integer;
  end;

implementation

// *** Сортировка пузырьковым методом
class function TAllSort.BubbleSort<T>(var Values: array of T; const Comparer: IComparer<T>;
  Index, Count: Integer): Integer;
Var
  N, i, j: Integer;
  temp: T;
Begin
  Result := 0;
  N := Length(Values);
  for i := 0 to N - 1 do
    for j := 1 to N - 1 do
    begin
      if FStopFlag then
        break;

      if Comparer.Compare(Values[j - 1], Values[j]) > 0 then
      begin { Обмен элементов }
        temp := Values[j - 1];
        Values[j - 1] := Values[j];
        Values[j] := temp;

        inc(Result);
      end;
    end;
end;

// *** Пирамидальная сортировка
class function TAllSort.HeapSortSink<T>(var Values: array of T; const Comparer: IComparer<T>;
  Index, Arraylength: Integer): Integer;
var
  leftChild, sinkIndex, rightChild, parent: Integer;
  done: Boolean;
  Item: T;
begin
  Result := 0;
  sinkIndex := index;
  Item := Values[index];
  done := False;

  while (not done) and (not FStopFlag) do
  begin // search sink-path and move up all items
    leftChild := ((sinkIndex) * 2) + 1;
    rightChild := ((sinkIndex + 1) * 2);

    if rightChild <= Arraylength then
    begin
      if Comparer.Compare(Values[leftChild], Values[rightChild]) < 0 then
      begin
        inc(Result);
        Values[sinkIndex] := Values[rightChild];
        sinkIndex := rightChild;
      end
      else
      begin
        inc(Result);
        Values[sinkIndex] := Values[leftChild];
        sinkIndex := leftChild;
      end;
    end
    else
    begin
      done := True;

      if leftChild <= Arraylength then
      begin
        inc(Result);

        Values[sinkIndex] := Values[leftChild];
        sinkIndex := leftChild;
      end;
    end;
  end;

  // move up current Item
  Values[sinkIndex] := Item;
  done := False;

  while (not done) and (not FStopFlag) do
  begin
    parent := Trunc((sinkIndex - 1) / 2);
    if (Comparer.Compare(Values[parent], Values[sinkIndex]) < 0) and (parent >= Index) then
    begin
      Item := Values[parent];
      Values[parent] := Values[sinkIndex];
      Values[sinkIndex] := Item;
      sinkIndex := parent;
    end
    else
      done := True;
  end;
end;

class procedure TAllSort.Init;
begin
  FStopFlag := False;
end;

class procedure TAllSort.Log(aMsg: string);
begin
  if (Assigned(FOnLog)) then
    FOnLog(aMsg);
end;

class procedure TAllSort.Stop;
begin
  FStopFlag := True;
end;

class procedure TAllSort.Swap<T>(var Values: array of T; aPos1, aPos2: UInt64);
var
  LTemp: T;
begin
  LTemp := Values[aPos1];
  Values[aPos1] := Values[aPos2];
  Values[aPos2] := LTemp;
end;

class function TAllSort.HeapSort<T>(var Values: array of T; const Comparer: IComparer<T>;
  Index, Count: Integer): Integer;
var
  x: Integer;
  b: T;
begin
  Result := 0;

  // first make it a Heap
  for x := Trunc((High(Values) - 1) / 2) downto Low(Values) do
  begin
    if FStopFlag then
      break;

    Result := Result + HeapSortSink<T>(Values, Comparer, x, High(Values));
  end;

  // do the ButtomUpHeap sort
  for x := High(Values) downto Low(Values) + 1 do
  begin
    if FStopFlag then
      break;

    inc(Result);
    b := Values[x];
    Values[x] := Values[Low(Values)];
    Values[Low(Values)] := b;
    Result := Result + HeapSortSink<T>(Values, Comparer, Low(Values), x - 1);
  end;
end;

// *** Быстрая сортировка
class function TAllSort.QuickSort2<T>(var Values: array of T; const Comparer: IComparer<T>;
  Index, Count: Integer): Integer;
var
  LLow, LHigh: Integer;
  pivot, temp: T;
begin
  Result := 0;

  if (Length(Values) = 0) or ((Count - Index) <= 0) then
    Exit;

  LLow := Index;
  LHigh := Count;
  pivot := Values[LLow + (LHigh - LLow) div 2];

  repeat
    if FStopFlag then
      break;

    while Comparer.Compare(Values[LLow], pivot) < 0 do
      inc(LLow);
    while Comparer.Compare(Values[LHigh], pivot) > 0 do
      dec(LHigh);
    if LLow <= LHigh then
    begin
      if LLow <> LHigh then
      begin
        TAllSort.Swap(Values, LLow, LHigh);
        inc(Result);
      end;

      inc(LLow);
      dec(LHigh);
    end;
  until (LLow > LHigh) or (FStopFlag);

  if LHigh > Index then
    Result := Result + QuickSort2(Values, Comparer, Index, LHigh);
  if LLow < Count then
    Result := Result + QuickSort2(Values, Comparer, LLow, Count);

  Log('Sorting...');
end;

class function TAllSort.QuickSort<T>(var Values: array of T; const Comparer: IComparer<T>;
  Index, Count: Integer): Integer;

var
  LLo, LHi: Integer;
  pivot, temp: T;

begin
  Result := 0;

  if (Length(Values) = 0) or ((Count - Index) <= 0) then
    Exit;

  repeat
    if FStopFlag then
      break;

    LLo := Index;
    LHi := Count;
    pivot := Values[Index + (Count - Index) shr 1];
    repeat
      while Comparer.Compare(Values[LLo], pivot) < 0 do
        inc(LLo);
      while Comparer.Compare(Values[LHi], pivot) > 0 do
        dec(LHi);
      if LLo <= LHi then
      begin
        if LLo <> LHi then
        begin
          TAllSort.Swap(Values, LLo, LHi);

          inc(Result);
        end;
        inc(LLo);
        dec(LHi);
      end;
    until (LLo > LHi) or (FStopFlag);
    if Index < LHi then
      Result := Result + QuickSort<T>(Values, Comparer, Index, LHi);
    Index := LLo;
  until (LLo >= Count) or (FStopFlag);
end;

initialization

TAllSort.Init;

end.
