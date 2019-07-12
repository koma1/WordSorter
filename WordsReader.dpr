program WordsReader;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  WordReader in 'WordReader.pas';

var
  LPair: TWordSorter.TPairType;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    if ParamCount > 0 then
      with TWordSorter.Create(ParamStr(1)) do
      try
        LoadWords;

        for LPair in GetSorted do
          WriteLn(Format('"%s" - %d', [LPair.Key, LPair.Value]));
      finally
        Free;
      end
    else
      WriteLn(Format('Usage: %s <file_name>', [ExtractFileName(ParamStr(0))]));
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
