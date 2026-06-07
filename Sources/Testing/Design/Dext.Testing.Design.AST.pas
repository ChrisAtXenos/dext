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
begin
  Result := False;
  if not Assigned(ATests) then
    ATests := TList<TTestLocation>.Create;

  Lines := AText.Split([#10, #13]);
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
          // Test method candidates usually start with "Test" or the class has [TestFixture] attribute.
          // To be safe, we match any procedure/function in the public/published section of classes 
          // ending/descending from test structures, or simple naming convention of "Test"
          if SameText(Copy(MatchObj.Groups[2].Value, 1, 4), 'Test') or 
             CurrentClass.ToLower.Contains('test') or 
             CurrentClass.ToLower.Contains('fixture') then
          begin
            TestLoc.ClassName := CurrentClass;
            TestLoc.MethodName := MatchObj.Groups[2].Value;
            TestLoc.Line := I + 1;
            ATests.Add(TestLoc);
            Result := True;
          end;
        end;
      end;
    end;
  end;
end;

end.
