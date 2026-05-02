unit Dext.Entity.Migrations.Tests;

interface

uses
  Dext.Collections,
  Dext.Testing,
  Dext.Entity.Migrations.Model,
  Dext.Entity.Migrations.Differ,
  Dext.Entity.Migrations.Operations,
  System.SysUtils;

type
  [TestFixture]
  TMigrationTests = class
  public
    [Test]
    procedure Test_Rename_Table_Detection;
    [Test]
    procedure Test_Rename_Column_Detection;
  end;

implementation

{ TMigrationTests }

procedure TMigrationTests.Test_Rename_Table_Detection;
var
  OldModel, NewModel: TSnapshotModel;
  OldTable, NewTable: TSnapshotTable;
  Differ: TModelDiffer;
  Ops: IList<TMigrationOperation>;
  Found: Boolean;
  Op: TMigrationOperation;
begin
  OldModel := TSnapshotModel.Create;
  OldTable := TSnapshotTable.Create;
  OldTable.Name := 'OldUsers';
  OldModel.Tables.Add(OldTable);

  NewModel := TSnapshotModel.Create;
  NewTable := TSnapshotTable.Create;
  NewTable.Name := 'Users';
  NewTable.RenamedFrom := 'OldUsers'; // Simulate attribute
  NewModel.Tables.Add(NewTable);

  Differ := TModelDiffer.Create;
  try
    Ops := Differ.Diff(NewModel, OldModel);
    
    Found := False;
    for Op in Ops do
      if Op is TRenameTableOperation then
      begin
        Should(TRenameTableOperation(Op).OldName).Be('OldUsers');
        Should(TRenameTableOperation(Op).NewName).Be('Users');
        Found := True;
      end;
      
    Should(Found).BeTrue;
  finally
    Differ.Free;
    OldModel.Free;
    NewModel.Free;
  end;
end;

procedure TMigrationTests.Test_Rename_Column_Detection;
var
  OldModel, NewModel: TSnapshotModel;
  Table, NewTable: TSnapshotTable;
  OldCol, NewCol: TSnapshotColumn;
  Differ: TModelDiffer;
  Ops: IList<TMigrationOperation>;
  Found: Boolean;
  Op: TMigrationOperation;
begin
  OldModel := TSnapshotModel.Create;
  Table := TSnapshotTable.Create;
  Table.Name := 'Users';
  OldCol := TSnapshotColumn.Create;
  OldCol.Name := 'Full_Name';
  Table.Columns.Add(OldCol);
  OldModel.Tables.Add(Table);

  NewModel := TSnapshotModel.Create;
  NewTable := TSnapshotTable.Create;
  NewTable.Name := 'Users';
  NewCol := TSnapshotColumn.Create;
  NewCol.Name := 'Name';
  NewCol.RenamedFrom := 'Full_Name';
  NewTable.Columns.Add(NewCol);
  NewModel.Tables.Add(NewTable);

  Differ := TModelDiffer.Create;
  try
    Ops := Differ.Diff(NewModel, OldModel);
    
    Found := False;
    for Op in Ops do
      if Op is TRenameColumnOperation then
      begin
        Should(TRenameColumnOperation(Op).TableName).Be('Users');
        Should(TRenameColumnOperation(Op).OldName).Be('Full_Name');
        Should(TRenameColumnOperation(Op).NewName).Be('Name');
        Found := True;
      end;
      
    Should(Found).BeTrue;
  finally
    Differ.Free;
    OldModel.Free;
    NewModel.Free;
  end;
end;

end.
