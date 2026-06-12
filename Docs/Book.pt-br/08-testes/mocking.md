# Mocking

Crie dublês de teste com `Mock<T>` para interfaces e classes.

> [!IMPORTANT]
> `Mock<T>` é um **Record Genérico** que vive em `Dext.Mocks` — ele **NÃO** faz parte da facade `Dext.Testing`. Ele **NÃO** precisa de `.Free` pois seu ciclo de vida é gerenciado automaticamente na pilha.

## Mock de Interfaces

Interfaces devem ter RTTI habilitada (`{$M+}`) para serem mockáveis:

```pascal
uses
  Dext.Mocks; // Mock<T>, Arg, Times

type
  {$M+} // OBRIGATÓRIO para interfaces mockáveis
  IServico = interface
    ['{7E8A0B1C-2C3D-4E5F-6A7B-8C9D0E1F2A3B}']
    function Calcular(A: Integer): Integer;
  end;
  {$M-}

procedure TestMock;
begin
  // 1. Criar Mock
  var MeuMock := Mock<IServico>.Create;

  // 2. Setup (definição fluente)
  MeuMock.Setup.Returns(42).When.Calcular(Arg.Any<Integer>);

  // 3. Act
  var Resultado := MeuMock.Instance.Calcular(10); // Retorna 42

  // 4. Verify
  MeuMock.Received(Times.Once).Calcular(10);
end;
```

---

## Métodos de Setup

```pascal
// Retorna um valor específico
MeuMock.Setup.Returns(42).When.Calcular(Arg.Any<Integer>);

// Retorna valores em sequência sucessiva
MeuMock.Setup.ReturnsInSequence([User1, User2]).When.GetNext;

// Lança exceção
MeuMock.Setup.Throws(ENotFoundException).When.GetById(Arg.Any<Integer>);
```

---

## Matching de Argumentos (Arg)

```pascal
// Qualquer valor de um tipo
MeuMock.Setup.Returns(User).When.FindById(Arg.Any<Integer>);

// Valor exato
MeuMock.Received(Times.Once).FindById(42);

// Argumento condicional
MeuMock.Setup.Returns(True).When.IsValid(Arg.Is<string>(
  function(S: string): Boolean
  begin
    Result := S.Length > 5;
  end));
```

---

## Verificação

```pascal
// Verificar chamado exatamente uma vez
MeuMock.Received(Times.Once).FindById(1);

// Verificar chamado N vezes
MeuMock.Received(Times.Exactly(3)).Salvar(Arg.Any<TUser>);

// Verificar nunca chamado
MeuMock.DidNotReceive.Deletar(Arg.Any<Integer>);

// Verificar pelo menos/no máximo
MeuMock.Received(Times.AtLeast(1)).ListarTodos;
MeuMock.Received(Times.AtMost(5)).ListarTodos;

// Verificar que nenhuma outra chamada foi feita
MeuMock.VerifyNoOtherCalls;
```

---

## Mock de Classes Concretas (Spies)

O Dext também suporta mockar métodos virtuais de classes concretas e configurar comportamento parcial (redirecionando chamadas não configuradas para a classe real):

```pascal
var MockRepo := Mock<TUserRepository>.Create;
MockRepo.CallsBaseForUnconfiguredMembers; // Ativa comportamento de Spy

MockRepo.Setup.Returns(MockedUser).When.FindById(99);
// FindById(99) retorna o mock. Outros IDs invocarão o banco/código real.
```

---

## Auto-Mocking Container (`TAutoMocker`)

O `TAutoMocker` elimina o código repetitivo de criação e injeção de múltiplos mocks ao instanciar automaticamente a classe sob teste (SUT) resolvendo suas dependências com mocks:

```pascal
uses
  Dext.Mocks.Auto;

procedure TestUserService;
begin
  var Mocker := TAutoMocker.Create;
  try
    // Cria automaticamente IUserRepository e IEmailService e injeta no construtor
    var Service := Mocker.CreateInstance<TUserService>;
    
    // Configura expectativas no mock criado silenciosamente pelo container
    Mocker.GetMock<IUserRepository>.Setup
      .Returns(True)
      .When
      .Save(Arg.Any<TUser>);

    Service.Register('John', 'john@dext.dev');

    // Valida se o email foi enviado
    Mocker.GetMock<IEmailService>.Received(Times.Once).SendWelcomeEmail('john@dext.dev');
  finally
    Mocker.Free;
  end;
end;
```

---

[← Testes](README.md) | [Próximo: Assertions →](assertions.md)
