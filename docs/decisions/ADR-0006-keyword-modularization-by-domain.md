# ADR-0006: Keyword Modularization by Domain

Status: Accepted
Date: 2026-06-02

## Context

The project needs maintainable organization as keyword count grows.

## Decision

Organize keywords into domain folders:

- Keywords/Core
- Keywords/Validations
- Keywords/Logicals

## Consequences

- Positive: clearer ownership and discovery.
- Positive: simpler mental model for contributors.
- Trade-off: vocabulary tagging from newer drafts is still implicit.

## Evidence

- src/Keywords/Core
- src/Keywords/Validations
- src/Keywords/Logicals

## IDEA alignment

Partially aligned. Modularization exists, but full vocabulary-based grouping (core/applicator/metadata/content/format) is still future work.
