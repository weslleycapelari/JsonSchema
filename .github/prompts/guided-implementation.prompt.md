---
name: guided-implementation
description: Use when the scope is confirmed and you need to make a small JsonSchema change with tests and validation.
---
# Guided Implementation

Purpose

Implement a confirmed JsonSchema change with the smallest correct edit and a focused validation pass.

Repository facts to keep in view

- JsonSchema is a Delphi library for JSON Schema validation.
- Runtime support is confirmed for Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.
- Draft 3, Draft 4, and draft-next appear only in historical test fixtures unless a source file explicitly says otherwise.
- Validation messages are maintained in enUS and ptBR.
- Validation flows through walkers, visitors, and a resource registry.

Execution rules

- Start from the owning abstraction, not the broadest surface.
- Change the code that directly decides the behavior.
- Keep the edit small and consistent with existing Delphi style.
- Update or add the smallest relevant test for the touched behavior.
- Update enUS and ptBR together when user-facing error text changes.
- Update public documentation only when the contract changes.
- Keep runtime behavior, fixture-only test data, and translation text separate.

Confirmation gate

- If the affected draft, runtime support, or fixture-only status is unclear, stop and confirm before editing.

Validation

- Run the narrowest test or compile check that can falsify the change.
- Prefer a failing test before the fix when practical.
- Validate the touched slice before expanding scope.
- Report what passed, what remains Needs Confirmation, and any draft impact.

Do not

- Do not merge in unrelated cleanup.
- Do not refactor the surrounding architecture unless the fix requires it.
- Do not promise support for unimplemented drafts.
