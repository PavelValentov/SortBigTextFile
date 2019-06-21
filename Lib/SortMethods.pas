// Модуль описания наших 100 методов сортировки
unit SortMethods;

interface

Uses
  System.Types, System.Generics.Collections, System.Generics.Defaults;

type
  // Методы сортировки должны быть вида TSorting<T>
  TSorting<T> = reference to function(var Values: array of T;
    const Comparer: IComparer<T>; Index, Count: Integer): Integer;

  // Основной класс, содержит все 100 методов сортировки
  TAllSort = class
  private
    // *** Пирамидальная сортировка вспомогательная процедура
    class function HeapSortSink<T>(var Values: array of T;
      const Comparer: IComparer<T>; Index, Arraylength: Integer): Integer;

  public
    // *** Сортировка пузырьковым методом
    class function BubbleSort<T>(var Values: array of T;
      const Comparer: IComparer<T>; Index, Count: Integer): Integer;

    // *** Быстрая сортировка
    class function QuickSort<T>(var Values: array of T;
      const Comparer: IComparer<T>; Index, Count: Integer): Integer;

    // *** Пирамидальная сортировка
    class function HeapSort<T>(var Values: array of T;
      const Comparer: IComparer<T>; Index, Count: Integer): Integer;
  end;

implementation

// *** Сортировка пузырьковым методом
class function TAllSort.BubbleSort<T>(var Values: array of T;
  const Comparer: IComparer<T>; Index, Count: Integer): Integer;
Var
  N, i, j: Integer;
  temp: T;
Begin
  Result := 0;
  N := Length(Values);
  for i := 0 to N - 1 do
    for j := 1 to N - 1 do
      if Comparer.Compare(Values[j - 1], Values[j]) > 0 then
      begin { Обмен элементов }
        temp := Values[j - 1];
        Values[j - 1] := Values[j];
        Values[j] := temp;

        inc(Result);
      end;
end;

// *** Пирамидальная сортировка
class function TAllSort.HeapSortSink<T>(var Values: array of T;
  const Comparer: IComparer<T>; Index, Arraylength: Integer): Integer;
var
  leftChild, sinkIndex, rightChild, parent: Integer;
  done: boolean;
  Item: T;
begin
  Result := 0;
  sinkIndex := index;
  Item := Values[index];
  done := False;

  while not done do
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

  while not done do
  begin
    parent := Trunc((sinkIndex - 1) / 2);
    if (Comparer.Compare(Values[parent], Values[sinkIndex]) < 0) and
      (parent >= Index) then
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

class function TAllSort.HeapSort<T>(var Values: array of T;
  const Comparer: IComparer<T>; Index, Count: Integer): Integer;
var
  x: Integer;
  b: T;
begin
  Result := 0;

  // first make it a Heap
  for x := Trunc((High(Values) - 1) / 2) downto Low(Values) do
    Result := Result + HeapSortSink<T>(Values, Comparer, x, High(Values));

  // do the ButtomUpHeap sort
  for x := High(Values) downto Low(Values) + 1 do
  begin
    inc(Result);
    b := Values[x];
    Values[x] := Values[Low(Values)];
    Values[Low(Values)] := b;
    Result := Result + HeapSortSink<T>(Values, Comparer, Low(Values), x - 1);
  end;
end;

// *** Быстрая сортировка
class function TAllSort.QuickSort<T>(var Values: array of T;
  const Comparer: IComparer<T>; Index, Count: Integer): Integer;
var
  i, j: Integer;
  pivot, temp: T;
begin
  Result := 0;

  if (Length(Values) = 0) or ((Count - Index) <= 0) then
    Exit;

  repeat
    i := Index;
    j := Count;
    pivot := Values[Index + (Count - Index) shr 1];
    repeat
      while Comparer.Compare(Values[i], pivot) < 0 do
        inc(i);
      while Comparer.Compare(Values[j], pivot) > 0 do
        Dec(j);
      if i <= j then
      begin
        if i <> j then
        begin
          temp := Values[i];
          Values[i] := Values[j];
          Values[j] := temp;

          inc(Result);
        end;
        inc(i);
        Dec(j);
      end;
    until i > j;
    if Index < j then
      Result := Result + QuickSort<T>(Values, Comparer, Index, j);
    Index := i;
  until i >= Count;
end;

end.
