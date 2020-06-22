unit DHT_Sensors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;
  //uExceptMsg in 'uExceptMsg\uExceptMsg.pas';

 const _UnitName = 'DHT_Sensors';

type
  T_DHT = class
    DeviceID : byte;
    Topic: string;
    sType: String;
    SubType : String;
    Description  : String;


    packetID: word;
    payLoad: string;
    Temp: single;
    H_rel: single;
    H_abs: single;
    FirstReceive, LastReceive: TDateTime;

    public
     procedure PayLoad_to_Rec(sPayLoad : string);
  end;

implementation

uses uExceptMsg in 'uExceptMsg\uExceptMsg.pas';

procedure T_DHT.PayLoad_to_Rec(sPayLoad : string);
var
  strArray: TStringArray;
  OK: boolean;

begin
  try
    if (sPayLoad = '') then
    begin
      exit;
    end;


    self.payLoad := sPayLoad;
    strArray := sPayLoad.Split('/');
    if (length(strArray) = 3) then
    begin
      OK := TryStrToFloat(strArray[0], self.Temp);
      if (OK = False) then
        EXIT;

      OK := TryStrToFloat(strArray[1], self.H_rel);
      if (OK = False) then
        EXIT;

      OK := TryStrToFloat(strArray[2], self.H_abs);
      if (OK = False) then
        EXIT;

      if (self.FirstReceive = 0.0) then
      begin
        self.FirstReceive := now();
      end;
      self.LastReceive := now();
    end;
  except
    // ExceptMsg('Error (194) DHT_PayLoad_Split', ExceptObject);
    ExceptMsg(_UnitName, 5841, 'Error PayLoad_To_Rec', ExceptObject);
  end;
end;

end.

