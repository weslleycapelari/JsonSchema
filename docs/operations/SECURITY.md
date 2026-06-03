# Security

## Purpose

This document captures the main security considerations for the library.

## Relevant risks

The main security-sensitive areas are:

- remote schema fetching
- URI resolution
- reference recursion
- local file access through schema loading
- validation of untrusted JSON input

## Guidance

- Treat remote schemas as untrusted input until validated.
- Prefer controlled schema sources for production usage.
- Keep URI handling deterministic and test it with edge cases.
- Avoid assuming that a resolved reference is safe simply because it was found.
- Review any new network or file access carefully before adding it to the library.

## Operational note

The library is focused on validation, not on sandboxing. Callers should still validate the trust boundary around incoming schemas and remote resources.
