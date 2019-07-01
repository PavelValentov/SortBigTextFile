unit mainGenerator;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit;

const
  BUFFER_STRINGS_COUNT = 4 * 1024 * 1024;
  TEXT_FILE_NAME = '../../../database.txt';
  // TEXT_FILE_NAME = 'database.txt';

type
  TLogEvent = procedure(msg: String) of object;

  TGenerator = class(TThread)
  private
    FOnLog: TLogEvent;
    FPhrase: String;
    FWords: TStringList;
    FPrases: TStringList;
    FStop: boolean; // flag to stop
    FLastLogTime: Cardinal;
    FFileSizeLimit: UInt64;

    function DispatchPhrase: boolean; // dispatch phrase to list of words
    function AddPhrase(aUsedWords: Array of integer): integer; // Add phrases to FPrases
    function MakePhrase(aUsedWords: Array of integer): string; // Return phrase string

    procedure Log(aMsg: string);
  protected
    procedure Execute; override;
  public
    property OnLog: TLogEvent read FOnLog write FOnLog;
    property Stop: boolean read FStop write FStop;
    constructor Create(aPhrase: String; aFileSize: UInt64);
    destructor Destroy; override;
  end;

  TfmMain = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    lbFooter: TLabel;
    Label1: TLabel;
    edMaxFileSize: TEdit;
    Label2: TLabel;
    edPhrase: TEdit;
    btGenerate: TButton;
    btStop: TButton;
    procedure btGenerateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btStopClick(Sender: TObject);
  private
    { Private declarations }
    FGenerating: boolean;
    FGenerator: TGenerator;

    procedure FChangeGeneratingStatus(aStatus: boolean);
    property Generating: boolean read FGenerating write FChangeGeneratingStatus;

    procedure GeneratorTerminated(Sender: TObject);
  public
    { Public declarations }
    procedure Log(msg: String);
  end;

var
  fmMain: TfmMain;

implementation

uses Winapi.Windows;

{$R *.fmx}

// Start to generate new text database
procedure TfmMain.btGenerateClick(Sender: TObject);
var
  LFileSizeLimit: UInt64;
begin
  try
    LFileSizeLimit := StrToUInt64(edMaxFileSize.Text);
    if LFileSizeLimit < 1 then
    begin
      Log('File size limit is too small');
      exit;
    end;
  except
    on E: Exception do
    begin
      Log('Error: ' + E.Message);
      exit;
    end;
  end;

  // upates the controls states
  Generating := true;

  // starts a generator thread
  FGenerator := TGenerator.Create(Trim(edPhrase.Text), LFileSizeLimit);
  FGenerator.OnLog := Log;
  FGenerator.OnTerminate := GeneratorTerminated;
  FGenerator.FreeOnTerminate := false;
  FGenerator.Start;
end;

// stop a generator forcibly
procedure TfmMain.btStopClick(Sender: TObject);
begin
  if Assigned(FGenerator) then
    if FGenerator.Started then
      FGenerator.Stop := true;
end;

// updates form controls states
procedure TfmMain.FChangeGeneratingStatus(aStatus: boolean);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      btGenerate.Enabled := not aStatus;
      edMaxFileSize.Enabled := not aStatus;

      btStop.Enabled := aStatus;
    end);
end;

// initializes start states
procedure TfmMain.FormCreate(Sender: TObject);
begin
  Generating := false;
  Log('Press "Generate new text file"');
end;

// stops a generator thread and clear memory
procedure TfmMain.FormDestroy(Sender: TObject);
begin
  try
    if Assigned(FGenerator) then
    begin
      if FGenerator.Started then
      begin
        FGenerator.Stop := true;
        FGenerator.WaitFor;
        FGenerator.Free;
      end;
    end;
  finally
  end;
end;

// event of a thread terminated
procedure TfmMain.GeneratorTerminated(Sender: TObject);
begin
  Generating := false;
end;

// shows status message in the main process
procedure TfmMain.Log(msg: String);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      lbFooter.Text := msg;
      Application.ProcessMessages;
    end);
end;

{ TGenerator }

// Recursing function makes new phrase
// @param {Array of integer} aUsedWords - indexes of already used words
function TGenerator.AddPhrase(aUsedWords: Array of integer): integer;
var
  LResPhrase: string;
  LPhrasesCounter: integer;
  LUsedWords: Array of integer;
  i, m: integer;
  NoMatch: boolean;

begin
  LPhrasesCounter := 0;

  if (Length(aUsedWords) = FWords.Count) then
  begin
    // The new phrase completed
    LResPhrase := MakePhrase(aUsedWords);
    FPrases.Add(LResPhrase);
    OutputDebugString(PChar('New phrase: ' + LResPhrase));
    inc(LPhrasesCounter);
  end
  else
  begin
    // Makes new phrase from words dictionary
    for i := 0 to FWords.Count - 1 do
    begin
      if FStop then
        break;

      NoMatch := true;
      for m := Low(aUsedWords) to High(aUsedWords) do
        if aUsedWords[m] = i then
        begin
          NoMatch := false;
          break;
        end;

      // this not used in the phrase yet, adds this one to the destination phrase
      if NoMatch then
      begin
        SetLength(LUsedWords, Length(aUsedWords) + 1);
        for m := Low(aUsedWords) to High(aUsedWords) do
          LUsedWords[m] := aUsedWords[m];
        LUsedWords[High(LUsedWords)] := i;
        LPhrasesCounter := LPhrasesCounter + AddPhrase(LUsedWords);
      end;
    end;
  end;

  // show a progress every 1 sec
  if GetTickCount > FLastLogTime + 1000 then
    Log('Total phrases count in dictionary: ' + FPrases.Count.ToString);

  // returns count of generated phrases
  result := LPhrasesCounter;
end;

// initialize thread parameters
constructor TGenerator.Create(aPhrase: String; aFileSize: UInt64);
begin
  inherited Create(true);

  FStop := false;
  FPhrase := aPhrase;
  FFileSizeLimit := aFileSize * 1024 * 1024;
  FWords := TStringList.Create;
  FPrases := TStringList.Create;
end;

// clear the memory
destructor TGenerator.Destroy;
begin
  try
    FWords.Free;
  finally

  end;

  try
    FPrases.Free;
  finally

  end;

  inherited;
end;

// dispatches source phrase into words
// returns true/false result
function TGenerator.DispatchPhrase: boolean;
begin
  try
    FWords.Clear;
    FWords.Delimiter := ' ';
    FWords.StrictDelimiter := true;
    FWords.DelimitedText := FPhrase;
    result := true;
  except
    result := false;
  end;
end;

procedure TGenerator.Execute;

  function GetRandomInt64(): UInt64;
  var
    LTemp: UInt64;
    LRange: Byte;
  begin
    LTemp := 0;
    LRange := Random(4);

    Int64Rec(LTemp).Words[0] := Random(High(Word));

    if LRange > 0 then
      Int64Rec(LTemp).Words[1] := Random(High(Word));

    if LRange > 1 then
      Int64Rec(LTemp).Words[2] := Random(High(Word));

    if LRange > 2 then
      Int64Rec(LTemp).Words[3] := Random(High(Word));

    result := LTemp;
  end;

var
  LDicSize: integer;
  LFileSize: UInt64;

  LNum, LCount: UInt64;
  LPhrase: String;
  LPhrases: TStringList;
  LStringStream: TFileStream;
begin
  inherited;

  try
    // dispatches source phrase into words
    if not DispatchPhrase then
    begin
      Log('Error while dispatching the phrase');
      sleep(1000);
      exit;
    end;

    if (FWords.Count < 2) then
    begin
      Log('Phrase is too short. It have to be at least 2 words length');
      sleep(1000);
      exit;
    end;

    Log('The phrase has words count: ' + FWords.Count.ToString);
    sleep(500);

    // make a phrases dictionary
    LDicSize := AddPhrase([]);
    Log('Total phrases count in dictionary: ' + LDicSize.ToString);
    sleep(500);

    if FStop then
      exit;

    LStringStream := TFileStream.Create(TEXT_FILE_NAME, fmCreate or fmOpenWrite);
    try
      LPhrases := TStringList.Create;
      try
        LFileSize := 0;
        LCount := 0;
        // make a text database while file size will reach the limit
        while ((LFileSize < FFileSizeLimit) and (not FStop)) do
        begin
          // generate random index for a phrase
          // LNum := Random(1000);
          LNum := GetRandomInt64();

          // gets random phrase from the dictionary
          LPhrase := UIntToStr(LNum) + '. ' + FPrases.Strings[Random(FPrases.Count)];

          // fill the phrases bufer to save into a file
          LPhrases.Add(LPhrase);
          LFileSize := LFileSize + Length(LPhrase);
          Inc(LCount);

          // Save next part of database
          if LPhrases.Count >= BUFFER_STRINGS_COUNT then
          begin
            LPhrases.SaveToStream(LStringStream);
            LPhrases.Clear;
          end;

          if GetTickCount > FLastLogTime + 1000 then
            Log('File size: ' + UIntToStr(LFileSize) + '. Phrase: ' + LPhrase);
        end;

        Log('Final file size: ' + UIntToStr(LFileSize) + ' Bytes. Phrases count: ' +
          UIntToStr(LCount));

        // Save last part of database
        LPhrases.SaveToStream(LStringStream);
        LPhrases.Clear;
      finally
        LPhrases.Free;
      end;
    finally
      LStringStream.Free;
      Terminate;
    end;
  except
    on E: Exception do
    begin
      Log('Error: ' + E.Message);
      Terminate;
    end;
  end;
end;

// Send log message to the main process
procedure TGenerator.Log(aMsg: string);
begin
  FLastLogTime := GetTickCount;
  if (Assigned(OnLog)) then
    OnLog(aMsg);
end;

// Make phrase from words indexes consits in the aUsedWords
function TGenerator.MakePhrase(aUsedWords: array of integer): string;
var
  i: integer;
  resPhrase: string;
begin
  resPhrase := '';
  for i := Low(aUsedWords) to High(aUsedWords) do
  begin
    if Length(resPhrase) > 0 then
      resPhrase := resPhrase + ' ';

    resPhrase := resPhrase + FWords.Strings[aUsedWords[i]];
  end;

  result := resPhrase;
end;

end.
