unit Dext.Testing.Design.AST;

interface

uses
  System.SysUtils,
  System.Classes,
  System.RegularExpressions,
  System.Generics.Collections;

type
  TTestLocation = record
    ClassName: string;
    MethodName: string;
    Line: Integer;
    FileName: string;
  end;

  TTestASTScanner = class
  public
    class function ScanFile(const AFileName: string; out ATests: TList<TTestLocation>): Boolean; overload;
    class function ScanText(const AText: string; out ATests: TList<TTestLocation>): Boolean; overload;
  end;

implementation

{ TTestASTScanner }

class function TTestASTScanner.ScanFile(const AFileName: string; out ATests: TList<TTestLocation>): Boolean;
var
  LFileContent: string;
  LStream: TStringList;
  I: Integer;
  LTest: TTestLocation;
begin
  Result := False;
  ATests := TList<TTestLocation>.Create;
  if not FileExists(AFileName) then
    Exit;

  LStream := TStringList.Create;
  try
    try
      LStream.LoadFromFile(AFileName);
      LFileContent := LStream.Text;
      Result := ScanText(LFileContent, ATests);
      if Result then
      begin
        for I := 0 to ATests.Count - 1 do
        begin
          LTest := ATests[I];
          LTest.FileName := AFileName;
          ATests[I] := LTest;
        end;
      end;
    except
      // Silent fail
    end;
  finally
    LStream.Free;
  end;
end;

class function TTestASTScanner.ScanText(const AText: string; out ATests: TList<TTestLocation>): Boolean;
var
  Lines: TArray<string>;
  I: Integer;
  Line: string;
  Trimmed: string;
  CurrentClass: string;
  InTypeSection: Boolean;
  InPublishedSection: Boolean;
  MatchObj: TMatch;
  TestLoc: TTestLocation;
  ClassRegex, MethodRegex: TRegEx;
  LMethodName: string;
begin
  Result := False;
  if not Assigned(ATests) then
    ATests := TList<TTestLocation>.Create;

  Lines := AText.Split([#10]);
  CurrentClass := '';
  InTypeSection := False;
  InPublishedSection := False;

  // Regex patterns
  ClassRegex := TRegEx.Create('^\s*(\w+)\s*=\s*class\s*(\(([^)]+)\))?', [roIgnoreCase]);
  MethodRegex := TRegEx.Create('^\s*(procedure|function)\s+(\w+)\s*(\([^)]*\))?\s*;', [roIgnoreCase]);

  for I := 0 to Length(Lines) - 1 do
  begin
    Line := Lines[I];
    Trimmed := Line.Trim;

    if Trimmed = '' then Continue;

    // Detect section types
    if SameText(Trimmed, 'type') then
    begin
      InTypeSection := True;
      Continue;
    end;
    
    if SameText(Trimmed, 'implementation') then
    begin
      Break; // Only parse interface section for speed and safety
    end;

    if InTypeSection then
    begin
      // Look for Class Declarations
      MatchObj := ClassRegex.Match(Trimmed);
      if MatchObj.Success then
      begin
        CurrentClass := MatchObj.Groups[1].Value;
        InPublishedSection := True; // Default to true for test runner methods
        Continue;
      end;

      // Class termination
      if SameText(Trimmed, 'end;') then
      begin
        CurrentClass := '';
        InPublishedSection := False;
        Continue;
      end;

      // Visibility markers
      if SameText(Trimmed, 'private') or SameText(Trimmed, 'protected') then
      begin
        InPublishedSection := False;
        Continue;
      end;
      
      if SameText(Trimmed, 'public') or SameText(Trimmed, 'published') then
      begin
        InPublishedSection := True;
        Continue;
      end;

      // Look for Methods
      if (CurrentClass <> '') and InPublishedSection then
      begin
        MatchObj := MethodRegex.Match(Trimmed);
        if MatchObj.Success then
        begin
          LMethodName := MatchObj.Groups[2].Value;
          // Only matches if method starts with "Test" and isn't setup/teardown
          if SameText(Copy(LMethodName, 1, 4), 'Test') and
             (not SameText(LMethodName, 'setup')) and
             (not SameText(LMethodName, 'teardown')) then
          begin
            TestLoc.ClassName := CurrentClass;
            TestLoc.MethodName := LMethodName;
            TestLoc.Line := I + 1;
            TestLoc.FileName := '';
            ATests.Add(TestLoc);
            Result := True;
          end;
        end;
      end;
    end;
  end;
end;

end.
