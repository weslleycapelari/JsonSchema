# Product Idea

## Purpose

JsonSchema Delphi is a standards-oriented JSON Schema validation library and tooling ecosystem written in Delphi.

The project aims to provide a reusable, extensible, strongly typed foundation for validating JSON documents against JSON Schema drafts, while keeping the core maintainable over time.

## Vision

The project is intended to support:

- multiple JSON Schema drafts
- an extensible keyword system
- strong typing in the Delphi implementation
- reusable compiled schemas
- localized validation messages
- minimal runtime dependencies
- a clean public API
- production-grade maintainability

## Confirmed runtime support

The current codebase confirms runtime support for:

- Draft 6
- Draft 7
- Draft 2019-09
- Draft 2020-12

Historical fixtures for Draft 3, Draft 4, and draft-next exist in the repository, but they are not confirmed runtime support.

## Current product direction

The current implementation focuses on:

- schema compilation before validation
- keyword-level validators
- draft-specific parser classes
- a central schema registry
- localized enUS and ptBR error text
- reference resolution through schema URIs and JSON Pointer navigation

## Initial scope history

The early MVP validated the architecture around Draft 6 string keywords and result reporting before the keyword set expanded.

That MVP history matters because it explains the current architecture:

- compile first, validate later
- isolate each keyword in its own unit
- keep the public API simple
- add functionality incrementally

## Long-term goals

Future phases may include:

- broader keyword coverage
- more explicit vocabulary grouping
- full test suite compliance for each supported draft
- richer annotation and output capabilities
- custom vocabulary support
- HyperSchema and other advanced specification extensions

## Non goals

The project should not drift into unrelated product areas such as:

- OpenAPI support as a primary target
- IDE tooling
- GUI applications
- code generation as a core requirement

Those can be treated as separate future packages or tools.
