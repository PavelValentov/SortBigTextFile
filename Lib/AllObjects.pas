// Модуль описания наших 100 объектов и функций сравнения 100 объектов
unit AllObjects;

interface

Uses
  System.SysUtils, System.Types, System.Generics.Collections,
  System.Generics.Defaults;

const
  MAX_PHRASE_INDEXES_BUFFER_SIZE = 1024 * 1024; // bytes
  // MAX_PHRASE_INDEXES_BUFFER_SIZE = 16 * 1024 * 1024; // bytes

type
  // Описание классов 100 объектов

  // Запись файла для хранения индексов Uint64
  TPhraseFile = Record
    Index: Uint64; // Order of the phrase in a file. First in order, after sorting right order
    Str: String; // String for sorting
    FileName: String; // file name for index cluster
    Sorted: Boolean; // already sorted list
    Clustered: Boolean; // This Index is too large, will be stored in a file
    FileSize: Uint64;
    Indexes: TArray<Uint64>;

    Function ToString: String;
    Function LoadFromFile: Uint64;
    Function SaveToFile: Uint64;
    Function SortFile: Uint64;
    Procedure AddIndex(aIndex: Uint64);
    Procedure Clear;
    Procedure Sort;
  public
    Constructor Create(aStr: String; aIndex: Uint64);
  end;

  TPhraseFileComparer = class(TComparer<TPhraseFile>);

  // Двухмерный вектор
  TVector2D = Record
    X, Y: Integer;

    function ToString: String;
    Constructor Create(X_, Y_: Integer);
  end;

  // Запись, полученная из строки типа "Number. String"
  TAltiumString = Record
    Number: Uint64;
    Str: String;

    function ToString: String;
    Constructor Create(aStr: String);
  end;

  // Запись, полученная из строки типа "Number. String" + Index
  TIndexedAltiumString = Record
    Index: Uint64;
    Number: Uint64;
    Str: String;

    function ToString: String;
    Constructor Create(aStr: String; aIndex: Uint64 = 0);
  end;

  // Описание функций сравнения 100 объектов
  TAllComparison = class
  public
    // TComparison<T> = reference to function(const Left, Right: T): Integer;

    // Правила сравнения 2D векторов
    class function Compare_TVector2D(const V1, V2: TVector2D): Integer;

    // Правила сравнения строк типа "Number. String"
    class function Compare_TAltiumString(const V1, V2: TAltiumString): Integer;

    // Правила сравнения прямоугольников
    class function Compare_TRect(const V1, V2: TRect): Integer;

    // Правила сравнения записей типа файл фраз
    class function Compare_TPhraseFile(const V1, V2: TPhraseFile): Integer;
  end;

implementation

uses
  System.Classes,
  Winapi.Windows;

{ TVector2DComparer }

class function TAllComparison.Compare_TAltiumString(const V1, V2: TAltiumString): Integer;
var
  strRes: Integer;
begin
  try
    strRes := AnsiCompareStr(V1.Str, V2.Str);
    if strRes = 0 then
    begin
      if (V1.Number > V2.Number) then
        Result := 1
      else if (V1.Number < V2.Number) then
        Result := -1
      else
        Result := 0
    end
    else
      Result := strRes;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Error: ' + E.Message));
      Result := 0
    end;
  end;
end;

class function TAllComparison.Compare_TPhraseFile(const V1, V2: TPhraseFile): Integer;
begin
  Result := AnsiCompareStr(V1.Str, V2.Str);
end;

class function TAllComparison.Compare_TRect(const V1, V2: TRect): Integer;
begin
  Result := 0;
end;

class function TAllComparison.Compare_TVector2D(const V1, V2: TVector2D): Integer;
var
  modV1, modV2: extended;
begin
  modV1 := Sqrt(Abs(V1.X * V1.X) + Abs(V1.Y * V1.Y));
  modV2 := Sqrt(Abs(V2.X * V2.X) + Abs(V2.Y * V2.Y));

  Result := Round(modV1 - modV2);
end;

{ TVector2D }

constructor TVector2D.Create(X_, Y_: Integer);
begin
  X := X_;
  Y := Y_;
end;

function TVector2D.ToString: String;
begin
  // координаты вектора и модуль
  Result := '(' + X.ToString + ',' + Y.ToString + ')=' + Trunc(Sqrt(Abs(X * X) + Abs(Y * Y))
    ).ToString;
end;

{ TAltiumString }
// Разбираем строку типа "Number. String"
constructor TAltiumString.Create(aStr: String);
var
  LArr: TArray<string>;
begin
  try
    LArr := aStr.Split(['. ']);
    if (Length(LArr) <> 2) then
      Raise Exception.Create('Wrong source string format');
    Number := StrToUInt64(LArr[0]);
    Str := LArr[1];
  except
    on E: Exception do
    begin
      Number := 0;
      Str := '';
    end;
  end;
end;

// Возвращаем строку типа "Number. String"
function TAltiumString.ToString: String;
begin
  Result := UIntToStr(Number) + '. ' + Str;
end;

{ TIndexedAltiumString }

constructor TIndexedAltiumString.Create(aStr: String; aIndex: Uint64 = 0);
var
  LArr: TArray<string>;
begin
  try
    Index := aIndex;
    LArr := aStr.Split(['. ']);
    if (Length(LArr) <> 2) then
      Raise Exception.Create('Wrong source string format');
    Number := StrToUInt64(LArr[0]);
    Str := LArr[1];
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Error: ' + E.Message));
      Number := 0;
      Str := '';
    end;
  end;
end;

function TIndexedAltiumString.ToString: String;
begin
  Result := UIntToStr(Number) + '. ' + Str;
end;

{ TPhraseFile }

procedure TPhraseFile.AddIndex(aIndex: Uint64);
var
  len: Integer;
begin
  len := Length(Self.Indexes);
  SetLength(Self.Indexes, len + 1);
  Self.Indexes[len] := aIndex;

  if (Length(Self.Indexes) * 8 > MAX_PHRASE_INDEXES_BUFFER_SIZE) then
  begin
    Self.SaveToFile;
  end;
end;

procedure TPhraseFile.Clear;
begin
  SetLength(Indexes, 0);
  if (FileExists(FileName)) then
  begin
    DeleteFile(PWideChar(FileName));
  end;
end;

constructor TPhraseFile.Create(aStr: String; aIndex: Uint64);
begin
  Index := aIndex;
  FileName := aIndex.ToString;
  FileSize := 0;
  Sorted := false;
  Clustered := false;
  Self.Str := aStr;
  Self.Indexes := [];
end;

function TPhraseFile.LoadFromFile: Uint64;
var
  LFS: TFileStream;
begin
  try
    LFS := TFileStream.Create(FileName, fmOpenRead);
    try
      LFS.Seek(0, soFromBeginning);
      SetLength(Self.Indexes, LFS.Size div 8); // UInt64 has 8 bytes
      Result := LFS.Read(Indexes[0], Length(Indexes) * 8);
    finally
      LFS.Free;
    end;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Error: ' + E.Message));
      Result := 0;
    end;
  end;
end;

function TPhraseFile.SaveToFile: Uint64;
var
  LFS: TFileStream;
begin
  try
    if not FileExists(FileName) then
    begin
      LFS := TFileStream.Create(FileName, fmCreate);
      try
      finally
        LFS.Free;
      end;
    end;

    Clustered := true;
    LFS := TFileStream.Create(FileName, fmOpenWrite);
    try
      LFS.Seek(0, soFromEnd);
      // LFS.Seek(LFS.Size, soFromBeginning);
      Result := LFS.Write(Indexes[0], Length(Indexes) * 8);
      // LFS.WriteBuffer(Indexes[0], Length(Indexes) * 8);
      FileSize := LFS.Size;
      SetLength(Indexes, 0);
    finally
      LFS.Free;
    end;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Error: ' + E.Message));
      Result := 0;
    end;
  end;
end;

procedure TPhraseFile.Sort;
begin
  TArray.Sort<Uint64>(Self.Indexes);
  Self.Sorted := true;
end;

function TPhraseFile.SortFile: Uint64;
begin

end;

function TPhraseFile.ToString: String;
begin
  Result := Str;
end;

end.
