unit Dext.ActiveArchitecture.Main.Form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.VCLUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.Grids, Vcl.DBGrids, Dext.Entity.DataSet,
  Dext.Entity.DataProvider, Dext.ActiveArchitecture.ViewModels, Dext.ActiveArchitecture.Domain,
  Dext.Collections, Dext.Entity.Drivers.Interfaces, Dext.Entity, Dext.ActiveArchitecture.Entities,
  Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TMainForm = class(TForm)
    EntityDataProvider: TEntityDataProvider;
    LogsMemo: TMemo;
    OrderDataSource: TDataSource;
    OrderDetailsDataSource: TDataSource;
    OrderDetailsEntityDataSet: TEntityDataSet;
    OrderDetailsGrid: TDBGrid;
    OrderEntityDataSet: TEntityDataSet;
    OrderGrid: TDBGrid;
    SqliteDemoConnection: TFDConnection;
    OrderDetailsEntityDataSetOrderId: TIntegerField;
    OrderDetailsEntityDataSetProductId: TIntegerField;
    OrderDetailsEntityDataSetUnitPrice: TCurrencyField;
    OrderDetailsEntityDataSetQuantity: TIntegerField;
    OrderDetailsEntityDataSetDiscount: TFloatField;
    OrderEntityDataSetOrderId: TIntegerField;
    OrderEntityDataSetCustomerId: TStringField;
    OrderEntityDataSetEmployeeId: TIntegerField;
    OrderEntityDataSetOrderDate: TDateTimeField;
    OrderEntityDataSetRequiredDate: TDateTimeField;
    OrderEntityDataSetShippedDate: TDateTimeField;
    OrderEntityDataSetShipVia: TIntegerField;
    OrderEntityDataSetFreight: TCurrencyField;
    OrderEntityDataSetShipName: TStringField;
    OrderEntityDataSetShipAddress: TStringField;
    OrderEntityDataSetShipCity: TStringField;
    OrderEntityDataSetShipRegion: TStringField;
    OrderEntityDataSetShipPostalCode: TStringField;
    OrderEntityDataSetShipCountry: TStringField;
  private
    FDbConnection: IDbConnection;
    FDbContext: TDbContext;
    FOrderDetails: IList<TOrderDetails>;
    FOrders: IList<TOrders>;
    FViewModel: TOrderViewModel;

    procedure CreateControls;
    procedure DoFormDestroy(Sender: TObject);
    procedure DoOrderDataSourceDataChange(Sender: TObject; Field: TField);
    procedure DoFilterComboChange(Sender: TObject);
  public
    procedure InjectDependencies(AViewModel: TOrderViewModel);
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.Rtti,
  Dext.Entity.Drivers.FireDAC,
  Dext.Entity.Dialects,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Base,
  Dext.Specifications.Types,
  Dext.ActiveArchitecture.Specifications,
  Dext.Logging,
  Dext.Logging.Global,
  Dext.Logging.Sinks.VCL;

{$R *.dfm}

procedure TMainForm.CreateControls;
var
  FilterPanel: TPanel;
  FilterLabel: TLabel;
  FilterCombo: TComboBox;
begin
  // Criação dinâmica do Painel de Filtros (DDD Specifications Showcase)
  FilterPanel := TPanel.Create(Self);
  FilterPanel.Parent := Self;
  FilterPanel.Align := alTop;
  FilterPanel.Height := 45;
  FilterPanel.BevelOuter := bvNone;
  FilterPanel.Color := clWhite;
  FilterPanel.ParentBackground := False;
  FilterPanel.BringToFront;

  FilterLabel := TLabel.Create(Self);
  FilterLabel.Parent := FilterPanel;
  FilterLabel.Left := 15;
  FilterLabel.Top := 15;
  FilterLabel.Caption := 'Filtrar por Especificação (DDD/Specification):';
  FilterLabel.Font.Name := 'Segoe UI';
  FilterLabel.Font.Style := [fsBold];
  FilterLabel.Font.Color := $00404040;

  FilterCombo := TComboBox.Create(Self);
  FilterCombo.Parent := FilterPanel;
  FilterCombo.Left := 280;
  FilterCombo.Top := 11;
  FilterCombo.Width := 480;
  FilterCombo.Style := csDropDownList;
  FilterCombo.Items.Add('Sem Filtro (Mostrar Todos os Pedidos)');
  FilterCombo.Items.Add('Especificação 1: Pedidos com Destino ao Brasil');
  FilterCombo.Items.Add('Especificação 2: Pedidos com Frete de Alto Valor (> R$ 50,00)');
  FilterCombo.Items.Add('Especificação 3: Pedidos do Brasil combinados com Frete Alto (> R$ 30,00)');
  FilterCombo.ItemIndex := 0;
  FilterCombo.OnChange := DoFilterComboChange;
end;

{ TMainForm }

procedure TMainForm.InjectDependencies(AViewModel: TOrderViewModel);
begin
  FViewModel := AViewModel;

  // Vincula os eventos em runtime de forma segura para não corromper o arquivo DFM da IDE
  OnDestroy := DoFormDestroy;
  OrderDataSource.OnDataChange := DoOrderDataSourceDataChange;

  // Inicialização que antes ficava no FormCreate
  Self.Caption := 'Dext - Active Architecture';
  CreateControls;

  SqliteDemoConnection.ConnectionDefName := 'SQLite_Demo';
  SqliteDemoConnection.Connected := True;

  // 1. Inicializa o Dext Logger com o Memo Sink
  Log.AddSink(TMemoLogSink.Create(LogsMemo, 500));
  Log.Info('Dext Logging inicializado com TMemoLogSink!');

  // 2. Criação do DbContext e conexão Dext
  FDbConnection := TFireDACConnection.Create(SqliteDemoConnection, False); // False = Não é dono da conexão, que é gerida pelo DFM/Form
  FDbContext := TDbContext.Create(FDbConnection, TSQLiteDialect.Create);

  // 2.1 Ativa o log da geração de SQL no DbContext
  FDbContext.OnLog :=
    procedure(ASql: string)
    begin
      Log.Info('SQL: ' + ASql);
    end;

  // Registrar entidades no contexto
  FDbContext.Entities<TOrders>;
  FDbContext.Entities<TOrderDetails>;

  // 3. Carregar os dados na lista
  FOrders := FDbContext.Entities<TOrders>.ToList;
  FOrderDetails := FDbContext.Entities<TOrderDetails>.ToList;

  // 4. Configurar e popular o dataset mestre (TOrders)
  OrderEntityDataSet.Load<TOrders>(FOrders);
  OrderEntityDataSet.Open;
  OrderDataSource.DataSet := OrderEntityDataSet;

  // 5. Configurar e popular o dataset detalhe (TOrderDetails) mestre/detalhe
  OrderDetailsEntityDataSet.Load<TOrderDetails>(FOrderDetails);
  OrderDetailsEntityDataSet.MasterSource := OrderDataSource;
  OrderDetailsEntityDataSet.MasterFields := 'OrderId';
  OrderDetailsEntityDataSet.IndexFieldNames := 'OrderId';
  OrderDetailsEntityDataSet.Open;
  OrderDetailsDataSource.DataSet := OrderDetailsEntityDataSet;
end;

procedure TMainForm.DoFormDestroy(Sender: TObject);
begin
  OrderDetailsEntityDataSet.Close;
  OrderEntityDataSet.Close;

  FOrders := nil;
  FOrderDetails := nil;

  if Assigned(FDbContext) then
  begin
    FDbContext.Free;
    FDbContext := nil;
  end;

  FDbConnection := nil;

  if Assigned(FViewModel) then
    FViewModel.Free;
end;

procedure TMainForm.DoOrderDataSourceDataChange(Sender: TObject; Field: TField);
var
  Order: TOrders;
begin
  // Evita reentrada se a ViewModel já estiver calculando ou se não houver registros
  if not Assigned(FViewModel) or FViewModel.IsCalculating then
    Exit;

  Order := TOrders(OrderEntityDataSet.GetCurrentObject);
  if Assigned(Order) then
  begin
    // Se o frete já foi calculado (ou seja, não é zero), pulamos para economizar chamadas HTTP
    if Order.Freight.Value > 0.0 then
      Exit;

    FViewModel.Load(Order);

    // Atualiza o título da janela indicando o cálculo assíncrono em background (Zero UI Blocking!)
    Self.Caption := 'Calculando cotação de frete para ' + Order.ShipCountry.Value + ' (Assíncrono)...';

    FViewModel.CalcularFreteExterno(
      procedure
      begin
        // Callback executado na Main Thread de forma automática e segura pelo Dext!
        Self.Caption := 'Dext Framework - Delphi Connect Portugal - Clean Architecture VCL';
        // Recarrega a Grid para exibir o frete recém calculado e atualizado no domínio rico
        OrderEntityDataSet.RefreshRecord;
      end);
  end;
end;

procedure TMainForm.DoFilterComboChange(Sender: TObject);
var
  Spec: ISpecification<TOrders>;
begin
  try
    case TComboBox(Sender).ItemIndex of
         // Pedidos do Brasil
      1: Spec := TBrazilOrdersSpec.Create;
         // Pedidos com Frete Alto (> R$ 50)
      2: Spec := TExpensiveFreightSpec.Create(50.00);
         // Brasil + Frete Alto (> R$ 30)
      3: Spec := TBrazilHeavyFreightSpec.Create(30.00);
    else
      // Sem Filtro
      Spec := nil;
    end;

    if Assigned(Spec) then
      OrderEntityDataSet.FilterExpression := Spec.GetExpression
    else
      OrderEntityDataSet.FilterExpression := nil;

    Log.Info('Especificação aplicada! Filtro Ativo: "' + OrderEntityDataSet.Filter + '"');
  except on E: Exception do
    begin
      OrderEntityDataSet.FilterExpression := nil;
      Log.Error(E.ClassName + ' - ' + E.Message);
    end;
  end;
end;

end.
