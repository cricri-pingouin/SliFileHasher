unit FmMain;

interface

uses
  Messages, SysUtils, Classes, Controls, Forms, Grids, StdCtrls, IniFiles;

type
  TfrmType = class(TForm)
    btnClear: TButton;
    chkCRC32b: TCheckBox;
    chkSHA1: TCheckBox;
    chkMD4: TCheckBox;
    chkMD5: TCheckBox;
    strgrd: TStringGrid;
    chkMD2: TCheckBox;
    btnCSV: TButton;
    btnTXT: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SaveStringGrid(const AFileName: SysUtils.TFileName);
    procedure btnClearClick(Sender: TObject);
    procedure chkCRC32bClick(Sender: TObject);
    procedure chkSHA1Click(Sender: TObject);
    procedure chkMD2Click(Sender: TObject);
    procedure chkMD4Click(Sender: TObject);
    procedure chkMD5Click(Sender: TObject);
    procedure btnCSVClick(Sender: TObject);
    procedure btnTXTClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
  public
    { Public declarations }
    SelectedFileName: string;
  end;

var
  frmType: TfrmType;
  FullFilesNames: TStringList;
  FilesDropped: Boolean;
  ColsWidth: Integer;

implementation

uses
  ShellAPI, UFileCatcher, IdHashMessageDigest, IdHash, IdHashSHA1, IdHashCRC;

{$R *.dfm}

function MD2(const fileName: string): string;
var
  idmd2: TIdHashMessageDigest2;
  fs: TFileStream;
begin
  idmd2 := TIdHashMessageDigest2.Create;
  fs := TFileStream.Create(fileName, fmOpenRead or fmShareDenyWrite);
  try
    result := idmd2.AsHex(idmd2.HashValue(fs));
  finally
    fs.Free;
    idmd2.Free;
  end;
end;

function MD4(const fileName: string): string;
var
  idmd4: TIdHashMessageDigest4;
  fs: TFileStream;
begin
  idmd4 := TIdHashMessageDigest4.Create;
  fs := TFileStream.Create(fileName, fmOpenRead or fmShareDenyWrite);
  try
    result := idmd4.AsHex(idmd4.HashValue(fs));
  finally
    fs.Free;
    idmd4.Free;
  end;
end;

function MD5(const fileName: string): string;
var
  idmd5: TIdHashMessageDigest5;
  fs: TFileStream;
begin
  idmd5 := TIdHashMessageDigest5.Create;
  fs := TFileStream.Create(fileName, fmOpenRead or fmShareDenyWrite);
  try
    result := idmd5.AsHex(idmd5.HashValue(fs));
  finally
    fs.Free;
    idmd5.Free;
  end;
end;

function SHA1(const fileName: string): string;
var
  sha1: TIdHashSHA1;
  fs: TFileStream;
begin
  sha1 := TIdHashSHA1.Create;
  fs := TFileStream.Create(fileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := sha1.AsHex(sha1.HashValue(fs));
  finally
    fs.Free;
    sha1.Free;
  end;
end;

function CRC32b(fileName: string): LongWord;
var
  crc32b: TIdHashCRC32;
  fs: TFileStream;
begin
  crc32b := TIdHashCRC32.Create;
  try
    fs := TFileStream.Create(fileName, fmOpenRead or fmShareDenyWrite);
    try
      Result := crc32b.HashValue(fs);
    finally
      fs.Free;
    end;
  finally
    crc32b.Free;
  end;
end;

function IntToStrDelimited(aNum: integer): string;
// Formats the integer aNum with the default Thousand Separator
var
  D: Double;
begin
  D := aNum;
  Result := Format('%.0n', [D]); // ".0" -> no decimals, n -> thousands separators
end;

function GetSizeOfFile(const FileName: string): Int64;
var
  Rec: TSearchRec;
begin
  Result := 0;
  if (FindFirst(FileName, faAnyFile, Rec) = 0) then
  begin
    Result := Rec.Size;
    FindClose(Rec);
  end;
end;

function ExtractFileNameWoExt(const FileName: string): string;
var
  i: integer;
begin
  i := LastDelimiter('.' + PathDelim + DriveDelim, FileName);
  if (i = 0) or (FileName[i] <> '.') then
    i := MaxInt;
  Result := ExtractFileName(Copy(FileName, 1, i - 1));
end;

procedure TfrmType.SaveStringGrid(const AFileName: SysUtils.TFileName);
var
  F: TextFile;
  i, j: Integer;
  RowContent: string;
begin
  AssignFile(F, AFileName);
  Rewrite(F);
  with strgrd do
  begin
    // loop through cells
    for i := 0 to RowCount - 1 do
    begin
      RowContent := '';
      for j := 0 to ColCount - 1 do
      begin
        if (j > 0) then
          RowContent := RowContent + ',';
        RowContent := RowContent + Cells[j, i];
      end;
      Writeln(F, RowContent);
    end;
  end;
  CloseFile(F);
end;

procedure TfrmType.btnClearClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to strgrd.ColCount - 1 do
    strgrd.Cols[i].Clear;
  strgrd.RowCount := 2;
  strgrd.Cells[0, 0] := 'File name';
  strgrd.Cells[1, 0] := 'Extension';
  strgrd.Cells[2, 0] := 'Size (KB)';
  strgrd.Cells[3, 0] := 'CRC32b hash';
  strgrd.Cells[4, 0] := 'SHA1 hash';
  strgrd.Cells[5, 0] := 'MD2 hash';
  strgrd.Cells[6, 0] := 'MD4 hash';
  strgrd.Cells[7, 0] := 'MD5 hash';
  FilesDropped := False;
end;

procedure TfrmType.btnCSVClick(Sender: TObject);
begin
  SaveStringGrid('hashes.csv');
end;

procedure TfrmType.btnTXTClick(Sender: TObject);
begin
  SaveStringGrid('hashes.txt');
end;

procedure TfrmType.chkCRC32bClick(Sender: TObject);
begin
  if (chkCRC32b.Checked) then
    strgrd.ColWidths[3] := ColsWidth
  else
    strgrd.ColWidths[3] := 0;
end;

procedure TfrmType.chkSHA1Click(Sender: TObject);
begin
  if (chkSHA1.Checked) then
    strgrd.ColWidths[4] := ColsWidth
  else
    strgrd.ColWidths[4] := 0;
end;

procedure TfrmType.chkMD2Click(Sender: TObject);
begin
  if (chkMD2.Checked) then
    strgrd.ColWidths[5] := ColsWidth
  else
    strgrd.ColWidths[5] := 0;
end;

procedure TfrmType.chkMD4Click(Sender: TObject);
begin
  if (chkMD4.Checked) then
    strgrd.ColWidths[6] := ColsWidth
  else
    strgrd.ColWidths[6] := 0;
end;

procedure TfrmType.chkMD5Click(Sender: TObject);
begin
  if (chkMD5.Checked) then
    strgrd.ColWidths[7] := ColsWidth
  else
    strgrd.ColWidths[7] := 0;
end;

procedure TfrmType.FormActivate(Sender: TObject);
var
  i: Integer;
  FullName: string;
  ThisFileSize: Int64;
begin
  //Command line parameters
  if ParamCount > 0 then    //THIS BIT: ParamCount
  begin
    strgrd.visible := False;
    strgrd.RowCount := ParamCount + 1;
    FullFilesNames := TStringList.Create;
    for i := 1 to ParamCount do  //ParamStr(0) is app path and name
    begin
      //Get file properties
      FullName := ParamStr(i);   //AND THIS: ParamStr(x)
      FullFilesNames.Add(FullName);
      ThisFileSize := GetSizeOfFile(FullName);
      //Populate StringGrid
      strgrd.Cells[0, i] := ExtractFileNameWoExt(FullName);
      strgrd.Cells[1, i] := UpperCase(StringReplace(ExtractFileExt(FullName), '.', '', []));
      strgrd.Cells[2, i] := IntToStrDelimited(ThisFileSize div 1024);
      if (chkCRC32b.Checked) then
        strgrd.Cells[3, i] := IntToHex(crc32b(FullName), 8);
      if (chkSHA1.Checked) then
        strgrd.Cells[4, i] := sha1(FullName);
      if (chkMD2.Checked) then
        strgrd.Cells[5, i] := MD2(FullName);
      if (chkMD4.Checked) then
        strgrd.Cells[6, i] := MD4(FullName);
      if (chkMD5.Checked) then
        strgrd.Cells[7, i] := MD5(FullName);
    end;
    FilesDropped := True;
    strgrd.visible := True;
  end;
end;

procedure TfrmType.FormCreate(Sender: TObject);
var
  i: Integer;
  myINI: TINIFile;
begin
  //Initialise options from INI file
  myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'filehash.ini');
  ColsWidth := myINI.Readinteger('Settings', 'ColsWidth', 120);
  chkCRC32b.Checked := myINI.ReadBool('Settings', 'CRC32b', False);
  chkSHA1.Checked := myINI.ReadBool('Settings', 'SHA1', False);
  chkMD2.Checked := myINI.ReadBool('Settings', 'MD2', False);
  chkMD4.Checked := myINI.ReadBool('Settings', 'MD4', False);
  chkMD5.Checked := myINI.ReadBool('Settings', 'MD5', False);
  myINI.Free;
  // Tell windows we accept file drops
  DragAcceptFiles(Self.Handle, True);
  //Init StringGrid
  strgrd.Cells[0, 0] := 'File name';
  strgrd.Cells[1, 0] := 'Extension';
  strgrd.Cells[2, 0] := 'Size (KB)';
  strgrd.Cells[3, 0] := 'CRC32b hash';
  strgrd.Cells[4, 0] := 'SHA1 hash';
  strgrd.Cells[5, 0] := 'MD2 hash';
  strgrd.Cells[6, 0] := 'MD4 hash';
  strgrd.Cells[7, 0] := 'MD5 hash';
  for i := 3 to 7 do
    strgrd.ColWidths[i] := 0;
  if (chkCRC32b.Checked) then
    strgrd.ColWidths[3] := ColsWidth;
  if (chkSHA1.Checked) then
    strgrd.ColWidths[4] := ColsWidth;
  if (chkMD2.Checked) then
    strgrd.ColWidths[5] := ColsWidth;
  if (chkMD4.Checked) then
    strgrd.ColWidths[6] := ColsWidth;
  if (chkMD5.Checked) then
    strgrd.ColWidths[7] := ColsWidth;
  FilesDropped := False;
end;

procedure TfrmType.FormDestroy(Sender: TObject);
var
  myINI: TIniFile;
begin
  // Cancel acceptance of file drops
  DragAcceptFiles(Self.Handle, False);
  //Save settings to INI file
  myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'filehash.ini');
  myINI.WriteInteger('Settings', 'ColsWidth', ColsWidth);
  myINI.WriteBool('Settings', 'CRC32b', chkCRC32b.Checked);
  myINI.WriteBool('Settings', 'SHA1', chkSHA1.Checked);
  myINI.WriteBool('Settings', 'MD2', chkMD2.Checked);
  myINI.WriteBool('Settings', 'MD4', chkMD4.Checked);
  myINI.WriteBool('Settings', 'MD5', chkMD5.Checked);
  myINI.Free;
  // Cancel acceptance of file drops
  DragAcceptFiles(Self.Handle, False);
end;

procedure TfrmType.WMDropFiles(var Msg: TWMDropFiles);
var
  CurrentRows, i, FileCount: Integer;
  Catcher: TFileCatcher; //File catcher class
  FullName: string;
  ThisFileSize: Int64;
begin
  inherited;
  // Create file catcher object to hide all messy details
  Catcher := TFileCatcher.Create(Msg.Drop);
  FileCount := Pred(Catcher.FileCount) + 1; //Not sure why +1 needed
  strgrd.visible := False;
  if FilesDropped then
  begin
    CurrentRows := strgrd.RowCount - 1; //-1 for header, I think! We don't want it here...
    strgrd.RowCount := CurrentRows + FileCount + 1; //+1 for header ... but we need it here
  end
  else
  begin
    CurrentRows := 0;
    strgrd.RowCount := FileCount + 1; //+1 for header
  end;
  FullFilesNames := TStringList.Create;
  try
    // Try to add each dropped file to display
    for i := 0 to FileCount - 1 do  //-1 due to base 0
    begin
      //Get file properties
      FullName := Catcher.Files[i];
      FullFilesNames.Add(FullName);
      ThisFileSize := GetSizeOfFile(FullName);
      //Populate StringGrid
      strgrd.Cells[0, CurrentRows + i + 1] := ExtractFileNameWoExt(FullName);
      strgrd.Cells[1, CurrentRows + i + 1] := UpperCase(StringReplace(ExtractFileExt(FullName), '.', '', []));
      strgrd.Cells[2, CurrentRows + i + 1] := IntToStrDelimited(ThisFileSize div 1024);
      if (chkCRC32b.Checked) then
        strgrd.Cells[3, CurrentRows + i + 1] := IntToHex(crc32b(FullName), 8);
      if (chkSHA1.Checked) then
        strgrd.Cells[4, CurrentRows + i + 1] := sha1(FullName);
      if (chkMD2.Checked) then
        strgrd.Cells[5, CurrentRows + i + 1] := MD2(FullName);
      if (chkMD4.Checked) then
        strgrd.Cells[6, CurrentRows + i + 1] := MD4(FullName);
      if (chkMD5.Checked) then
        strgrd.Cells[7, CurrentRows + i + 1] := MD5(FullName);
    end;
    FilesDropped := True;
  finally
    Catcher.Free;
  end;
  // Notify Windows we handled message
  Msg.Result := 0;
  strgrd.visible := True;
end;

end.

