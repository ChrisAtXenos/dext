# Soft Delete

Marque registros como excluídos sem removê-los fisicamente do banco de dados.

## Ativando o Soft Delete

Aplique o atributo `[SoftDelete]` à classe da sua entidade. Por padrão, ele utiliza uma flag Boolean onde `True` significa excluído.

```pascal
type
  [Table('tasks')]
  [SoftDelete('IsDeleted')] // Mapeia para a propriedade abaixo
  TTask = class
  private
    FIsDeleted: Boolean;
  public
    property IsDeleted: Boolean read FIsDeleted write FIsDeleted;
  end;
```

### Valores Customizados

Você também pode usar inteiros ou enums para os estados.

```pascal
[SoftDelete('Status', 99, 0)] // Excluído = 99, Ativo = 0
TUser = class
  property Status: Integer read FStatus write FStatus;
end;
```

## Timestamp de Exclusão (Auditoria)

Se você precisar saber **quando** um registro foi excluído, utilize o atributo `[DeletedAt]`. A simples presença deste atributo em uma propriedade habilita automaticamente o Soft Delete para a entidade.

```pascal
type
  [Table('orders')]
  TOrder = class
  private
    FDeletedAt: DateTimeType; // Ideal: Smart Property (Dext unit)
  public
    [DeletedAt]
    property DeletedAt: DateTimeType read FDeletedAt write FDeletedAt;
  end;
```

> [!TIP]
> O ideal é utilizar **Smart Properties** (`DateTimeType`), que já oferecem suporte nativo a nulos e segurança de tipo em consultas. Caso não esteja utilizando Smart Properties, utilize obrigatoriamente `Nullable<TDateTime>` para garantir que o campo inicie como `NULL`.

Neste modo:
*   **Filtro**: O Dext aplicará automaticamente `WHERE DeletedAt IS NULL` para registros ativos.
*   **Ação**: Ao chamar `.Remove()`, o campo receberá o timestamp atual (`Now`).

### Modo Híbrido (Performance + Auditoria)

Para cenários de alta performance, você pode combinar os dois atributos. Use o `[SoftDelete]` na classe para o filtro rápido (booleano) e o `[DeletedAt]` na propriedade para auditoria:

```pascal
[SoftDelete('IsDeleted')] 
TOrder = class
  property IsDeleted: Boolean read FIsDeleted write FIsDeleted;

  [DeletedAt] 
  property DeletedAt: DateTimeType read FDeletedAt write FDeletedAt;
end;
```

> [!IMPORTANT]
> No modo híbrido, o Dext prioriza a flag booleana para a geração dos filtros SQL por questões de performance, mas garante que ambos os campos sejam atualizados durante a exclusão.

## Operações

### Excluindo (Soft)

O método padrão `.Remove()` agora realizará um `UPDATE` em vez de um `DELETE`.

```pascal
Db.Tasks.Remove(Task);
Db.SaveChanges; 
// UPDATE tasks SET is_deleted = 1 WHERE id = ...
```

### Exclusão Física (Hard Delete)

Para ignorar a regra de soft delete e remover permanentemente um registro:

```pascal
Db.Tasks.HardDelete(Task);
// DELETE FROM tasks WHERE id = ...
```

### Restaurando (Undelete)

Para "desfazer" uma exclusão:

```pascal
Db.Tasks.Restore(Task);
// UPDATE tasks SET is_deleted = 0 WHERE id = ...
```

## Consultas (Querying)

Por padrão, registros ocultos com soft-delete são **escondidos** de todas as consultas.

```pascal
// Retorna apenas registros ativos
var Active := Db.Tasks.ToList;
```

### Incluindo Registros Excluídos

Para ver tudo (ex: em um painel administrativo):

```pascal
var All := Db.Tasks.IgnoreQueryFilters.ToList;
```

### Lixeira (Apenas Excluídos)

Para buscar apenas registros que foram excluídos:

```pascal
var Trash := Db.Tasks.OnlyDeleted.ToList;
```

## Notas Importantes

- **Cascateamento**: O Soft Delete **não** cascateia automaticamente para relacionamentos filhos. Você deve gerenciar as exclusões de dependentes manualmente ou via triggers no banco.
- **IdentityMap**: Entidades com soft-delete são removidas do cache de memória após o `SaveChanges` para manter um estado consistente.

---

[← Transações](transacoes.md) | [Próximo: Procedimentos Armazenados →](procedimentos-armazenados.md)
