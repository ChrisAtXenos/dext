# Persistent Background Jobs

Persistent Background Jobs permitem que você enfileire tarefas assíncronas (fora do processo principal, agendadas ou atrasadas) que sobrevivem a travamentos da aplicação e reinicializações. O motor serializa automaticamente os parâmetros do método e os salva em um banco de dados persistente (como SQLite ou In-Memory).

Diferente de tarefas simples em background com `IHostedService`, os Persistent Background Jobs são resilientes, monitoráveis, suportam retentativas automáticas e podem ser configurados facilmente via `appsettings.json`.

---

## Configuração

Configure os parâmetros dos jobs no arquivo `appsettings.json`:

```json
{
  "Dext": {
    "BackgroundJobs": {
      "Storage": {
        "Provider": "SQLite", // "SQLite" ou "InMemory"
        "ConnectionString": "DataSource=dext_jobs.db"
      },
      "Server": {
        "WorkerCount": 4,
        "PollIntervalInSeconds": 5
      }
    }
  }
}
```

---

## Registro

Para habilitar a execução de background jobs, registre o motor no startup da aplicação usando `AddBackgroundJobs`:

```pascal
uses
  Dext.DI.Interfaces,
  Dext.BackgroundJobs.Config;

procedure ConfigureServices(const Services: IServiceCollection);
begin
  // Registre as classes dos seus jobs no DI
  Services.AddTransient<TEmailService>;

  // Registra o cliente e armazenamento de background jobs com base no appsettings.json
  Services.AddBackgroundJobs;
end;
```

---

## Criando um Serviço de Job

Um background job é um método público de uma classe registrada no container DI. Os parâmetros do método devem ser tipos simples serializáveis para JSON (números, strings, booleanos).

```pascal
type
  TEmailService = class
  public
    procedure SendWelcomeEmail(const AEmail: string; const AUserId: Integer);
  end;

procedure TEmailService.SendWelcomeEmail(const AEmail: string; const AUserId: Integer);
begin
  // Lógica de envio de e-mail aqui...
end;
```

---

## Enfileirando e Agendando Tarefas

Inicialize o helper de cliente `TDextJobs` e comece a enfileirar as tarefas.

### 1. Enfileirar Imediatamente (Fire-and-Forget)

Executa o job assim que uma thread livre do worker pool estiver disponível.

```pascal
uses
  Dext.BackgroundJobs.Intf;

// Inicializa a fachada com a instância do cliente resolvida no DI
var Client := ServiceProvider.GetRequiredService<IJobClient>;
TDextJobs.Initialize(Client);

// Enfileira para execução imediata
var JobId := TDextJobs.Enqueue<TEmailService>('SendWelcomeEmail', ['user@example.com', 123]);
```

### 2. Agendar com Atraso (Delay)

Executa o job após o término do período de tempo especificado.

```pascal
uses
  System.TimeSpan,
  Dext.BackgroundJobs.Intf;

// Agenda para ser executado daqui a 1 hora
var JobId := TDextJobs.Schedule<TEmailService>(
  'SendWelcomeEmail', 
  ['user@example.com', 123], 
  TTimeSpan.FromHours(1)
);
```

---

## Resiliência e Falhas

Se uma exceção não tratada for lançada durante a execução de um job, o motor de jobs:
1. Marcará o status do job como falhado (`jsFailed`).
2. Incrementará o contador `AttemptCount`.
3. Em uma fase futura do roadmap, fará a retentativa automática com backoff exponencial.
4. Salvará a mensagem de exceção e o stack trace na coluna `ErrorLog` para depuração.
