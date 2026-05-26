unit Dext.ActiveArchitecture.UnitTests;

interface

uses
  System.Classes,
  System.Rtti,
  System.SysUtils,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.ActiveArchitecture.Entities,
  Dext.ActiveArchitecture.Domain,
  Dext.ActiveArchitecture.ViewModels,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Base,
  Dext.ActiveArchitecture.Specifications;

type
  // 1. Suite de Testes para a Entidade TOrderDetails (Domínio Rico)
  [Fixture]
  TOrderDetailsTests = class
  public
    [Test]
    procedure Deve_Aplicar_Desconto_Zero_Para_Ate_10_Itens;
    [Test]
    procedure Deve_Aplicar_5_Porcento_De_Desconto_Para_11_A_50_Itens;
    [Test]
    procedure Deve_Aplicar_10_Porcento_De_Desconto_Para_Mais_De_50_Itens;
  end;



  // 2. Suite de Testes para a ViewModel TOrderViewModel (MVVM & Clean Architecture)
  [Fixture]
  TOrderViewModelTests = class
  public
    [Test]
    procedure Deve_Calcular_Frete_Usando_Serviço_Mockado;
    [Test]
    procedure Deve_Inicializar_Em_Estado_Limpo;
  end;

  // 3. Suite de Testes para as Especificações de Domínio (DDD Specification)
  [Fixture]
  TOrderSpecificationsTests = class
  public
    [Test]
    procedure Deve_Expressar_Filtro_Do_Brasil_Corretamente;
    [Test]
    procedure Deve_Expressar_Filtro_De_Frete_Alto_Corretamente;
    [Test]
    procedure Deve_Expressar_Filtro_Combinado_Corretamente;
  end;

implementation

uses
  Dext.Mocks,
  Dext.Mocks.Matching;

{ TOrderDetailsTests }

procedure TOrderDetailsTests.Deve_Aplicar_Desconto_Zero_Para_Ate_10_Itens;
var
  Item: TOrderDetails;
begin
  Item := TOrderDetails.Create;
  try
    Item.UnitPrice := 10.00;
    Item.Quantity := 10;
    
    Item.CalcularDescontoProgressivo;
    
    Should(Item.Discount).Be(0.0);
    Should(Item.ObterTotalComDesconto).Be(100.00);
  finally
    Item.Free;
  end;
end;

procedure TOrderDetailsTests.Deve_Aplicar_5_Porcento_De_Desconto_Para_11_A_50_Itens;
var
  Item: TOrderDetails;
begin
  Item := TOrderDetails.Create;
  try
    Item.UnitPrice := 10.00;
    Item.Quantity := 20;
    
    Item.CalcularDescontoProgressivo;
    
    Should(Item.Discount).Be(0.05);
    Should(Item.ObterTotalComDesconto).Be(190.00);
  finally
    Item.Free;
  end;
end;

procedure TOrderDetailsTests.Deve_Aplicar_10_Porcento_De_Desconto_Para_Mais_De_50_Itens;
var
  Item: TOrderDetails;
begin
  Item := TOrderDetails.Create;
  try
    Item.UnitPrice := 10.00;
    Item.Quantity := 100;
    
    Item.CalcularDescontoProgressivo;
    
    Should(Item.Discount).Be(0.10);
    Should(Item.ObterTotalComDesconto).Be(900.00);
  finally
    Item.Free;
  end;
end;

{ TOrderViewModelTests }

procedure TOrderViewModelTests.Deve_Calcular_Frete_Usando_Serviço_Mockado;
var
  ExecutouCallback: Boolean;
  Order: TOrders;
  ShippingMock: Mock<IShippingService>;
  TimeoutCounter: Integer;
  ViewModel: TOrderViewModel;
begin
  ShippingMock := Mock<IShippingService>.Create;
  ShippingMock.Setup
    .Returns<Double>(42.5)
    .When
    .CalcularCotacaoFrete(Arg.Any<string>, Arg.Any<Double>);

  ViewModel := TOrderViewModel.Create(ShippingMock.Instance);
  Order := TOrders.Create;
  try
    Order.ShipCountry := 'Portugal';
    ViewModel.Load(Order);
    
    ExecutouCallback := False;
    
    // Dispara a cotação assíncrona calculada em background pela ViewModel
    ViewModel.CalcularFreteExterno(
      procedure
      begin
        ExecutouCallback := True;
      end);
      
    // Loop de espera simples no teste para simular o término da task de background (máximo 500ms)
    TimeoutCounter := 0;
    while (not ExecutouCallback) and (TimeoutCounter < 50) do
    begin
      CheckSynchronize(10); // Processa as chamadas de sincronia (TThread.Queue) e aguarda até 10ms
      Inc(TimeoutCounter);
    end;
    
    // Verificações com asserções fluentes do Dext
    Should(ViewModel.Errors.Count).Be(0);
    Should(ViewModel.CalculatedFreight).Be(42.5); // 5.0 * 8.5
    Should(Order.Freight.Value).Be(42.5); // O objeto de banco subjacente deve estar atualizado
  finally
    Order.Free;
    ViewModel.Free;
  end;
end;

procedure TOrderViewModelTests.Deve_Inicializar_Em_Estado_Limpo;
var
  ShippingMock: Mock<IShippingService>;
  ViewModel: TOrderViewModel;
begin
  ShippingMock := Mock<IShippingService>.Create;
  ViewModel := TOrderViewModel.Create(ShippingMock.Instance);
  try
    Should(ViewModel.IsCalculating).BeFalse;
    Should(ViewModel.CalculatedFreight).Be(0.0);
    Should(ViewModel.Errors.Count).Be(0);
  finally
    ViewModel.Free;
  end;
end;

{ TOrderSpecificationsTests }

procedure TOrderSpecificationsTests.Deve_Expressar_Filtro_Do_Brasil_Corretamente;
var
  Spec: ISpecification<TOrders>;
begin
  Spec := TBrazilOrdersSpec.Create;
  Should(Spec.GetExpression.ToString).Contain('ShipCountry');
  Should(Spec.GetExpression.ToString).Contain('Brazil');
end;

procedure TOrderSpecificationsTests.Deve_Expressar_Filtro_De_Frete_Alto_Corretamente;
var
  Spec: ISpecification<TOrders>;
begin
  Spec := TExpensiveFreightSpec.Create(50.00);
  Should(Spec.GetExpression.ToString).Contain('Freight');
  Should(Spec.GetExpression.ToString).Contain('50');
end;

procedure TOrderSpecificationsTests.Deve_Expressar_Filtro_Combinado_Corretamente;
var
  Spec: ISpecification<TOrders>;
begin
  Spec := TBrazilHeavyFreightSpec.Create(30.00);
  Should(Spec.GetExpression.ToString).Contain('ShipCountry');
  Should(Spec.GetExpression.ToString).Contain('Brazil');
  Should(Spec.GetExpression.ToString).Contain('Freight');
  Should(Spec.GetExpression.ToString).Contain('30');
end;

end.
