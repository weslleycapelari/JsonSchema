# Copilot Instructions

## Repository context

This repository contains a Delphi library for JSON Schema validation, with confirmed runtime support for Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.

## General rules

* Preserve existing behavior before expanding the scope of a change.
* Do not invent runtime support for drafts that appear only in test fixtures.
* If a change touches validation, translations, or reference resolution, inspect the owning file before editing.
* Make small, verifiable changes.
* Avoid broad refactors when the goal is a targeted fix.

## Recommended workflow

1. Locate the public entry point or the responsible visitor.
2. Confirm the affected draft.
3. Make the minimum code change.
4. Update or add a test.
5. Update public documentation when the contract changes.

## Translation and language

* The library maintains enUS and ptBR.
* When adding a new validation error, update both translations.
* Keep placeholders semantically aligned across languages.

## Validation

* Behavior changes require a test.
* Draft compatibility changes need coverage per draft.
* If the build environment is not confirmed, mark the gap as Needs Confirmation instead of assuming it works.

## Architecture

* The current architecture uses a walker, visitors, a registry, and separate translation.
* Do not merge these layers without strong justification.

## What this agent should report

* What is confirmed and what remains Needs Confirmation.
* The impact by draft or by subsystem.
* Actionable recommendations, not generic lists.
* The smallest test or reading needed to remove uncertainty.

## Quick checklist

* The affected draft is identified.
* The change does not break Draft 6, Draft 7, Draft 2019-09, or Draft 2020-12.
* Translations remain consistent.
* Relevant tests are updated.
* Public documentation still matches runtime behavior.
