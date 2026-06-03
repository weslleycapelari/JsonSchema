# Copilot Instructions

## Repository context

This repository contains a Delphi JSON Schema validation library.
Confirmed runtime support is Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.

## Source-of-truth and scope

* Preserve existing behavior before expanding scope.
* Do not infer runtime draft support from fixtures or plans alone.
* Treat implementation plans as guidance, not proof of completed runtime behavior.
* Prefer small, verifiable, low-risk changes over broad refactors.
* If the goal is targeted, avoid opportunistic architecture rewrites.

## Core workflow

1. Locate the public entry point (validator, parser, visitor, registry, localization).
 If the relevant entry point unit does not exist, stop and report the missing unit as a blocker before proposing any code changes.
2. Confirm affected draft(s) and subsystem(s).
3. Read owning units before editing (validation, localization, registry, references).
4. Apply the minimum coherent change.
5. Update or add tests for behavior changes.
6. Update docs only when external behavior or contract changed.

## Coding standards (Delphi)

Formatting:

* Use 2-space indentation and never tabs.
* Keep lines to a maximum of 150 columns.
* Use one space after commas and around assignment operators.
* Do not vertically align parameters/assignments with extra spaces.
* `begin` must be on its own line (except allowed `case` indentation cases).
* Use `end else` and `end else if` formatting (same line as `end`).

Language usage and naming:

* Reserved words must stay lowercase (`function`, `string`, `array`, etc.).
* Primitive type names must keep canonical casing (`Integer`, `Double`, etc.).
* Prefer `case` when a long `if` chain is equivalent.
* Avoid `with`, `Break`, and `Continue`.
* `Exit` is allowed for guard clauses only.
* Avoid magic strings and duplicated business rules.
* Keep naming consistent with codebase standards (fields with `F`, locals with `l`).

## Error handling and resource safety

* Use explicit `try..finally` for owned resources.
* Do not release multiple independently-created resources in a single `finally` block.
* Use `try..except` only when there is a real recovery/action path.
* Do not silently swallow exceptions.
* Prefer ownership-safe patterns for JSON/context objects (avoid double free risks).

## Documentation standards

* All code comments and XML docs must be in English.
* Each unit should include a responsibility header block after `unit` and before `interface`.
* XML doc tags should be single-line when the entire line (including indentation) does not exceed 150 columns.
* Use multiline XML tags with 2-space inner indentation when needed.
* Do not use `{$REGION}` inside `interface` sections.
* `{$REGION}` is allowed in `implementation` only.

## Architecture boundaries

* Keep separation between walker/visitors, keyword registry, compiled schema, and localization.
* Do not collapse translation into validators or parser orchestration layers.
* Prefer declarative keyword registration in parsers.
* Keep keyword parsing/instantiation logic close to each keyword unit.

## Keyword and registry evolution guidance

When touching keyword registration or new keywords:

* Confirm the active factory signatures in the current code before changing API shape.
* Prefer static `CreateKeyword` factories per keyword class.
* If sub-schema compilation is needed, use compile delegates instead of parser-coupled logic.
* If sibling keyword introspection is needed, pass parent schema context explicitly.
* When a keyword has divergent semantics across supported drafts, implement per-draft branches and explicitly mark each branch with the applicable draft version in a comment.
* Flag draft semantic conflicts in the report as a multi-draft divergence.
* Keep parser constructors readable; split registration by category when it improves clarity.

Target keyword sets discussed in project plans include:

* Numeric: `multipleOf`, `exclusiveMaximum`, `exclusiveMinimum`
* String: `pattern`
* Array: `items`, `additionalItems`, `uniqueItems`, `contains`
* Object: `maxProperties`, `minProperties`, `properties`, `patternProperties`, `additionalProperties`, `dependencies`, `propertyNames`
* Logical: `allOf`, `anyOf`, `oneOf`, `not`

Implement incrementally and validate draft impact.

## Localization

* Keep enUS and ptBR in sync.
* Every new validation keyword/error requires both locales.
* Keep placeholder semantics aligned across languages.
* If a ptBR translation cannot be verified, emit the English string as a placeholder and mark the entry with a TODO comment and a Needs Confirmation flag in the report.
* Prefer dispatcher-style localization extension over long monolithic conditional chains.

## Testing and verification

* Any behavior change requires tests.
* Draft-compatibility changes require coverage by affected draft(s).
* For keyword additions, include direct unit tests and runner/integration coverage where applicable.
* If environment/build execution is unavailable, report as Needs Confirmation.
* Never claim full compatibility or test pass status without execution evidence.

## Review posture

When reviewing:

* Prioritize bugs, regressions, safety risks, and missing tests.
* Highlight affected file and concrete impact.
* Keep recommendations actionable and minimal.
* Separate confirmed findings from assumptions.

## Reporting expectations

Always report:

* What is confirmed vs Needs Confirmation.
* Impact by draft and/or subsystem.
* Exact smallest follow-up to remove remaining uncertainty.

## Quick checklist

* Affected draft(s) identified.
* Behavior preserved outside requested scope.
* Translations updated in enUS and ptBR (if errors changed).
* Tests updated/added for changed behavior.
* Documentation updated when contract changed.
* Any unverified claim explicitly marked Needs Confirmation.
