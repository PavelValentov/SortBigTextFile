program GenericSort;

uses
  Vcl.Forms,
  mainGenericTest in 'mainGenericTest.pas' {fmMainTest},
  AllObjects in '..\Lib\AllObjects.pas',
  AppliedObjectList in '..\Lib\AppliedObjectList.pas',
  SortMethods in '..\Lib\SortMethods.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMainTest, fmMainTest);
  Application.Run;
end.
