# Schema2Delphi Documentation Index

This directory collects the documentation for the `Schema2Delphi` tool, a utility designed to convert JSON Schema files into compliant Delphi class and record structures.

## Recommended Reading Order

1. **[Product Vision](product/IDEA.md)**: Conceptual vision, key features (nullables, enums, keyword resolution, leak-proof memory management) and scope of the tool.
2. **[Architecture](architecture/ARCHITECTURE.md)**: Structural overview of the compiled-schema traversal pipeline, Delphi Code AST, and modular concern delegation.
3. **[Architectural Decisions](decisions/README.md)**: History of design decisions and ADRs (Architectural Decision Records) guiding the codebase.
4. **[Development Setup](development/SETUP.md)**: Step-by-step guide to configure the workspace and build the graphical form and batch generator.
5. **[Testing Guide](development/TESTING.md)**: Execution details for the DUnit console and GUI test suites.
6. **[Public API](api/PUBLIC-API.md)**: Public interfaces, utility entry points (`GenerateClassFromSchema`), and customization configurations.

## Notes

- All generated Delphi DTO files target compatibility with modern Delphi compilers (such as Athens 36.0) using native `System.JSON` attributes.
- Generated code complies with the project's memory management rules, using clean `try..finally` structures and explicit nested object loops.
