# SchemaValidatorCLI - Design Decisions

This document summarizes key architectural and technical decisions made during the development of `SchemaValidatorCLI`.

---

## 1. Modularization vs. Monolithic `.dpr`

* **Context**: Console applications in Delphi are often implemented inside a single `.dpr` project file.
* **Decision**: We modularized the CLI codebase into separate units (`Config`, `Utils`, `Formatters`, `Runner`) inside a `src/` directory.
* **Rationale**:
  * Adheres to the Single Responsibility Principle (SRP).
  * Keeps the codebase highly maintainable.
  * Allows unit tests to import and test parts of the CLI logic (like the parser and draft detector) without running the entire program.

---

## 2. Testable Argument Parser (`ParseArgumentsEx`)

* **Context**: Delphi's standard parameter functions (`ParamCount` and `ParamStr`) are global read-only variables initialized by the OS, making them difficult to mock during tests.
* **Decision**: We refactored `ParseArguments` to delegate to `ParseArgumentsEx(const pArgs: TArray<string>)`.
* **Rationale**:
  * Enables writing direct unit tests that pass arbitrary arrays of string arguments.
  * Keeps the main `ParseArguments` function clean (it simply constructs the array from OS parameters).

---

## 3. Path Resolution Limitations in `IValidationError`

* **Context**: The `schema_validator_cli_plan.md` originally requested printing `InstancePath` and `SchemaPath` inside formatted error reports. However, the core library's `IValidationError` interface does not yet expose these path properties.
* **Decision**: We removed references to `InstancePath` and `SchemaPath` from the formatted outputs to avoid compiler errors. We output the localized message, keyword, and resolution, and use empty strings `""` as JSON placeholders.
* **Rationale**:
  * Ensures compatibility and compile success with the current state of the core validation engine.
  * Prevents breaking changes on the core interfaces while keeping formatting templates extensible for future path support.

---

## 4. Win32 `CreateProcess` for Integration Testing

* **Context**: Integration tests must ensure that the compiled executable runs as expected, returns correct exit codes, and prints output in different formats.
* **Decision**: We implemented a custom Win32 pipe wrapper using `CreateProcess` in `TestSchemaValidatorCLI.pas`.
* **Rationale**:
  * Simulates actual terminal executions.
  * Captures program outputs (`stdout` and `stderr`) and the process exit code (`0`, `1`, `2`) safely.
  * Runs inside the DUnit framework so that any regression in the executable's behavior is caught immediately during the test suite run.
