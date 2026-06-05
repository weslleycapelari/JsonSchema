# SchemaMockGen - Design Decisions

This document summarizes key architectural and technical decisions made during the development of `SchemaMockGen`.

---

## 1. Shared AST Generator Backend

* **Context**: We need to compile both a pipeline-friendly command-line tool (CLI) and an interactive VCL desktop tool (GUI).
* **Decision**: We created a shared code generation engine unit `SchemaMockGen.Generator.pas` and utility unit `SchemaMockGen.Utils.pas` in the `src/` directory.
* **Rationale**:
  * Promotes code reuse (DRY principle).
  * Ensures that mock generation behavior, constraints parsing, and LCG randomness remain identical between CLI runs and GUI clicks.
  * Simplifies testing, as we can test the generator engine once, and both CLI and GUI inherit the bug fixes.

---

## 2. Seeded Randomness LCG Algorithm

* **Context**: Delphi's built-in `Random` depends on global variable state `RandSeed` and is not guaranteed to generate identical sequences across different compiler platforms or when concurrent threads manipulate the state.
* **Decision**: We implemented `TSeededRandom`, a custom Linear Congruential Generator (LCG) class with Knuth's parameters.
* **Rationale**:
  * Totally thread-safe and isolated from other units.
  * Assures cross-platform repeatability (a seed of `12345` will always yield the exact same JSON dataset).

---

## 3. Resolving Delphi Record Helper Property Quirks

* **Context**: Calling record helper methods like `.IsEmpty` directly on string properties (e.g. `mmoOutput.Text.IsEmpty` or `edtSchemaPath.Text.IsEmpty`) causes the compiler to throw the error `E2018 Record, object or class type required` in several Delphi versions.
* **Decision**: We substituted `.IsEmpty` with traditional string comparisons (`= ''`) in the GUI form code.
* **Rationale**:
  * Fixes compiler errors.
  * Maintains broad compatibility across older and newer compiler editions without compiler directives.
