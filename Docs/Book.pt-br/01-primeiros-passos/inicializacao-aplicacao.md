# Inicialização da Aplicação

Para projetos profissionais, o Dext recomenda separar a configuração do arquivo `.dpr` principal usando uma **Classe Startup**.

## Por que usar uma Classe Startup?

- **Código Limpo**: Mantém o arquivo `.dpr` minimalista e focado apenas em iniciar o processo.
- **Separação de Preocupações**: Serviços e Middlewares são configurados em uma classe dedicada.
- **Testabilidade**: Mais fácil de "mockar" configurações durante testes de integração.
- **Manutenibilidade**: Evita o código "macarronada" em blocos globais.

## O Padrão Startup Class

Crie uma nova unit (ex: `App.Startup.pas`) implementando a interface `IStartup`:

```pascal
unit App.Startup;

interface

uses
  Dext.Web, Dext.DependencyInjection;

type
  TStartup = class(TInterfacedObject, IStartup)
  public
    procedure ConfigureServices(const Services: IServiceCollection; const Configuration: IConfiguration);
    procedure Configure(const App: IApplicationBuilder);
  end;

implementation

procedure TStartup.ConfigureServices(const Services: IServiceCollection; const Configuration: IConfiguration);
begin
  // 1. Registre seus serviços de negócio
  Services.AddScoped<IUserService, TUserService>;
  
  // 2. Configure o Banco de Dados
  Services.AddDbContext<TAppDbContext>(procedure(Options: TDbContextOptions)
    begin
      Options.UsePostgreSQL(Configuration.GetValue('ConnectionStrings:Default'));
    end);
end;

procedure TStartup.Configure(const App: IApplicationBuilder);
begin
  // 3. Configure o Pipeline de Middlewares
  App.UseExceptionHandler;
  App.UseCors;
  App.UseAuthentication;
  
  // 4. Mapear Rotas/Controllers
  App.MapControllers;
  
  App.MapGet('/', procedure(Ctx: IHttpContext)
    begin
      Ctx.Response.Write('Bem-vindo à Dext API');
    end);
end;

end.
```

## Programa Principal (.dpr)

Com a classe Startup, seu arquivo principal fica extremamente enxuto:

```pascal
program MeuProjeto;

{$APPTYPE CONSOLE}

uses
  Dext.Web,
  App.Startup in 'src\App.Startup.pas';

begin
  TWebHostBuilder.CreateDefault
    .UseStartup<TStartup>
    .Build
    .Run;
end.
```

## Avançado: Seed de Dados

Você também pode incluir um método de seed na sua classe Startup para popular o banco no primeiro acesso, como visto no exemplo **OrderAPI**:

```pascal
class procedure TStartup.Seed(const App: IWebApplication);
begin
  using var Scope := App.Services.CreateScope;
  var Context := Scope.ServiceProvider.GetService<TAppDbContext>;
  
  Context.EnsureCreated;
  if Context.Users.Count = 0 then
  begin
    Context.Users.Add(TUser.Create('Admin'));
    Context.SaveChanges;
  end;
end;
```

> 📦 **Referência de Qualidade**: Veja o exemplo [Web.OrderAPI](../../../Examples/Web.OrderAPI/OrderAPI.Startup.pas) para uma implementação real completa deste padrão.

---

[← Estrutura do Projeto](estrutura-projeto.md) | [Próximo: Framework Web →](../02-framework-web/README.md)
