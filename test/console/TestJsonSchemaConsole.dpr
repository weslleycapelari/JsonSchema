program TestJsonSchemaConsole;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  TestFramework,
  TextTestRunner,
  // Source Core
  JsonSchema.Core.Constants in '..\..\src\Core\JsonSchema.Core.Constants.pas',
  JsonSchema.Core.Interfaces in '..\..\src\Core\JsonSchema.Core.Interfaces.pas',
  JsonSchema.Results in '..\..\src\Core\JsonSchema.Results.pas',
  JsonSchema.CompiledSchema in '..\..\src\Core\JsonSchema.CompiledSchema.pas',
  JsonSchema.Registry in '..\..\src\Core\JsonSchema.Registry.pas',
  JsonSchema.JSONHelper in '..\..\src\Core\JsonSchema.JSONHelper.pas',
  JsonSchema.Core.SchemaRegistry in '..\..\src\Core\JsonSchema.Core.SchemaRegistry.pas',
  // Source Core URI
  JsonSchema.Core.URI.Types in '..\..\src\Core\URI\JsonSchema.Core.URI.Types.pas',
  JsonSchema.Core.URI.Reference in '..\..\src\Core\URI\JsonSchema.Core.URI.Reference.pas',
  JsonSchema.Core.URI.Utils in '..\..\src\Core\URI\JsonSchema.Core.URI.Utils.pas',
  JsonSchema.Core.URI.ParseResult in '..\..\src\Core\URI\JsonSchema.Core.URI.ParseResult.pas',
  JsonSchema.Core.URI.Builder in '..\..\src\Core\URI\JsonSchema.Core.URI.Builder.pas',
  JsonSchema.Core.URI.Validator in '..\..\src\Core\URI\JsonSchema.Core.URI.Validator.pas',
  // Source Localization
  JsonSchema.Localization.Enums in '..\..\src\Localization\JsonSchema.Localization.Enums.pas',
  JsonSchema.Localization.Interfaces in '..\..\src\Localization\JsonSchema.Localization.Interfaces.pas',
  JsonSchema.Localization.Base in '..\..\src\Localization\JsonSchema.Localization.Base.pas',
  JsonSchema.Localization.EnUS in '..\..\src\Localization\JsonSchema.Localization.EnUS.pas',
  JsonSchema.Localization.PtBR in '..\..\src\Localization\JsonSchema.Localization.PtBR.pas',
  JsonSchema.Localization in '..\..\src\Localization\JsonSchema.Localization.pas',
  // Source Keywords
  JsonSchema.Keywords.TypeKeyword in '..\..\src\Keywords\Validations\JsonSchema.Keywords.TypeKeyword.pas',
  JsonSchema.Keywords.MinLength in '..\..\src\Keywords\Validations\JsonSchema.Keywords.MinLength.pas',
  JsonSchema.Keywords.Enum in '..\..\src\Keywords\Validations\JsonSchema.Keywords.Enum.pas',
  JsonSchema.Keywords.ConstKeyword in '..\..\src\Keywords\Validations\JsonSchema.Keywords.ConstKeyword.pas',
  JsonSchema.Keywords.Required in '..\..\src\Keywords\Validations\JsonSchema.Keywords.Required.pas',
  JsonSchema.Keywords.Minimum in '..\..\src\Keywords\Validations\JsonSchema.Keywords.Minimum.pas',
  JsonSchema.Keywords.Maximum in '..\..\src\Keywords\Validations\JsonSchema.Keywords.Maximum.pas',
  JsonSchema.Keywords.MaxLength in '..\..\src\Keywords\Validations\JsonSchema.Keywords.MaxLength.pas',
  JsonSchema.Keywords.MinItems in '..\..\src\Keywords\Validations\JsonSchema.Keywords.MinItems.pas',
  JsonSchema.Keywords.MaxItems in '..\..\src\Keywords\Validations\JsonSchema.Keywords.MaxItems.pas',
  JsonSchema.Keywords.MultipleOf in '..\..\src\Keywords\Validations\JsonSchema.Keywords.MultipleOf.pas',
  JsonSchema.Keywords.ExclusiveMaximum in '..\..\src\Keywords\Validations\JsonSchema.Keywords.ExclusiveMaximum.pas',
  JsonSchema.Keywords.ExclusiveMinimum in '..\..\src\Keywords\Validations\JsonSchema.Keywords.ExclusiveMinimum.pas',
  JsonSchema.Keywords.Pattern in '..\..\src\Keywords\Validations\JsonSchema.Keywords.Pattern.pas',
  JsonSchema.Keywords.UniqueItems in '..\..\src\Keywords\Validations\JsonSchema.Keywords.UniqueItems.pas',
  JsonSchema.Keywords.Contains in '..\..\src\Keywords\Validations\JsonSchema.Keywords.Contains.pas',
  JsonSchema.Keywords.MaxProperties in '..\..\src\Keywords\Validations\JsonSchema.Keywords.MaxProperties.pas',
  JsonSchema.Keywords.MinProperties in '..\..\src\Keywords\Validations\JsonSchema.Keywords.MinProperties.pas',
  JsonSchema.Keywords.PropertyNames in '..\..\src\Keywords\Validations\JsonSchema.Keywords.PropertyNames.pas',
  JsonSchema.Keywords.Properties in '..\..\src\Keywords\Validations\JsonSchema.Keywords.Properties.pas',
  JsonSchema.Keywords.PatternProperties in '..\..\src\Keywords\Validations\JsonSchema.Keywords.PatternProperties.pas',
  JsonSchema.Keywords.Items in '..\..\src\Keywords\Validations\JsonSchema.Keywords.Items.pas',
  JsonSchema.Keywords.AdditionalItems in '..\..\src\Keywords\Validations\JsonSchema.Keywords.AdditionalItems.pas',
  JsonSchema.Keywords.AdditionalProperties in '..\..\src\Keywords\Validations\JsonSchema.Keywords.AdditionalProperties.pas',
  JsonSchema.Keywords.Dependencies in '..\..\src\Keywords\Validations\JsonSchema.Keywords.Dependencies.pas',
  JsonSchema.Core.ValidationContext in '..\..\src\Core\JsonSchema.Core.ValidationContext.pas',
  JsonSchema.Keywords.DependentRequired in '..\..\src\Keywords\Validations\JsonSchema.Keywords.DependentRequired.pas',
  JsonSchema.Keywords.DependentSchemas in '..\..\src\Keywords\Validations\JsonSchema.Keywords.DependentSchemas.pas',
  JsonSchema.Keywords.UnevaluatedProperties in '..\..\src\Keywords\Validations\JsonSchema.Keywords.UnevaluatedProperties.pas',
  JsonSchema.Keywords.UnevaluatedItems in '..\..\src\Keywords\Validations\JsonSchema.Keywords.UnevaluatedItems.pas',
  JsonSchema.Keywords.RecursiveRef in '..\..\src\Keywords\Core\JsonSchema.Keywords.RecursiveRef.pas',
  JsonSchema.Keywords.Vocabulary in '..\..\src\Keywords\Core\JsonSchema.Keywords.Vocabulary.pas',
  JsonSchema.Keywords.Deprecated in '..\..\src\Keywords\Metadata\JsonSchema.Keywords.Deprecated.pas',
  JsonSchema.Keywords.ReadOnlyWriteOnly in '..\..\src\Keywords\Metadata\JsonSchema.Keywords.ReadOnlyWriteOnly.pas',
  JsonSchema.Keywords.AllOf in '..\..\src\Keywords\Logicals\JsonSchema.Keywords.AllOf.pas',
  JsonSchema.Keywords.AnyOf in '..\..\src\Keywords\Logicals\JsonSchema.Keywords.AnyOf.pas',
  JsonSchema.Keywords.OneOf in '..\..\src\Keywords\Logicals\JsonSchema.Keywords.OneOf.pas',
  JsonSchema.Keywords.NotKeyword in '..\..\src\Keywords\Logicals\JsonSchema.Keywords.NotKeyword.pas',
  JsonSchema.Keywords.Schema in '..\..\src\Keywords\Core\JsonSchema.Keywords.Schema.pas',
  JsonSchema.Keywords.Id in '..\..\src\Keywords\Core\JsonSchema.Keywords.Id.pas',
  JsonSchema.Keywords.Ref in '..\..\src\Keywords\Core\JsonSchema.Keywords.Ref.pas',
  JsonSchema.Keywords.Title in '..\..\src\Keywords\Metadata\JsonSchema.Keywords.Title.pas',
  JsonSchema.Keywords.Description in '..\..\src\Keywords\Metadata\JsonSchema.Keywords.Description.pas',
  JsonSchema.Keywords.Default in '..\..\src\Keywords\Metadata\JsonSchema.Keywords.Default.pas',
  JsonSchema.Keywords.Examples in '..\..\src\Keywords\Metadata\JsonSchema.Keywords.Examples.pas',
  JsonSchema.Keywords.IfThenElse in '..\..\src\Keywords\Logicals\JsonSchema.Keywords.IfThenElse.pas',
  JsonSchema.Keywords.Comment in '..\..\src\Keywords\Metadata\JsonSchema.Keywords.Comment.pas',
  JsonSchema.Keywords.Format in '..\..\src\Keywords\Format\JsonSchema.Keywords.Format.pas',
  JsonSchema.Keywords.Format.Constants in '..\..\src\Keywords\Format\JsonSchema.Keywords.Format.Constants.pas',
  JsonSchema.Keywords.Format.IPv6 in '..\..\src\Keywords\Format\JsonSchema.Keywords.Format.IPv6.pas',
  JsonSchema.Keywords.Format.DateTime in '..\..\src\Keywords\Format\JsonSchema.Keywords.Format.DateTime.pas',
  JsonSchema.Keywords.Format.Iri in '..\..\src\Keywords\Format\JsonSchema.Keywords.Format.Iri.pas',
  JsonSchema.Keywords.Format.UriTemplate in '..\..\src\Keywords\Format\JsonSchema.Keywords.Format.UriTemplate.pas',
  // Source Draft Parsers
  JsonSchema.Draft6.Parser in '..\..\src\Drafts\JsonSchema.Draft6.Parser.pas',
  JsonSchema.Draft7.Parser in '..\..\src\Drafts\JsonSchema.Draft7.Parser.pas',
  JsonSchema.Draft2019_09.Parser in '..\..\src\Drafts\JsonSchema.Draft2019_09.Parser.pas',
  JsonSchema.Draft2020_12.Parser in '..\..\src\Drafts\JsonSchema.Draft2020_12.Parser.pas',
  // Source Public Facade
  JsonSchema.Validator in '..\..\src\JsonSchema.Validator.pas',
  // Test units
  TestJsonSchema.Keywords.Logical in '..\src\Keywords\Validations\TestJsonSchema.Keywords.Logical.pas',
  TestJsonSchema.Keywords.Core in '..\src\Keywords\Validations\TestJsonSchema.Keywords.Core.pas',
  TestJsonSchema.Keywords.TypeKeyword in '..\src\Keywords\Validations\TestJsonSchema.Keywords.TypeKeyword.pas',
  TestJsonSchema.Keywords.MinLength in '..\src\Keywords\Validations\TestJsonSchema.Keywords.MinLength.pas',
  TestJsonSchema.Keywords.ConstKeyword in '..\src\Keywords\Validations\TestJsonSchema.Keywords.ConstKeyword.pas',
  TestJsonSchema.Keywords.Enum in '..\src\Keywords\Validations\TestJsonSchema.Keywords.Enum.pas',
  TestJsonSchema.Keywords.Required in '..\src\Keywords\Validations\TestJsonSchema.Keywords.Required.pas',
  TestJsonSchema.Keywords.Numeric in '..\src\Keywords\Validations\TestJsonSchema.Keywords.Numeric.pas',
  TestJsonSchema.Keywords.MaxLength in '..\src\Keywords\Validations\TestJsonSchema.Keywords.MaxLength.pas',
  TestJsonSchema.Keywords.ItemsCount in '..\src\Keywords\Validations\TestJsonSchema.Keywords.ItemsCount.pas',
  TestJsonSchema.Keywords.SizesAndSubschemas in '..\src\Keywords\Validations\TestJsonSchema.Keywords.SizesAndSubschemas.pas',
  TestJsonSchema.Keywords.Structural in '..\src\Keywords\Validations\TestJsonSchema.Keywords.Structural.pas',
  TestJsonSchema.Keywords.PatternAndUnique in '..\src\Keywords\Validations\TestJsonSchema.Keywords.PatternAndUnique.pas',
  TestJsonSchema.Validator in '..\src\TestJsonSchema.Validator.pas',
  TestJsonSchema.Translations in '..\src\TestJsonSchema.Translations.pas',
  TestJsonSchema.JSONHelper in '..\src\TestJsonSchema.JSONHelper.pas',
  TestJsonSchema.Utils.DraftResolver in '..\src\TestJsonSchema.Utils.DraftResolver.pas',
  TestJsonSchema.Utils.Paths in '..\src\TestJsonSchema.Utils.Paths.pas',
  TestJsonSchema.Runner.DUnit in '..\src\TestJsonSchema.Runner.DUnit.pas';

begin
  try
    WriteLn('Running JSON Schema Console Tests...');
    WriteLn;
    with TextTestRunner.RunRegisteredTests do
      Free;
  except
    on E: Exception do
    begin
      WriteLn(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.