unit Dext.ActiveArchitecture.ViewModels;

interface

uses
  System.SysUtils,
  System.Classes,
  Dext.Threading.Async,
  Dext.ActiveArchitecture.Entities,
  Dext.ActiveArchitecture.Domain;

type
  /// <summary>
  /// ViewModel que orquestra a lógica de tela e estado da UI para Pedidos (MVVM).
  /// Recebe a injeção do serviço IShippingService, promovendo desacoplamento e testabilidade.
  /// No Clean Architecture + RAD com TEntityDataSet, a ViewModel não duplica os campos da entidade.
  /// Os campos persistentes são vinculados diretamente do TEntityDataSet para os controles visuais,
  /// mantendo a produtividade do RAD, enquanto a ViewModel gerencia o estado da UI e Use Cases.
  /// </summary>
  TOrderViewModel = class
  private
    FCalculatedFreight: Double;
    FDirty: Boolean;
    FErrors: TStrings;
    FIsCalculating: Boolean;
    FOrder: TOrders; // Domínio rico injetado
    FShippingService: IShippingService; // Serviço injetado (Use Case)

    function GetTotalWeight: Double;
  public
    constructor Create(AShippingService: IShippingService);
    destructor Destroy; override;
    
    procedure Load(AOrder: TOrders);
    procedure Clear;
    procedure CalcularFreteExterno(OnCompleteProc: TProc);
    
    // Opcional: expõe o objeto de domínio ativo se a View precisar de alguma validação direta
    property Order: TOrders read FOrder;
    
    // Propriedades exclusivamente de controle de estado e UI (não persistentes no banco)
    // Sem duplicar OrderId, CustomerId ou Freight!
    property IsCalculating: Boolean read FIsCalculating;
    property CalculatedFreight: Double read FCalculatedFreight;
    property TotalWeight: Double read GetTotalWeight;
    property Errors: TStrings read FErrors;
  end;

implementation

uses
  Dext.Logging,
  Dext.Logging.Global,
  Dext.Logging.Tracing,
  Dext.Telemetry.Context,
  Dext.Types.UUID;

{ TOrderViewModel }

constructor TOrderViewModel.Create(AShippingService: IShippingService);
begin
  inherited Create;
  FShippingService := AShippingService;
  FErrors := TStringList.Create;
  Clear;
end;

destructor TOrderViewModel.Destroy;
begin
  FErrors.Free;
  inherited;
end;

procedure TOrderViewModel.Clear;
begin
  FOrder := nil;
  FIsCalculating := False;
  FCalculatedFreight := 0.0;
  FErrors.Clear;
  FDirty := False;
end;

procedure TOrderViewModel.Load(AOrder: TOrders);
begin
  FOrder := AOrder;
  FIsCalculating := False;
  FCalculatedFreight := 0.0;
  FErrors.Clear;
  FDirty := False;
end;

procedure TOrderViewModel.CalcularFreteExterno(OnCompleteProc: TProc);
var
  Country: string;
  OrderId: Integer;
  Weight: Double;
  Span: TSpan;
  ParentTraceId: string;
  ParentSpanId: string;
begin
  if not Assigned(FOrder) then
  begin
    FErrors.Add('Nenhum pedido foi selecionado');
    Log.Warn('Tentativa de calcular frete sem nenhum pedido selecionado.');
    Exit;
  end;

  FIsCalculating := True;
  FErrors.Clear;
  OrderId := FOrder.OrderId.Value;
  Country := FOrder.ShipCountry.Value;
  Weight := GetTotalWeight;

  Log.Info('Iniciando cálculo assíncrono de frete para o Pedido #{OrderId} (Destino: {Country}, Peso: {Weight}kg)...', [OrderId, Country, FormatFloat('0.00', Weight)]);

  Span := TTracer.BeginSpan('ViewModel.CalcularFreteExterno', 'UseCase');
  Span.SetAttribute('order.id', OrderId);
  Span.SetAttribute('order.ship_country', Country);
  Span.SetAttribute('order.weight', FloatToStr(Weight));

  ParentTraceId := Span.TraceId;
  ParentSpanId := Span.SpanId;

  // Executa o consumo da API externa em uma thread de background usando TAsyncTask.Run do Dext Core.
  // Evita congelamento de tela em ERPs (Zero UI Blocking).
  TAsyncTask.Run<Double>(
    function: Double
    var
      SubSpan: TSpan;
      Node: PScopeNode;
    begin
      Node := TraceContext.Push('AsyncTaskScope', TUUID.FromString(ParentTraceId), TUUID.FromString(ParentSpanId));
      try
        SubSpan := TTracer.BeginSpan('ShippingService.CalcularCotacaoFrete', 'ExternalService');
        SubSpan.SetAttribute('shipping.country', Country);
        SubSpan.SetAttribute('shipping.weight', FloatToStr(Weight));
        try
          Result := FShippingService.CalcularCotacaoFrete(Country, Weight);
          SubSpan.SetAttribute('shipping.result', FloatToStr(Result));
        except
          on E: Exception do
          begin
            SubSpan.SetStatus('Error', E.Message);
            raise;
          end;
        end;
      finally
        SubSpan.Finish;
        TraceContext.Pop(Node);
      end;
    end)
    .OnComplete(
      procedure(Res: Double)
      begin
        FCalculatedFreight := Res;
        FOrder.Freight := Res; // Atualiza o frete diretamente no domínio rico
        FIsCalculating := False;
        
        Log.Info('Cálculo de frete finalizado para o Pedido #{OrderId}. Valor calculado: {Freight}', [OrderId, FormatFloat('R$ #,##0.00', Res)]);
        
        Span.SetAttribute('freight.value', FloatToStr(Res));
        Span.SetStatus('Success');
        Span.Finish;
        
        if Assigned(OnCompleteProc) then
          OnCompleteProc();
      end)
    .OnException(
      procedure(E: Exception)
      begin
        FErrors.Add('Erro ao obter cotação: ' + E.Message);
        FIsCalculating := False;
        
        Log.Error('Erro ao calcular frete para o Pedido #{OrderId}: {Error}', [OrderId, E.Message]);
        
        Span.SetStatus('Error', E.Message);
        Span.Finish;
        
        if Assigned(OnCompleteProc) then
          OnCompleteProc();
      end)
    .Start;
end;

function TOrderViewModel.GetTotalWeight: Double;
begin
  if Assigned(FOrder) then
  begin
    // Peso dinâmico e coerente baseado no ID do Pedido para tornar a demonstração viva
    Result := 5.0 + (FOrder.OrderId.Value mod 10) * 3.5;
  end
  else
    Result := 12.5;
end;

end.
