unit Dext.Entity.Async.Tests;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Dext.Testing.Attributes,
  Dext.Testing,
  Dext.Mocks,
  Dext.Entity.Core,
  Dext.Entity.Context,
  Dext.Entity.Setup,
  Dext.Entity.DbSet,
  Dext.Entity.Query,
  Dext.Entity.Dialects,
  Dext.Entity.Drivers.Interfaces,
  Dext.Threading.Async,
  Dext.Collections;

type
  [TestFixture('Async ORM Operations Tests')]
  TAsyncTests = class
  public
    [Test]
    [Description('Verify ToListAsync raises error when connection is not pooled')]
    procedure TestToListAsyncShouldFailOnNonPooledConnection;

    [Test]
    [Description('Verify SaveChangesAsync raises error when connection is not pooled')]
    procedure TestSaveChangesAsyncShouldFailOnNonPooledConnection;

    [Test]
    [Description('Verify ToListAsync executes correctly on pooled connection')]
    procedure TestToListAsyncShouldSucceedOnPooledConnection;

    [Test]
    [Description('Verify SaveChangesAsync executes correctly on pooled connection')]
    procedure TestSaveChangesAsyncShouldSucceedOnPooledConnection;
  end;

implementation

{ TAsyncTests }

procedure TAsyncTests.TestToListAsyncShouldFailOnNonPooledConnection;
var
  Conn: Mock<IDbConnection>;
  Query: TFluentQuery<TObject>;
begin
  Conn := Mock<IDbConnection>.Create;
  Conn.Setup.Returns(False).When.IsPooled;

  Query := TFluentQuery<TObject>.Create(nil, nil, nil, nil, nil, Conn.Instance);

  Should(procedure
    begin
      Query.ToListAsync;
    end).Throw(Exception);
end;

procedure TAsyncTests.TestSaveChangesAsyncShouldFailOnNonPooledConnection;
var
  Conn: Mock<IDbConnection>;
  Ctx: TDbContext;
begin
  Conn := Mock<IDbConnection>.Create;
  Conn.Setup.Returns(False).When.IsPooled;
  
  Ctx := TDbContext.Create(Conn.Instance);
  try
    Should(procedure
      begin
        Ctx.SaveChangesAsync;
      end).Throw(Exception);
  finally
    Ctx.Free;
  end;
end;

procedure TAsyncTests.TestToListAsyncShouldSucceedOnPooledConnection;
var
  Conn: Mock<IDbConnection>;
  Query: TFluentQuery<TObject>;
  Builder: TAsyncBuilder<IList<TObject>>;
begin
  Conn := Mock<IDbConnection>.Create;
  Conn.Setup.Returns(True).When.IsPooled;

  // We need a factory that returns something for ToList
  Query := TFluentQuery<TObject>.Create(
    function: TQueryIterator<TObject>
    begin
      Result := nil;
    end,
    nil, nil, nil, nil, Conn.Instance);

  Builder := Query.ToListAsync;
  Should(Builder.Start).NotBeNil;
end;

procedure TAsyncTests.TestSaveChangesAsyncShouldSucceedOnPooledConnection;
var
  Conn: Mock<IDbConnection>;
  Ctx: TDbContext;
  Builder: TAsyncBuilder<Integer>;
begin
  Conn := Mock<IDbConnection>.Create;
  Conn.Setup.Returns(True).When.IsPooled;
  
  Ctx := TDbContext.Create(Conn.Instance);
  try
    Builder := Ctx.SaveChangesAsync;
    Should(Builder.Start).NotBeNil;
  finally
    Ctx.Free;
  end;
end;

end.
