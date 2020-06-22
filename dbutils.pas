// 2020-06-05
unit dbutils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uExceptMsg,sqlite3conn, sqldb, globals;

function QY_CreateAndOpen(var QY : TSQLQuery; const sSQL : String): Boolean;
procedure QY_CloseAndFree(var QY : TSQLQuery);

implementation


const _Unitname = 'DBUtils';

// 2020-06-05
function QY_CreateAndOpen(var QY : TSQLQuery; const sSQL : String): Boolean;
var
  SQLite3Connection : TSQLite3Connection;
  SQLTransaction : TSQLTransaction;
  sPOs : String;
begin
  try
    sPos := '000';
    QY := TSQLQuery.Create(nil);
    sPos := '010';
    SQLTransaction := TSQLTransaction.Create(nil);
    sPos := '020';
    SQLite3Connection := TSQLite3Connection.Create(nil);
    sPos := '030';

    SQLite3Connection.DatabaseName:= appData.DatabaseName;
    sPos := '040';
    SQLite3Connection.Transaction := SQLTransaction;
    sPos := '050';
    QY.DataBase := SQLite3Connection;
    sPos := '060';
    QY.Transaction := SQLTransaction;
    sPos := '070';
    SQLite3Connection.Connected:= true;
    sPos := '080';
    SQLTransaction.Active:= true;

    sPos := '100';
    QY.SQL.Text := sSQL;
    sPos := '110';
    QY.Open;

    sPos := '999';
    Result := true;
  except
    ExceptMsg(_Unitname + 'sPos: ' + sPos , 2145,
                          'QY_CreateAndOpen sPos: ' + sPos   +CR +
                          'sSQL: ' + sSQL , ExceptObject);
    Result := false;
  end;
end;

// 2020-06-05
procedure QY_CloseAndFree(var QY : TSQLQuery);
var
  sPos : String;
begin
  try
    sPos := '000';
    QY.Close;
    sPos := '010';
    QY.Transaction.Active:= false;
    sPos := '020';
    QY.SQLConnection.Connected:= false;
    sPos := '030';
    QY.Free;
  except
    ExceptMsg(_Unitname + 'sPos: ' + sPos , 2678, 'QY_CloseAndFree sPos: ' + sPos , ExceptObject);
  end;
end;

end.

