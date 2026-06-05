# Schema2Delphi Architectural Decision Records (ADRs)

This folder records the architectural decisions made during the design and development of the `Schema2Delphi` code generator tool.

## Decisions Index

- **[ADR-0001: Compiled-Schema AST Code Generator](ADR-0001-compiled-schema-ast-code-generator.md)**: Transitioning from manual JSON tree walking to traversing compiled schema ASTs.
- **[ADR-0002: Modular Concern Separation](ADR-0002-modular-concern-separation.md)**: Separating type mapping, name sanitization, attribute mapping, and generation context into independent, testable modules following SOLID and SRP.
- **[ADR-0003: Pure Interface-Based Reference Counting](ADR-0003-pure-interface-based-reference-counting.md)**: Exposing the generator engine as an interface to prevent reference-counting memory corruption.
- **[ADR-0004: Reverse Topological Order for Records](ADR-0004-reverse-topological-order-for-records.md)**: Generating records in reverse topological dependency order to ensure compilation without forward declarations.
