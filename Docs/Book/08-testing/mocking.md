# Mocking

Create test doubles with `Mock<T>` for interfaces and classes.

> [!IMPORTANT]
> `Mock<T>` is a **generic Record** that lives in `Dext.Mocks` — it is **NOT** part of the `Dext.Testing` facade. It does **NOT** need `.Free` since its lifecycle is managed automatically on the stack.

## Interface Mocking

Interfaces must have RTTI enabled (`{$M+}`) to be mockable:

```pascal
uses
  Dext.Mocks; // Mock<T>, Arg, Times

type
  {$M+} // REQUIRED for mockable interfaces
  IService = interface
    ['{7E8A0B1C-2C3D-4E5F-6A7B-8C9D0E1F2A3B}']
    function Calculate(A: Integer): Integer;
  end;
  {$M-}

procedure TestMock;
begin
  // 1. Create Mock
  var MyMock := Mock<IService>.Create;

  // 2. Setup (fluent definition)
  MyMock.Setup.Returns(42).When.Calculate(Arg.Any<Integer>);

  // 3. Act
  var Result := MyMock.Instance.Calculate(10); // Returns 42

  // 4. Verify
  MyMock.Received(Times.Once).Calculate(10);
end;
```

---

## Setup Methods

```pascal
// Return a specific value
MyMock.Setup.Returns(42).When.Calculate(Arg.Any<Integer>);

// Return different values in sequence
MyMock.Setup.ReturnsInSequence([User1, User2]).When.GetNext;

// Throw exception
MyMock.Setup.Throws(ENotFoundException).When.GetById(Arg.Any<Integer>);
```

---

## Argument Matching (Arg)

```pascal
// Any value of a type
MyMock.Setup.Returns(User).When.FindById(Arg.Any<Integer>);

// Exact value
MyMock.Received(Times.Once).FindById(42);

// Conditional argument
MyMock.Setup.Returns(True).When.IsValid(Arg.Is<string>(
  function(S: string): Boolean
  begin
    Result := S.Length > 5;
  end));
```

---

## Verification

```pascal
// Verify called exactly once
MyMock.Received(Times.Once).FindById(1);

// Verify called N times
MyMock.Received(Times.Exactly(3)).Save(Arg.Any<TUser>);

// Verify never called
MyMock.DidNotReceive.Delete(Arg.Any<Integer>);

// Verify at least/at most
MyMock.Received(Times.AtLeast(1)).GetAll;
MyMock.Received(Times.AtMost(5)).GetAll;

// Verify no other calls were made
MyMock.VerifyNoOtherCalls;
```

---

## Class Mocking (Spies)

Dext also supports mocking virtual methods of concrete classes and configuring partial behavior (redirecting unconfigured calls to the actual class logic):

```pascal
var MockRepo := Mock<TUserRepository>.Create;
MockRepo.CallsBaseForUnconfiguredMembers; // Active spy/partial behavior

MockRepo.Setup.Returns(MockedUser).When.FindById(99);
// FindById(99) returns mock. Other IDs will invoke the actual database/repository.
```

---

## Auto-Mocking Container (`TAutoMocker`)

`TAutoMocker` eliminates repetitive boilerplate code for creating and injecting multiple mocks by automatically instantiating the class under test (SUT) and resolving its dependencies:

```pascal
uses
  Dext.Mocks.Auto;

procedure TestUserService;
begin
  var Mocker := TAutoMocker.Create;
  try
    // Automatically creates IUserRepository and IEmailService and injects them
    var Service := Mocker.CreateInstance<TUserService>;
    
    // Configure expectations on the mock created silently by the container
    Mocker.GetMock<IUserRepository>.Setup
      .Returns(True)
      .When
      .Save(Arg.Any<TUser>);

    Service.Register('John', 'john@dext.dev');

    // Validate if the email was sent
    Mocker.GetMock<IEmailService>.Received(Times.Once).SendWelcomeEmail('john@dext.dev');
  finally
    Mocker.Free;
  end;
end;
```

---

[← Testing](README.md) | [Next: Assertions →](assertions.md)
