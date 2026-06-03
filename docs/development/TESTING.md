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

## Compliance & Coverage Status

The project is **100% compliant** with the official **JSON Schema Test Suite** for:

- Draft 6
- Draft 7
- Draft 2019-09
- Draft 2020-12

A total of **6,184 test cases** are automatically loaded, compiled, and executed, ensuring full compliance and preventing regressions during development.

## Running Tests

Tests can be executed using the DUnit console runner (`test/console/TestJsonSchemaConsole.exe` or by compiling `test/console/TestJsonSchemaConsole.dpr`) or via the GUI runner (`test/gui/TestJsonSchema.dpr`).
