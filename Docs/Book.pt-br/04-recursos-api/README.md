# 4. Recursos da API

Recursos essenciais para construir APIs prontas para produção.

## Capítulos

1. [Middleware](middleware.md) - Componentes do pipeline de requisição
2. [Filtros de Action](filtros.md) - Interceptadores declarativos
3. [OpenAPI / Swagger](openapi-swagger.md) - Documentação auto-gerada
4. [Rate Limiting](rate-limiting.md) - Controle de taxa
5. [CORS](cors.md) - Cross-origin resource sharing
6. [Response Caching](cache.md) - Cabeçalhos e estratégias de cache
7. [Health Checks](health-checks.md) - Endpoints de monitoramento
8. [Validação](validacao.md) - Validação dinâmica e fortemente tipada de requisições

## Exemplos Rápidos

### Swagger

```pascal
App.UseSwagger;
App.UseSwaggerUI;
// Visite: /swagger
```

### Rate Limiting

```pascal
App.UseRateLimiting(
  TRateLimitOptions.Create
    .Limit(100)
    .PerMinute
);
```

### CORS

```pascal
App.UseCors(
  TCorsOptions.Create
    .AllowOrigin('https://meuapp.com')
    .AllowMethods(['GET', 'POST'])
);
```

### Health Check

```pascal
App.MapGet('/health', procedure(Ctx: IHttpContext)
  begin
    Ctx.Response.Json('{"status": "saudável"}');
  end);
```

---

[← Autenticação](../03-autenticacao/README.md) | [Próximo: OpenAPI/Swagger →](openapi-swagger.md)
