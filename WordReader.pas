unit WordReader;

interface

uses
  System.SysUtils, System.Classes, System.Character, System.Generics.Collections,
  System.Generics.Defaults;

type
  TWordSorter = class(TDictionary<string,Integer>)
  public
    type
      TPairType = TPair<string,Integer>;
      TPairTypeArray = TArray<TPairType>;
  private
    type
      TWordCounterComparer = class(TComparer<TPairType>)
      public
        function Compare(const Left, Right: TPairType): Integer; override;
      end;
  private
    FPosition: Integer;
    FStringStream: TStringStream;
    FComparer: TWordCounterComparer;
  protected
    function GetNext(out Word: string): Boolean;
  public
    constructor Create(const AFileName: string); overload;
    constructor Create(const AStream: TStream;
      AOwnsStream: Boolean = False); overload;
    destructor Destroy; override;
    procedure LoadWords;
    procedure IncWord(Word: string);
    function GetSorted: TPairTypeArray;
  end;

implementation

{ TWordReader }

constructor TWordSorter.Create(const AFileName: string);
begin
  Create(TFileStream.Create(AFileName, fmOpenRead), True);
end;

constructor TWordSorter.Create(const AStream: TStream;
  AOwnsStream: Boolean = False);
var
  LPos: Int64;
  LBuff: TBytes;
  LEncoding: TEncoding;
begin
  LPos := AStream.Position;
  try
    //Determining encoding
    SetLength(LBuff, 4);
    AStream.Read(LBuff, SizeOf(LBuff));
    AStream.Position := LPos;

    LEncoding := nil;
    TEncoding.GetBufferEncoding(LBuff, LEncoding);

    FStringStream := TStringStream.Create('', LEncoding);
    try
      FStringStream.LoadFromStream(AStream);
      FComparer := TWordCounterComparer.Create;
      inherited Create;
    except
      FComparer.Free;
      FStringStream.Free;
      raise;
    end;
  finally
    if AOwnsStream then    
      AStream.Free;
  end;
end;

destructor TWordSorter.Destroy;
begin
  FStringStream.Free;
  FComparer.Free;

  inherited;
end;

function TWordSorter.GetNext(out Word: string): Boolean;
var
  I: Integer;
  LString: string;
  StartPos: Integer;
begin
  StartPos := -1;
  LString := FStringStream.DataString;
  Result := FPosition < Length(LString);
  if Result then
  begin
    for I := FPosition + 1 to Length(LString) + 1 do
      if (LString[I].IsLetterOrDigit) and (StartPos < 0) then
        StartPos := I
      else
      if
        ( (not LString[I].IsLetterOrDigit) or (I > Length(LString)) ) //delimiter or end of buffer?
          and
        (StartPos >= 0)
      then
      begin
        Word := Copy(LString, StartPos, I - StartPos);
        Break;
      end;

    FPosition := I;

    Result := not Word.IsEmpty;
  end;
end;

procedure TWordSorter.IncWord(Word: string);
var
  LCount: Integer;
begin
  Word := WideLowerCase(Word);
  TryGetValue(Word, LCount);
  Inc(LCount);
  AddOrSetValue(Word, LCount);
end;

procedure TWordSorter.LoadWords;
var
  LStr: string;
begin
  while GetNext(LStr) do
    IncWord(LStr);
end;

function TWordSorter.GetSorted: TPairTypeArray;
begin
  Result := ToArray;
  TArray.Sort<TPairType>(Result, FComparer);
end;

{ TWordSorter.TWordCounterComparer }

function TWordSorter.TWordCounterComparer.Compare(const Left,
  Right: TPairType): Integer;
begin
  Result := Right.Value - Left.Value;
end;

end.
