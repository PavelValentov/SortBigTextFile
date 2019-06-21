// ������ �������� ����� 100 �������� � ������� ��������� 100 ��������
unit AllObjects;

interface

Uses
  System.SysUtils, System.Types, System.Generics.Collections,
  System.Generics.Defaults;

type
  // �������� ������� 100 ��������
  // ���������� ������
  TVector2D = Record
    X, Y: Integer;

    function ToString: String;
    Constructor Create(X_, Y_: Integer);
  end;

  // ������, ���������� �� ������ ���� "Number. String"
  TAltiumString = Record
    Index: UInt64;
    Str: String;

    function ToString: String;
    Constructor Create(aStr: String);
  end;

  // �������� ������� ��������� 100 ��������
  TAllComparison = class
  public
    // TComparison<T> = reference to function(const Left, Right: T): Integer;

    // ������� ��������� 2D ��������
    class function Compare_TVector2D(const V1, V2: TVector2D): Integer;

    // ������� ��������� ����� ���� "Number. String"
    class function Compare_TAltiumString(const V1, V2: TAltiumString): Integer;

    // ������� ��������� ���������������
    class function Compare_TRect(const V1, V2: TRect): Integer;
  end;

implementation

{ TVector2DComparer }

class function TAllComparison.Compare_TAltiumString(const V1, V2: TAltiumString): Integer;
var
  strRes: Integer;
begin
  strRes := AnsiCompareStr(V1.Str, V2.Str);
  if strRes = 0 then
  begin
    if (V1.Index > V2.Index) then
      Result := 1
    else if (V1.Index < V2.Index) then
      Result := -1
    else
      Result := 0
  end
  else
    Result := strRes;
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
  // ���������� ������� � ������
  Result := '(' + X.ToString + ',' + Y.ToString + ')=' + Trunc(Sqrt(Abs(X * X) + Abs(Y * Y))
    ).ToString;
end;

{ TAltiumString }
// ��������� ������ ���� "Number. String"
constructor TAltiumString.Create(aStr: String);
var
  LArr: TArray<string>;
begin
  try
    LArr := aStr.Split(['. ']);
    if (Length(LArr) <> 2) then
      Raise Exception.Create('Wrong source string format');
    Index := StrToUInt64(LArr[0]);
    Str := LArr[1];
  except
    on E: Exception do
    begin
      Index := 0;
      Str := '';
    end;
  end;
end;

// ���������� ������ ���� "Number. String"
function TAltiumString.ToString: String;
begin
  Result := UIntToStr(Index) + '. ' + Str;
end;

end.
