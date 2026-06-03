# Dialect System

## Purpose

This document explains how the library models JSON Schema drafts as dialect-specific parsers.

## Current design

The runtime supports these drafts:

- Draft 6
- Draft 7
- Draft 2019-09
- Draft 2020-12

Each draft is represented by its own parser class under `src/Drafts`.

The parsers are independent. They do not form an inheritance chain.

## Why this matters

Keeping drafts separate makes it easier to:

- preserve draft-specific semantics
- register different keyword sets when needed
- document differences explicitly
- evolve one draft without accidentally changing another

## Draft selection

The public validator routes validation through the parser for the requested draft.

The overload without an explicit draft uses Draft 6.

## What a new dialect needs

When a future draft is added, it should bring:

- a parser class
- keyword registrations for the supported vocabulary
- test coverage for the new behavior
- documentation of any semantic divergence from older drafts

## Rule

Treat each draft as an explicit contract, not as a subclass of another draft.
