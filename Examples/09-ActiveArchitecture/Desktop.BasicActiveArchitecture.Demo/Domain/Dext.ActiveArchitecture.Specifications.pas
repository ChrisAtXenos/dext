unit Dext.ActiveArchitecture.Specifications;

interface

uses
  Dext.Entity.Prototype,
  Dext.Specifications.Base,
  Dext.Specifications.Types,
  Dext.ActiveArchitecture.Entities;

type
  TOrdersSpec = class(TSpecification<TOrders>)
  private
    FOrder: TOrders;
  public
    constructor Create; reintroduce;
    property Order: TOrders read FOrder;
  end;

  // 1. Especificação: Pedidos do Brasil
  TBrazilOrdersSpec = class(TOrdersSpec)
  public
    constructor Create; reintroduce;
  end;

  // 2. Especificação: Pedidos com Frete Alto (> MinFreight)
  TExpensiveFreightSpec = class(TOrdersSpec)
  public
    constructor Create(MinFreight: Double); reintroduce;
  end;

  // 3. Especificação Combinada: Pedidos do Brasil com Frete Alto (> MinFreight)
  TBrazilHeavyFreightSpec = class(TOrdersSpec)
  public
    constructor Create(MinFreight: Double); reintroduce;
  end;

implementation

constructor TOrdersSpec.Create;
begin
  inherited;
  FOrder := Prototype.Entity<TOrders>;
end;

{ TBrazilOrdersSpec }

constructor TBrazilOrdersSpec.Create;
begin
  inherited Create;
  Where(Order.ShipCountry = 'Brazil');
end;

{ TExpensiveFreightSpec }

constructor TExpensiveFreightSpec.Create(MinFreight: Double);
begin
  inherited Create;
  Where(Order.Freight > MinFreight);
end;

{ TBrazilHeavyFreightSpec }

constructor TBrazilHeavyFreightSpec.Create(MinFreight: Double);
begin
  inherited Create;
  Where((Order.ShipCountry = 'Brazil') and (Order.Freight > MinFreight));
end;

end.
