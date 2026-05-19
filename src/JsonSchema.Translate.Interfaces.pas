unit JsonSchema.Translate.Interfaces;

interface

uses
  JsonSchema.Translate.Types;

type
  /// <summary>
  /// Contract for translation providers that supply validation error messages.
  /// Each language implements this interface by returning localized Error and Hint strings.
  /// </summary>
  ITranslate = interface(IInterface)
    ['{A1C3E5F7-2B4D-4E6F-8A0C-1D3E5F7A9B2C}']
    /// <summary>Returns the localized error message for the given error type.</summary>
    /// <param name="pErrorType">The validation error type to translate.</param>
    function GetMessage(const pErrorType: TErrorType): TErrorMessage;
  end;

implementation

end.
