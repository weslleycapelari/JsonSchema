# Changelog

This file records relevant project changes.

## [Unreleased]

### Highlights

- Governance baseline documentation for the README, contributing guide, templates, and agent guidance.
- Quality continuity docs for the pull request checklist and weekly audit routine.

### Changed

- None.

### Fixed

- None.

## [1.0.0]

Initial public stable release of the project.

### Added

- Delphi library for JSON Schema validation.
- Runtime support confirmed for Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.
- Full compliance for JSON Schema Draft 6 achieved (1151/1151 tests passed).
- Full compliance for JSON Schema Draft 7 achieved (1467/1467 tests passed).
- enUS and ptBR translations.
- Architecture based on walkers, visitors, and a registry for schema processing.
- DUnit test project.
- Schema2Delphi helper tool in `tools/`.

### Notes

- Release date: 2026-05-14.
- Numeric robustness improvements for `multipleOf`, including underflow and overflow-safe behavior.
- IDN-Hostname validation improvements with minimum RFC 5890 checks.
- Targeted Cross-Draft reference handling for draft-specific remote scenarios.

[Unreleased]: ./CHANGELOG.md
[1.0.0]: ./CHANGELOG.md
