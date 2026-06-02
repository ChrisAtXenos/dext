# Instalação e Configuração do Dext Framework

Este guia descreve os passos necessários para compilar o framework e configurar o Delphi para utilização do Dext.

## 1. Personalização do Framework (Dext.inc)

Antes de compilar o Dext Framework, você pode personalizar o comportamento e as dependências do framework editando o arquivo `Sources\Dext.inc`. Este arquivo centraliza todas as configurações globais:

### A. Drivers de Banco de Dados (Dext.Entity)
Por padrão, o Dext vem configurado apenas com o driver **SQLite** habilitado, garantindo total compatibilidade com o **Delphi Community Edition**. Se você possui Delphi Enterprise/Architect e deseja habilitar outros bancos de dados, descomente as linhas correspondentes:
```pascal
{$DEFINE DEXT_ENABLE_DB_SQLITE}      // Já ativo por padrão
{.$DEFINE DEXT_ENABLE_DB_POSTGRES}   // Remova o ponto (.) para ativar
{.$DEFINE DEXT_ENABLE_DB_MYSQL}
{.$DEFINE DEXT_ENABLE_DB_MSSQL}
{.$DEFINE DEXT_ENABLE_DB_ORACLE}
{.$DEFINE DEXT_ENABLE_DB_FIREBIRD}
```
*Importante:* Ao habilitar outros bancos de dados, adicione a unit `Dext.Entity.Drivers.FireDAC.Links` ao seu projeto (ex: na cláusula `uses` do `.dpr` ou Formulário Principal) para garantir que os drivers sejam vinculados corretamente.

### B. Integração com TestInsight (`DEXT_TESTINSIGHT`)
Se você utiliza a ferramenta **TestInsight** para gerenciar e executar testes unitários diretamente na IDE do Delphi, descomente a linha correspondente para ativar a integração:
```pascal
{.$DEFINE DEXT_TESTINSIGHT}
```
*Nota: Requer que `TestInsight.Client.pas` esteja no Library Path da sua IDE.*

### C. Web Stencils (`DEXT_ENABLE_WEB_STENCILS`)
Para projetos desenvolvidos em **Delphi 12.2 ou superior** no Windows, o Dext suporta o uso do novo mecanismo de templates **Web Stencils**:
```pascal
{$IFDEF DEXT_DELPHI12_UP}
  {$IFDEF MSWINDOWS}
    {$DEFINE DEXT_ENABLE_WEB_STENCILS}
  {$ENDIF}
{$ENDIF}
```

### D. Conflitos de Nomes de Componentes (`DEXT_USE_ENTITY_PREFIX`)
Caso você possua outras bibliotecas instaladas (como o Devart EntityDAC) que utilizem os mesmos nomes de componentes (`TEntityDataSet`, `TEntityDataProvider`), você enfrentará um conflito na IDE durante a instalação. Para resolver isso, descomente a linha correspondente para registrar componentes com o prefixo `TDext...`:
```pascal
{.$DEFINE DEXT_USE_ENTITY_PREFIX}
```

---

## 2. Compilação dos Fontes

Após ajustar o arquivo `Dext.inc` conforme a sua necessidade:

1. Abra o grupo de projetos principal no Delphi:
    * `Sources\DextFramework.groupproj`
2. No Project Manager, clique com o botão direito no nó raiz (**ProjectGroup**) e selecione **Build All**.
3. Aguarde a conclusão da compilação de todos os pacotes.

Os arquivos compilados serão gerados automaticamente na pasta:
* `Output\$(Platform)\$(Config)`
* *Exemplo:* `Output\Win32\Debug`

> **Nota:** O arquivo `Dext.inc` personalizado é copiado automaticamente para a pasta de saída (`Output`) durante o processo de Build, garantindo que suas aplicações herdem as mesmas definições do framework compilado.

## 3. Configuração de Variável de Ambiente (Recomendado)

Utilizar uma variável de ambiente simplifica seus Library Paths e permite alternar entre diferentes versões/forks do Dext facilmente.

1. No Delphi, vá em **Tools** > **Options** > **IDE** > **Environment Variables**.
2. Em **User System Overrides**, clique em **New...**.
3. **Variable Name**: `DEXT`
4. **Value**: O caminho completo para a pasta `Sources` dentro do seu repositório clonado.
    * *Exemplo:* `C:\dev\Dext\DextRepository\Sources`
    * *Nota:* Aponte para a pasta `Sources`, não a raiz.

    ![Variável de Ambiente DEXT](../../Images/ide-env-var.png)

## 4. Configuração do Library Path (DCUs)

Para que a IDE encontre os arquivos compilados do framework, você deve adicionar o caminho para a pasta de saída (`Output`) no Library Path.

> [!IMPORTANT]
> A IDE do Delphi **não expande** variáveis dinâmicas de projeto (como `$(Platform)` ou `$(Config)`) nas configurações globais de Library Path. Por isso, você deve adicionar caminhos específicos para as combinações que deseja utilizar.

1. No Delphi, vá em **Tools** > **Options** > **Language** > **Delphi** > **Library**.
2. Selecione a **Platform** desejada (ex: Windows 32-bit).
3. No campo **Library Path**, adicione o caminho para a pasta onde os arquivos `.dcu` foram gerados. Use a variável `$(DEXT)` para simplificar:
    * `$(DEXT)\..\Output\37.0_win32_debug` (para Debug)
    * `$(DEXT)\..\Output\37.0_win32_release` (para Release)

*Nota: Repita o processo para outras plataformas (ex: Win64), ajustando o nome da pasta conforme gerado na compilação do Passo 1.*

## 5. Configuração do Browsing Path (Arquivos Fonte)

Para permitir a navegação no código fonte (Ctrl+Click) e debugging detalhado, adicione os seguintes diretórios ao **Browsing Path** da sua IDE.

> [!WARNING]
> **NÃO coloque estas pastas de fontes no campo Library Path!**  
> Se você adicionar pastas de sources (fontes) no Library Path, o compilador do Delphi irá recompilar pedaços do Dext toda vez que você compilar o projeto da sua aplicação. Isso fará com que arquivos `.dcu` de versões diferentes fiquem espalhados pelas pastas do seu projeto, gerando erros de compilação difíceis de rastrear (como o erro `F2051`).  
> **O Dext deve ser compilado exclusivamente na instalação.**

1. No Delphi, vá em **Tools** > **Options** > **Language** > **Delphi** > **Library**.
2. Selecione a **Platform** desejada (ex: Windows 32-bit).
3. No campo **Browsing Path**, adicione os diretórios de Fontes listados abaixo.

```text
$(DEXT)
$(DEXT)\AI
$(DEXT)\AI\MCP
$(DEXT)\Core
$(DEXT)\Core\Base
$(DEXT)\Core\Interception
$(DEXT)\Core\Json
$(DEXT)\Dashboard
$(DEXT)\Data
$(DEXT)\Debug
$(DEXT)\Design
$(DEXT)\Events
$(DEXT)\Hosting
$(DEXT)\Hosting\CLI
$(DEXT)\Hosting\CLI\Logger
$(DEXT)\Hosting\CLI\Tools
$(DEXT)\Hubs
$(DEXT)\Hubs\Transports
$(DEXT)\Net
$(DEXT)\Testing
$(DEXT)\UI
$(DEXT)\Web
$(DEXT)\Web\Caching
$(DEXT)\Web\Hosting
$(DEXT)\Web\Indy
$(DEXT)\Web\Middleware
$(DEXT)\Web\Mvc
$(DEXT)\..\Apps\CLI\Commands
```

*Observação: As pastas `Http` e `Expressions` mencionadas em versões anteriores foram renomeadas ou reorganizadas para `Web` e outros módulos.*

> [!TIP]
> **Dica:** Como adicionar cada item manualmente é trabalhoso, você pode copiar a linha abaixo e colá-la diretamente no final do campo **Browsing Path**:
> ```text
> ;$(DEXT);$(DEXT)\AI;$(DEXT)\AI\MCP;$(DEXT)\Core;$(DEXT)\Core\Base;$(DEXT)\Core\Interception;$(DEXT)\Core\Json;$(DEXT)\Dashboard;$(DEXT)\Data;$(DEXT)\Debug;$(DEXT)\Design;$(DEXT)\Events;$(DEXT)\Hosting;$(DEXT)\Hosting\CLI;$(DEXT)\Hosting\CLI\Logger;$(DEXT)\Hosting\CLI\Tools;$(DEXT)\Hubs;$(DEXT)\Hubs\Transports;$(DEXT)\Net;$(DEXT)\Testing;$(DEXT)\UI;$(DEXT)\Web;$(DEXT)\Web\Caching;$(DEXT)\Web\Hosting;$(DEXT)\Web\Indy;$(DEXT)\Web\Middleware;$(DEXT)\Web\Mvc;$(DEXT)\..\Apps\CLI\Commands
> ```

## 5.1 Instalação para Outras Plataformas (Linux, Win64, Android, iOS...)

O Dext Framework suporta compilação multi-plataforma. Se você deseja utilizar o Dext em plataformas como Linux, Windows 64-bit ou dispositivos móveis, siga as instruções abaixo:

1. **Adicione a plataforma ao pacote (se necessário):**
   No Delphi Project Manager, se a plataforma desejada não estiver listada no pacote em **Target Platforms**, clique com o botão direito em **Target Platforms**, escolha **Add Platform...** e selecione a plataforma desejada.

2. **Selecione a plataforma ativa na barra de ferramentas:**
   Para compilar os pacotes do Dext para a plataforma desejada, você não precisa fazer isso pacote por pacote. Na barra de ferramentas principal do Delphi, selecione a plataforma desejada no menu drop-down de seleção de plataforma activa (ao lado do botão de Build/Run). Isso aplicará a plataforma ativa a todos os pacotes do Project Group que a suportam.
   
3. **Execute o Build:**
   Com a plataforma ativa selecionada (por exemplo, `Linux 64-bit` ou `Windows 64-bit`), clique com o botão direito no nó raiz (**ProjectGroup**) no Project Manager e selecione **Build All**.

4. **Configure os Paths para a nova plataforma:**
   Lembre-se de repetir os passos de **Library Path** (Passo 4) e **Browsing Path** (Passo 5) para cada uma das novas plataformas configuradas, selecionando a plataforma correspondente no menu de seleção de plataforma das Opções da IDE do Delphi.

## 6. Verificação

Para confirmar que a instalação está correta:

1. Feche o grupo de projetos do framework.
2. Abra o grupo de exemplos:
    * `Examples\DextExamples.groupproj`
3. Execute **Build All**.
4. Se todos os projetos compilarem com sucesso, o ambiente está configurado corretamente.

## 5. Conflitos de Nomes de Componentes (ex: Devart EntityDAC)

Caso você possua outras bibliotecas instaladas (como o Devart EntityDAC) que utilizem os mesmos nomes de componentes (`TEntityDataSet`, `TEntityDataProvider`), você enfrentará um conflito na IDE durante a instalação.

Para resolver isso, o Dext oferece uma opção de prefixo nos nomes:

1. Abra o arquivo `Sources\Dext.inc`.
2. Descomente a diretiva: `{$DEFINE DEXT_USE_ENTITY_PREFIX}`.
3. Recompile o framework.

Isso registrará os componentes como **`TDextEntityDataSet`** e **`TDextEntityDataProvider`**, permitindo que coexistam com outras bibliotecas na mesma IDE.

---

## Resolução de Problemas

### F2051: Unit was compiled with a different version

**Exemplo do Erro:**

```text
[dcc32 Fatal Error] Dext.WebHost.pas(35): F2051 Unit Dext.Web.HandlerInvoker was compiled with a different version of Dext.Json.TDextSerializer.Serialize
```

**Causa:**  
Este erro ocorre quando o compilador Delphi encontra um conflito entre arquivos `.dcu` pré-compilados e arquivos fonte `.pas` crus. Tipicamente, isso acontece quando as pastas `Sources` são incorretamente adicionadas ao **Library Path** em vez do **Browsing Path**.

**Solução:**

1. Vá em **Tools** > **Options** > **Language** > **Delphi** > **Library**.
2. Selecione a **Platform** correta (ex: Windows 32-bit).
3. Verifique seu **Library Path**:
    * ✅ Deve conter **apenas** a pasta `Output` com os DCUs compilados (ex: `C:\dev\Dext\DextRepository\Output\Win32\Debug`).
    * ❌ Remova quaisquer pastas `Sources\*` do Library Path.
4. Verifique seu **Browsing Path**:
    * ✅ Deve conter as pastas `Sources\*` (conforme listado no Passo 3 acima).
5. Limpe e recompile:
    * Delete quaisquer arquivos `.dcu` da pasta de saída do seu projeto.
    * Recompile o Dext framework (`Sources\DextFramework.groupproj` > **Build All**).
    * Recompile seu projeto.

### Compilação falha com erros "File not found"

**Causa:**  
O Library Path não contém a pasta dos DCUs compilados, ou o framework não foi compilado para a plataforma/configuração alvo.

**Solução:**

1. Certifique-se de que você compilou o framework Dext para a plataforma correta (Win32/Win64) e configuração (Debug/Release).
2. Verifique se o Library Path aponta para a pasta `Output` correta (ex: `Output\37.0_win32_debug`).
3. Se estiver alternando entre Debug e Release, atualize o Library Path de acordo ou adicione ambos os caminhos.

### Debug stepping não funciona / Não consigo navegar para o fonte

**Causa:**  
As pastas de Fontes (`Sources`) não estão no Browsing Path.

**Solução:**

1. Adicione todas as pastas `Sources\*` ao **Browsing Path** (não ao Library Path).
2. Garanta que a opção "Use debug DCUs" esteja ativada nas opções do seu projeto se desejar debugar também códigos da RTL/VCL.

### Referência Rápida: Resumo da Configuração de Paths

| Tipo de Path      | O Que Adicionar                           | Objetivo                             |
|-------------------|-------------------------------------------|--------------------------------------|
| **Library Path**  | `Output\Win32\Debug` (ou sua config alvo) | Localizar arquivos `.dcu` compilados  |
| **Browsing Path** | Todas as pastas `Sources\*`               | Navegação no código e debugging      |

---

[← Voltar para Primeiros Passos](README.md) | [Próximo: Hello World →](hello-world.md)
