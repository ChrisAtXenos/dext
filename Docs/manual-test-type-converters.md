# Teste Manual de Type Converters com PostgreSQL

Este documento descreve como testar manualmente os type converters com PostgreSQL.

## Pré-requisitos

1. PostgreSQL instalado e rodando
2. Database `dext_test` criado
3. Usuário `postgres` com senha `postgres` (ou ajuste em `EntityDemo.DbConfig.pas`)

## Passos para Teste

### 1. Abrir o Projeto Orm.EntityDemo

Abra o projeto `Examples\Orm.EntityDemo\Orm.EntityDemo.dpr` no Delphi IDE.

### 2. Configurar para PostgreSQL

No arquivo `EntityDemo.Main.pas`, localize a linha que configura o provider e altere para:

```pascal
TDbConfig.ConfigurePostgreSQL('localhost', 5432, 'dext_test', 'postgres', 'postgres');
```

### 3. Adicionar Entidades de Teste

Adicione as seguintes entidades no projeto (pode criar uma nova unit ou adicionar em uma existente):

```pascal
type
  TUserRole = (urGuest, urUser, urAdmin, urSuperAdmin);
  
  [Table('test_guid_entity')]
  TGuidTestEntity = class
  private
    FId: TGUID;
    FName: string;
  public
    [Column('id', [cpPrimaryKey])]
    property Id: TGUID read FId write FId;
    
    [Column('name')]
    property Name: string read FName write FName;
  end;

  [Table('test_enum_entity')]
  TEnumTestEntity = class
  private
    FId: Integer;
    FRole: TUserRole;
  public
    [Column('id', [cpPrimaryKey, cpAutoIncrement])]
    property Id: Integer read FId write FId;
    
    [Column('role')]
    [EnumAsString]
    property Role: TUserRole read FRole write FRole;
  end;
```

### 4. Testar GUID

```pascal
procedure TestGuid;
var
  Db: TMyDbContext;
  Entity: TGuidTestEntity;
  TestGuid: TGUID;
begin
  Db := TMyDbContext.Create(TDbConfig.CreateConnection, TDbConfig.CreateDialect);
  try
    Db.EnsureCreated;
    
    Entity := TGuidTestEntity.Create;
    try
      CreateGUID(TestGuid);
      Entity.Id := TestGuid;
      Entity.Name := 'Test GUID';
      
      Db.Set<TGuidTestEntity>.Add(Entity);
      Db.SaveChanges;
      
      WriteLn('GUID saved: ', GUIDToString(TestGuid));
    finally
      Entity.Free;
    end;
    
    // Carregar de volta
    Entity := Db.Set<TGuidTestEntity>.FirstOrDefault;
    if Entity <> nil then
    begin
      WriteLn('GUID loaded: ', GUIDToString(Entity.Id));
      WriteLn('Match: ', IsEqualGUID(TestGuid, Entity.Id));
      Entity.Free;
    end;
  finally
    Db.Free;
  end;
end;
```

### 5. Verificar no PostgreSQL

Conecte-se ao PostgreSQL e execute:

```sql
-- Ver tabelas criadas
\dt

-- Ver dados da tabela GUID
SELECT * FROM test_guid_entity;

-- Ver tipo da coluna
\d test_guid_entity

-- Ver dados da tabela Enum
SELECT * FROM test_enum_entity;
```

## Resultados Esperados

### GUID
- Coluna `id` deve ser do tipo `uuid`
- Valor deve ser armazenado no formato `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- Round-trip deve preservar o valor exato

### Enum (String mode)
- Coluna `role` deve ser do tipo `varchar` ou `text`
- Valor deve ser armazenado como string (ex: `'urSuperAdmin'`)
- Round-trip deve preservar o valor do enum

### JSON (se testado)
- Coluna deve ser do tipo `jsonb`
- Valor deve ser armazenado como JSON válido
- Round-trip deve preservar a estrutura do objeto

## Troubleshooting

Se houver erros:

1. **Erro de conexão**: Verifique se o PostgreSQL está rodando e as credenciais estão corretas
2. **Erro de tipo**: Verifique se os type converters estão registrados corretamente
3. **Erro de serialização**: Verifique se o `TDextJson` está funcionando corretamente

## Conclusão

Se todos os testes passarem, os type converters estão funcionando corretamente com PostgreSQL e prontos para publicação!
