# SchemaValidatorCLI - Product Vision

`SchemaValidatorCLI` is a lightweight, pipeline-friendly command-line wrapper built around the core Delphi `JsonSchema.Validator` library. It bridges the gap between our high-performance Delphi validation engine and automation pipelines, shell scripts, and third-party systems.

## Core Goals

1. **Automation & CI/CD Integration**: Provide a native binary that can be easily executed in GitHub Actions, GitLab CI, Azure Pipelines, or local build scripts to assert JSON document conformity.
2. **Standardized Communication**: Use standard OS exit codes (0 for valid, 1 for invalid, 2 for errors) and standardized structured stdout formats (JSON, JUnit XML) so that build agents and script processors can consume validation errors programmatically.
3. **Draft Compliance & Auto-Detection**: Fully leverage the core validator's compliance across JSON Schema Drafts 6, 7, 2019-09, and 2020-12, while providing automatic version detection from the schema `$schema` URI.
4. **Zero Configuration Deployment**: Compile as a single, self-contained native executable with no external runtimes, DLLs, or dependencies required, facilitating instant copy-paste deployment.
5. **Localization Integration**: Connect directly to the localization engine to produce diagnostic errors in the user's preferred language (e.g. English, Portuguese) straight to the console.
