Program filehash;

Uses
  Forms,
  FmMain In 'FmMain.pas' {frmType},
  UFileCatcher In 'UFileCatcher.pas';

{$R *.res}
{$SetPEFlags 1}

Begin
  Application.Initialize;
  Application.Title := 'File Hash';
  Application.CreateForm(TfrmType, frmType);
  Application.Run;
End.

