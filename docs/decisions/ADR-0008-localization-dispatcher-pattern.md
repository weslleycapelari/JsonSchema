# ADR-0008: Localization Dispatcher Pattern

Status: Accepted
Date: 2026-06-02

## Context

Validation errors require locale-specific messages and resolutions for many keywords.

## Decision

Use TLocalizationBase as a dispatcher with a dictionary from keyword name to translation method, and resolve active locale through TLocalizationEngine.

## Consequences

- Positive: adding a language is predictable and centralized.
- Positive: avoids long if/else translation chains.
- Trade-off: every new keyword requires translation implementation in each locale.

## Evidence

- src/Localization/JsonSchema.Localization.Base.pas
- src/Localization/JsonSchema.Localization.pas
- src/Localization/JsonSchema.Localization.EnUS.pas
- src/Localization/JsonSchema.Localization.PtBR.pas

## IDEA alignment

Aligned with extensibility and production-grade API expectations.
