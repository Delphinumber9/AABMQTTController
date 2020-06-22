unit uWindowsOpener;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Dialogs, DHT_Sensors, DateUtils,  TMS.MQTT.Client, TMS.MQTT.Global,
  // 2020.06-11
  LazSerial,
  // 2020-06-07:
  globals

  ;
  // uExceptMsg;

type

  T_WindowsOpener = class
    public
           ActorTopic: string;     // Zum Fensteröffner
        //   packetID: word;
        //   payLoad: string;
           WO_innenSensor : T_DHT;
           WO_aussenSensor : T_DHT;
          //  itRains: boolean;
          //  WindowIsOpen: boolean;
           lastOpened, lastClosed: TDateTime;
           //minIntervalBetween2Openings_inSec: integer;
           //minHumidityDiff_InOut: single;


            // max. Zeit zwischen Messwerten von Innen/Aussensensor
           // bei Überschreitung Fenster zu
           // maxDiffOfLastReceive_of_InOutSignals_inSec: integer;

           // 2020-06-11
           ActorID : Integer;
           doOpenClose : TOpenClose ;
           isOpenClose : TOpenClose;

           public
             procedure OpenCloseWindow(TMSMQTTClient: TTMSMQTTClient; // ; myLazSerial : TLazSerial;
                                       itRains: boolean);
             // 2020-06-17 procedure OpenWindow(TMSMQTTClient: TTMSMQTTClient);
             procedure OpenWindow(TMSMQTTClient: TTMSMQTTClient); // ; myLazSerial : TLazSerial);

             procedure CloseWindow(TMSMQTTClient: TTMSMQTTClient);//; myLazSerial : TLazSerial);   // 2020-06-19
             // 2020-05-31
             procedure CloseWindowForInit(TMSMQTTClient: TTMSMQTTClient); // ; myLazSerial : TLazSerial); // 2020-06-19

           private

           end;
implementation

uses  uExceptMsg; //  in '\uExceptMsg\uExceptMsg.pas';

const _Unitname = 'uWindowsOpener';



procedure T_WindowsOpener.OpenCloseWindow(TMSMQTTClient: TTMSMQTTClient; // myLazSerial : TLazSerial;
           itRains: boolean);
var
  durationFromLastClose_inSec: int64;
  draussenFeuchterAlsDrinnen : boolean;

begin
  try
    if (self.WO_aussenSensor.FirstReceive = 0.0) then EXIT;
    if (self.WO_innenSensor.FirstReceive = 0.0) then EXIT;

    // öffne, wenn die abs. Feuchte draussen + OffSet < als drinnen
    draussenFeuchterAlsDrinnen:= ((self.WO_aussenSensor.H_abs + appData.minHumidityDiff_InOut) >= self.WO_innenSensor.H_abs );

    // Fenster ist offen
    if (self.isOpenClose = TOpenClose.Open) then
    begin
      if (itRains or draussenFeuchterAlsDrinnen) then
      begin
        self.CloseWindow(TMSMQTTClient); //, myLazSerial);
        EXIT;
      end;
    end
    else
    begin     // Fenster ist zu

      if (itRains or draussenFeuchterAlsDrinnen) then
      begin
        EXIT;
      end;

      // ist das Fenster gerade erst geschlossen worden? Dann nicht öffnen, sonder raus
      // 2020-06-08 - die Entscheidung, wie häufig ein Fenster geöffnet werden darf,
      // sollte beim Actor liegen
      (*
      if (self.lastClosed > 0) then
      begin
        durationFromLastClose_inSec := DateUtils.SecondsBetween(self.lastClosed, Now());
        if (durationFromLastClose_inSec < appData.minIntervalBetween2Openings) then EXIT;
      end;
      *)

      // 2020-06-17
      self.OpenWindow(TMSMQTTClient); //, myLazSerial);
    end;

  except
    ExceptMsg(_Unitname, 9847, 'OpenCloseWindow', ExceptObject);
  end;
end;


procedure T_WindowsOpener.OpenWindow(TMSMQTTClient: TTMSMQTTClient); // ; myLazSerial : TLazSerial);
var packetID : Word;
    sSend : String;
begin
         try
            self.doOpenClose := TOpenClose.Open;
            self.lastOpened := Now();
            { TODO : fill - send ActorTopic to Fensteröffner}
            packetID := TMSMQTTClient.Publish(
                 self.ActorTopic,
                 'doOpen',
                 qosAtLeastOnce);

            // 2020-06-17 Serial senden:
            // 2020-06-17
            // Sende Serial an das Gateway
            sSend := 'SendToDevice:' + IntToStr(ActorID) + ';1;\n';
            // Sende an Actor
            // myLazSerial.WriteData(sSend);
         except
           ExceptMsg(_Unitname, 9867, 'OpenWindow', ExceptObject);

         end;
end;

// 2020-05-31
procedure T_WindowsOpener.CloseWindowForInit(TMSMQTTClient: TTMSMQTTClient); // ; myLazSerial : TLazSerial);
var packetID : Word;
    sSend : String;
begin
  try
    self.doOpenClose := TOpenClose.Close;
    self.lastClosed := now();
    { TODO : fill-send ActorTopic to Fensteröffner }
    packetID := TMSMQTTClient.Publish(
                 self.ActorTopic,
                 'doClose',
                 qosAtLeastOnce);
    // 2020-06-19
    // Sende Serial an das Gateway
    sSend := 'SendToDevice:' + IntToStr(ActorID) + ';0;\n';
    // Sende an Actor
     // myLazSerial.WriteData(sSend);
  except
    ExceptMsg(_Unitname, 2648, 'CloseWindow', ExceptObject);
  end;
end;

procedure T_WindowsOpener.CloseWindow(TMSMQTTClient: TTMSMQTTClient); // ; myLazSerial : TLazSerial);
var packetID : Word;
    sSend : String;
begin
  try
    self.doOpenClose := TOpenClose.Close;
    self.lastClosed := now();
    { TODO : fill-send ActorTopic to Fensteröffner }
    packetID := TMSMQTTClient.Publish(
                 self.ActorTopic,
                 'doClose',
                 qosAtLeastOnce);
    // 2020-06-19
    // Sende Serial an das Gateway
    sSend := 'SendToDevice:' + IntToStr(ActorID) + ';0;\n';
    // Sende an Actor
     // myLazSerial.WriteData(sSend);
  except
    ExceptMsg(_Unitname, 2659, 'CloseWindow', ExceptObject);
  end;
end;

end.

