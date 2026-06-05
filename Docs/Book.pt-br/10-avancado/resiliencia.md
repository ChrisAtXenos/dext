# Pipeline de Resiliência e Tratamento de Falhas

O Dext fornece um framework de resiliência thread-safe e totalmente desacoplado (`Dext.Resilience`) inspirado no Polly do .NET. Ele permite que desenvolvedores definam políticas de execução (Retry, Circuit Breaker, Fallback, Timeout) e as apliquem a qualquer operação de I/O ou CPU-bound usando uma API fluente.

---

## 1. Primeiros Passos

Para usar o pipeline de resiliência, adicione `Dext.Resilience` na sua cláusula uses:

```pascal
uses
  System.SysUtils,
  Dext.Resilience;
```

Você configura um pipeline utilizando `TResiliencePipeline.Create` e encadeando as políticas desejadas. O pipeline é um record leve e imutável para evitar alocações desnecessárias na heap.

```pascal
var Pipeline := TResiliencePipeline.Create
  .AddRetry(3, 100)               // 3 tentativas, 100ms de atraso base
  .AddCircuitBreaker(5, 30000)   // quebra o circuito após 5 erros, aguarda 30s
  .AddTimeout(5000);             // timeout após 5s
```

---

## 2. Políticas Centrais

### A. Política de Redirecionamento/Tentativa (`TRetryPolicy`)
A política de Retry reexecuta automaticamente operações que falharam. Suporta backoff linear ou exponencial com jitter (ruído aleatório) para evitar gargalos em cascata nos servidores.

```pascal
// Tenta 3 vezes, aguardando 50ms, 100ms, 150ms...
var Pipeline := TResiliencePipeline.Create.AddRetry(3, 50);
```

### B. Política de Disjuntor (`TCircuitBreakerPolicy`)
O Circuit Breaker evita que a aplicação execute repetidamente uma operação propensa a falhas:
- **Closed (Fechado)**: Operação normal. Falhas incrementam o contador de erros.
- **Open (Aberto)**: O circuito abre quando o limite de falhas é atingido. Chamadas subsequentes falham rápido imediatamente, lançando `ECircuitBrokenException`.
- **Half-Open (Meio-Aberto)**: Após o tempo de bloqueio expirar, o disjuntor entra em modo de teste. Uma única execução bem-sucedida fecha o circuito; qualquer falha o retorna ao estado `Open`.

```pascal
// Abre o circuito após 2 falhas consecutivas; mantém aberto por 1000ms
var Pipeline := TResiliencePipeline.Create.AddCircuitBreaker(2, 1000);
```

### C. Política de Fallback (`TFallbackPolicy`)
A política de Fallback intercepta exceções e executa um bloco alternativo ou retorna um valor padrão, garantindo que o sistema degrade graciosamente.

```pascal
var Pipeline := TResiliencePipeline.Create
  .AddFallback<string>(function: string
    begin
      Result := 'valor-padrao';
    end);

var Valor := Pipeline.Execute<string>(function: string
  begin
    raise Exception.Create('Erro no serviço primário');
  end); // Retorna 'valor-padrao'
```

### D. Política de Timeout (`TTimeoutPolicy`)
A política de Timeout impõe uma duração máxima de execução. Ela executa a operação de forma assíncrona usando cancelamento cooperativo e lança `ETimeoutException` caso o tempo limite seja excedido.

```pascal
var Pipeline := TResiliencePipeline.Create.AddTimeout(100);

try
  Pipeline.Execute(procedure
    begin
      Sleep(200); // Excede o timeout
    end);
except
  on E: ETimeoutException do
    // Tratar timeout
end;
```

---

## 3. Executando o Pipeline

O pipeline suporta chamadas síncronas (procedimentos e funções) utilizando overloads genéricos fortemente tipados:

### A. Executando Procedimentos (Sem retorno)
```pascal
Pipeline.Execute(procedure
  begin
    // Executa tarefa
  end);
```

### B. Executando Funções (Com retorno)
```pascal
var Res: Integer := Pipeline.Execute<Integer>(function: Integer
  begin
    Result := ExecutarCalculo();
  end);
```

---

## 4. Integração com RestClient

O `TRestClient` do Dext integra-se nativamente com este pipeline de resiliência. Os métodos `.Retry()` e `.Timeout()` a nível de cliente configuram este motor internamente. Você também pode injetar diretamente um pipeline customizado pré-configurado:

```pascal
var PipelinePersonalizado := TResiliencePipeline.Create
  .AddRetry(3)
  .AddFallback<IRestResponse>(function: IRestResponse
    begin
      Result := TMockResponse.Create(503, 'Serviço Temporariamente Indisponível');
    end);

var Resp := RestClient('https://api.exemplo.com')
  .ResiliencePipeline(PipelinePersonalizado)
  .Get('/data')
  .Await;
```
