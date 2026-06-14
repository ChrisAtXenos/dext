### Pipeline de Scaffolding: Fluxo de Execução

#### 1. Ponto de Entrada e Orquestração
*   **Unidade:** `DextTool.dpr` / `Dext.Hosting.CLI.Commands.Scaffold.pas`
*   **O que faz:** 
    *   O `DextTool.dpr` inicializa o ambiente e registra os comandos. 
    *   Quando você digita `scaffold`, a execução pula para `TScaffoldCommand.Execute` na unidade `Dext.Hosting.CLI.Commands.Scaffold`.
    *   Nesta etapa, os parâmetros (`--driver`, `--connection`, `--output`) são validados e a conexão com o banco é estabelecida via FireDAC.

#### 2. Abstração do Banco de Dados
*   **Unidade:** `Dext.Entity.Drivers.FireDAC.pas`
*   **O que faz:** 
    *   Implementa a interface `IDbConnection`. É aqui que o Dext "conversa" com o FireDAC de forma agnóstica.
    *   Esta unidade fornece o método `GetMetadata`, que é o wrapper sobre o `TFDMetaInfoQuery` do próprio FireDAC.

#### 3. Extração de Metadados (A "Alma" do Scaffolding)
*   **Unidade:** `Dext.Entity.Scaffolding.pas` (Classe `TFireDACSchemaProvider`)
*   **O que faz:** 
    *   Este é o coração da extração. Ele percorre o banco de dados em 3 níveis:
        1.  **GetTables:** Lista todas as tabelas.
        2.  **GetTableMetadata:** Para cada tabela, ele extrai Colunas, Chaves Primárias e, o mais importante, **Foreign Keys**.
    *   **Lógica de Fix (Recente):** Como o Firebird e outros bancos podem retornar metadados redundantes para a mesma chave estrangeira (especialmente se houver múltiplos índices para o mesmo campo), implementamos aqui a **Deduplicação de FKs**. Antes de adicionar uma FK à lista `Result.ForeignKeys`, verificamos se já existe uma FK para aquele par `ColumnName` + `ReferencedTable`.

#### 4. Geração de Código Delphi
*   **Unidade:** `Dext.Entity.Scaffolding.pas` (Classe `TDelphiEntityGenerator`)
*   **O que faz:** 
    *   Recebe a lista de `TMetaTable` (preenchida no passo anterior) e transforma em strings de código Delphi.
    *   **Lógica de Mapeamento:** Para cada FK encontrada nos metadados, o gerador cria:
        1.  Uma propriedade privada (`FNav...`) do tipo `Lazy<T>`.
        2.  Uma propriedade pública com o atributo `[ForeignKey(...)]`.
    *   **Ajuste de Nome:** Se houver colisões (ex: duas FKs para a mesma tabela), ele usa o sufixo `2`, `3`, etc. Por isso, se a deduplicação no passo 3 falhar, você acaba vendo `Country2`, `Country3`.

#### 5. Escrita do Arquivo
*   **Unidade:** `Dext.Hosting.CLI.Commands.Scaffold.pas`
*   **O que faz:** 
    *   Pega a string gigante gerada pelo `TDelphiEntityGenerator` e usa `TFile.WriteAllText` para salvar o seu `Entities.pas`.

---

### Resumo das Unidades para sua Revisão:

1.  **`Dext.Hosting.CLI.Commands.Scaffold.pas`**: Orquestração e CLI.
2.  **`Dext.Entity.Drivers.Interfaces.pas`**: Definição dos contratos (`IDbConnection`, `ISchemaProvider`).
3.  **`Dext.Entity.Drivers.FireDAC.pas`**: Implementação da conexão física.
4.  **`Dext.Entity.Scaffolding.pas`**: **A unidade mais importante.** Contém a extração (`TFireDACSchemaProvider`) e a geração de código (`TDelphiEntityGenerator`).

### O que revisar especificamente em `Dext.Entity.Scaffolding.pas`:

*   **Método `ExtractTableMetadataInternal`**: Verifique como as FKs são coletadas. Note que para Firebird (`FB`) e SQLite, existe um tratamento customizado via SQL direto nas tabelas de sistema (`RDB$RELATION_CONSTRAINTS`) para garantir precisão onde o metadado padrão do FireDAC às vezes falha.
*   **Método `GenerateClass`**: Veja como ele itera sobre `Table.ForeignKeys`. Se a lista que chega aqui estiver limpa (deduplicada), o código gerado será limpo.

Como o seu último teste com o script `TestScaffoldFB.ps1` retornou `VERIFIED: No duplicate 'User2' properties found`, isso confirma que a lógica na etapa 3 (extração) agora está filtrando corretamente os metadados redundantes do Firebird.

Deseja que eu aprofunde em algum desses métodos específicos?