program TextFileGenerator;

uses
  System.StartUpCopy,
  FMX.Forms,
  mainGenerator in 'mainGenerator.pas' {fmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
