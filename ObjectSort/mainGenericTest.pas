unit mainGenericTest;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TfmMainTest = class(TForm)
    Memo1: TMemo;
    Button3: TButton;
    Panel1: TPanel;
    Button4: TButton;
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  public
  end;

var
  fmMainTest: TfmMainTest;

implementation

{$R *.dfm}

Uses
  AllObjects, SortMethods, AppliedObjectList,
  System.Generics.Defaults;

procedure TfmMainTest.Button3Click(Sender: TObject);
var
  // объявляем переменную типа TAppliedObjectList<TVector2D>
  // указываем, что список будет хранить объекты типа TVector2D
  MyClass: TAppliedObjectList<TVector2D>;
  // вспомогательная переменная типа TVector2D
  v: TVector2D;
  i: Integer;
begin
  Memo1.Clear;
  try
    // создаем экземпляр нашего класса списка,
    // в качестве метода сравнения будем использовать
    // метод TAllComparison.Compare_TVector2D
    MyClass := TAppliedObjectList<TVector2D>.Create
      (TComparer<TVector2D>.Construct(TAllComparison.Compare_TVector2D));

    try
      // заполняем список объектами типа 2D вектор
      Memo1.Lines.Add('Исходный список:');
      v.Create(10, 21);
      MyClass.Add(v);
      Memo1.Lines.Add(v.ToString);

      v.Create(-10, 20);
      MyClass.Add(v);
      Memo1.Lines.Add(v.ToString);

      v.Create(-10, -2);
      MyClass.Add(v);
      Memo1.Lines.Add(v.ToString);

      v.Create(-1, 7);
      MyClass.Add(v);
      Memo1.Lines.Add(v.ToString);

      // вызываем метод "бычстрой" сортировки
      i := MyClass.SortBy<TVector2D>(TAllSort.QuickSort<TVector2D>);

      // выводим количество перестановок
      Memo1.Lines.Add(sLineBreak + 'Turns: ' + i.ToString);

      // выводим полученный список
      Memo1.Lines.Add('Полученный список:');
      for i := 0 to MyClass.Count - 1 do
      begin
        Memo1.Lines.Add(MyClass.Items[i].ToString);
      end;

    finally
      // не забываем удалить экземпляр, когда закончили с ним работать
      if Assigned(MyClass) then
        MyClass.Free;
    end;
  except
    on E: Exception do
      Memo1.Lines.Add(E.Message);
  end;
end;

procedure TfmMainTest.Button4Click(Sender: TObject);
var
  // объявляем переменную типа TAppliedObjectList<String>
  // указываем, что список будет хранить объекты типа строка
  MyClass: TAppliedObjectList<TAltiumString>;
  i: Integer;
begin
  Memo1.Clear;
  try
    // создаем экземпляр нашего класса,
    // в качестве метода сравнения будем использовать стандартный сравниватель для строк типа IComparer<T>
    MyClass := TAppliedObjectList<TAltiumString>.Create
      (TComparer<TAltiumString>.Construct(TAllComparison.Compare_TAltiumString));

    try
      Memo1.Lines.Text := '10. Мой друг художник и поэт в дождливый вечер на стекле' + sLineBreak +
        '20. Мою любовь нарисовал, открыв мне чудо на земле.' + sLineBreak +
        '11. Сидел я молча у окна и наслаждался тишиной' + sLineBreak +
        '1. Моя любовь с тех пор всегда была со мной.' + sLineBreak +
        '2. И время как вода текло и было мне всегда тепло,' + sLineBreak +
        '3. Когда в дождливый вечер я смотрел в оконное стекло.' + sLineBreak +
        '5. Когда в дождливый вечер я смотрел в оконное стекло.' + sLineBreak +
        '3. Когда в дождливый вечер я смотрел в оконное стекло.' + sLineBreak +
        '4. Когда в дождливый вечер я смотрел в оконное стекло.' + sLineBreak +
        '4. Но год за годом я встречал в глазах любви моей печаль,' + sLineBreak +
        '3333. Дождливой скуки тусклый след и вот, любовь сменила цвет.' + sLineBreak +
        '999. Моя любовь сменила цвет, угас чудесный яркий день' + sLineBreak +
        '666. Моя любовь сменила цвет, угас чудесный яркий день' + sLineBreak +
        '22222. Мою любовь ночная укрывает тень.' + sLineBreak +
        '88. Веселых красок болтовня, игра волшебного огня' + sLineBreak +
        '87. Веселых красок болтовня, игра волшебного огня' + sLineBreak +
        '89. Веселых красок болтовня, игра волшебного огня' + sLineBreak +
        '99. Моя любовь уже не радует меня.';

      // заполняем список строками из Memo
      for i := 0 to Memo1.Lines.Count - 1 do
      begin
        MyClass.Add(TAltiumString.Create(Memo1.Lines[i]));
      end;

      // вызываем метод сортировки QuickSort
      i := MyClass.SortBy<TAltiumString>(TAllSort.QuickSort<TAltiumString>);

      // выводим количество перестановок
      Memo1.Lines.Add(sLineBreak + 'Turns: ' + i.ToString);

      // выводим полученный список
      Memo1.Lines.Add('Полученный список:');
      for i := 0 to MyClass.Count - 1 do
      begin
        Memo1.Lines.Add(MyClass.Items[i].ToString);
      end;
    finally
      // не забываем удалить экземпляр, когда закончили с ним работать
      MyClass.Free;
    end;
  except
    on E: Exception do
      Memo1.Lines.Add(E.Message);
  end;
  Memo1.ScrollBy(0, Memo1.BoundsRect.Height);
end;

end.
