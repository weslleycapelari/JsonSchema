unit JsonSchema.Localization.Enums;

(*
--------------------------------------------------------------------------------
Defines supported locales as a strongly-typed enum.
--------------------------------------------------------------------------------
*)

interface

type
  {$SCOPEDENUMS ON}
  /// <summary>Supported locales for the validation localization engine.</summary>
  TLocale = (
    EnUS,
    PtBR
  );
  {$SCOPEDENUMS OFF}

implementation

end.
