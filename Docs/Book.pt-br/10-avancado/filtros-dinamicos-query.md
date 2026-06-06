# Filtros Dinâmicos de Query

O ORM do Dext aplica **filtros globais de query** automaticamente em cada consulta. Os mais comuns são:

- **Soft Delete** — registros marcados como excluídos ficam ocultos (`WHERE IsDeleted = 0`).
- **Multi-Tenancy** — queries são escopadas ao tenant atual (`WHERE TenantId = 'x'`).

Em alguns cenários — painéis administrativos, auditorias ou fluxos de recuperação — você precisa ignorar esses filtros. Os Filtros Dinâmicos de Query fornecem uma saída type-safe em uma única linha de código.

---

## Ignorando Filtros — Três Abordagens

### 1. Diretamente no DbSet

```pascal
// Retorna TODOS os registros, incluindo os soft-deleted
var AllTasks := Db.Tasks.IgnoreQueryFilters.ToList;

// Ou: retorna apenas os registros soft-deleted
var Trash := Db.Tasks.OnlyDeleted.ToList;
```

`IgnoreQueryFilters` é escopado à chamada única. Chamadas subsequentes a `Db.Tasks.ToList` continuarão aplicando todos os filtros normalmente.

---

### 2. Via Specification

```pascal
uses Dext.Specifications;

var Spec := TSpecification<TTask>.Create;
Spec.IgnoreQueryFilters;

var AllTasks := Db.Tasks.ToList(Spec);
```

A flag `IsIgnoringFilters` na spec é automaticamente propagada ao `DbSet` antes da geração do SQL, e redefinida imediatamente após.

---

### 3. Admin Spec Autocontida (Padrão Recomendado)

Para queries administrativas recorrentes, incorpore a flag no construtor da spec:

```pascal
type
  TAllTasksSpec = class(TSpecification<TTask>)
  public
    constructor Create;
  end;

constructor TAllTasksSpec.Create;
begin
  inherited Create;
  IgnoreQueryFilters; // Declarado uma vez, reutilizável em qualquer lugar
  OrderBy(TPropExpression.Create('Id').Desc);
end;

// Uso — limpo, sem magic strings
var AllTasks := Db.Tasks.ToList(TAllTasksSpec.Create);
```

---

## Bypass de Multi-Tenancy

`IgnoreQueryFilters` ignora **tanto** o Soft Delete **quanto** os filtros de Multi-Tenancy simultaneamente. Ideal para operações de super-admin que precisam de acesso entre tenants.

```pascal
// Query administrativa cross-tenant
var AllOrders := Db.Orders.IgnoreQueryFilters.ToList;
```

> [!CAUTION]
> Use `IgnoreQueryFilters` apenas em contextos administrativos confiáveis. Nunca exponha em endpoints de API públicos sem verificações explícitas de autorização.

---

## Como Funciona

```
DbSet.IgnoreQueryFilters.ToList
│
├── TFluentQuery.IgnoreQueryFilters
│     └── Define ISpecification.FIgnoreQueryFilters = True
│
└── TDbSet<T>.ToList(ASpec)
      ├── Lê Spec.IsIgnoringFilters
      ├── Define FIgnoreQueryFilters = True no DbSet (escopado)
      ├── TSQLGenerator ignora GetSoftDeleteFilter  → sem WHERE IsDeleted
      ├── TSQLGenerator ignora GetQueryFiltersSQL   → sem filtro de tenant
      └── finally: ResetQueryFlags (restaura o estado)
```

Todo o mecanismo é **escopado à chamada**: cada `ToList` é independente.

---

## Referência da API

| API | Descrição |
|---|---|
| `DbSet.IgnoreQueryFilters.ToList` | Ignora todos os filtros globais para esta query |
| `DbSet.OnlyDeleted.ToList` | Retorna apenas os registros soft-deleted |
| `ISpecification.IgnoreQueryFilters` | Define a flag no objeto spec |
| `ISpecification.IsIgnoringFilters` | Lê a flag (usado internamente pelo `ToList`) |
| `ISpecification.IsOnlyDeleted` | Lê a flag OnlyDeleted (usado internamente pelo `ToList`) |

---

[← Background Jobs](background-jobs.md) | [Tópicos Avançados →](README.md)
