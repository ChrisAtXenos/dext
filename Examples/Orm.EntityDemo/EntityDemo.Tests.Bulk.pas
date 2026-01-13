unit EntityDemo.Tests.Bulk;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Dext.Entity.Dialects,
  EntityDemo.Tests.Base,
  EntityDemo.Entities,
  EntityDemo.DbConfig;

type
  TBulkTest = class(TBaseTest)
  public
    procedure Run; override;
  end;

implementation

{ TBulkTest }

procedure TBulkTest.Run;
var
  BulkUsers: TObjectList<TUser>;
  i: Integer;
  StartTime: TDateTime;
  Duration: TDateTime;
  Count: Integer;
  Dialect: ISQLDialect;
  SQL: string;
begin
  Dialect := TDbConfig.CreateDialect;
  
  Log('📦 Running Bulk Operation Tests...');
  Log('================================');

  BulkUsers := TObjectList<TUser>.Create(False);
  try
    // 1. Bulk Insert
    Log('   Preparing 100 users...');
    for i := 1 to 100 do
    begin
      var U := TUser.Create;
      U.Name := 'Bulk User ' + i.ToString;
      U.Age := 20;
      U.Email := 'bulk' + i.ToString + '@dext.com';
      U.Address := nil; 
      BulkUsers.Add(U);
    end;

    StartTime := Now;
    FContext.Entities<TUser>.AddRange(BulkUsers);
    FContext.SaveChanges;
    Duration := Now - StartTime;
    
    LogSuccess(Format('Inserted 100 users in %s', [FormatDateTime('ss.zzz', Duration)]));

    SQL := Format('SELECT COUNT(*) FROM %s WHERE %s = 20 AND %s LIKE ''Bulk User%%''',
      [Dialect.QuoteIdentifier('users'), Dialect.QuoteIdentifier('Age'), Dialect.QuoteIdentifier('full_name')]);
    Count := FConn.ExecSQLScalar(SQL);
    AssertTrue(Count = 100, 'Bulk Add Verified.', Format('Bulk Add Failed: Found %d users.', [Count]));

    // 2. Bulk Update
    Log('   Updating 100 users...');
    for var U in BulkUsers do
    begin
      U.Age := 30;
      // Note: We need to call UpdateRange, but currently UpdateRange iterates and calls Update.
      // We can modify the objects here and then call UpdateRange.
    end;

    StartTime := Now;
    FContext.Entities<TUser>.UpdateRange(BulkUsers);
    FContext.SaveChanges;
    Duration := Now - StartTime;

    LogSuccess(Format('Updated 100 users in %s', [FormatDateTime('ss.zzz', Duration)]));

    SQL := Format('SELECT COUNT(*) FROM %s WHERE %s = 30 AND %s LIKE ''Bulk User%%''',
      [Dialect.QuoteIdentifier('users'), Dialect.QuoteIdentifier('Age'), Dialect.QuoteIdentifier('full_name')]);
    Count := FConn.ExecSQLScalar(SQL);
    AssertTrue(Count = 100, 'Bulk Update Verified.', Format('Bulk Update Failed: Found %d users.', [Count]));

    // 3. Bulk Remove
    Log('   Removing 100 users...');
    StartTime := Now;
    FContext.Entities<TUser>.RemoveRange(BulkUsers);
    FContext.SaveChanges;
    Duration := Now - StartTime;

    LogSuccess(Format('Removed 100 users in %s', [FormatDateTime('ss.zzz', Duration)]));

    SQL := Format('SELECT COUNT(*) FROM %s WHERE %s LIKE ''Bulk User%%''',
      [Dialect.QuoteIdentifier('users'), Dialect.QuoteIdentifier('full_name')]);
    Count := FConn.ExecSQLScalar(SQL);
    AssertTrue(Count = 0, 'Bulk Remove Verified.', Format('Bulk Remove Failed: Found %d users.', [Count]));

  finally
    BulkUsers.Free;
  end;
  
  Log('');
end;

end.
