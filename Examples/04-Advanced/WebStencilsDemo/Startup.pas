unit Startup;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Dext.Collections,      // IList<T>
  Dext.Configuration.Interfaces,
  Dext.Core.SmartTypes,
  Dext.DI.Interfaces,
  Dext.Entity.Core,      // IDbSet<T>
  Dext.Entity.Query,
  Dext.Specifications.Types,
  Dext.Web.Interfaces,   // IResult, IWebApplication
  Dext.Web.Results,
  Dext.Web.View,
  {$IFDEF DEXT_ENABLE_WEB_STENCILS}
  Web.Stencils,
  {$ENDIF}
  Dext.Web.View.WebStencils,
  Dext,
  Dext.Entity,           // Entity Facade
  Dext.Web,              // Web HELPERS LAST
  Customer;

type
  TAppDbContext = class(TDbContext)
  private
    function GetCustomers: IDbSet<TCustomer>;
  public
    constructor Create; overload;
    property Customers: IDbSet<TCustomer> read GetCustomers;
  end;

  TSearchDTO = record
    SearchTerm: string;
  end;

  TStartup = class(TInterfacedObject, IStartup)
  public
    class procedure SeedData(const Services: IServiceProvider);
    procedure ConfigureServices(const Services: TDextServices; const Configuration: IConfiguration);
    procedure Configure(const App: IWebApplication);
  end;

implementation

{ TAppDbContext }

constructor TAppDbContext.Create;
begin
  // Initialize with nil as the container will provide the real options if needed, 
  // but for TDbContext it's required by the framework constraints.
  inherited Create(nil, nil, nil);
end;

function TAppDbContext.GetCustomers: IDbSet<TCustomer>;
begin
  Result := Entities<TCustomer>;
end;

{ TStartup }

procedure TStartup.ConfigureServices(const Services: TDextServices; const Configuration: IConfiguration);
begin
  Services
    .AddDbContext<TAppDbContext>(
      procedure(Opts: TDbContextOptions)
      begin
        Opts.UseSqlite('webstencils-customers.db');
      end)
    {$IFDEF DEXT_ENABLE_WEB_STENCILS}
    .AddWebStencils;
    {$ELSE}
    .AddDextTemplating;
    {$ENDIF}
end;

procedure TStartup.Configure(const App: IWebApplication);
begin
  // JSON global settings
  JsonDefaultSettings(JsonSettings.CamelCase.CaseInsensitive.ISODateFormat);

  App.Builder
    .UseDeveloperExceptionPage
    //.UseExceptionHandler
    .UseHttpLogging
    .UseViewEngine
    .UseStaticFiles('wwwroot')
    .MapGetResult<IResult>('/',
      function: IResult
      begin
        Result := Results.View('index');
      end)
    .MapGetResult<TAppDbContext, IResult>('/customers',
      function(Db: TAppDbContext): IResult
      begin
        Result := Results.View<TCustomer>('customers', Db.Customers.QueryAll);
      end)
    .MapGetResult<TAppDbContext, TSearchDTO, IResult>('/customers/search',
      function(Db: TAppDbContext; Query: TSearchDTO): IResult
      var
        c: TCustomer;
      begin
        c := Prototype.Entity<TCustomer>;
        Result := Results.View<TCustomer>('customers_list',
          Db.Customers.Where((c.Name.Contains(Query.SearchTerm)) or (c.Email.Contains(Query.SearchTerm)))
        );
      end);
end;

class procedure TStartup.SeedData(const Services: IServiceProvider);
var
  DB: TAppDbContext;

  procedure AddCustomer(const Name, Email: string);
  var
    C: TCustomer;
  begin
    C := TCustomer.Create;
    C.Name := Name;
    C.Email := Email;
    DB.Customers.Add(C);
  end;

begin
  // Using explicit type cast to resolve GetService ambiguity in some Delphi versions
  DB := Services.GetService(TAppDbContext) as TAppDbContext;
  if DB = nil then Exit;
  
  DB.EnsureCreated;
  
  if DB.Customers.QueryAll.Count = 0 then
  begin
    AddCustomer('Cesar Romero', 'cesar@dotpas.dev');
    AddCustomer('Jaques Nascimento', 'jaques@neoui.com');
    AddCustomer('Armando Neto', 'armandinho@dext.dev');
    AddCustomer('John Doe', 'john@example.com');
    AddCustomer('Jane Smith', 'jane.smith@test.com');
    AddCustomer('Bob Anderson', 'bob@anderson.io');
    AddCustomer('Alice Cooper', 'alice.c@music.com');
    AddCustomer('Charlie Brown', 'charlie@peanuts.com');
    AddCustomer('David Bowie', 'david@stardust.io');
    AddCustomer('Grace Hopper', 'grace@cobol.dev');
    AddCustomer('Ada Lovelace', 'ada@first-dev.org');
    AddCustomer('Alan Turing', 'alan@enigma.com');
    
    DB.SaveChanges;
  end;
end;

end.
