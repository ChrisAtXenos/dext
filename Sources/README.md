# Dext Framework - Sources Directory

Este diretório contém os códigos-fontes e arquivos de pacotes (.dpk/.dproj) do **Dext Framework**.

## Estrutura de Pacotes por Versão do Delphi

Para manter a compatibilidade com múltiplas versões do Delphi (incluindo versões legadas), a estrutura de pacotes está organizada da seguinte forma:

* **`/Sources` (Raiz):**
  Contém os pacotes para as versões modernas do Delphi, a partir do **Delphi 10.4 Sydney** (inclusive).
  
* **`/Sources/packages`:**
  Diretório reservado para pacotes de IDEs anteriores ao Delphi 10.4 Sydney (por exemplo, de **Delphi XE2** até **Delphi 10.3 Rio**).
  Estes pacotes são gerados ou sincronizados automaticamente a partir dos pacotes principais para facilitar testes de compilação em ambientes mais antigos.

> [!NOTE]
> Pacotes que utilizam recursos introduzidos a partir do Delphi XE7/XE8 (como o `Dext.Net.Core`, que faz uso do `TNetHTTPClient`) não são suportados em versões anteriores.
