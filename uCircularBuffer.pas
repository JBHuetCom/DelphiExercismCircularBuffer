unit uCircularBuffer;

interface

  type
    ICircularBuffer<T> = interface(IInterface)
      ['{3DBE8320-64B5-4481-A6A6-E647E999366D}']
      function Read : T;
      procedure Write(const AValue : T);
      procedure Clear;
      procedure OverWrite(const AValue : T);
    end;

    TCircularBuffer<T> = class(TInterfacedObject, ICircularBuffer<T>)
    private
      FBuffer : TArray<T>;
      FWritableStatus : TArray<boolean>;
      FReadingPosition : integer;
      FWritingPosition : integer;
      procedure ResetFields(const ASize : integer);
      procedure MoveForward(var AValue : integer);
      procedure MoveBackward(var AValue : integer);
      function BufferIsEmpty : boolean;
      function BufferIsFull : boolean;
    public
      constructor Create(const ASize : integer); overload;
      destructor Destroy; override;
      function Read : T;
      procedure Write(const AValue : T);
      procedure Clear;
      procedure OverWrite(const AValue : T);
    end;

implementation

  uses
    SysUtils;

  procedure TCircularBuffer<T>.ResetFields(const ASize : integer);
    var
      i : integer;
    begin
      SetLength(self.FBuffer, 0);
      SetLength(self.FWritableStatus, 0);
      self.FReadingPosition := 0;
      self.FWritingPosition := -1;
      SetLength(self.FBuffer, ASize);
      SetLength(self.FWritableStatus, ASize);
      for i := Low(self.FWritableStatus) to High(self.FWritableStatus) do
        self.FWritableStatus[i] := TRUE;
    end;

  constructor TCircularBuffer<T>.Create(const ASize: integer);
    begin
      self.ResetFields(ASize);
    end;

  destructor TCircularBuffer<T>.Destroy;
    begin
      SetLength(self.FBuffer, 0);
      SetLength(self.FWritableStatus, 0);
    end;

  procedure TCircularBuffer<T>.MoveForward(var AValue : integer);
    begin
      AValue := (AValue + 1) mod Length(Self.FBuffer);
    end;

  procedure TCircularBuffer<T>.MoveBackward(var AValue : integer);
    begin
      AValue := (AValue + Length(Self.FBuffer) - 1) mod Length(Self.FBuffer);
    end;

  function TCircularBuffer<T>.BufferIsEmpty : boolean;
    var
      i : integer;
    begin
      Result := TRUE;
      for i := Low(self.FWritableStatus) to High(self.FWritableStatus) do
        Result := Result AND self.FWritableStatus[i];
    end;

  function TCircularBuffer<T>.BufferIsFull : boolean;
    var
      i : integer;
    begin
      Result := TRUE;
      for i := Low(self.FWritableStatus) to High(self.FWritableStatus) do
        Result := Result AND not self.FWritableStatus[i];
    end;

  function TCircularBuffer<T>.Read : T;
    begin
      if self.BufferIsEmpty then
        raise EInvalidOpException.Create('Error: buffer is empty. Cannot read.');
      if self.FWritableStatus[self.FReadingPosition] then
        raise EInvalidOpException.Create('Error: buffer item is empty. Cannot read.');
      Result := self.FBuffer[self.FReadingPosition];
      self.FWritableStatus[self.FReadingPosition] := TRUE;
      self.MoveForward(self.FReadingPosition);
    end;

  procedure TCircularBuffer<T>.Write(const AValue: T);
    begin
      if self.BufferIsFull then
        raise EInvalidOpException.Create('Error: buffer is full. Cannot write.');
      self.MoveForward(self.FWritingPosition);
      if not self.FWritableStatus[self.FWritingPosition] then
        begin
          self.MoveBackward(self.FWritingPosition);
          raise EInvalidOpException.Create('Error: buffer item is not empty. Cannot write.');
        end;
      self.FBuffer[self.FWritingPosition] := AValue;
      self.FWritableStatus[self.FWritingPosition] := FALSE;
    end;

  procedure TCircularBuffer<T>.Clear;
    begin
      self.ResetFields(Length(self.FBuffer));
    end;

  procedure TCircularBuffer<T>.OverWrite(const AValue: T);
    begin
      if self.BufferIsFull then
        begin
          self.FWritingPosition := self.FReadingPosition;
          self.FBuffer[self.FWritingPosition] := AValue;
          self.FWritableStatus[self.FWritingPosition] := FALSE;
          self.MoveForward(self.FReadingPosition);
        end
      else
        self.Write(AValue);
    end;

end.
