# MCP VCL Database Demo

Este exemplo demonstra como utilizar a implementação nativa do **Dext MCP Server** integrada a uma aplicação visual VCL no Delphi com o banco de dados **FireDAC** (SQLite em memória).

---

## Recursos Demonstrados

- **Servidor MCP Assíncrono**: Inicia o servidor em segundo plano sem congelar a tela da aplicação.
- **FireDAC**: Consulta e atualização de dados no SQLite.
- **DBGrid**: Visualização em tempo real das alterações feitas pelo modelo de IA (LLM).
- **Console de Eventos**: Memo integrado que exibe o log de requisições recebidas do cliente MCP.
- **Tools Personalizadas**:
  - `listar-participantes`: Retorna a listagem atual de pessoas cadastradas.
  - `sortear-participante`: Sorteia uma pessoa aleatória não sorteada, marcando-a no banco.
  - `executar-sql`: Permite a IA rodar consultas SELECT ou comandos UPDATE diretamente no banco.

---

## Como Executar

1. Compile e execute o projeto `MCP.VclDbDemo.dproj`.
2. Clique no botão **Iniciar Servidor**. Por padrão, ele escutará na porta `3031`.
3. Para testar localmente via curl:
   ```bash
   curl http://localhost:3031/health
   ```
4. Conecte ao seu assistente de preferência (ex: Claude Code):
   ```bash
   claude mcp add db-demo http://localhost:3031/mcp
   ```

5. Interaja com a IA:
   > "Faça um sorteio dos participantes agora e me diga quem ganhou"
   > "Quantos participantes temos no banco?"
   > "Rode uma query para ver quem já foi sorteado"
