# Release

## Purpose

This document describes the release process for the library.

## Release checklist

Before a release, confirm that:

- supported draft behavior is still intact
- keyword changes are covered by tests
- translation changes are present in enUS and ptBR when needed
- public documentation matches the runtime behavior
- unresolved issues are marked clearly

## Recommended sequence

1. Review the changelog.
2. Run the relevant test projects.
3. Verify any draft-specific regressions.
4. Confirm documentation updates.
5. Tag the release version.

## Release discipline

A release should not include unverified support claims.

If a behavior was only observed in fixtures or plans, it should remain documented as roadmap material until confirmed by code and tests.
