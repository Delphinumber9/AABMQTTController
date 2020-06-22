unit uExceptMsg;

interface

uses
  // VarDef,         2
  Dialogs,
  SysUtils,
  Forms,
  uFrmExceptMsg, //  in 'ExceptMsg\uExceptMsg.pas',
  Controls;

const
  CR = #13 + #10;
  DetailHeight = 600;
  UserHeight = 180;

var
  bDetails: boolean;

{Original}
procedure ExceptMsg(UnitName: string; CodeLine: integer;
  UserMessage, inDetailMessage: string; ExcObj: TObject;
  bShowMessage: boolean); overload;
{Ableitungen}
procedure ExceptMsg(UnitName: string; CodeLine: integer;
  inDetailMessage: string); overload;
procedure ExceptMsg(UnitName: string; CodeLine: integer; inDetailMessage: string;
  ExcObj: TObject); overload;
procedure ExceptMsg(UnitName: string; CodeLine: integer; ExcObj: TObject); overload;
procedure ExceptMsg(UnitName: string; CodeLine: integer;
  UserMessage, inDetailMessage: string); overload;
procedure ExceptMsg(CodeLine: integer; UserMessage, inDetailMessage: string); overload;

procedure myApplicationTerminate;


implementation

// Uses Util, uCommonDataFkt, AdsTable, uPingCheck;

const
  _UnitName = 'uExceptMsg';

function DirSlash(Directory: string): string;
var
  StrBuffer: string;
  // Sorgt dafür, dass das letzte Zeichen eines Pfadnamens ein Slash ist.
begin
   {$IFDEF LINUX}
  if Copy(Directory, Length(Directory), 1) <> '/' then
    StrBuffer := Directory + '/'
  else
    StrBuffer := Directory;
  DirSlash := StrBuffer;
   {$ENDIF}
   {$IFDEF MSWINDOWS}
  if Copy(Directory, Length(Directory), 1) <> '\' then
    StrBuffer := Directory + '\'
  else
    StrBuffer := Directory;
  DirSlash := StrBuffer;
   {$ENDIF}

end;



procedure ExceptMsg(CodeLine: integer; UserMessage, inDetailMessage: string); overload;
begin
  ExceptMsg('', CodeLine, UserMessage, inDetailMessage, nil, True);
end;

procedure ExceptMsg(UnitName: string; CodeLine: integer; inDetailMessage: string;
  ExcObj: TObject); overload;
begin
  ExceptMsg(UnitName, CodeLine, '', inDetailMessage, ExcObj, True);
end;

procedure ExceptMsg(UnitName: string; CodeLine: integer;
  inDetailMessage: string); overload;
begin
  ExceptMsg(UnitName, CodeLine, '', inDetailMessage, nil, True);
end;

procedure ExceptMsg(UnitName: string; CodeLine: integer;
  UserMessage, inDetailMessage: string); overload;
begin
  ExceptMsg(UnitName, CodeLine, UserMessage, inDetailMessage, nil, True);
end;


procedure ExceptMsg(UnitName: string; CodeLine: integer; ExcObj: TObject); overload;
begin
  ExceptMsg(UnitName, CodeLine, '', '', ExcObj, True);
end;

//RS: 2009-07-01
function isCommunicationError(ExcObj: TObject): boolean;
{Function soll ermitteln, ob es sich um eine Exception aufgrund eines Kommumikationproblem handelt
 Function soll wchsen um weitere Kommunikation-Errors
}
var
  sExceptionMessage: string;
begin
  Result := False;
  try
    if ExcObj = nil then
    begin
      EXIT;
    end
    else
    begin
      sExceptionMessage := Exception(ExcObj).Message;
      //RS: 2009-07-20
      if Pos('11008', sExceptionMessage) > 0 then
      begin
        Result := True;
        EXIT;
      end;
      if Pos('6313', sExceptionMessage) > 0 then
      begin
        Result := True;
        EXIT;
      end;
      if Pos('6610', sExceptionMessage) > 0 then
      begin
        Result := True;
        EXIT;
      end;
    end;
  except
    ShowMessage(_unitName + ' 0172' + CR + 'Exception: ' +
      Exception(ExceptObject).Message);
  end;
end;

procedure myApplicationTerminate;
  {
  Terminate funzt allerdings nicht unter XP (bei mir)
  Halt funzt bei mir, bringt bei W2003-Server jedoch eine Excepetion (Eigenschaft Visible darf in OnHide oder OnShow nicht gesetzt werden)
  Nachdem Terminate aktiviert wurde, kam der Fehler unter W2003 nicht mehr
  und Halt stoppet das System unter XP

  ToDo: Sauberen Ausstieg programmieren, meinetwegen mit eien GV
        oder aber im Kochbuch nachsehen, wie ein Password-Dialog mit der Anwendung harmoniert
  }

{ ich habe festgestellt, dass Terminate und halt nicht unbedingt das programm anhalten,
  das ist abhängig vom Betriebssystem WinXP oder Windows 2003 Server
  Desweiteren wird eine Exception geworfen: OnHide...
  Diese Funktion soll das Problem lösen.
  ggf. kann die Funktion verbessert werden

  es wure alle Termonate und halt durch diese funktion ersetzt
}
begin
  try
    //    Application.Terminate;
    //RS: 2009-05-27
    {für XP}
    Halt;
  except
   {  do nothing
    ExceptMsg(_UnitName, 186, 'Application to DownLoad:'+ ApplicationName +CR+
                              'Application.EXE: ' + Application.ExeName,
                               ExceptObject);
                               }
  end;
  try
    //RS: 2009-05-27
    {für Win 2003 Server}
    Application.Terminate;
  except
    {  do nothing
    ExceptMsg(_UnitName, 195, 'Application to DownLoad:'+ ApplicationName +CR+
                              'Application.EXE: ' + Application.ExeName,
                               ExceptObject);
                               }
  end;
end;


procedure ExceptMsg(UnitName: string; CodeLine: integer;
  UserMessage, inDetailMessage: string; ExcObj: TObject;
  bShowMessage: boolean); overload;
var
  ErrorMessageFile: Text;
  ErrorMessageName, Pfad, ExceptionMessage, lDetailMessage: string;
  IOR: integer;

begin
  Screen.Cursor := crDefault;
  try

    Application.CreateForm(TfrmError, frmError);


    lDetailMessage := inDetailMessage + CR + CR + 'Unitname: ' +
      UnitName + CR + 'CodeLine:' + IntToStr(CodeLine);

    Screen.Cursor := crDefault;
    ExceptionMessage := '';
    if UserMessage = '' then
    begin
      frmError.lbl_UserMessage.Caption := 'Anwendungsfehler.';
    end
    else
    begin
      frmError.lbl_UserMessage.Caption := UserMessage;
    end;
    if ExcObj = nil then
    begin
      frmError.MMO_DetailMessage.Text := lDetailMessage;
    end
    else
    begin
      frmError.MMO_DetailMessage.Text :=
        lDetailMessage + CR + CR + 'Exception:' +
        Exception(ExcObj).Message;
      ExceptionMessage := Exception(ExcObj).Message;
    end;

    if bShowMessage then
    begin
      frmError.gbx_Details.Enabled := False;
      frmError.gbx_Details.Visible := False;
      frmError.Height := UserHeight;
      frmError.ShowModal;
    end;

    try
      Pfad := ExtractFilePath(Application.ExeName);
      if Pfad = '' then
        Pfad := 'C:';
      ErrorMessageName := DirSlash(Pfad) + 'ErrorLog.TXT';

      {Fehlermeldung für permanente Fehler-Log-Datei schreiben}
      { ErrorMessage öffnen oder rewriten }
      if not FileExists(ErrorMessageName) then
      begin
        Assign(ErrorMessageFile, ErrorMessageName);
        {$I- }
        Rewrite(ErrorMessageFile);
{$I+}
        IOR := IOResult;
        if IOR <> 0 then
        begin
          MessageDlg('IOR:' + IntToStr(IOR) + CR +
            'ErrorMessageName:' + ErrorMessageName + ':' + CR +
            'in uExceptMsg, can not REWRITE above file' + CR +
            'Program terminated.' + CR + 'uExceptMsg (078)',
            mtError, [mbOK], 0);
          Exit;
        end;
      end
      else
      begin
        Assign(ErrorMessageFile, ErrorMessageName);
        {$I- }
        Append(ErrorMessageFile);
{$I+}
        Ior := IOResult;
        if IOR <> 0 then
        begin
          MessageDlg('IOR:' + IntToStr(IOR) + CR +
            'ErrorMessageName:' + ErrorMessageName + ':' + CR +
            'uExceptMsg (094). Kann Systemmeldung nicht in das File "' + ErrorMessageName
            + '" schreiben (anhängen). .' + CR + 'Detailmessage:' + CR +
            lDetailMessage + CR + CR + 'Program terminated.' + CR +
            'uExceptMsg (063)', mtError, [mbOK], 0);
          Exit;
        end;
      end; {of ExistFile(ErrorMessageName)}
      try
        Writeln(ErrorMessageFile, CR + 'ExceptMsg: ', DateToStr(Date), ' - ', TimeToStr(Time));
        Writeln(ErrorMessageFile, frmError.MMO_DetailMessage.Text + CR);
        Close(ErrorMessageFile);
      except
        ;
      end;

    except
      MessageDlg('ExceptMsg (110) ExceptMsg could not executed.' + CR +
        'Error Logfile was not updated.' + CR + CR +
        'Exception:' + Exception(ExceptObject).Message,
        mtError, [mbOK], 0);
    end;  // Except
  finally
    FreeAndNil(frmError);
  end;
end; {Procedure ExceptMsg}



end.
