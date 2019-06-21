unit mainSorter;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation;

const
  BUFFER_STRINGS_COUNT = 30000;
  SOURCE_FILE_NAME = '../../../database.txt';
  DEST_FILE_NAME = '../../../destdb.txt';
  TEMP_FILE_NAME = '../../../tempdb.txt';

type
  TLogEvent = procedure(msg: String) of object;

  TSorter = class(TThread)
  private
    FOnLog: TLogEvent;
    FStop: boolean; // flag to stop
    FLastLogTime: Cardinal;

    procedure Log(aMsg: string);
  protected
    procedure Execute; override;
  public
    property OnLog: TLogEvent read FOnLog write FOnLog;
    property Stop: boolean read FStop write FStop;
    constructor Create();
    destructor Destroy; override;
  end;

  TfmMain = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    btSort: TButton;
    lbFooter: TLabel;
    btStop: TButton;
    procedure btSortClick(Sender: TObject);
    procedure btStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FSorting: boolean;
    FSorter: TSorter;

    procedure FChangeSortingStatus(aStatus: boolean);
    property Sorting: boolean read FSorting write FChangeSortingStatus;
    procedure SorterTerminated(Sender: TObject);
  public
    { Public declarations }
    procedure Log(msg: String);
  end;

var
  fmMain: TfmMain;

implementation

{$R *.fmx}

Uses
  AllObjects, SortMethods, AppliedObjectList, System.Generics.Defaults,
  Winapi.Windows;

{ TSorter }

constructor TSorter.Create;
begin
  inherited Create(true);

  FStop := false;
end;

destructor TSorter.Destroy;
begin
  try
  finally
  end;

  inherited;
end;

procedure TSorter.Execute;
var
  LTempStream: TFileStream;
  LStringStream: TStringStream;
  LStr: String;
  LStrCounter: UInt64;
  LArr: TArray<string>;
  LTempStr: AnsiString; // sets reminder of readed string block
  LDestStr: AnsiString;
  LBlockSize: UInt64;

  LSorter: TAppliedObjectList<TAltiumString>;
  i: Integer;
  LFullTurns, LTurns: Integer;
  LFirstTurn: boolean; // Flag of first iteration

  LSourceFileName: String;
begin
  try
    inherited;

    try
      LFirstTurn := true;

      while ((LFullTurns > 0) or LFirstTurn) and (not FStop) do
      begin
        LFullTurns := 0;
        LStrCounter := 0;
        LTempStr := '';

        LTempStream := TFileStream.Create(TEMP_FILE_NAME, fmCreate);
        try
          LStringStream := TStringStream.Create(LDestStr, TEncoding.ANSI);
          // LStringStream := TStringStream.Create();
          try
            // LStringStream.LoadFromStream(LFileStream);
            if (LFirstTurn) then
              LSourceFileName := SOURCE_FILE_NAME
            else
              LSourceFileName := DEST_FILE_NAME;
            if (not FileExists(LSourceFileName)) then
              Raise Exception.Create('Source text file not exits');

            LStringStream.LoadFromFile(LSourceFileName);
            if (LStringStream.Size < 1024) then
              Raise Exception.Create('Source file size is too small');

            LBlockSize := BUFFER_STRINGS_COUNT * (Random(5) + 1);
            LStringStream.Seek(0, soFromBeginning);

            // создаем экземпл€р нашего класса,
            // в качестве метода сравнени€ будем использовать стандартный сравниватель дл€ строк типа IComparer<T>
            LSorter := TAppliedObjectList<TAltiumString>.Create
              (TComparer<TAltiumString>.Construct(TAllComparison.Compare_TAltiumString));
            try
              while ((Length(LStr) > 0) or (LStringStream.Position = 0)) and (not FStop) do
              begin
                LStr := LTempStr + LStringStream.ReadString(LBlockSize);
                LArr := LStr.Split([sLineBreak]);

                if Length(LArr) > 0 then
                begin
                  LTempStr := LArr[High(LArr)];
                  SetLength(LArr, Length(LArr) - 1);

                  LStrCounter := LStrCounter + Length(LArr);

                  // заполн€ем список строками из массива
                  LSorter.Clear;
                  for i := Low(LArr) to High(LArr) do
                  begin
                    LSorter.Add(TAltiumString.Create(LArr[i]));
                    if (FStop) then exit;
                  end;
                  if GetTickCount > FLastLogTime + 1000 then
                    Log('Will sorted strings: ' + LSorter.Count.ToString);

                  // вызываем метод сортировки QuickSort
                  LTurns := LSorter.SortBy<TAltiumString>(TAllSort.BubbleSort<TAltiumString>);
                  LFullTurns := LFullTurns + LTurns;

                  // выводим отсортированный список в строку
                  LDestStr := '';
                  for i := 0 to LSorter.Count - 1 do
                  begin
                    LDestStr := LDestStr + LSorter.Items[i].ToString + sLineBreak;
                    if (FStop) then exit;
                  end;
                  if GetTickCount > FLastLogTime + 1000 then
                    Log('Sorted strings: ' + LSorter.Count.ToString);

                  LTempStream.Write(LDestStr[1], Length(LDestStr) * SizeOf(LDestStr[1]));
                  if GetTickCount > FLastLogTime + 1000 then
                    Log('Written bytes: ' + (Length(LDestStr) * SizeOf(LDestStr[1])).ToString);
                end;
              end;
            finally
              // не забываем удалить экземпл€р, когда закончили с ним работать
              LSorter.Free;
            end;
          finally
            LStringStream.Free;
          end;
        finally
          LTempStream.Free;
        end;

        Log('Iteration done. Turns: ' + LFullTurns.ToString);
        sleep(50);
        if (FileExists(DEST_FILE_NAME)) then
        begin
          DeleteFile(DEST_FILE_NAME);
        end;

        if not RenameFile(TEMP_FILE_NAME, DEST_FILE_NAME) then
          Raise Exception.Create('Can not rename file: ' + TEMP_FILE_NAME);

        if (LFirstTurn) then
          LFirstTurn := false;
      end;

      Log('Well done. Turns: ' + LFullTurns.ToString);

      if (not FileExists(TEMP_FILE_NAME)) then
      begin
        DeleteFile(TEMP_FILE_NAME);
      end;
    except
      on E: Exception do
      begin
        Log('Error: ' + E.Message);
      end;
    end;
  finally
    // want to be sure the thread will be terminated
    Terminate;
  end;
end;

// Send log message to the main process
procedure TSorter.Log(aMsg: string);
begin
  FLastLogTime := GetTickCount;
  if (Assigned(OnLog)) then
    OnLog(aMsg);
end;

procedure TfmMain.btSortClick(Sender: TObject);
begin
  // upates the controls states
  Sorting := true;

  // starts a generator thread
  FSorter := TSorter.Create();
  FSorter.OnLog := Log;
  FSorter.OnTerminate := SorterTerminated;
  FSorter.FreeOnTerminate := false;
  FSorter.Priority := tpTimeCritical;
  FSorter.Start;
end;

procedure TfmMain.btStopClick(Sender: TObject);
begin
  if Assigned(FSorter) then
    if FSorter.Started then
      FSorter.Stop := true;
end;

procedure TfmMain.FChangeSortingStatus(aStatus: boolean);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      btSort.Enabled := not aStatus;

      btStop.Enabled := aStatus;
    end);
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  Sorting := false;
  Log('Press "Sort file to"');
end;

// stops a generator thread and clear memory
procedure TfmMain.FormDestroy(Sender: TObject);
begin
  try
    if Assigned(FSorter) then
    begin
      if FSorter.Started then
      begin
        FSorter.Stop := true;
        FSorter.WaitFor;
        FSorter.Free;
      end;
    end;
  finally
  end;
end;

// shows status message in the main process
procedure TfmMain.Log(msg: String);
begin
  TThread.Queue(nil,
    procedure
    begin
      lbFooter.Text := msg;
      Application.ProcessMessages;
    end);
end;

// event of a thread terminated
procedure TfmMain.SorterTerminated(Sender: TObject);
begin
  Sorting := false;
end;

end.
