unit utils;


{$mode objfpc}{$H+}

interface
uses  StdCtrls, Classes, SysUtils, globals;

  procedure addLinesToMemo(var memo : TMemo; line : String);



implementation

// 2020-06-19
  procedure addLinesToMemo(var memo : TMemo; line : String);
  var
    Lines: TStringList;
  begin
    Lines := TStringList.Create;
    Lines.Add(line);
    Lines.AddStrings(memo.Lines);
    memo.Lines := Lines;

   if (memo.Lines.Count > appData.maxLinesInMemos) then begin
      memo.Lines.Clear;
   end;
  end;
end.

