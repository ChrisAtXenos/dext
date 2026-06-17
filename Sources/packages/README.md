# Legacy Packages Directory

Este diretório contém os arquivos de pacotes (`.dpk` e `.dproj`) destinados a versões antigas do Delphi (anteriores ao **Delphi 10.4 Sydney**), cobrindo de **Delphi XE2** a **Delphi 10.3 Rio**.

Estes arquivos podem ser gerados e atualizados automaticamente usando a ferramenta `tmsdev` com o comando `sync-packages`.

## Exemplo de Sincronização com `tmsdev`:
Para criar ou atualizar os pacotes deste diretório usando o Delphi 11 como base:
```powershell
tmsdev sync-packages -targets:dxe2-dxe8,d10-d10.3 -source:d11 -createtarget
```
