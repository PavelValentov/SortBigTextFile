unit USorter;

interface

uses
  System.Classes,
  System.Generics.Defaults,
  System.Generics.Collections, // дженерики
  AllObjects,
  System.SyncObjs; // для критический секций

const
  WRITE_BUFFER_SIZE = 128 * 1024 * 1024; // bytes
  SORT_BUFFER_SIZE = 32 * 1024 * 1024; // bytes
  MAX_SORT_BUFFER_SIZE_MULTIPLIER = 3;
  SOURCE_FILE_NAME = 'database.txt';
  DEST_FILE_NAME = 'destdb.txt';

type
  TLogEvent = procedure(msg: String) of object;

  TSorter = class(TThread)
  private
    FTimerIndexing, FTimerAll: Cardinal;
    FIndexes: TArray<TPhraseFile>;
    FOnLog: TLogEvent;
    FStop: Boolean; // flag to stop
    FLastLogTime: Cardinal;
    FCurrentMultiplier: UInt64;
    FAllPharases: TDictionary<String, UInt64>;

    function GetBufferSizeIteration: UInt64;
    procedure TryLog(aMsg: string);
    procedure Log(aMsg: string);
    procedure StopSorting(aStop: Boolean);
  protected
    procedure Execute; override;
    function MakeIndexes: Boolean;
    function ReadFileToStr(FileStream: TFileStream): String;
    function AddFileIndex(aAStr: TAltiumString): Boolean;
  public
    property OnLog: TLogEvent read FOnLog write FOnLog;
    property Stop: Boolean read FStop write StopSorting;
    constructor Create();
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows;

{ TSorter }

function TSorter.AddFileIndex(aAStr: TAltiumString): Boolean; // returns is a new record or not
var
  i: integer;
  found: Boolean;
  val: UInt64;
begin
  Result := true; // is a new item in the files list

  if (FAllPharases.TryGetValue(aAStr.Str, val)) then
  begin
    Result := false;
    FIndexes[val].AddIndex(aAStr.Number);
  end;

  // for i := Low(FIndexes) to High(FIndexes) do
  // begin
  // if FIndexes[i].Str = aAStr.Str then
  // begin
  // Result := false;
  // FIndexes[i].AddIndex(aAStr.Number);
  // break;
  // end;
  // end;

  if Result then
  begin
    i := Length(FIndexes);
    SetLength(FIndexes, i + 1);
    FIndexes[i] := TPhraseFile.Create(aAStr.Str, i);
    FIndexes[i].AddIndex(aAStr.Number);
    FAllPharases.Add(aAStr.Str, i);
  end;
end;

constructor TSorter.Create;
begin
  inherited Create(true);

  FCurrentMultiplier := 0;
  FStop := false;
  FAllPharases := TDictionary<String, UInt64>.Create;
end;

destructor TSorter.Destroy;
begin
  try
    FAllPharases.Free;
  finally
  end;

  inherited;
end;

procedure TSorter.Execute;
var
  LDestStream: TFileStream;
  LDestWriteStr: AnsiString;
  Phrase: AnsiString;

  iPhrases, iIndexes: UInt64;
  LTurns: integer;
begin
  try
    inherited;

    FTimerAll := GetTickCount;
    try
      try
        FTimerIndexing := GetTickCount;
        FStop := not MakeIndexes;
        FTimerIndexing := (GetTickCount - FTimerIndexing) div 1000;

        if (FStop) then
          Raise Exception.Create('Can not make Indexes');

        TryLog('Sorting index files...');
        TArray.Sort<TPhraseFile>(FIndexes,
          TComparer<TPhraseFile>.Construct(TAllComparison.Compare_TPhraseFile));
        TryLog('Sorted index files by turns count: ' + LTurns.ToString);

        LDestStream := TFileStream.Create(DEST_FILE_NAME, fmCreate);
        try
          for iPhrases := Low(FIndexes) to High(FIndexes) do
          begin
            if FIndexes[iPhrases].Clustered then
            begin
              FIndexes[iPhrases].LoadFromFile;
            end;

            if not FIndexes[iPhrases].Sorted then
            begin
              FIndexes[iPhrases].Sort;
              TryLog('Sorted indexes of phrase number ' + iPhrases.ToString);
            end;

            LDestWriteStr := '';
            for iIndexes := 0 to Length(FIndexes[iPhrases].Indexes) - 1 do
            begin
              Phrase := FIndexes[iPhrases].Indexes[iIndexes].ToString + '. ' + FIndexes[iPhrases]
                .Str + sLineBreak;
              LDestWriteStr := LDestWriteStr + Phrase;
            end;

            LDestStream.Write(LDestWriteStr[1], Length(LDestWriteStr) * SizeOf(LDestWriteStr[1]));
            TryLog('Write phrases to the destination file ' + Round(iPhrases / Length(FIndexes) *
              100).ToString + '%');
            LDestWriteStr := '';

            FIndexes[iPhrases].Clear;
          end;
        finally
          LDestStream.Free;
        end;
        FTimerAll := (GetTickCount - FTimerAll) div 1000;

        Log('Well done. Sorting: ' + FTimerIndexing.ToString + ' sec. All work: ' +
          FTimerAll.ToString + ' sec.');
      except
        on E: Exception do
        begin
          Log('Error: ' + E.Message);
        end;
      end;
    finally
      try
        for iPhrases := Low(FIndexes) to High(FIndexes) do
        begin
          FIndexes[iPhrases].Clear;
        end;
        SetLength(FIndexes, 0);
      except
        on E: Exception do
          Log('Error: ' + E.Message);
      end;
    end;
  finally
    // want to be sure the thread will be terminated
    Terminate;
  end;
end; // TSorter.Execute

function TSorter.GetBufferSizeIteration: UInt64;
begin
  if (FCurrentMultiplier < MAX_SORT_BUFFER_SIZE_MULTIPLIER) then
    Inc(FCurrentMultiplier)
  else
    FCurrentMultiplier := 1;

  Result := FCurrentMultiplier * SORT_BUFFER_SIZE;
end;

// Send log message to the main process
procedure TSorter.Log(aMsg: string);
begin
  FLastLogTime := GetTickCount;
  if (Assigned(FOnLog)) then
    FOnLog(aMsg);
end;

function TSorter.ReadFileToStr(FileStream: TFileStream): String;
var
  Bytes: TBytes;
  Read: LongInt;
begin
  Result := '';
  if FileStream.Size > 0 then
  begin
    SetLength(Bytes, WRITE_BUFFER_SIZE);
    Read := FileStream.Read(Bytes[0], WRITE_BUFFER_SIZE);
    SetLength(Bytes, Read);
  end;
  Result := TEncoding.ANSI.GetString(Bytes);
end;

function TSorter.MakeIndexes: Boolean; // TRUE if success
var
  LSource: TFileStream;
  // LStringStream: TStringStream;
  LStr: String;
  LStrCounter: UInt64;
  LArr: TArray<string>;
  LTempStr: AnsiString; // sets reminder of readed string block
  LDestWriteStr: AnsiString;
  LBlockCounter: UInt64;

  i: UInt64;
begin
  Result := false;
  try
    Log('Making indexes...');

    LStrCounter := 0;
    LTempStr := '';

    if (not FileExists(SOURCE_FILE_NAME)) then
      Raise Exception.Create('Source text file not exits');
    LSource := TFileStream.Create(SOURCE_FILE_NAME, fmOpenRead, fmShareDenyWrite);

    try
      if (LSource.Size < 1024) then
        Raise Exception.Create('Source file size is too small');

      LSource.Seek(0, soFromBeginning);

      TryLog('Reading source file');
      // Очищаем буфер записи
      LDestWriteStr := '';
      LBlockCounter := 0;
      while ((Length(LStr) > 0) or (LSource.Position = 0)) and (not FStop) do
      begin

        LStr := LTempStr + ReadFileToStr(LSource);
        // LStr := LTempStr + LStringStream.ReadString(SORT_BUFFER_SIZE);
        LArr := LStr.Split([sLineBreak]);
        Inc(LBlockCounter);

        if Length(LArr) = 0 then
          continue;

        // запоминаем обрезок последней строки
        LTempStr := LArr[High(LArr)];
        SetLength(LArr, Length(LArr) - 1);

        LStrCounter := LStrCounter + Length(LArr);

        // заполняем список строками из массива
        for i := Low(LArr) to High(LArr) do
        begin
          if (Trim(LArr[i]).IsEmpty) then
            OutputDebugString(PChar('Error: string is empty: ' + i.ToString));

          AddFileIndex(TAltiumString.Create(LArr[i]));

          if i mod 1000 = 0 then
            TryLog('Indexing a block: ' + LBlockCounter.ToString + '. String: ' + i.ToString + '/' +
              High(LArr).ToString + '. Progress: ' + Round(LSource.Position / LSource.Size * 100)
              .ToString + '%');

          if (FStop) then
            exit;
        end;

        TryLog('Indexing a block: ' + LBlockCounter.ToString + '. Progress: ' +
          Round(LSource.Position / LSource.Size * 100).ToString + '%');
      end;
      // finally
      // LStringStream.Free;
      // end;
    finally
      LSource.Free;
    end;

    try
      for i := Low(FIndexes) to High(FIndexes) do
      begin
        if FIndexes[i].Clustered then
          FIndexes[i].SaveToFile;
      end;
    except
      on E: Exception do
        Log('Error: ' + E.Message);
    end;

    FAllPharases.Clear;

    Log('Indexes has been read');
    Result := true;
  except
    on E: Exception do
    begin
      Log('Error: ' + E.Message);
    end;
  end;
end;

procedure TSorter.StopSorting(aStop: Boolean);
begin
  FStop := aStop;
end;

procedure TSorter.TryLog(aMsg: string);
begin
  if GetTickCount > FLastLogTime + 1000 then
    Log(aMsg);
end;

end.
