// Модуль реализации основного класса работы со списками однотипных объектов
unit AppliedObjectList;

interface

uses
  System.Generics.Collections, // дженерики
  System.Generics.Defaults, // дженерики
  System.SyncObjs; // для критический секций

// Основной класс для работы со списком однотипных объектов
type
  TAppliedObjectList<T> = class(TList<T>)
  private type
    // arrayofT = array of T;
    TSorting<T> = reference to function(var Values: array of T;
      const Comparer: IComparer<T>; Index, Count: Integer): Integer;

  var
    FCS: TCriticalSection;
    FComparer: IComparer<T>;
    Target: Array of T;

  public
    constructor Create; overload;
    constructor Create(const AComparer: IComparer<T>); overload;
    destructor Destroy; override;

    // здесь будем размещать наши публичные методы для оперирования над различными объектами

    // универсальный метод сортировки с указанием нужного метода сравнения
    // возвращает количество перестановок, надеюсь, что их будет меньше MaxInt
    function SortBy<T>(const AProc: TSorting<T>): Integer; overload;
  end;

implementation

constructor TAppliedObjectList<T>.Create;
begin
  inherited Create;

  FCS := TCriticalSection.Create;

  // Вообще,
  // если не предусматривается создание универсального "сравнивателя"
  // для всех nsczx объектов,
  // я бы убрал этот метод
  Create(TComparer<T>.Default);
end;

constructor TAppliedObjectList<T>.Create(const AComparer: IComparer<T>);
begin
  inherited Create(AComparer);

  FCS := TCriticalSection.Create;

  // запоминаем выбранный "сравниватель"
  FComparer := AComparer;
  if FComparer = nil then
    // а если он не указан, то подставляем по-умолчанию,
    // который может не корректно работать с нашим объектом
    FComparer := TComparer<T>.Default;
end;

destructor TAppliedObjectList<T>.Destroy;
begin
  FCS.Enter;
  try
  finally
    FCS.Leave;
  end;
  FCS.Free;

  inherited;
end;

function TAppliedObjectList<T>.SortBy<T>(const AProc: TSorting<T>): Integer;
var
  i: Integer;
begin
  Result := 0;

  // свойство List в классе TList<T> — только для чтения,
  // поэтому переносим список объектов во временный массив для сортировки
  // заключаем в потоконезависимую секцию, чтобы список по ходу переноса не изменился
  FCS.Enter;
  try
    SetLength(Target, Count);

    for i := 0 to Count - 1 do
    begin
      Target[i] := Items[i];
      // Target[i] := Items[i];
    end;

  finally
    FCS.Leave;
  end;

  if (Count < 2) then
    Exit;

  // забыли указать метод сортировки? — сортируем по методом по умолчанию - быстрая сортировка
  if @AProc = nil then
    Sort(FComparer)
  else
    Result := AProc(Target, FComparer, 0, Count - 1);

  // возвращаем список из временного массива
  // заключаем в потоконезависимую секцию, чтобы список по ходу переноса не изменился
  FCS.Enter;
  try
    Self.Clear;
    for i := 0 to Length(Target) - 1 do
    begin
      Add(Target[i]);
    end;

  finally
    FCS.Leave;
  end;

  // обрезаем временный массив
  SetLength(Target, 0);
end;

end.
