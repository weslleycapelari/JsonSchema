unit JsonSchema.Registry.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Enumera��o que representa os componentes de uma URI.</summary>
  /// <remarks>Utilizado principalmente pela classe TValidator para especificar regras de valida��o de forma segura.</remarks>
  TURIComponent = (uricScheme, uricUserInfo, uricHost, uricPort, uricAuthority, uricPath, uricQuery, uricFragment);

  /// <summary>Conjunto de TURIComponent para manipula��o de m�ltiplos componentes.</summary>
  TURIComponents = set of TURIComponent;

  /// <summary>Classe base para todas as exce��es geradas pela biblioteca RFC3986.</summary>
  ERFC3986Exception = class(Exception);

  /// <summary>Exce��o lan�ada quando o componente 'authority' de uma URI � inv�lido.</summary>
  /// <remarks>
  ///   Ocorre quando a string da autoridade (ex: 'user@host:port') n�o pode
  ///   ser corretamente dividida em suas subpartes. Refer�ncia RFC 3986: Se��o 3.2.
  /// </remarks>
  EInvalidAuthority = class(ERFC3986Exception);

  /// <summary>Exce��o lan�ada durante o processo de valida��o da URI.</summary>
  /// <remarks>� a classe base para erros mais espec�ficos encontrados pela classe TValidator.</remarks>
  EValidationError = class(ERFC3986Exception);

  /// <summary>Exce��o lan�ada quando um componente requerido pela valida��o est� ausente.</summary>
  /// <remarks>Por exemplo, se TValidator for configurado para exigir um 'scheme' e a URI n�o o possuir.</remarks>
  EMissingComponentError = class(EValidationError);

  /// <summary>Exce��o lan�ada quando a resolu��o de uma URI relativa falha.</summary>
  /// <remarks>
  ///   Tipicamente ocorre quando a URI base fornecida n�o � uma URI absoluta,
  ///   impossibilitando a resolu��o. Refer�ncia RFC 3986: Se��o 5.2.
  /// </remarks>
  EResolutionError = class(ERFC3986Exception);

const
  // Regex derivado do Ap�ndice B da RFC 3986 para parsear os 5 componentes da URI.
  URI_PATTERN = '^(?:(?<scheme>[A-Za-z][A-Za-z0-9+\-.]*):)?(?:\/\/(?<authority>[^\/?#\\]*))?(?<path>[^?#\\]*)(?:\?(?<query>[^#\\]*))?(?:#(?<fragment>[^\\]*))?$';

implementation

end.
