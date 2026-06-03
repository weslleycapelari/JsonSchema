# Vocabulary System

## Purpose

This document explains how keyword families are organized in the current implementation and how that organization may evolve.

## Current vocabulary grouping

The code currently groups keywords by domain:

- `Keywords/Core`
- `Keywords/Validations`
- `Keywords/Logicals`
- `Keywords/Format`
- `Keywords/Metadata`

This grouping is practical for the codebase and keeps related behavior close together.

## Current behavior

Keywords are registered per draft parser through the registry.

That means the effective vocabulary of a draft is defined by what the parser registers.

## Extension boundary

The registry and keyword factory design provide the main extension boundary for future vocabularies and custom keywords.

## Future direction

The product vision includes more explicit vocabulary separation, such as:

- core vocabulary
- applicator vocabulary
- validation vocabulary
- format vocabulary
- metadata vocabulary
- content vocabulary
- custom vocabularies

That separation is not yet fully modeled in the runtime as a first-class type system.

## Rule

Document vocabulary-level changes explicitly when a keyword moves across categories or when a new vocabulary becomes visible in runtime behavior.
