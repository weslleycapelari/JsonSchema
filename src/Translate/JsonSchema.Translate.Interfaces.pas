unit JsonSchema.Translate.Interfaces;

interface

uses
  JsonSchema.Translate.Types;

type
  /// <summary>
  ///   Contract for translation providers that supply localized validation error messages.
  ///   Each language implements this interface by returning a TErrorMessage record
  ///   containing both the error text and a hint for correction.
  /// </summary>
  ITranslate = interface(IInterface)
    ['{A1C3E5F7-2B4D-4E6F-8A0C-1D3E5F7A9B2C}']
    /// <summary>Returns the localized error message and hint for the given error type.</summary>
    function GetMessage(const pErrorType: TErrorType): TErrorMessage;
  end;

implementation

end.
