# Visitor Pattern

## Purpose

This document records the current decision to avoid a visitor-based runtime until there is a clear need.

## Current state

The runtime validates by compiling schemas into keyword validator objects and calling `Validate` directly.

There is no active visitor layer in the current implementation.

## Why the visitor pattern is deferred

A visitor layer is useful only when the runtime needs a stronger separation for concerns such as:

- annotation collection
- output formatting
- optimization passes
- alternative evaluation modes

Those needs are not required for the current core validation pipeline.

## Consequences

- Current code stays simpler.
- Keyword behavior remains directly testable.
- Future visitor adoption remains possible if the feature set grows.

## Rule

Do not introduce a visitor layer unless it solves an actual problem that the current compiled-schema execution model cannot solve cleanly.
