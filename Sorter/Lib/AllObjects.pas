// Модуль описания наших 100 объектов и функций сравнения 100 объектов
unit AllObjects;

interface

Uses
  System.SysUtils, System.Types, System.Generics.Collections,
  System.Generics.Defaults;

type
  // Описание классов 100 объектов
  TVector2D = Record
    X, Y: Integer;

    function ToString: String;
    Constructor Create(X_, Y_: Integer);
  end;

  // Описание функций сравнения 100 объектов
  TAllComparison = class
  public
    // TComparison<T> = reference to function(const Left, Right: T): Integer;

    // Правила сравнения 2D векторов
    class function Compare_TVector2D(const V1, V2: TVector2D): Integer;

    // Правила сравнения прямоугольников
    class function Compare_TRect(const V1, V2: TRect): Integer;
  end;

implementation

{ TVector2DComparer }

class function TAllComparison.Compare_TRect(const V1, V2: TRect): Integer;
begin
  Result := 0;
end;

class function TAllComparison.Compare_TVector2D(const V1,
  V2: TVector2D): Integer;
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
  Result := '(' + X.ToString + ',' + Y.ToString + ')=' +
    Trunc(Sqrt(Abs(X * X) + Abs(Y * Y))).ToString;
end;

end.
