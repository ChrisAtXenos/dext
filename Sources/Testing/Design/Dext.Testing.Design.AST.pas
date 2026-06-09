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

/// <summary>
/// Returns True if the trimmed line contains one of the fixture-level attributes:
///   [TestFixture], [TestFixture('...')], [TestClass], [Fixture], [Fixture('...')]
/// </summary>
function IsFixtureAttribute(const ATrimmed: string): Boolean;
var
  LLower: string;
begin
  LLower := LowerCase(ATrimmed);
  Result :=
    (LLower = '[testfixture]') or LLower.StartsWith('[testfixture(') or
    (LLower = '[fixture]')     or LLower.StartsWith('[fixture(') or
    (LLower = '[testclass]')   or LLower.StartsWith('[testclass(');
end;

/// <summary>
/// Returns True if the trimmed line is exactly '[Test]', '[Fact]', '[TestCase]',
/// '[TestCase(...]', '[TestCaseSource(...]', '[Ignore]' etc. — i.e. a method-level
/// attribute that appears on the line immediately before the procedure/function.
/// We treat any line matching \[Test...\] or \[Fact\] as "the next method is a test".
/// </summary>
function IsTestAttribute(const ATrimmed: string): Boolean;
var
  LLower: string;
begin
  LLower := LowerCase(ATrimmed);
  Result :=
    (LLower = '[test]') or
    (LLower = '[fact]') or
    LLower.StartsWith('[test(') or
    LLower.StartsWith('[testcase') or
    LLower.StartsWith('[testcasesource') or
    LLower.StartsWith('[fact(');
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
  NextLineIsFixture: Boolean;  // The NEXT class declaration is a test fixture
  NextMethodIsTest: Boolean;   // The NEXT method declaration is a test
  MatchObj: TMatch;
  TestLoc: TTestLocation;
  TypeDeclRegex, MethodRegex: TRegEx;
  LMethodName: string;
  LNestingDepth: Integer;
  LKeyword: string;
begin
  Result := False;
  if not Assigned(ATests) then
    ATests := TList<TTestLocation>.Create;

  Lines := AText.Split([#10]);
  CurrentClass := '';
  LNestingDepth := 0;
  InTypeSection := False;
  InPublishedSection := False;
  NextLineIsFixture := False;
  NextMethodIsTest := False;

  // Regex patterns
  // Matches: ClassName = class(...) or ClassName = class
  TypeDeclRegex := TRegEx.Create('^\s*(\w+)\s*=\s*(class|record|interface|object)\b', [roIgnoreCase]);
  // Matches: procedure/function Name(...); or procedure/function Name;
  MethodRegex := TRegEx.Create('^\s*(procedure|function)\s+(\w+)\s*(\([^)]*\))?\s*;', [roIgnoreCase]);

  for I := 0 to Length(Lines) - 1 do
  begin
    Line := Lines[I];
    Trimmed := Line.Trim;

    if Trimmed = '' then Continue;

    // Remove trailing CR that may remain after splitting on LF
    if (Length(Trimmed) > 0) and (Trimmed[Length(Trimmed)] = #13) then
      Trimmed := Trimmed.TrimRight([#13]);
    if Trimmed = '' then Continue;

    // Stop at implementation section — we only parse the interface
    if SameText(Trimmed, 'implementation') then
      Break;

    // Detect type section
    if SameText(Trimmed, 'type') then
    begin
      InTypeSection := True;
      Continue;
    end;

    // -----------------------------------------------------------------------
    // Attribute detection (works both inside and outside type sections)
    // We look for attribute lines like [TestFixture], [Test], etc.
    // Handles both standalone attribute lines AND inline attribute+method lines:
    //   [Test]                          <- standalone attribute line
    //   [Test] procedure MethodName;    <- inline attribute + method
    //   [TestFixture('desc')]           <- fixture attribute with argument
    // -----------------------------------------------------------------------
    if (Length(Trimmed) >= 2) and (Trimmed[1] = '[') then
    begin
      var LBracketEnd := Pos(']', Trimmed);
      if LBracketEnd > 0 then
      begin
        // Extract the attribute part: from '[' up to and including ']'
        var LAttrPart := Copy(Trimmed, 1, LBracketEnd);
        // Everything after the attribute on the same line (trimmed)
        var LRemainder := Trim(Copy(Trimmed, LBracketEnd + 1, MaxInt));

        if IsFixtureAttribute(LAttrPart) then
        begin
          NextLineIsFixture := True;
          // If the class declaration is also on this line (unusual but handle it):
          // fall through so the TypeDeclRegex can match the remainder below.
          if LRemainder <> '' then
            Trimmed := LRemainder  // parse the remainder as a normal line below
          else
            Continue;
        end
        else if IsTestAttribute(LAttrPart) then
        begin
          NextMethodIsTest := True;
          // If the method declaration is also on this line (e.g. [Test] procedure Foo;):
          // parse the remainder as a normal line so we match it immediately.
          if LRemainder <> '' then
            Trimmed := LRemainder  // fall through to method regex below
          else
            Continue;
        end
        else
        begin
          // Some other attribute — clear method flag only if the attribute
          // itself is on its own line (no remainder following it)
          if LRemainder = '' then
            Continue;
          // Otherwise there might be a declaration after the attribute — fall through
          Trimmed := LRemainder;
        end;
      end;
    end;

    if not InTypeSection then
      Continue;

    // -----------------------------------------------------------------------
    // Inside type section
    // -----------------------------------------------------------------------

    // Class / Record / Interface declaration
    MatchObj := TypeDeclRegex.Match(Trimmed);
    if MatchObj.Success and (Pos('class of', LowerCase(Trimmed)) = 0) and
       (not TRegEx.IsMatch(Trimmed, '\b(class|interface)\s*;', [roIgnoreCase])) then
    begin
      LKeyword := MatchObj.Groups[2].Value;
      if CurrentClass = '' then
      begin
        if SameText(LKeyword, 'class') then
        begin
          CurrentClass := MatchObj.Groups[1].Value;
          LNestingDepth := 1;

          // Decide whether this class is a test fixture:
          //   1. Preceded by a fixture attribute ([TestFixture], [TestClass], …)
          //   2. OR class name contains 'Test' or 'Tests' (heuristic fallback)
          if NextLineIsFixture then
            InPublishedSection := True
          else if CurrentClass.ToLower.Contains('test') then
            InPublishedSection := True  // heuristic: name implies tests
          else
            InPublishedSection := False;

          NextLineIsFixture := False;
        end;
      end
      else
      begin
        // Nested type inside current class — track depth
        Inc(LNestingDepth);
        NextLineIsFixture := False;
      end;
      NextMethodIsTest := False;
      Continue;
    end;

    // Block termination
    if SameText(Trimmed, 'end;') then
    begin
      if CurrentClass <> '' then
      begin
        Dec(LNestingDepth);
        if LNestingDepth <= 0 then
        begin
          CurrentClass := '';
          LNestingDepth := 0;
          InPublishedSection := False;
        end;
      end;
      NextLineIsFixture := False;
      NextMethodIsTest := False;
      Continue;
    end;

    // Visibility markers
    if SameText(Trimmed, 'private') or SameText(Trimmed, 'protected') or
       SameText(Trimmed, 'strict private') or SameText(Trimmed, 'strict protected') then
    begin
      // Only suppress heuristic-name scanning; attribute-tagged methods still work
      // because NextMethodIsTest will be set by the [Test] line above.
      // We track InPublishedSection for the heuristic path only.
      InPublishedSection := False;
      Continue;
    end;

    if SameText(Trimmed, 'public') or SameText(Trimmed, 'published') then
    begin
      InPublishedSection := True;
      Continue;
    end;

    // Method discovery
    if CurrentClass <> '' then
    begin
      MatchObj := MethodRegex.Match(Trimmed);
      if MatchObj.Success then
      begin
        LMethodName := MatchObj.Groups[2].Value;

        // Accept if:
        //   (A) The line was preceded by [Test] / [Fact] attribute, OR
        //   (B) Heuristic: public section + name starts with Test/Should
        //       and is not Setup/TearDown
        var LAccept := False;

        if NextMethodIsTest then
          LAccept := True
        else if InPublishedSection then
        begin
          LAccept :=
            (SameText(Copy(LMethodName, 1, 4), 'Test') or
             SameText(Copy(LMethodName, 1, 6), 'Should')) and
            (not SameText(LMethodName, 'setup')) and
            (not SameText(LMethodName, 'teardown'));
        end;

        if LAccept then
        begin
          TestLoc.ClassName := CurrentClass;
          TestLoc.MethodName := LMethodName;
          TestLoc.Line := I + 1;
          TestLoc.FileName := '';
          ATests.Add(TestLoc);
          Result := True;
        end;

        NextMethodIsTest := False; // consumed
      end;
    end;
  end;
end;

end.
