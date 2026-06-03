# Documentation Guide

## Purpose

This repository uses documentation as part of the design surface, not as an afterthought.

## Documentation hierarchy

The recommended documentation set is:

- `README.md` for project entry and quick start
- `docs/architecture.md` and `docs/architecture/ARCHITECTURE.md` for architecture overview
- `docs/decisions/` for ADRs
- `docs/product/` for product vision and domain language
- `docs/development/` for setup, style, and testing
- `docs/api/` for public and extension APIs
- `docs/operations/` for release and security guidance

## Writing rules

- Write project-facing documentation in English.
- Distinguish confirmed runtime behavior from roadmap items.
- Do not document fixture-only support as runtime support.
- Keep the current implementation and the intended direction separate when they differ.

## When to add documentation

Add or update documentation when a change affects:

- public contracts
- validation behavior
- supported drafts
- localization text
- reference resolution
- extension points
- release or testing procedures

## Decision records

Use ADRs for important technical decisions that affect long-term maintenance.

Good ADR candidates include:

- parser structure
- registry design
- URI resolution strategy
- localization architecture
- validation result design
- schema compilation behavior

## Maintenance rule

Documentation should evolve with the codebase. If code and docs diverge, the document should be corrected or explicitly marked as historical or roadmap content.
