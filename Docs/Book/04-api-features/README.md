# 4. API Features

Essential features for building production-ready APIs.

## Chapters

1. [Middleware](middleware.md) - Request pipeline components
2. [Action Filters](filters.md) - Declarative interceptors
3. [OpenAPI / Swagger](openapi-swagger.md) - Auto-generated documentation
4. [Rate Limiting](rate-limiting.md) - Request throttling
5. [CORS](cors.md) - Cross-origin resource sharing
6. [Response Caching](cache.md) - Cache headers & strategies
7. [Health Checks](health-checks.md) - Monitoring endpoints
8. [Validation](validation.md) - Dynamic & type-safe request validation

## Quick Examples

### Swagger

```pascal
App.UseSwagger;
App.UseSwaggerUI;
// Visit: /swagger
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
    .AllowOrigin('https://myapp.com')
    .AllowMethods(['GET', 'POST'])
);
```

### Health Check

```pascal
App.MapGet('/health', procedure(Ctx: IHttpContext)
  begin
    Ctx.Response.Json('{"status": "healthy"}');
  end);
```

---

[← Authentication](../03-authentication/README.md) | [Next: OpenAPI/Swagger →](openapi-swagger.md)
