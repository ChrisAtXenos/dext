unit Dext.ActiveArchitecture.Domain;

interface

type
  {$M+}
  /// <summary>
  /// Contrato do serviço de cotação de frete externo (Clean Architecture).
  /// Esta interface reside na camada Core/Domain e é independente de rede ou HTTP.
  /// </summary>
  IShippingService = interface
    ['{A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D}']
    
    /// <summary>
    /// Calcula a cotação de frete internacional com base no país destino e peso total dos produtos.
    /// </summary>
    function CalcularCotacaoFrete(const Country: string; TotalWeight: Double): Double;
  end;

implementation

end.
