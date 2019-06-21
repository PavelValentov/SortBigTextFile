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
  // ��������� ���������� ���� TAppliedObjectList<TVector2D>
  // ���������, ��� ������ ����� ������� ������� ���� TVector2D
  MyClass: TAppliedObjectList<TVector2D>;
  // ��������������� ���������� ���� TVector2D
  v: TVector2D;
  i: Integer;
begin
  Memo1.Clear;
  try
    // ������� ��������� ������ ������ ������,
    // � �������� ������ ��������� ����� ������������
    // ����� TAllComparison.Compare_TVector2D
    MyClass := TAppliedObjectList<TVector2D>.Create
      (TComparer<TVector2D>.Construct(TAllComparison.Compare_TVector2D));

    try
      // ��������� ������ ��������� ���� 2D ������
      Memo1.Lines.Add('�������� ������:');
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

      // �������� ����� "��������" ����������
      i := MyClass.SortBy<TVector2D>(TAllSort.QuickSort<TVector2D>);

      // ������� ���������� ������������
      Memo1.Lines.Add(sLineBreak + 'Turns: ' + i.ToString);

      // ������� ���������� ������
      Memo1.Lines.Add('���������� ������:');
      for i := 0 to MyClass.Count - 1 do
      begin
        Memo1.Lines.Add(MyClass.Items[i].ToString);
      end;

    finally
      // �� �������� ������� ���������, ����� ��������� � ��� ��������
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
  // ��������� ���������� ���� TAppliedObjectList<String>
  // ���������, ��� ������ ����� ������� ������� ���� ������
  MyClass: TAppliedObjectList<TAltiumString>;
  i: Integer;
begin
  Memo1.Clear;
  try
    // ������� ��������� ������ ������,
    // � �������� ������ ��������� ����� ������������ ����������� ������������ ��� ����� ���� IComparer<T>
    MyClass := TAppliedObjectList<TAltiumString>.Create
      (TComparer<TAltiumString>.Construct(TAllComparison.Compare_TAltiumString));

    try
      Memo1.Lines.Text := '10. ��� ���� �������� � ���� � ��������� ����� �� ������' + sLineBreak +
        '20. ��� ������ ���������, ������ ��� ���� �� �����.' + sLineBreak +
        '11. ����� � ����� � ���� � ����������� �������' + sLineBreak +
        '1. ��� ������ � ��� ��� ������ ���� �� ����.' + sLineBreak +
        '2. � ����� ��� ���� ����� � ���� ��� ������ �����,' + sLineBreak +
        '3. ����� � ��������� ����� � ������� � ������� ������.' + sLineBreak +
        '5. ����� � ��������� ����� � ������� � ������� ������.' + sLineBreak +
        '3. ����� � ��������� ����� � ������� � ������� ������.' + sLineBreak +
        '4. ����� � ��������� ����� � ������� � ������� ������.' + sLineBreak +
        '4. �� ��� �� ����� � �������� � ������ ����� ���� ������,' + sLineBreak +
        '3333. ��������� ����� ������� ���� � ���, ������ ������� ����.' + sLineBreak +
        '999. ��� ������ ������� ����, ���� �������� ����� ����' + sLineBreak +
        '666. ��� ������ ������� ����, ���� �������� ����� ����' + sLineBreak +
        '22222. ��� ������ ������ �������� ����.' + sLineBreak +
        '88. ������� ������ ��������, ���� ���������� ����' + sLineBreak +
        '87. ������� ������ ��������, ���� ���������� ����' + sLineBreak +
        '89. ������� ������ ��������, ���� ���������� ����' + sLineBreak +
        '99. ��� ������ ��� �� ������ ����.';

      // ��������� ������ �������� �� Memo
      for i := 0 to Memo1.Lines.Count - 1 do
      begin
        MyClass.Add(TAltiumString.Create(Memo1.Lines[i]));
      end;

      // �������� ����� ���������� QuickSort
      i := MyClass.SortBy<TAltiumString>(TAllSort.QuickSort<TAltiumString>);

      // ������� ���������� ������������
      Memo1.Lines.Add(sLineBreak + 'Turns: ' + i.ToString);

      // ������� ���������� ������
      Memo1.Lines.Add('���������� ������:');
      for i := 0 to MyClass.Count - 1 do
      begin
        Memo1.Lines.Add(MyClass.Items[i].ToString);
      end;
    finally
      // �� �������� ������� ���������, ����� ��������� � ��� ��������
      MyClass.Free;
    end;
  except
    on E: Exception do
      Memo1.Lines.Add(E.Message);
  end;
  Memo1.ScrollBy(0, Memo1.BoundsRect.Height);
end;

end.
