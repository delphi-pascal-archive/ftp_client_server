{ $HDR$}

unit mainf;

interface

uses
  Windows, Messages, Graphics, Controls, Forms, Dialogs, StdCtrls, ExtCtrls, ComCtrls,
  Menus,  SysUtils, Classes, IdIntercept, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdFTP, IdAntiFreezeBase, IdAntiFreeze, IdLogBase, IdLogDebug, IdGlobal,
  IdLogEvent, IdFTPCommon, IdFTPList, FileCtrl;

type
  TMainForm = class(TForm)
    DirectoryListBox: TListBox;
    IdFTP1: TIdFTP;
    DebugListBox: TListBox;
    UploadOpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    StatusBar1: TStatusBar;
    IdAntiFreeze1: TIdAntiFreeze;
    ProgressBar1: TProgressBar;
    PopupMenu1: TPopupMenu;
    Download1: TMenuItem;
    Upload1: TMenuItem;
    Delete1: TMenuItem;
    N1: TMenuItem;
    Back1: TMenuItem;
    IdLogEvent1: TIdLogEvent;
    HeaderControl1: THeaderControl;
    CurrentDirEdit: TEdit;
    ChDirButton: TButton;
    CreateDirButton: TButton;
    Label4: TLabel;
    Label1: TLabel;
    FtpServerEdit: TEdit;
    Label2: TLabel;
    UserIDEdit: TEdit;
    PasswordEdit: TEdit;
    Label3: TLabel;
    ConnectButton: TButton;
    TraceCheckBox: TCheckBox;
    UsePassive: TCheckBox;
    DownloadButton: TButton;
    UploadButton: TButton;
    DeleteButton: TButton;
    BackButton: TButton;
    AbortButton: TButton;
    procedure ConnectButtonClick(Sender: TObject);
    procedure UploadButtonClick(Sender: TObject);
    procedure DirectoryListBoxDblClick(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure IdFTP1Disconnected(Sender: TObject);
    procedure AbortButtonClick(Sender: TObject);
    procedure BackButtonClick(Sender: TObject);
    procedure IdFTP1Status(axSender: TObject; const axStatus: TIdStatus;
      const asStatusText: String);
    procedure TraceCheckBoxClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DirectoryListBoxClick(Sender: TObject);
    procedure IdFTP1Work(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCount: Integer);
    procedure IdFTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCountMax: Integer);
    procedure IdFTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
    procedure UsePassiveClick(Sender: TObject);
    procedure ChDirButtonClick(Sender: TObject);
    procedure CreateDirButtonClick(Sender: TObject);
    procedure IdLogEvent1Received(ASender: TComponent; const AText,
      AData: String);
    procedure IdLogEvent1Sent(ASender: TComponent; const AText,
      AData: String);
    procedure DebugListBoxDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure DirectoryListBoxDrawItem(Control: TWinControl;
      Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure HeaderControl1SectionResize(HeaderControl: THeaderControl;
      Section: THeaderSection);
  private
    { Private declarations }
    AbortTransfer: Boolean;
    TransferrignData: Boolean;
    BytesToTransfer: LongWord;
    STime: TDateTime;
    procedure ChageDir(DirName: string);
    procedure PutToDebugLog(Operation, S1: string);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

var
 AverageSpeed: Double=0;

procedure TMainForm.ConnectButtonClick(Sender: TObject);
begin
 ConnectButton.Enabled:=false;
 if IdFTP1.Connected
 then
  try
   if TransferrignData
   then IdFTP1.Abort;
   IdFTP1.Quit;
  finally
   CurrentDirEdit.Text:='/';
   DirectoryListBox.Items.Clear;
   ConnectButton.Caption:='Connect';
   ConnectButton.Enabled:=true;
   ConnectButton.Default:=true;
  end
 else
  with IdFTP1 do try
   Username:=UserIDEdit.Text;
   Password:=PasswordEdit.Text;
   Host:=FtpServerEdit.Text;
   Connect;
   Self.ChageDir(CurrentDirEdit.Text);
  finally
   ConnectButton.Enabled:=true;
   if Connected
   then
    begin
     ConnectButton.Caption:='Disconnect';
     ConnectButton.Default:=false;
    end;
  end;
end;

procedure TMainForm.UploadButtonClick(Sender: TObject);
begin
 if IdFTP1.Connected
 then
  begin
   if UploadOpenDialog1.Execute
   then
    try
     IdFTP1.TransferType:=ftBinary;
     IdFTP1.Put(UploadOpenDialog1.FileName, ExtractFileName(UploadOpenDialog1.FileName));
     ChageDir(idftp1.RetrieveCurrentDir);
    finally

    end;
  end;
end;

procedure TMainForm.ChageDir(DirName: string);
var
 LS: TStringList;
begin
 LS:=TStringList.Create;
 try
  IdFTP1.ChangeDir(DirName);
  IdFTP1.TransferType:=ftASCII;
  CurrentDirEdit.Text:=IdFTP1.RetrieveCurrentDir;
  DirectoryListBox.Items.Clear;
  IdFTP1.List(LS);
  DirectoryListBox.Items.Assign(LS);
  if DirectoryListBox.Items.Count>0
  then
   if AnsiPos('total', DirectoryListBox.Items[0])>0
   then DirectoryListBox.Items.Delete(0);
 finally
  LS.Free;
 end;
end;

procedure TMainForm.DirectoryListBoxDblClick(Sender: TObject);
var
 Name: string;
begin
 if not IdFTP1.Connected
 then Exit;
 Name:=IdFTP1.DirectoryListing.Items[DirectoryListBox.ItemIndex].FileName;
 if IdFTP1.DirectoryListing.Items[DirectoryListBox.ItemIndex].ItemType=ditDirectory
 then
  begin
   // Change directory
   ChageDir(Name);
  end
 else
  begin
   try
    SaveDialog1.FileName:=Name;
    if SaveDialog1.Execute
    then
     begin
      IdFTP1.TransferType:=ftBinary;
      BytesToTransfer:=IdFTP1.Size(Name);
      if FileExists(Name)
      then
       begin
        case MessageDlg('File aready exists. Do you want to resume the download operation?',
            mtConfirmation, mbYesNoCancel, 0) of
          mrYes:
            begin
             BytesToTransfer:=BytesToTransfer-FileSizeByName(Name);
             IdFTP1.Get(Name, SaveDialog1.FileName, false, true);
            end;
          mrNo:
            begin
             IdFTP1.Get(Name, SaveDialog1.FileName, true);
            end;
          mrCancel:
            begin
             Exit;
            end;
       end;
     end
    else IdFTP1.Get(Name, SaveDialog1.FileName, false);
    end;
   finally

   end;
  end;
end;

procedure TMainForm.DeleteButtonClick(Sender: TObject);
var
 Name: string;
begin
 if not IdFTP1.Connected
 then Exit;
 Name:=IdFTP1.DirectoryListing.Items[DirectoryListBox.ItemIndex].FileName;
 if IdFTP1.DirectoryListing.Items[DirectoryListBox.ItemIndex].ItemType=ditDirectory
 then
  try
   idftp1.RemoveDir(Name);
   ChageDir(idftp1.RetrieveCurrentDir);
  finally

  end
 else
  try
   idftp1.Delete(Name);
   ChageDir(idftp1.RetrieveCurrentDir);
  finally
  
  end;
end;

procedure TMainForm.IdFTP1Disconnected(Sender: TObject);
begin
 StatusBar1.Panels[1].Text:='Disconnected.';
end;

procedure TMainForm.AbortButtonClick(Sender: TObject);
begin
 AbortTransfer:=true;
end;

procedure TMainForm.BackButtonClick(Sender: TObject);
begin
 if not IdFTP1.Connected
 then Exit;
 try
   ChageDir('..');
 finally

 end;
end;

procedure TMainForm.IdFTP1Status(axSender: TObject; const axStatus: TIdStatus;
  const asStatusText: string);
begin
 DebugListBox.ItemIndex:=DebugListBox.Items.Add(asStatusText);
 StatusBar1.Panels[1].Text:=asStatusText;
end;

procedure TMainForm.TraceCheckBoxClick(Sender: TObject);
begin
 if TraceCheckBox.Checked
 then IdFtp1.Intercept:=IdLogEvent1
 else IdFtp1.Intercept:=nil;
 DebugListBox.Visible:=TraceCheckBox.Checked;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 IdFtp1.Intercept:=IdLogEvent1;
end;

procedure TMainForm.DirectoryListBoxClick(Sender: TObject);
begin
 if not IdFTP1.Connected
 then Exit;
 if DirectoryListBox.ItemIndex>-1
 then
  begin
   if IdFTP1.DirectoryListing.Items[DirectoryListBox.ItemIndex].ItemType=ditDirectory
   then DownloadButton.Caption:='Change dir'
   else DownloadButton.Caption:='Download';
  end;
end;

procedure TMainForm.IdFTP1Work(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
var
 S: string;
 TotalTime: TDateTime;
 // RemainingTime: TDateTime;
 H, M, Sec, MS: Word;
 DLTime: Double;
begin
 TotalTime:=Now-STime;
 DecodeTime(TotalTime, H, M, Sec, MS);
 Sec:=Sec+M*60+H*3600;
 DLTime:=Sec+MS/1000;
 if DLTime>0
 then AverageSpeed:={(AverageSpeed + }(AWorkCount/1024)/DLTime{)/2};
 if AverageSpeed>0
 then
  begin
   Sec:=Trunc(((ProgressBar1.Max-AWorkCount)/1024/AverageSpeed));
   S:=Format('%2d:%2d:%2d', [Sec div 3600, (Sec div 60) mod 60, Sec mod 60]);
   S:='Time remaining '+S;
  end
 else S:='';
 //
 S:=FormatFloat('0.00 KB/s', AverageSpeed)+'; '+S;
 case AWorkMode of
  wmRead: StatusBar1.Panels[1].Text:='Download speed '+S;
  wmWrite: StatusBar1.Panels[1].Text:='Uploade speed '+S;
 end;
 if AbortTransfer
 then IdFTP1.Abort;
 ProgressBar1.Position:=AWorkCount;
 AbortTransfer:=false;
end;

procedure TMainForm.IdFTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCountMax: Integer);
begin
 TransferrignData:=true;
 AbortButton.Visible:=true;
 AbortTransfer:=false;
 STime:=Now;
 if AWorkCountMax>0
 then ProgressBar1.Max:=AWorkCountMax
 else ProgressBar1.Max:=BytesToTransfer;
 AverageSpeed:=0;
end;

procedure TMainForm.IdFTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
begin
 AbortButton.Visible:=false;
 StatusBar1.Panels[1].Text:='Transfer complete.';
 BytesToTransfer:=0;
 TransferrignData:=false;
 ProgressBar1.Position:=0;
 AverageSpeed:=0;
end;

procedure TMainForm.UsePassiveClick(Sender: TObject);
begin
 IdFTP1.Passive:=UsePassive.Checked;
end;

procedure TMainForm.ChDirButtonClick(Sender: TObject);
begin
 ChageDir(CurrentDirEdit.Text);
end;

procedure TMainForm.CreateDirButtonClick(Sender: TObject);
var
 S: string;
begin
 S:=InputBox('Make new directory', 'Name', '');
 if S<>''
 then
  try
   IdFTP1.MakeDir(S);
   ChageDir(CurrentDirEdit.Text);
  finally

  end;
end;

procedure TMainForm.PutToDebugLog(Operation, S1: String);
var
 S: string;
begin
 while Length(S1)>0 do
  begin
   if Pos(#13, S1)>0
   then
    begin
     S:=Copy(S1, 1, Pos(#13, S1)-1);
     Delete(S1, 1, Pos(#13, S1));
     if S1[1]=#10
     then Delete(S1, 1, 1);
    end
   else S := S1;
   DebugListBox.ItemIndex := DebugListBox.Items.Add(Operation + S);
  end;
end;

procedure TMainForm.IdLogEvent1Received(ASender: TComponent; const AText,
  AData: string);
begin
 PutToDebugLog('<<- ', AData);
end;

procedure TMainForm.IdLogEvent1Sent(ASender: TComponent; const AText,
  AData: string);
begin
 PutToDebugLog('->> ', AData);
end;

{$IFDEF Linux}
procedure TMainForm.DebugListBoxDrawItem(Sender: TObject; Index: Integer;
  Rect: TRect; State: TOwnerDrawState; var Handled: Boolean);
{$ELSE}
procedure TMainForm.DebugListBoxDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
{$ENDIF}
begin
 if Pos('>>', DebugListBox.Items[index])>1
 then DebugListBox.Canvas.Font.Color:=clRed
 else DebugListBox.Canvas.Font.Color:=clBlue;
 if odSelected in State
 then
  begin
   DebugListBox.Canvas.Brush.Color:=$00895F0A;
   DebugListBox.Canvas.Font.Color:=clWhite;
  end
 else DebugListBox.Canvas.Brush.Color := clWindow;
 DebugListBox.Canvas.FillRect(Rect);
 DebugListBox.Canvas.TextOut(Rect.Left, Rect.Top, DebugListBox.Items[index]);
end;

{$IFDEF Linux}
procedure TMainForm.DirectoryListBoxDrawItem(Sender: TObject; Index: Integer;
  Rect: TRect; State: TOwnerDrawState; var Handled: Boolean);
{$ELSE}
procedure TMainForm.DirectoryListBoxDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
{$ENDIF}
var
 R: TRect;
begin
 if odSelected in State
 then
  begin
   DirectoryListBox.Canvas.Brush.Color:=$00895F0A;
   DirectoryListBox.Canvas.Font.Color:=clWhite;
  end
 else DirectoryListBox.Canvas.Brush.Color:=clWindow;
 //
 if Assigned(IdFTP1.DirectoryListing) and (IdFTP1.DirectoryListing.Count>Index)
 then
  begin
   DirectoryListBox.Canvas.FillRect(Rect);
   with IdFTP1.DirectoryListing.Items[Index] do
    begin
     DirectoryListBox.Canvas.TextOut(Rect.Left, Rect.Top, FileName);
     R:=Rect;
     R.Left:=Rect.Left+HeaderControl1.Sections.Items[0].Width;
     R.Right:=R.Left+HeaderControl1.Sections.Items[1].Width;
     DirectoryListBox.Canvas.FillRect(R);
     DirectoryListBox.Canvas.TextOut(R.Left, Rect.Top, IntToStr(Size));

     R.Left:=R.Right;
     R.Right:=R.Left+HeaderControl1.Sections.Items[2].Width;
     DirectoryListBox.Canvas.FillRect(R);

     if ItemType=ditDirectory
     then DirectoryListBox.Canvas.TextOut(R.Left, Rect.Top, 'Directory')
     else DirectoryListBox.Canvas.TextOut(R.Left, Rect.Top, 'File');

     R.Left:=R.Right;
     R.Right:=R.Left+HeaderControl1.Sections.Items[3].Width;
     DirectoryListBox.Canvas.FillRect(R);
     DirectoryListBox.Canvas.TextOut(R.Left, Rect.Top, FormatDateTime('mm/dd/yyyy hh:mm', ModifiedDate));

     R.Left:=R.Right;
     R.Right:=R.Left+HeaderControl1.Sections.Items[4].Width;
     DirectoryListBox.Canvas.FillRect(R);
     DirectoryListBox.Canvas.TextOut(R.Left, Rect.Top, GroupName);

     R.Left:=R.Right;
     R.Right:=R.Left+HeaderControl1.Sections.Items[5].Width;
     DirectoryListBox.Canvas.FillRect(R);
     DirectoryListBox.Canvas.TextOut(R.Left, Rect.Top, OwnerName);

     R.Left:=R.Right;
     R.Right:=R.Left+HeaderControl1.Sections.Items[6].Width;
     DirectoryListBox.Canvas.FillRect(R);
     DirectoryListBox.Canvas.TextOut(R.Left, Rect.Top, OwnerPermissions + GroupPermissions + UserPermissions);
    end;
  end;
end;

{$IFDEF Linux}
procedure TMainForm.HeaderControl1SectionResize(HeaderControl: TCustomHeaderControl;
  Section: TCustomHeaderSection);
{$ELSE}
procedure TMainForm.HeaderControl1SectionResize(HeaderControl: THeaderControl; Section: THeaderSection);
{$ENDIF}
begin
 DirectoryListBox.Repaint;
end;

end.
