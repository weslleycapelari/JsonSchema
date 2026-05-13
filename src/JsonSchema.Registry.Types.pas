unit JsonSchema.Registry.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Enumeração que representa os componentes de uma URI.</summary>
  /// <remarks>Utilizado principalmente pela classe TValidator para especificar regras de validação de forma segura.</remarks>
  TURIComponent = (uricScheme, uricUserInfo, uricHost, uricPort, uricAuthority, uricPath, uricQuery, uricFragment);

  /// <summary>Conjunto de TURIComponent para manipulação de múltiplos componentes.</summary>
  TURIComponents = set of TURIComponent;

  /// <summary>Classe base para todas as exceções geradas pela biblioteca RFC3986.</summary>
  ERFC3986Exception = class(Exception);

  /// <summary>Exceção lançada quando o componente 'authority' de uma URI é inválido.</summary>
  /// <remarks>
  ///   Ocorre quando a string da autoridade (ex: 'user@host:port') não pode
  ///   ser corretamente dividida em suas subpartes. Referência RFC 3986: Seção 3.2.
  /// </remarks>
  EInvalidAuthority = class(ERFC3986Exception);

  /// <summary>Exceção lançada durante o processo de validação da URI.</summary>
  /// <remarks>É a classe base para erros mais específicos encontrados pela classe TValidator.</remarks>
  EValidationError = class(ERFC3986Exception);

  /// <summary>Exceção lançada quando um componente requerido pela validação está ausente.</summary>
  /// <remarks>Por exemplo, se TValidator for configurado para exigir um 'scheme' e a URI não o possuir.</remarks>
  EMissingComponentError = class(EValidationError);

  /// <summary>Exceção lançada quando a resolução de uma URI relativa falha.</summary>
  /// <remarks>
  ///   Tipicamente ocorre quando a URI base fornecida não é uma URI absoluta,
  ///   impossibilitando a resolução. Referência RFC 3986: Seção 5.2.
  /// </remarks>
  EResolutionError = class(ERFC3986Exception);

const
  // Regex derivado do Apêndice B da RFC 3986 para parsear os 5 componentes da URI.
  URI_PATTERN = '^(?:(?<scheme>[^:\/?#]+):)?(?:\/\/(?<authority>[^\/?#]*))?(?<path>[^?#]*)(?:\?(?<query>[^#]*))?(?:#(?<fragment>.*))?';

implementation

end.
