program MetaTest;
{$APPTYPE CONSOLE}
uses System.SysUtils, FireDAC.Comp.Client, FireDAC.Stan.Intf, Data.DB, FireDAC.Phys.SQLite, FireDAC.Phys.Intf, FireDAC.DApt, FireDAC.Stan.Def, FireDAC.Stan.ExprFuncs, FireDAC.Stan.Async;

var
  Conn: TFDConnection;
  Meta: TFDMetaInfoQuery;
  i: Integer;
begin
  try
    Conn := TFDConnection.Create(nil);
    Conn.DriverName := 'SQLite';
    Conn.Params.Add('Database=:memory:');
    Conn.Connected := True;
    Conn.ExecSQL('CREATE TABLE Users (Id INTEGER PRIMARY KEY, Name TEXT)');
    Conn.ExecSQL('CREATE TABLE Roles (Id INTEGER PRIMARY KEY, Name TEXT)');
    Conn.ExecSQL('CREATE TABLE UserRoles (UserId INTEGER, RoleId INTEGER, PRIMARY KEY (UserId, RoleId), FOREIGN KEY (UserId) REFERENCES Users(Id), FOREIGN KEY (RoleId) REFERENCES Roles(Id))');
    
    Meta := TFDMetaInfoQuery.Create(nil);
    Meta.Connection := Conn;
    
    Writeln('--- mkTableFields BaseObjectName ---');
    Meta.MetaInfoKind := mkTableFields;
    Meta.ObjectName := '';
    Meta.BaseObjectName := 'UserRoles';
    try
      Meta.Open;
      Writeln('OK!');
      Meta.Close;
    except
      on E: Exception do Writeln(E.Message);
    end;
    
    Writeln('--- mkPrimaryKeyFields ---');
    Writeln('--- mkForeignKeyFields ---');
    Meta.MetaInfoKind := mkForeignKeyFields;
    Meta.BaseObjectName := 'UserRoles';
    Meta.ObjectName := 'FK_0';
    Meta.Open;
    for i := 0 to Meta.FieldCount - 1 do Write(Meta.Fields[i].FieldName, ' | ');
    Writeln;
    while not Meta.Eof do
    begin
      for i := 0 to Meta.FieldCount - 1 do Write(Meta.Fields[i].AsString, ' | ');
      Writeln;
      Meta.Next;
    end;
    Meta.Close;
  except
    on E: Exception do Writeln(E.Message);
  end;
end.
