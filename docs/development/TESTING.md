# Testing

## Purpose

This document describes how tests are organized and how they should be used to validate changes in JsonSchema Delphi.

## Test entry points

The repository currently exposes two primary test applications:

- `test/gui/TestJsonSchema.dpr`
- `test/console/TestJsonSchemaConsole.dpr`

These projects reference the library units, the keyword tests, and the supporting utilities used by the test suite.

## Test organization

Tests are grouped by concern, including:

- core types and helpers
- validator behavior
- translation behavior
- keyword-specific validations
- draft-specific behavior
- registry and URI resolution

## What should be tested

Any change that affects the runtime should be covered by tests, especially when it touches:

- keyword validation
- draft-specific behavior
- localization
- schema registry behavior
- `$ref` or URI resolution
- compiled-schema execution

## Recommended test types

- Positive tests for valid instances
- Negative tests for invalid instances
- Edge-case tests for boundaries and null-like values
- Draft-specific tests when semantics differ across drafts
- Regression tests for bugs discovered in the codebase

## Practical rule

Prefer the smallest test that fails before the fix and passes after the fix.

## Coverage expectations

- Every keyword should have dedicated tests.
- Every draft should have compliance coverage.
- Historical fixtures should not be mistaken for runtime support.

## Working with results

When a validation test fails, check:

- the reported keyword
- the localized message
- the technical context attached to the error
- the draft used by the parser or validator

## Notes

The official JSON Schema Test Suite is a valuable future target, but repository-local regression coverage remains the immediate source of truth for current implementation behavior.
