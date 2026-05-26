unit Dext.ActiveArchitecture.Services;

interface

uses
  System.SysUtils,
  Dext.Net.RestClient,
  Dext.Net.RestRequest,
  Dext.ActiveArchitecture.Domain;

type
  // DTOs de Infraestrutura para desserialização do JSON da API de câmbio
  TExchangeRates = record
    USD: Double;
    BRL: Double;
    EUR: Double;
    GBP: Double;
    ARS: Double;
    CAD: Double;
    DKK: Double;
    MXN: Double;
    NOK: Double;
    PLN: Double;
    SEK: Double;
    CHF: Double;
    VES: Double;
  end;

  TExchangeRateResponse = record
    provider: string;
    base: string;
    rates: TExchangeRates;
  end;

  TPaisMoeda = record
    Pais: string;
    Moeda: string;
  end;

  /// <summary>
  /// Implementação concreta do serviço de frete externo consumindo uma API REST.
  /// Reside na camada de Infraestrutura e utiliza o TRestClient do Dext.
  /// </summary>
  TShippingService = class(TInterfacedObject, IShippingService)
  private
    FClient: TRestClient;
    function ObterMoedaDoPais(const Country: string): string;
    function ObterTaxaBaseUSD(const Country: string): Double;
    function ObterTaxaFallback(const AMoeda: string): Double;
    function ObterTaxaCambio(const AMoeda: string; const ARates: TExchangeRates): Double;
  public
    constructor Create;
    destructor Destroy; override;
    
    function CalcularCotacaoFrete(const Country: string; TotalWeight: Double): Double;
  end;

implementation

uses
  Dext.Json;

const
  MoedaPaises: array[0..20] of TPaisMoeda = (
    (Pais: 'Brazil'; Moeda: 'BRL'),
    (Pais: 'Brasil'; Moeda: 'BRL'),
    (Pais: 'Portugal'; Moeda: 'EUR'),
    (Pais: 'Austria'; Moeda: 'EUR'),
    (Pais: 'Belgium'; Moeda: 'EUR'),
    (Pais: 'Finland'; Moeda: 'EUR'),
    (Pais: 'France'; Moeda: 'EUR'),
    (Pais: 'Germany'; Moeda: 'EUR'),
    (Pais: 'Italy'; Moeda: 'EUR'),
    (Pais: 'Spain'; Moeda: 'EUR'),
    (Pais: 'Argentina'; Moeda: 'ARS'),
    (Pais: 'Canada'; Moeda: 'CAD'),
    (Pais: 'Denmark'; Moeda: 'DKK'),
    (Pais: 'Mexico'; Moeda: 'MXN'),
    (Pais: 'Norway'; Moeda: 'NOK'),
    (Pais: 'Poland'; Moeda: 'PLN'),
    (Pais: 'Sweden'; Moeda: 'SEK'),
    (Pais: 'Switzerland'; Moeda: 'CHF'),
    (Pais: 'UK'; Moeda: 'GBP'),
    (Pais: 'USA'; Moeda: 'USD'),
    (Pais: 'Venezuela'; Moeda: 'VES')
  );

{ TShippingService }

constructor TShippingService.Create;
begin
  inherited;
  // Inicialização e configuração do timeout do cliente REST gerido por escopo
  FClient := TRestClient
    .Create('https://api.exchangerate-api.com/v4/latest/USD')
    .Timeout(3000);
end;

destructor TShippingService.Destroy;
begin
  inherited;
end;

function TShippingService.ObterMoedaDoPais(const Country: string): string;
var
  I: Integer;
begin
  Result := 'USD'; // Moeda padrão caso não encontre no mapa
  for I := Low(MoedaPaises) to High(MoedaPaises) do
  begin
    if SameText(MoedaPaises[I].Pais, Country) then
    begin
      Result := MoedaPaises[I].Moeda;
      Break;
    end;
  end;
end;

function TShippingService.ObterTaxaBaseUSD(const Country: string): Double;
begin
  // Custo logístico base estimado em USD de acordo com a distância
  if SameText(Country, 'USA') then
    Result := 5.0
  else if SameText(Country, 'Canada') or SameText(Country, 'Mexico') then
    Result := 8.0
  else if SameText(Country, 'Brazil') or SameText(Country, 'Argentina') or SameText(Country, 'Venezuela') then
    Result := 15.0
  else
    Result := 10.0; // Europa, Escandinávia e outros
end;

function TShippingService.ObterTaxaFallback(const AMoeda: string): Double;
begin
  // Valores de câmbio aproximados em caso de falha da API REST externa
  if SameText(AMoeda, 'BRL') then Result := 5.0
  else if SameText(AMoeda, 'EUR') then Result := 0.9
  else if SameText(AMoeda, 'ARS') then Result := 800.0
  else if SameText(AMoeda, 'CAD') then Result := 1.35
  else if SameText(AMoeda, 'DKK') then Result := 6.9
  else if SameText(AMoeda, 'MXN') then Result := 17.0
  else if SameText(AMoeda, 'NOK') then Result := 10.5
  else if SameText(AMoeda, 'PLN') then Result := 4.0
  else if SameText(AMoeda, 'SEK') then Result := 10.5
  else if SameText(AMoeda, 'CHF') then Result := 0.88
  else if SameText(AMoeda, 'GBP') then Result := 0.78
  else if SameText(AMoeda, 'VES') then Result := 36.0
  else Result := 1.0;
end;

function TShippingService.ObterTaxaCambio(const AMoeda: string; const ARates: TExchangeRates): Double;
begin
  if SameText(AMoeda, 'BRL') then Result := ARates.BRL
  else if SameText(AMoeda, 'EUR') then Result := ARates.EUR
  else if SameText(AMoeda, 'ARS') then Result := ARates.ARS
  else if SameText(AMoeda, 'CAD') then Result := ARates.CAD
  else if SameText(AMoeda, 'DKK') then Result := ARates.DKK
  else if SameText(AMoeda, 'MXN') then Result := ARates.MXN
  else if SameText(AMoeda, 'NOK') then Result := ARates.NOK
  else if SameText(AMoeda, 'PLN') then Result := ARates.PLN
  else if SameText(AMoeda, 'SEK') then Result := ARates.SEK
  else if SameText(AMoeda, 'CHF') then Result := ARates.CHF
  else if SameText(AMoeda, 'GBP') then Result := ARates.GBP
  else if SameText(AMoeda, 'VES') then Result := ARates.VES
  else Result := ARates.USD;
end;

function TShippingService.CalcularCotacaoFrete(const Country: string; TotalWeight: Double): Double;
var
  ResponseText: string;
  BaseRateUSD: Double;
  ExchangeRate: Double;
  Moeda: string;
  RatesResponse: TExchangeRateResponse;
begin
  BaseRateUSD := ObterTaxaBaseUSD(Country);
  Moeda := ObterMoedaDoPais(Country);
  ExchangeRate := ObterTaxaFallback(Moeda);

  try
    // Demonstração real de requisição síncrona/fluente e resiliente no Dext.Net
    ResponseText := FClient.Get.Await.ContentString;

    if not ResponseText.IsEmpty then
    begin
      // Desserialização elegante e fluida usando o próprio parser JSON do Dext
      RatesResponse := TDextJson.Deserialize<TExchangeRateResponse>(ResponseText);
      ExchangeRate := ObterTaxaCambio(Moeda, RatesResponse.rates);
    end;
  except
    // Fallback: mantém as cotações estimadas em memória
  end;

  Result := TotalWeight * BaseRateUSD * ExchangeRate;
end;

end.
