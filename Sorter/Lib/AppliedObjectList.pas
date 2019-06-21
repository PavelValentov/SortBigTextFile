// ������ ���������� ��������� ������ ������ �� �������� ���������� ��������
unit AppliedObjectList;

interface

uses
  System.Generics.Collections, // ���������
  System.Generics.Defaults, // ���������
  System.SyncObjs; // ��� ����������� ������

// �������� ����� ��� ������ �� ������� ���������� ��������
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

    // ����� ����� ��������� ���� ��������� ������ ��� ������������ ��� ���������� ���������

    // ������������� ����� ���������� � ��������� ������� ������ ���������
    // ���������� ���������� ������������, �������, ��� �� ����� ������ MaxInt
    function SortBy<T>(const AProc: TSorting<T>): Integer; overload;
  end;

implementation

constructor TAppliedObjectList<T>.Create;
begin
  inherited Create;

  FCS := TCriticalSection.Create;

  // ������,
  // ���� �� ����������������� �������� �������������� "������������"
  // ��� ���� nsczx ��������,
  // � �� ����� ���� �����
  Create(TComparer<T>.Default);
end;

constructor TAppliedObjectList<T>.Create(const AComparer: IComparer<T>);
begin
  inherited Create(AComparer);

  FCS := TCriticalSection.Create;

  // ���������� ��������� "������������"
  FComparer := AComparer;
  if FComparer = nil then
    // � ���� �� �� ������, �� ����������� ��-���������,
    // ������� ����� �� ��������� �������� � ����� ��������
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

  // �������� List � ������ TList<T> � ������ ��� ������,
  // ������� ��������� ������ �������� �� ��������� ������ ��� ����������
  // ��������� � ����������������� ������, ����� ������ �� ���� �������� �� ���������
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

  // ������ ������� ����� ����������? � ��������� �� ������� �� ��������� - ������� ����������
  if @AProc = nil then
    Sort(FComparer)
  else
    Result := AProc(Target, FComparer, 0, Count - 1);

  // ���������� ������ �� ���������� �������
  // ��������� � ����������������� ������, ����� ������ �� ���� �������� �� ���������
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

  // �������� ��������� ������
  SetLength(Target, 0);
end;

end.
