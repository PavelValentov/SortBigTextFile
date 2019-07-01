unit mainSorter;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, USorter,
  AllObjects, SortMethods, AppliedObjectList;

type
  TLogEvent = procedure(msg: String) of object;

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
  System.Generics.Defaults,
  Winapi.Windows;

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
  TThread.Synchronize(nil,
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
