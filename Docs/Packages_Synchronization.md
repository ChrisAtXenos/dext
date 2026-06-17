# Sincronização de Pacotes Legados (Delphi XE2 a 10.3 Rio)

Este documento descreve como manter os pacotes do Dext Framework atualizados para versões anteriores ao Delphi 10.4 Sydney.

## Visão Geral

O Dext Framework utiliza os pacotes localizados na pasta `Sources` (baseados no **Delphi 10.4 Sydney** ou superior) como a principal fonte de verdade (*Source of Truth*). 

Para evitar a manutenção manual dos pacotes `.dpk` e `.dproj` de 11 versões legadas diferentes do Delphi (do XE2 até o 10.3 Rio), utilizamos a ferramenta **`tmsdev`** para sincronizar as alterações automaticamente a partir dos pacotes principais.

---

## Como Atualizar os Pacotes

Sempre que você adicionar novos arquivos, alterar dependências (`requires`), ou renomear pacotes na pasta principal `Sources`, você deve sincronizar as versões legadas executando o script utilitário de automação:

### Passo a Passo:

1. Abra um terminal do **PowerShell** no diretório raiz do repositório `DextRepository`.
2. Execute o seguinte comando:
   ```powershell
   powershell -ExecutionPolicy Bypass -File Scripts/sync-legacy-packages.ps1
   ```
3. O script irá:
   * Criar um ambiente temporário de sincronização.
   * Filtrar o arquivo `DextFramework.groupproj` para remover referências a executáveis de ferramentas (como `DextTool` e `DextSidecar`) que não devem ser gerados como pacotes de compatibilidade.
   * Chamar a ferramenta `tmsdev` para atualizar/criar as estruturas de pacotes legados.
   * Mover os arquivos gerados para a pasta correspondente sob [Sources/packages](file:///C:/dev/Dext/DextRepository/Sources/packages).
   * Excluir os diretórios temporários.

---

## Estrutura do tmsbuild.yaml

O arquivo [tmsbuild.yaml](file:///C:/dev/Dext/DextRepository/tmsbuild.yaml) está configurado para direcionar automaticamente o instalador do TMS Smart Setup para a pasta correta com base na versão utilizada:

* **Delphi 10.4 Sydney ou superior:** Utiliza diretamente a pasta [Sources](file:///C:/dev/Dext/DextRepository/Sources).
* **Delphi XE2 até Delphi 10.3 Rio:** Utiliza as subpastas específicas mapeadas em `package folders` (ex: `Sources\packages\drio`, `Sources\packages\dxe7`, etc.).

---

## Cuidados Especiais

* **Exclusão de Pacotes Incompatíveis:**
  Pacotes como o `Dext.Net.Core` (que dependem de recursos modernos introduzidos a partir do XE7/XE8, como o `TNetHTTPClient`) são automaticamente gerados pelo `tmsdev`, mas o `tmsbuild.yaml` está configurado com `ide since: delphixe7` na framework `rtl1` correspondente. Isso garante que o instalador ignore a compilação desse pacote em IDEs incompatíveis mais antigas.
