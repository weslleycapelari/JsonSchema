# ADR-0002: Modular Concern Separation

## Status

Approved

## Context

Initially, the AST-based code generator (`TJsonSchemaCodeGenerator`) concentrated all duties (schema parsing, keyword lookup, string casing, keyword sanitization, attribute compilation, and code output generation) in a single, high-density file (`Schema2Delphi.Visitor.pas`). This violated the Single Responsibility Principle (SRP) and made testing individual components difficult.

## Decision

We decided to modularize the codebase by extracting distinct tasks into dedicated units:

- **`Schema2Delphi.Sanitizer`**: Pure utility functions handling keyword checking and PascalCase conversions.
- **`Schema2Delphi.AttributeProcessor`**: Responsible for matching JSON Schema validation properties to Delphi custom attributes.
- **`Schema2Delphi.TypeMapper`**: Encapsulates all type-lookup, `$ref` resolving, and enum generation logic.
- **`Schema2Delphi.Common`**: Defines shared types and the `IGenerationContext` interface to prevent circular dependencies.

## Consequences

- **Pros**:
  - Code files are kept short, highly focused, and easy to maintain.
  - Better alignment with SOLID principles.
  - Changes to attribute formats or keyword naming rules are isolated to their respective modules.
- **Cons**:
  - Marginally increases the number of files in the project repository.
