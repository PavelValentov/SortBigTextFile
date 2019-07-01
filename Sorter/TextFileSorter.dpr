program TextFileSorter;

uses
  System.Classes,
  System.StartUpCopy,
  FMX.Forms,
  mainSorter in 'mainSorter.pas' {fmMain} ,
  AllObjects in '..\Lib\AllObjects.pas',
  AppliedObjectList in '..\Lib\AppliedObjectList.pas',
  SortMethods in '..\Lib\SortMethods.pas',
  USorter in 'USorter.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;

end.
