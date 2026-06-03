# Architecture Overview

This project is a Delphi JSON Schema validation library built around a small public facade, draft-specific parsers, a compiled-schema execution model, and a keyword registry.

The current implementation is keyword-driven, not visitor-driven. Schemas are compiled into a list of keyword validators and then executed directly against JSON instances.

## Canonical Architecture Document

The detailed, up-to-date architecture documentation has been moved to:

👉 **[docs/architecture/ARCHITECTURE.md](architecture/ARCHITECTURE.md)**

Please refer to that document for details on:

- The validation pipeline and facade design.
- The per-draft compilation structure and keyword mapping.
- The localization dispatch engine.
- The reference resolution registry and the URI/JSON Pointer subsystem.
- Pluggable format registries and draft compliance rules.
