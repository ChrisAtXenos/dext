# Arquitetura do Servidor Dext & Análise Profunda do Indy

## 1. Resumo Executivo
Este documento descreve a arquitetura do Servidor HTTP Dext, implementado sobre a biblioteca **Indy (Internet Direct)**. Ele documenta as melhorias críticas de estabilidade realizadas para suportar a aplicação **Sidecar** (VCL/GUI), detalhando as causas raízes de travamentos anteriores (Access Violations) e os padrões arquiteturais estabelecidos para preveni-los.

## 2. Arquitetura do Servidor

### 2.1. O Padrão "Adapter" (Adaptador)
O Dext evita reinventar a roda adaptando o componente maduro `TIdHTTPServer` para a abstração `IWebHost`.

*   **TIndyWebServer (Adaptador)**: Envolve o `TIdHTTPServer`. Ele traduz os eventos específicos do Indy (`OnCommandGet`) para requisições do pipeline Dext (`IHttpContext`).
*   **Desacoplamento**: O restante do framework (Controllers, Middleware, Roteamento) não sabe nada sobre o Indy. Isso permite trocar o motor subjacente (por exemplo, para HTTP.sys ou FastCGI) no futuro sem quebrar a lógica da aplicação.

### 2.2. Modelo de Threads do Indy
Entender o Indy é crucial para a estabilidade:
1.  **Modelo Síncrono/Bloqueante**: Diferente de Node.js ou Asp.Net (que usam Async I/O), o Indy reserva uma thread do SO para cada conexão ativa.
2.  **Thread Ouvinte (Listener)**: O `TIdHTTPServer` cria uma thread interna em segundo plano apenas para ouvir requisições de conexão na porta.
3.  **Threads de Contexto**: Quando um cliente conecta, o Indy cria uma thread de trabalho dedicada (Context) que vive enquanto a conexão durar (ou duração do Keep-Alive).

---

## 3. Análise de Causa Raiz: Problemas de Estabilidade do "Sidecar"

Antes da refatoração recente, a aplicação Sidecar sofria de Access Violations (AV) intermitentes e "Hangs" (congelamentos) durante o encerramento. Uma pesquisa profunda revelou três anti-padrões convergentes:

### 3.1. O Anti-Padrão "Thread Encapsulada"
**Problema**: O Sidecar estava envolvendo a chamada `IWebHost.Run` dentro de uma `TThread.CreateAnonymousThread`.
**Análise**:
*   O `TIdHTTPServer` **já é multi-thread**. Ele gerencia suas próprias threads de Listener e Workers.
*   Ao envolver o `Run` (que era bloqueante) em mais uma thread, criou-se um limbo de responsabilidade (ownership).
*   **A Armadilha**: Quando o Formulário Principal da VCL fecha, ele destrói a referência da interface. Se a Thread Anônima ainda estiver rodando (bloqueada dentro do loop `Run`), ela tenta acessar a Interface/Objeto destruído, causando um **Access Violation**.

### 3.2. Deadlock de Encerramento Bloqueante
**Problema**: Usuários com conexões ativas de **Server-Sent Events (SSE)** (Dext Hubs) possuem threads presas em loops infinitos (`while Connected do ...`).
**Análise**:
*   Definir `Server.Active := False` sinaliza para as threads pararem, mas isso **não** interrompe uma thread bloqueada em `Sleep()` ou `Socket.Read()`.
*   A Thread Principal espera o Servidor desativar.
*   O Servidor espera as Threads de Trabalho terminarem.
*   As Threads de Trabalho estão dormindo/bloqueadas indefinidamente.
*   **Resultado**: A aplicação congela até o SO matá-la, ou quebra se recursos forem liberados prematuramente.

### 3.3. Inanição (Starvation) da Thread Principal VCL
**Problema**: Usar `Run` (loop bloqueante) na Thread Principal congela a interface gráfica (GUI).
**Correção**: Introduzimos o `Start` (Não-Bloqueante).
*   `TIdHTTPServer.Active := True` é não-bloqueante. Ele inicia a thread Listener e retorna imediatamente.
*   Isso permite que o loop `Application.Run` da VCL processe Mensagens do Windows livremente enquanto o Indy lida com o Tráfego de Rede em segundo plano.

---

## 4. A Solução: Gerenciamento Robusto de Ciclo de Vida

Para resolver esses problemas definitivamente, implementamos uma estratégia de 3 pilares:

### 4.1. Separação de Responsabilidades: `Start` vs `Run`
Dividimos o modelo de execução para suportar corretamente tanto Console quanto Apps GUI:

| Método | Comportamento | Ambiente Alvo |
| :--- | :--- | :--- |
| **`Start`** | Ativa o servidor e retorna imediatamente. NÃO bloqueia. | **VCL/FMX Forms** (Sidecar) |
| **`Run`** | Chama `Start`, depois entra em loop esperando sinal de término (Ctrl+C). | **Console Services** (CLI / Daemons) |

### 4.2. Limpeza Agressiva de Sockets (`Stop`)
A correção mais crítica para o problema de "Hang". Apenas definir `Active := False` é insuficiente para threads presas.

**Algoritmo implementado em `TIndyWebServer.Stop`**:
1.  **Sinal Gracioso**: Define flag global de parada.
2.  **Interrupção Forçada**: Itera por todas as conexões de clientes ativas (`Contexts`).
3.  **Fechar Socket à Força**: Chama `Context.Binding.CloseSocket`.
    *   Isso força o socket do SO subjacente a fechar.
    *   O Indy levanta um `EIdSocketError` imediatamente dentro da thread de trabalho.
    *   O mecanismo de `try..except` na thread de trabalho captura isso e sai do loop graciosamente.
4.  **Desativação**: Finalmente, define `Active := False`.

### 4.3. Propriedade de Interface & Segurança ARC
*   Removido `TThread.CreateAnonymousThread` do Sidecar.
*   A instância `IWebHost` agora pertence ao `TMainForm` (ou `TDextApplication`).
*   O método `Start` roda na Thread Principal (seguro para inicialização).
*   O método `Stop` (chamado no `FormDestroy`) garante que o servidor seja completamente desligado **antes** da classe ser destruída.

---

## 5. Padrões Arquiteturais para Colaboradores

Ao trabalhar no Core do Servidor, siga estas regras:

1.  **Nunca Envolva o Indy em uma Thread**: Ele já é multi-thread. Use `Start` (Active := True) e deixe o Indy gerenciar suas threads.
2.  **Sem Loops Infinitos sem Timeout**: Em Middleware/Handlers, sempre verifique `Wait(Timestamp)` ou `Context.Connected` frequentemente.
3.  **Interrupção de Hardware**: Se uma thread precisa ser parada urgentemente para prevenir estados zumbis, fechar o handle do socket é o único método 100% confiável em arquiteturas de sockets bloqueantes.
4.  **Idempotência**: Garanta que métodos `Stop` e `Teardown` possam ser chamados múltiplas vezes sem erro (Verifique `if Active then...`).

## 6. Referências
*   **Projeto Indy**: [Documentação Indy Sockets](https://www.indyproject.org/)
*   **Microsoft .NET Hosting**: Conceitos de `IHost`, `StartAsync`, `StopAsync` adaptados para Delphi/Dext.
