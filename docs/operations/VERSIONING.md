# Versioning

## Purpose

This document describes the versioning policy for JsonSchema Delphi.

## Versioning model

The project should use semantic versioning principles:

- major version for incompatible API or contract changes
- minor version for backward-compatible feature additions
- patch version for backward-compatible fixes

## Compatibility rules

A version bump should consider:

- public API changes
- draft compatibility
- validation behavior changes
- localization message changes
- reference resolution changes

## Documentation rule

When a version changes, the changelog and any user-facing documentation that depends on the public contract should be updated together.
