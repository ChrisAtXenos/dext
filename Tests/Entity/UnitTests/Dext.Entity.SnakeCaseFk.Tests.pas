unit Dext.Entity.SnakeCaseFk.Tests;

interface

uses
  System.SysUtils,
  Dext.Testing,
  Dext.Testing.Attributes,
  Dext.Entity.Attributes,
  Dext.Entity.Dialects,
  Dext.Specifications.SQL.Generator,
  Dext.Entity.Naming;

type
  [Table('categories')]
  TCategory = class
  private
    FId: Integer;
  public
    [PK] property Id: Integer read FId write FId;
  end;

  [Table('products')]
  TProduct = class
  private
    FId: Integer;
    FCategoryId: Integer;
    FCategory: TCategory;
  public
    [PK] property Id: Integer read FId write FId;
    
    [ForeignKey('Category')]
    property CategoryId: Integer read FCategoryId write FCategoryId;
    
    // Navigation
    property Category: TCategory read FCategory write FCategory;
  end;

  [TestFixture('SQL Generator SnakeCase FK Tests')]
  TSnakeCaseFkTests = class
  public
    [Test]
    procedure Test_GenerateCreateTable_WithSnakeCase_NormalizesForeignKey;
  end;

implementation

procedure TSnakeCaseFkTests.Test_GenerateCreateTable_WithSnakeCase_NormalizesForeignKey;
var
  Generator: TSqlGenerator<TProduct>;
  SQL: string;
begin
  Generator := TSqlGenerator<TProduct>.Create(TSQLiteDialect.Create, nil);
  try
    Generator.NamingStrategy := TSnakeCaseNamingStrategy.Create;
    SQL := Generator.GenerateCreateTable('products');
    
    // 1. Check current column normalization (from property ProductId/CategoryId)
    Should(SQL).Contain('"category_id" INTEGER');
    
    // 2. Check Foreign Key constraint normalization
    // The bug was: FOREIGN KEY ("CategoryId") ...
    // The fix should be: FOREIGN KEY ("category_id") ...
    Should(SQL).Contain('FOREIGN KEY ("category_id")');
    
    // 3. Check Related Table (categories) and PK (id) normalization
    Should(SQL).Contain('REFERENCES "categories" ("id")');
    
    // 4. Ensure PascalCase is gone from identifiers
    Should(SQL).NotContain('CategoryId');
  finally
    Generator.Free;
  end;
end;

end.
