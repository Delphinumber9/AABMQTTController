unit uFrmExceptMsg;

interface

uses
  {$IFDEF MSWINDOWS}
     Windows,
  {$ENDIF}
  Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TfrmError = class(TForm)
    btn_OK: TButton;
    btn_Details: TButton;
    GroupBox1: TGroupBox;
    gbx_Details: TGroupBox;
    lbl_UserMessage: TLabel;
    mmo_DetailMessage: TMemo;
    btn_Terminate: TButton;
    Label1: TLabel;
    procedure btn_OKClick(Sender: TObject);
    procedure btn_DetailsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btn_TerminateClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  frmError: TfrmError;

implementation

{$R *.DFM}

uses uExceptMsg;

const _UnitName = 'uFrmExceptMsg';

procedure TfrmError.btn_OKClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmError.btn_DetailsClick(Sender: TObject);
begin
  Try
    if frmError = nil then begin
       EXIT;
    end;
    bDetails := bDetails = False;
    If bDetails Then Begin
      frmError.Height := DetailHeight;
      frmError.gbx_Details.Enabled := True;
      frmError.gbx_Details.Visible := True;
      frmError.btn_Details.Caption := 'Details schließen';

    End Else Begin
      frmError.Height := UserHeight;
      frmError.gbx_Details.Enabled := False;
      frmError.gbx_Details.Visible := False;
      frmError.btn_Details.Caption := 'Details zeigen';

    End;
    Application.ProcessMessages;
  Except
    MessageDlg(_unitname + '  (053) Fehlerprozedure konnte nicht ausgeführt werden.'+CR+
               'Exception:'+Exception(ExceptObject).Message,
                mtError,[mbOK],0);
  End;
end;

procedure TfrmError.FormCreate(Sender: TObject);
begin
  bDetails := False; 
end;

procedure TfrmError.btn_TerminateClick(Sender: TObject);
begin
  If mrOK = MessageDLG('Möchten Sie das Programm wirklich beenden?'+CR+CR+
                       'Bei einem Programmabbruch kann Datenverlust entstehen!', mtWarning, mbOKCancel, 0)
    Then Begin
      myApplicationTerminate;
      Application.ProcessMessages;
    End;
end;

end.
