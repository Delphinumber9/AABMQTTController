unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  LazSerial, TMS.MQTT.Client,
  // 2020-03
  TMS.MQTT.Global, {StrUtils, }DateUtils,
  uWindowsOpener,
  uExceptMsg,
  // uExceptMsg in 'C:\lazarus\Projects\MQTTStart\ExceptMsg\uExceptMsg.pas',
  DHT_Sensors, IniFiles, sqlite3conn, sqldb,
  Serial, Globals, dbutils,
  utils
  ;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnConnectToBroker: TButton;
    btnSetSubscriber: TButton;
    btnValidateSubscribe: TButton;
    Button1: TButton;
    btnTestSQLConn: TButton;
    Button4: TButton;
    cbxItRains: TCheckBox;
    cbxWindows1Open: TCheckBox;
    Label1: TLabel;
    lbll_Serial_transmitted: TLabel;
    lbl_MQTT_Messages: TLabel;
    lbl_MQTT_Messages1: TLabel;
    Memo_MQTT_RX: TMemo;
    Memo_MQTT_TX: TMemo;
    Memo_Serial_RX: TMemo;
    Memo_Serial_TX: TMemo;
    myLazSerial: TLazSerial;
    SQLite3Connection: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    TimerCheckOpenClose: TTimer;
    TMSMQTTClient: TTMSMQTTClient;
    toggleOpenWindow: TToggleBox;
    toggleCloseWindow: TToggleBox;
    procedure btnConnectToBrokerClick(Sender: TObject);
    procedure btnSetSubscriberClick(Sender: TObject);
    procedure btnTestSQLConnClick(Sender: TObject);

    procedure btnValidateSubscribeClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure myLazSerialRxData(Sender: TObject);
    procedure TimerCheckOpenCloseTimer(Sender: TObject);
    procedure TMSMQTTClientConnectedStatusChanged(ASender: TObject;
      const AConnected: boolean; AStatus: TTMSMQTTConnectionStatus);
    procedure TMSMQTTClientPublishReceived(ASender: TObject; APacketID: word;
      ATopic: string; APayload: TBytes);
    procedure TMSMQTTClientSubscriptionAcknowledged(ASender: TObject;
      APacketID: word; ASubscriptions: TTMSMQTTSubscriptions);
    procedure toggleCloseWindowChange(Sender: TObject);
    procedure toggleOpenWindowChange(Sender: TObject);

    // 2020-04-02
    procedure setSubscriber;
    procedure connectToBroker;
    // 2020-05-31
    procedure SendMQTTMessage(sTopic, sPayload : String);
    procedure OpenPort;
    procedure CloseWindowsForInit(Sender: TObject);
  private

  public

  end;

var
  frmMain: TfrmMain;



const
  _UnitName = 'uMain';
  //maxLinesInMemos = 100;

  // windowsOpeners_max = 2;
  itRains = False; { TODO : muss nach var verschoben werden, wenn es einen Regensensor gibt }

var
  // 2020-06-07
  allDevices: array of T_allDevices;

  Aussensensor: T_DHT;
  innenSensors: array of T_DHT;

  windowsOpeners: array of T_WindowsOpener;


implementation

{$R *.lfm}

{ TfrmMain }

// 2020-06-17
procedure WritePortToControl(Value : String);
var
  INIFileName: string;
  INIFile: TINIFile;
begin
  try
    INIFileName := ExtractFilePath(ParamStr(0)) + 'Control.ini';
    INIFile := TINIFile.Create(INIFileName);

    {$IFDEF MSWINDOWS}
        INIFile.WriteString('Ports', 'WindowsPort', Value);
        {$ELSE}
          {$IFDEF LINUX}
              // appData.PortName := INIFile.ReadString('Ports', 'LinuxPort', '/dev/ttyUSB0');
              INIFile.WriteString('Ports', 'LinuxPort', Value);
          {$ENDIF}
      {$ENDIF}

    INIFile.Free;
  except
    ExceptMsg(_Unitname, 1289, 'WritePortToControl', ExceptObject);
  end;
end;

procedure ReadControl(var appData: TAppData);
var
  INIFileName: string;
  INIFile: TINIFile;
begin
  try
    INIFileName := ExtractFilePath(ParamStr(0)) + 'Control.ini';
    INIFile := TINIFile.Create(INIFileName);
    // with INIFile do begin
    appData.maxLiveTimeOfSignals_inSec :=
      INIFile.ReadInteger('WindowsOpener', 'maxLiveTimeOfSignals_inSec', 299);

    // 2020-06-19
    appData.maxLinesInMemos :=
      INIFile.ReadInteger('General', 'maxLinesInMemos', 200);


    //appData.windowsOpeners_max :=
      // INIFile.ReadInteger('WindowsOpener', 'windowsOpeners_max', 8);

    // 2020-06-07
    appData.minIntervalBetween2Openings := INIFile.ReadInteger('WindowsOpener', 'minIntervalBetween2Openings_inSec', 180);
    appData.minHumidityDiff_InOut := INIFile.ReadInteger('WindowsOpener', 'minHumidityDiff_InOut', 1);


    appData.DatabaseName :=     INIFile.ReadString('DatabaseName', 'DatabaseName', 'AirControl.db');

    // 2020-06-11
    appData.GatewaySendCommand:= 'SendToDevice:';

    // 2020-05-30
    {$IFDEF MSWINDOWS}
        appData.PortName := INIFile.ReadString('Ports', 'WindowsPort', 'COM1');
        {$ELSE}
          {$IFDEF LINUX}
              appData.PortName := INIFile.ReadString('Ports', 'LinuxPort', '/dev/ttyUSB0');
          {$ENDIF}
      {$ENDIF}

    INIFile.Free;
    // end;
  except
    ExceptMsg(_Unitname, 931, 'Error ReadControl', ExceptObject);

  end;
end; // ReadCounterFile

// 2020-05-31
function ReadSensorActorIDDataFromControl(SensorActorID : byte) : string;
var
  INIFileName, sSensorActorID  : string;
  INIFile: TINIFile;
begin
  try
    INIFileName := ExtractFilePath(ParamStr(0)) + 'Control.ini';
    INIFile := TINIFile.Create(INIFileName);
    sSensorActorID :=  'SensorActorID_' + intToStr(SensorActorID);
    Result := INIFile.ReadString(sSensorActorID, 'Topic', 'noTopicFoundinControl.ini for ' + sSensorActorID);
    INIFile.Free;
    // end;
  except
    ExceptMsg(_Unitname, 7612, 'Error ReadControl', ExceptObject);

  end;
end;


// 2020-06-07
function getSensorActorIDfromDevices(SensorActorID : byte; var Topic : string) : boolean;
var
  INIFileName, sSensorActorID  : string;
  INIFile: TINIFile;
  i : integer;

begin
  try
    for i:= 0 to Length(allDevices) do begin
      if (allDevices[i].DeviceID = SensorActorID) then begin
        Topic := allDevices[i].Topic;
        result := true;
        EXIT;
      end;
    end;

    // Fehlerfall
    Topic := 'noTopicFoundinDevices for SensorActorID' + sSensorActorID;
    Result := false;
  except
    ExceptMsg(_Unitname, 7612, 'Error ReadControl', ExceptObject);
    Result := false;

  end;
end;


procedure initWindowsOpeners(aussenSensor: T_DHT; innenSensors: array of T_DHT);
var
  i: integer;
begin
  try
    //Aussensensor.Topic := 'Aussensensor/T_Hrel_Habs';

    for i := 0 to Length(windowsOpeners) - 1 do
    begin
      windowsOpeners[i] := T_WindowsOpener.Create;
      windowsOpeners[i].ActorTopic := 'WindowsOpener_R' + IntToStr(i + 1) + '/OpenClose';

      // windowsOpeners[i].innenSensor := innenSensors[i];
      // windowsOpeners[i].aussenSensor := aussenSensor;

      // 2020-06-11
      windowsOpeners[i].doOpenClose:= TOpenClose.Close;
      windowsOpeners[i].isOpenClose:= TOpenClose.Close;

      windowsOpeners[i].WO_innenSensor := innenSensors[i];
      windowsOpeners[i].WO_aussenSensor := aussenSensor;

      // windowsOpeners[i].minIntervalBetween2Openings_inSec := 60;
      // windowsOpeners[i].minHumidityDiff_InOut := 1;
      // windowsOpeners[i].maxDiffOfLastReceive_of_InOutSignals_inSec := 120;


    end;
  except
    ExceptMsg(_UNitname, 7598, 'Error InitWindowsOpeners', ExceptObject);
  end;
end;


// 2020-06-07
procedure initDHTSensors_byDB;
var
  i : integer;
  QY : TSQLQuery;
  sSQL : String;
begin
  try

    // Aussensensor.Topic := ReadRadioDataFromControl(RadioID : byte);
    // ************* AussenSensoren ****************
    sSQL := 'Select * from Devices'
          + ' where Upper(Type) = ''SENSOROUT'' '
          + ' and Upper(SubType) = ''DHT''  '
          + ' order by Topic' ;

    if (QY_CreateAndOpen(QY, sSQL) = False) then begin
      EXIT;
    end;
    if (QY.RecordCount <>1 ) then begin
      ShowMessage('Error (2350): Die Anzahl der DHT-AussenSensoren muss = 1 sein! Table Devices ändern');
      EXIT;
    end;

    i:= 0;
    while not QY.EOF do begin
       // Topic := QY.FieldByName('DHTinTopic').AsString;
       Aussensensor := T_DHT.Create;
       Aussensensor.Topic := QY.FieldByName('Topic').AsString; //'Aussensensor/T_Hrel_Habs';
       Aussensensor.DeviceID := QY.FieldByName('DeviceID').AsInteger;
       Aussensensor.sType := QY.FieldByName('Type').AsString;
       Aussensensor.SubType := QY.FieldByName('SubType').AsString;
       Aussensensor.Description := QY.FieldByName('Description').AsString;

       i := i + 1;
       QY.Next;
    end;

    QY_CloseAndFree(QY);

    // ************* InnenSensoren ****************
    sSQL := 'Select * from Devices'
          + ' where Upper(Type) = ''SENSORIN'' '
          + ' and Upper(SubType) = ''DHT''  '
          + ' order by Topic' ;

    if (QY_CreateAndOpen(QY, sSQL) = False) then begin
      EXIT;
    end;


    SetLength(innenSensors, QY.RecordCount);
    i:= 0;
    while not QY.EOF do begin
       // Topic := QY.FieldByName('DHTinTopic').AsString;

       innenSensors[i] := T_DHT.Create;
       innenSensors[i].Topic := QY.FieldByName('Topic').AsString; // 'Innensensor_R' + IntToStr(i + 1) + '/T_Hrel_Habs';
       innenSensors[i].DeviceID := QY.FieldByName('DeviceID').AsInteger;
       innenSensors[i].sType := QY.FieldByName('Type').AsString;
       innenSensors[i].SubType := QY.FieldByName('SubType').AsString;
       innenSensors[i].Description := QY.FieldByName('Description').AsString;

       i := i + 1;
       QY.Next;
    end;

    QY_CloseAndFree(QY);

  except
    ExceptMsg(_Unitname, 2256, 'Error InitDHTSensors', ExceptObject);

  end;
end;

// 2020-06-07
procedure initAllDevices_byDB;
var
  i : integer;
  QY : TSQLQuery;
  sSQL : String;
begin
  try


     // ************* AllDevices****************
    sSQL := 'Select * from Devices'
          + ' order by DeviceID' ;

    if (QY_CreateAndOpen(QY, sSQL) = False) then begin
        EXIT;
    end;



    if (QY_CreateAndOpen(QY, sSQL) = False) then begin
      EXIT;
    end;

    SetLength(allDevices, QY.RecordCount);
    i:= 0;
    while not QY.EOF do begin
       allDevices[i] := T_allDevices.Create;
       allDevices[i].DeviceID := QY.FieldByName('DeviceID').AsInteger;
       allDevices[i].sType := QY.FieldByName('Type').AsString;
       allDevices[i].SubType := QY.FieldByName('SubType').AsString;
       allDevices[i].Topic := QY.FieldByName('Topic').AsString;
       allDevices[i].Description := QY.FieldByName('Description').AsString;

       i := i + 1;
       QY.Next;
    end;

    QY_CloseAndFree(QY);

  except
    ExceptMsg(_Unitname, 3458, 'Error InitDHTSensors', ExceptObject);
  end;
end;

procedure initWindowsOpeners_byDB;
var
  i, j : integer;
  QY : TSQLQuery;
  sWO_DHTInTopic, sSQL: string;
begin
  try
    //alt: Aussensensor.Topic := 'Aussensensor/T_Hrel_Habs';
    //neu: Aussensensor.Topic := 'Out/DHT';

    // 2020-06-11
     sSQL := 'Select * from WindowOpener WO, Devices D'
          + ' where WO.ActorTopic = D.Topic'
          + ' order by DHTinTopic';

    if (QY_CreateAndOpen(QY, sSQL) = False) then begin
      EXIT;
    end;


    SetLength(windowsOpeners, QY.RecordCount);
    i:= 0;
    while not QY.EOF do begin
       // Topic := QY.FieldByName('DHTinTopic').AsString;
       windowsOpeners[i] := T_WindowsOpener.Create;
       windowsOpeners[i].WO_aussenSensor := T_DHT.Create();
       windowsOpeners[i].WO_innenSensor := T_DHT.Create();

       windowsOpeners[i].ActorTopic := QY.FieldByName('ActorTopic').AsString; // 'WindowsOpener_R' + IntToStr(i + 1) + '/OpenClose';
       // windowsOpeners[i].innenSensor.Topic := QY.FieldByName('DHTinTopic').AsString;
       // windowsOpeners[i].aussenSensor.Topic := QY.FieldByName('DHToutTopic').AsString;

       // 2020-06-11
       windowsOpeners[i].ActorID := QY.FieldByName('DeviceID').AsInteger;

       sWO_DHTInTopic := QY.FieldByName('DHTinTopic').AsString;

       // 2020-06-07 ToDo: next 2 lines: hier muss eine Zuordnung getroffen werden:
       windowsOpeners[i].WO_aussenSensor := aussenSensor;
       // windowsOpeners[i].WO_innenSensor := innenSensors[i];
       // 2020-06-08
       // passenden InnenSensor suchen und zuweisen, wird später in OpenClose verwendet:
       for j := 0 to Length(innenSensors) do begin
         if (sWO_DHTInTopic.ToUpper = innenSensors[j].Topic.ToUpper) then begin
            windowsOpeners[i].WO_innenSensor := innenSensors[j];
            break;
         end;
       end;
       // windowsOpeners[i].minIntervalBetween2Openings_inSec := appData.minIntervalBetween2Openings;
       // windowsOpeners[i].minHumidityDiff_InOut := appData.minHumidityDiff_InOut;
       // windowsOpeners[i].maxDiffOfLastReceive_of_InOutSignals_inSec := appData.maxDiffOfLastReceive_of_InOut_inSec;
       i := i + 1;
       QY.Next;
    end;

     QY_CloseAndFree(QY);

  except
    ExceptMsg(_UNitname, 7598, 'Error InitWindowsOpeners', ExceptObject);
  end;
end;


procedure initAll;
begin
  try
    ReadControl(appData);

    // 2020-06-07 SetLength(windowsOpeners, appData.windowsOpeners_max);

    // 2020-06-07 initDHTSensors;
    initAllDevices_byDB;
    initDHTSensors_byDB;
    initWindowsOpeners_byDB;
    // initWindowsOpeners(aussenSensor, innenSensors);

  except

  end;
end;


procedure TfrmMain.connectToBroker;
begin
  TMSMQTTClient.ClientID := 'MyClientID';
  TMSMQTTClient.BrokerHostName := 'LocalHost';
  TMSMQTTClient.OnConnectedStatusChanged := @TMSMQTTClientConnectedStatusChanged;

  // Optional - Auto-Reconnect
  TMSMQTTClient.KeepAliveSettings.AutoReconnect := True;
  TMSMQTTClient.KeepAliveSettings.AutoReconnectInterval := 5; // Try

  TMSMQTTClient.Connect;
end;

procedure TfrmMain.btnConnectToBrokerClick(Sender: TObject);
begin
  connectToBroker;
end;

procedure TfrmMain.setSubscriber;
var
  i: integer;
begin
  try
    //packetID := TMSMQTTClient.Subscribe('Arduino/LED', // the topic filter
    //  TMS.MQTT.Global.qosAtMostOnce);  // Default - the quality of Service that could be used

    // Aussensensor/T_Hrel_Habs
    (* 2020-06-08 - allDevices wird jetzt ausgewertet, damit alle Topics aboniert werden
    Aussensensor.packetID :=
      TMSMQTTClient.Subscribe(Aussensensor.Topic, qosAtMostOnce);

    for i := 0 to Length(innenSensors) - 1 do
    begin
      innenSensors[i].packetID :=
        TMSMQTTClient.Subscribe(innenSensors[i].Topic, qosAtMostOnce);
    end;
    *)

    // 2020-06-08 - allDevices wird jetzt ausgewertet, damit alle Topics aboniert werden
    for i := 0 to Length(allDevices) - 1 do
    begin
      allDevices[i].packetID :=
        TMSMQTTClient.Subscribe(allDevices[i].Topic, qosAtMostOnce);
    end;

  except
    ExceptMsg(_UnitName, 12325, 'Eror (128) SetSubscriber', ExceptObject);
  end;
end;

procedure TfrmMain.btnSetSubscriberClick(Sender: TObject);
begin
  setSubscriber;
end;

procedure TfrmMain.btnTestSQLConnClick(Sender: TObject);
var iRecordCount, i : Integer;
    Topic : String;
begin
  // 2020-06-02
  try
    SQLite3Connection.Connected:= true;
    SQLTransaction1.Active:= true;

    // SQLQuery1.SQL.Text := 'Select * from Devices order by DeviceID';
    SQLQuery1.SQL.Text := 'Select * from WindowOpener order by DHTinTopic Desc';
    SQLQuery1.Open;
    iRecordCount:= SQLQuery1.RecordCount;

    while not SQLQuery1.EOF do begin
       Topic := SQLQuery1.FieldByName('DHTinTopic').AsString;
       SQLQuery1.Next;
    end;

 (*
    for i:= 1 to SQLQuery1.RecordCount do begin
       Topic := SQLQuery1.FieldByName('Topic').AsString;
       SQLQuery1.Next;
    end;    *)


    SQLQuery1.Close;
    SQLTransaction1.Active:= false;
    SQLite3Connection.Connected:= false;

  except
    ExceptMsg(_UnitName, 13275, 'Eror (128) SetSubscriber', ExceptObject);
  end;

end;


procedure TfrmMain.OpenPort;
// 2020-06-12
// Beispiel mit SerialHandle, ich vermute, der Port kann abgetestet werden:
// SerialHanndle gab 0, als der Port nicht existierte
// gab 652 als der Port existierte, allerdings trotzdem eine EXception auf der VM.
// unter Linux testen
//
// https://wiki.freepascal.org/Hardware_Access#TLazSerial
//
// Achtung: Es wird 'FPC built in Serial unit' benutzt
//
// Pi:
// falscher Port gibt -1 zurück
// richtiger: 21

var serialHandle : LongInt;
    i : integer;
    sTestPortName : String;
    ErrorOpen : boolean;
  begin
    try
      // Test only:
        // appData.PortName:='COM4';

        ErrorOpen := false;
        // 2020-06-22 myLazSerial.BaudRate := br__9600;
        myLazSerial.BaudRate := br115200;
        myLazSerial.Device := appData.PortName;
        try
           myLazSerial.Open;
        except
          ErrorOpen := true;
          // myLazSerial.Close;

        end;
        (*
        // 2002-06-12 TEST
        // serialhandle := SerOpen(appData.PortName);
        if (ErrorOpen) then begin // Port suchen
           for i:= 1 to 20 do begin
             {$IFDEF MSWINDOWS}
                //sTestPortName := 'COM'+ IntToStr(i);
                sTestPortName := 'COM3';
             {$ELSE}
                 {$IFDEF LINUX}
                   sTestPortName := '/dev/ttyUSB'+ IntToStr(i-1);
                 {$ENDIF}
             {$ENDIF}

              // serialHandle := SerOpen(sTestPortName);
              // if (serialHandle > 0) then begin // Port gefunden
              if (true)   then begin
                try

                  appData.PortName:= sTestPortName;
                  myLazSerial.Open;
                  WritePortToControl(appData.PortName);
                  ErrorOpen := false;
                  break;
                except
                  ErrorOpen := true;
                  myLazSerial.Close;
                end;
              end;
           end;
        end;
        *)
        if (myLazSerial.Active) then
        begin
          Memo_Serial_RX.Lines.Add('active Port: ' + appData.PortName);
          TimerCheckOpenClose.Enabled:=true;
        end else begin
           Memo_Serial_RX.Lines.Add('Port: ' + appData.PortName + ' laesst sich nicht öffnen');
           Memo_Serial_RX.Lines.Add('*** Anwendung wird geschlossen. **************************');

//            ShowMessage('STOP');

           ShowMessage('Port: ' + appData.PortName + ' laesst sich nicht öffnen' + CR +
                        'Anwendung wird geschlossen.');
           TimerCheckOpenClose.Enabled:=false;
           Application.Terminate;

        end;

      except
        ExceptMsg(_UnitName, 13215, 'Eror (128) SetSubscriber', ExceptObject);
      end;
  end;



var
  FSubscribeRequestPacketId: integer;

procedure TfrmMain.btnValidateSubscribeClick(Sender: TObject);
begin
  TMSMQTTClient.OnSubscriptionAcknowledged := @TMSMQTTClientSubscriptionAcknowledged;
  FSubscribeRequestPacketId := TMSMQTTClient.Subscribe('myapp/sensors/#');
end;

procedure TfrmMain.Button1Click(Sender: TObject);
var i : double;
begin
  try
        i := i/0;
  except
    ExceptMsg(_UnitName, 2156, 'Error Test 1/0', ExceptObject);
  end;

end;

procedure TfrmMain.Button4Click(Sender: TObject);
begin

end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  i: integer;
begin
  try
    TMSMQTTClient.OnPublishReceived := nil;

    for i := 0 to Length(windowsOpeners) - 1 do
    begin
      windowsOpeners[i].Free;
    end;
    for i := 0 to Length(innenSensors) - 1 do
    begin
      innenSensors[i].Free;
    end;
  except
    ExceptMsg(_UnitName, 2156, 'Error FormClose', ExceptObject);
  end;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  TMSMQTTClient := TTMSMQTTClient.Create(Self);
  TMSMQTTClient.OnPublishReceived := @TMSMQTTClientPublishReceived;

  initAll;


  connectToBroker;
  setSubscriber;
  // 2020-05-31
  CloseWindowsForInit(frmMain);

  // 2020-05-31
  OpenPort;

end;

// 2020-05-31
function extractDHTMessage(sReceive : String; var sTopic,sPayload : String) : Boolean;
var   ReceiveSplitted : array of string;
      sPrefix, sRadioID  : String;
      iRadioID : byte;

begin
  try
     result := false;
     ReceiveSplitted:= sReceive.Split(';');
     // iLength := Length(ReceiveSplitted);
     if (Length(ReceiveSplitted) < 5 ) then begin   // Satz zu kurz, raus
       EXIT;
     end
     ELSE
     begin
        sPrefix := ReceiveSplitted[0];
        // DHT-Satz ?
        if (sPrefix.ToUpper() <> 'DHT') then EXIT;

        sRadioID := ReceiveSplitted[1];
        iRadioID := StrToInt(sRadioID);
        // 2020-06-07 sTopic := ReadSensorActorIDDataFromControl(iRadioID);
        if (getSensorActorIDfromDevices(iRadioID, sTopic )) then begin

          sPayLoad := ReceiveSplitted[2]+  '/'
                  + ReceiveSplitted[3]+  '/'
                  + ReceiveSplitted[4];
          Result := true;
          EXIT;
        end;
        Result := false;
     end;
  except
    ExceptMsg(_UnitName, 8645, 'Error extractDHTMessage', ExceptObject);
  end;
end;

// 2020-05-25 - hier sollen Daten empfangen werden
procedure TfrmMain.myLazSerialRxData(Sender: TObject);
var
  sReceived, sTopic, sPayload: string;
  Lines : TStringList;
begin
  if (myLazSerial.DataAvailable) then
  begin
    sReceived := myLazSerial.ReadData;

    Lines := TStringList.Create;
    Lines.Add(sReceived);
    Lines.AddStrings(Memo_Serial_RX.Lines);
    Memo_Serial_RX.Lines := Lines;

    // Memo_Serial_RX.Lines.add(IntToStr(Memo_Serial_RX.Lines.Count + 1) + ' - ' +sReceived);
    if (Memo_Serial_RX.Lines.Count > appData.maxLinesInMemos) then begin
      Memo_Serial_RX.Lines.Clear;
    end;

    // 2020-05-31
      if (extractDHTMessage(sReceived, sTopic, sPayload)) then begin
         SendMQTTMessage(sTopic, sPayload);
      end;
  end;
end;

procedure TfrmMain.TimerCheckOpenCloseTimer(Sender: TObject);
var
  i: integer;
  sSend : String;
begin
  try
    for i := 0 to Length(windowsOpeners)- 1 do
    begin
      windowsOpeners[i].OpenCloseWindow(frmMain.TMSMQTTClient,
        // myLazSerial,
        itRains);

      // 2020-06-11
      // Sende Serial an das Gateway
      sSend := 'SendToDevice:' + IntToStr(windowsOpeners[i].ActorID) + ';';
      if (windowsOpeners[i].isOpenClose = TOpenClose.Close)  then begin
        if (windowsOpeners[i].doOpenClose = TOpenClose.Open)  then begin
          // Sende an Actor
          sSend := sSend + '1;';
          myLazSerial.WriteData(sSend);
          addLinesToMemo(Memo_Serial_TX,'TX: ' + sSend);

          // 2020-06-11 ToDo Wieder raus:
          windowsOpeners[i].isOpenClose := TOpenClose.Open;

        end;
      end
      ELSE
      if (windowsOpeners[i].isOpenClose = TOpenClose.Open)  then begin
        if (windowsOpeners[i].doOpenClose = TOpenClose.Close)  then begin
          // Sende an Actor
          sSend := sSend + '0;';
          myLazSerial.WriteData(sSend);
          addLinesToMemo(Memo_Serial_TX,'TX: ' + sSend);
          // 2020-06-11 ToDo Wieder raus:
          windowsOpeners[i].isOpenClose := TOpenClose.Close;
        end;
      end;
    end;
  except
    ExceptMsg(_UnitName, 4567, 'Error TimerCheckOpenCloseTimer', ExceptObject);
  end;

end;

procedure TfrmMain.CloseWindowsForInit(Sender: TObject);
var
  i: integer;
begin
  try
    for i := 0 to Length(windowsOpeners) - 1 do
    begin
      windowsOpeners[i].CloseWindowForInit(frmMain.TMSMQTTClient); //, myLazSerial);
    end;
  except
    ExceptMsg(_UnitName, 7649, 'CloseWindowsForInit', ExceptObject);
  end;

end;

procedure TfrmMain.TMSMQTTClientConnectedStatusChanged(ASender: TObject;
  const AConnected: boolean; AStatus: TTMSMQTTConnectionStatus);
begin
  begin
    if (AConnected) then
    begin
      // The client is now connected and you can now start interacting with the broker.
      // ShowMessage('We are connected!');
      Memo_MQTT_RX.Lines.Add('We are connected!');
    end
    else
    begin
      // The client is NOT connected and any interaction with the broker will result in an exception.
      case AStatus of
        csConnectionRejected_InvalidProtocolVersion,
        csConnectionRejected_InvalidIdentifier,
        csConnectionRejected_ServerUnavailable,
        csConnectionRejected_InvalidCredentials,
        csConnectionRejected_ClientNotAuthorized:
          ; // the connection is rejected by broker
        csConnectionLost:
          ; // the connection with the broker is lost
        csConnecting:
          ; // The client is trying to connect to the broker
        csReconnecting:
          ; // The client is trying to reconnect to the broker end;
      end;
    end;
  end;

end;




procedure TfrmMain.TMSMQTTClientPublishReceived(ASender: TObject;
  APacketID: word; ATopic: string; APayload: TBytes);

var
  sPayLoad: string;
  i : integer;

begin
  try
    sPayLoad := TEncoding.UTF8.GetString(APayload);

    (*
    Lines.Add('RX: ' + ATopic + ' - ' + sPayLoad);
        Lines.AddStrings(Memo_MQTT_RX.Lines);
        Memo_MQTT_RX.Lines := Lines;  *)

    addLinesToMemo(Memo_MQTT_RX, 'RX: ' + ATopic + ' - ' + sPayLoad);

    cbxItRains.Checked := itRains;

    if (ATopic = aussenSensor.Topic) then
    begin
      aussenSensor.PayLoad_to_Rec(sPayLoad);
    end;

    for i := 0 to Length(windowsOpeners) - 1 do
    begin
      ;
      if (ATopic = innenSensors[i].Topic) then
      begin

        innenSensors[i].PayLoad_to_Rec(sPayLoad);


        // Öffne Fenster - in den Timer verschoben:
        //windowsOpeners[i].OpenCloseWindow(frmMain.TMSMQTTClient,  itRains);

        if (i = 0) then
        begin
          cbxWindows1Open.Checked := (windowsOpeners[i].doOpenClose=TOpenClose.Open);
        end;
      end;
    end;


  except
    ExceptMsg(_UnitName, 56497, 'Error ClientPublishReceived', ExceptObject);
  end;
end;

procedure TfrmMain.TMSMQTTClientSubscriptionAcknowledged(ASender: TObject;
  APacketID: word; ASubscriptions: TTMSMQTTSubscriptions);
begin
  if (APacketID = FSubscribeRequestPacketId) and ASubscriptions[0].Accepted then
  begin
    ShowMessage('We are subscribed!');
  end;

end;

procedure TfrmMain.toggleCloseWindowChange(Sender: TObject);
var
  packetID: word;
begin
  windowsOpeners[0].CloseWindow(frmMain.TMSMQTTClient); //, myLazSerial);
  (*
  packetID := TMSMQTTClient.Publish(
                 windowsOpeners[0].ActorTopic,
                 'doClose',
                 qosAtLeastOnce);
                 *)
end;

procedure TfrmMain.toggleOpenWindowChange(Sender: TObject);
var
  packetID: word;
begin
  windowsOpeners[0].OpenWindow(frmMain.TMSMQTTClient); // , myLazSerial);
  // Send payload
  (*
   packetID := TMSMQTTClient.Publish(
                 windowsOpeners[0].ActorTopic,
                 'doOpen',
                 qosAtLeastOnce);
  *)

end;

// 2020-05-31
procedure TfrmMain.SendMQTTMessage(sTopic, sPayload : String);
var
  packetID: word;
  Lines : TStringList;
begin
  if (sTopic = '') then exit;

  try
    packetID := TMSMQTTClient.Publish(
                 sTopic,
                 sPayload,
                 qosAtLeastOnce);

    Lines := TStringList.Create;
    Lines.Add('TX: ' + sTopic + ' - ' + sPayLoad);
    Lines.AddStrings(Memo_MQTT_TX.Lines);
    Memo_MQTT_TX.Lines := Lines;

    if (Memo_MQTT_TX.Lines.Count > appData.maxLinesInMemos) then begin
      Memo_MQTT_TX.Lines.Clear;
    end;
  except
    ExceptMsg(_UnitName, 825, 'Error SendMQTTMessage', ExceptObject);
  end;

end;


end.
