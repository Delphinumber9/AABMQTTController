unit globals;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAppData = record
    maxLiveTimeOfSignals_inSec: longint;
    // 2020-06-07 innenSensors_max: longint;
    // 2020-06-07 windowsOpeners_max: longint;
    PortName: string;
    DatabaseName : String;
    // 2020-06-07
    minIntervalBetween2Openings : Integer;
    minHumidityDiff_InOut : Integer;

    // 2020-06-11
    GatewaySendCommand : String;
    // 2020-06-19
    maxLinesInMemos : Integer;
  end;

  TOpenClose = (Close=0, Open=1);


  // end;

  type
  T_allDevices = class
    DeviceID : byte;
    sType: String;
    SubType : String;
    Topic: string;
    Description  : String;
    packetID : Integer;
  end;


var
  appData: TAppData;


implementation

end.

