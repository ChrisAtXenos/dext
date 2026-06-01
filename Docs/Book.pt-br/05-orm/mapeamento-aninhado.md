# Multi-Mapping (Objetos Aninhados) & Motor de Hidratação

O Dext suporta **Multi-Mapping** (semelhante ao multi-mapping do Dapper), permitindo que você hidrate grafos de objetos complexos e multiníveis a partir de uma única consulta SQL plana com múltiplos joins. Isso é alcançado usando o atributo `[Nested]`.

Ao contrário de outros ORMs ou micro-mappers que exigem lambdas complexos ou strings manuais de divisão, o Dext implementa um **motor de hidratação recursivo e altamente otimizado orientado por convenção**.

---

## O Atributo [Nested]

O atributo `[Nested]` informa ao ORM que uma propriedade representa um objeto aninhado que deve ser hidratado a partir das colunas do conjunto de resultados atual, em vez de ser carregado via uma consulta separada (Lazy Loading) ou um join `Include`.

### Exemplo Básico

```pascal
type
  TAddress = class
  private
    FStreet: string;
    FCity: string;
  public
    property Street: string read FStreet write FStreet;
    property City: string read FCity write FCity;
  end;

  [Table('Users')]
  TUser = class
  private
    FId: Integer;
    FName: string;
    FAddress: TAddress;
  public
    [PK, AutoInc]
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;

    [Nested]
    property Address: TAddress read FAddress write FAddress;
  end;
```

---

## Lógica de Hidratação sob o Capô

Quando você executa uma consulta, o Dext lê a lista plana de nomes de colunas retornados pelo banco de dados.

Em vez de exigir uma string de configuração manual do tipo `splitOn` do Dapper (.NET) (ex: `splitOn: 'Id'`), os motores do `TReflection` e `TDbSet` do Dext funcionam via **Roteamento de Caminho Baseado em Convenção**:

1. **Escaneamento de Caminho (Path)**: O hidratador encontra colunas com separadores como `_` ou `.` (ex: `Address_Street`, `Address_City` ou `Address.Street`).
2. **Auto-Instanciação**: O hidratador verifica o prefixo `Address`. Se a propriedade existir na entidade alvo (`TUser`), for do tipo classe e estiver atualmente como `nil`, o hidratador **a instancia automaticamente** em tempo de execução usando o cache otimizado e thread-safe do `TActivator`.
3. **Escrita Direta em Campos**: Durante a hidratação, o Dext ignora os property setters lentos. Ele escreve diretamente nos campos privados da classe (ex: `FStreet`, `FCity`) resolvidos pelo cache da RTTI, evitando efeitos colaterais ou overhead de rastreamento no *Change Tracker* (Dirty Tracking).

```pascal
// Executando uma consulta SQL pura com tabelas joined
var Users := Db.Users.FromSql(
  'SELECT u.Id, u.Name, a.Street AS Address_Street, a.City AS Address_City ' +
  'FROM Users u INNER JOIN Addresses a ON u.AddressId = a.Id'
).ToList;

// Resultado: Cada objeto TUser é criado, seu objeto FAddress interno é
// automaticamente alocado e os campos aninhados são completamente hidratados.
```

---

## Multi-Mapping Avançado com Prefixos

Você pode especificar um prefixo personalizado no atributo `[Nested]` para mapear colunas que não correspondam exatamente ao nome da propriedade:

```pascal
type
  TUser = class
  private
    FAddress: TAddress;
  public
    [Nested('addr_')]
    property Address: TAddress read FAddress write FAddress;
  end;

// O hidratador agora espera colunas que começam com: addr_Street, addr_City
```

---

## Aninhamento Recursivo com Profundidade Infinita

Como o método `TReflection.SetValueByPath` do Dext é totalmente recursivo, ele suporta o mapeamento de árvores de objetos profundas. O motor de hidratação percorrerá e alocará automaticamente as classes aninhadas em qualquer profundidade, desde que caminhos de colunas correspondentes sejam encontrados no resultado da consulta.

### Exemplo de Aninhamento Profundo

```pascal
type
  TCountry = class
  private
    FName: string;
  public
    property Name: string read FName write FName;
  end;

  TAddress = class
  private
    FCity: string;
    FCountry: TCountry;
  public
    property City: string read FCity write FCity;
    
    [Nested]
    property Country: TCountry read FCountry write FCountry;
  end;

  TUser = class
  private
    FAddress: TAddress;
  public
    [Nested]
    property Address: TAddress read FAddress write FAddress;
  end;
```

**Colunas para consultar**:
* `Address_City`
* `Address_Country_Name` (ou `Address.Country.Name`)

Quando o hidratador do Dext processar a coluna `Address_Country_Name`, ele a dividirá em segmentos (`Address` -> `Country` -> `Name`). Ele instanciará automaticamente `FAddress` (se for `nil`), depois instanciará `FCountry` (se for `nil`) e, finalmente, definirá o campo `Name` do país.

---

## Quando usar Multi-Mapping vs Include

*   **Use `Include`**: Para relacionamentos de banco de dados padrão (1:1, 1:N) onde a entidade relacionada é uma entidade rastreada pelo banco, com seu próprio ciclo de vida independente e chaves primárias.
*   **Use `[Nested]`**:
    *   Para **Value Objects** (padrão DDD) que não possuem identidade própria no banco de dados e são armazenados na mesma tabela que o proprietário.
    *   Para otimizar manualmente joins complexos ao executar consultas SQL puras via `FromSql`.
    *   Para ignorar completamente o overhead de rastreamento de entidades e ler DTOs/projeções de leitura complexos em uma única viagem plana ao banco de dados.
