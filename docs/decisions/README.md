# Architecture Decisions

This folder contains Architecture Decision Records (ADRs) extracted from the current implementation in src and aligned against IDEA.md.

Status legend:

- Accepted: implemented and observable in code.
- Proposed: documented direction based on current constraints and roadmap.

## ADR Index

- ADR-0001 - Plugin registry for keywords (Accepted)
- ADR-0002 - Independent draft parsers without inheritance chains (Accepted)
- ADR-0003 - Compile-before-validate pipeline (Accepted)
- ADR-0004 - Unified keyword factory signature with parent schema and compile delegate (Accepted)
- ADR-0005 - Stateless keyword validators with constructor-time schema parsing (Accepted)
- ADR-0006 - Core/Validation/Logical keyword modularization (Accepted)
- ADR-0007 - Boolean schema support (true/false) (Accepted)
- ADR-0008 - Localization dispatcher engine per locale (Accepted)
- ADR-0009 - Validation error context as JSON object metadata (Accepted)
- ADR-0010 - Validation result consolidation model (Accepted)
- ADR-0011 - Schema registry with URI pre-scan and remote resolution (Accepted)
- ADR-0012 - JSON pointer based $ref resolution with recursion guard (Accepted)
- ADR-0013 - Global compilation context for root schema and base URI (Accepted)
- ADR-0014 - JSON helper type guards for Delphi JSON inheritance quirks (Accepted)
- ADR-0015 - Validator facade as public API entry point (Accepted)
- ADR-0016 - Per-draft parser registration structure (Accepted)
- ADR-0017 - Dependencies keyword dual-mode interpretation (Accepted)
- ADR-0018 - Deferred visitor pattern adoption (Accepted)
- ADR-0019 - RFC-compliant URI and JSON Pointer subsystem (Accepted)
- ADR-0020 - Draft-aware format modularization (Accepted)

## Scope notes

- These ADRs document implemented decisions first, not aspirational plans.
- IDEA.md long-term goals not yet implemented are treated as roadmap, not Accepted decisions.
