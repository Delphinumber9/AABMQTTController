unit myInifile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Forms;

implementation

procedure ReadControlFile;
var
   INIFileName: string;
   ME_HFO_TOTAL_MASS : single;
   AUX_HFO_TOTAL_MASS : single;

   INIFile: TINIFile;
begin
   INIFileName := ExtractFilePath(Application.EXEName) + 'Control.INI';
   INIFile := TINIFile.Create(INIFileName);
   with INIFile do begin

      ME_HFO_TOTAL_MASS := ReadFloat('Counters','ME_HFO_TOTAL',0.0);
      AUX_HFO_TOTAL_MASS := ReadFloat('Counters','AUX_HFO_TOTAL',0.0);

      Free;
   end;
end; // ReadCounterFile

procedure WriteControlFile;
var
   INIFileName: string;
   INIFile: TINIFile;

   ME_HFO_TOTAL_MASS : single;
   AUX_HFO_TOTAL_MASS : single;
begin
   INIFileName := ExtractFilePath(Application.EXEName) + 'Control.INI';
   INIFile := TINIFile.Create(INIFileName);

   with INIFile do begin

      WriteFloat('Counters','ME_HFO_TOTAL',ME_HFO_TOTAL_MASS);
      WriteFloat('Counters','AUX_HFO_TOTAL',AUX_HFO_TOTAL_MASS);

      Free;
   end;
end; // WriteCounterFile


end.

