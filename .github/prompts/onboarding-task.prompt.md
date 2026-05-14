---
name: onboarding-task
description: Use when you need to scope a JsonSchema change, identify the affected draft, and confirm the correct entry point before any edit.
---
# Onboarding Task

Purpose

Establish the smallest safe scope for a JsonSchema change before implementation starts.

Repository facts to keep in view

- JsonSchema is a Delphi library for JSON Schema validation.
- Runtime support is confirmed for Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.
- Draft 3, Draft 4, and draft-next appear only in historical test fixtures unless a source file explicitly says otherwise.
- Validation messages are maintained in enUS and ptBR.
- Validation flows through walkers, visitors, and a resource registry.

What to do

- Identify the public entry point, owning visitor, or nearest test that controls the behavior.
- State whether the work is runtime behavior, translation text, URI or reference handling, documentation, or fixture-only data.
- Identify the affected draft or drafts.
- Call out the smallest nearby file or test that should anchor the change.
- Separate confirmed facts from assumptions.

Confirmation gate

- If the scope, affected draft, or runtime support is ambiguous, stop and ask for confirmation before proposing edits.

Output

- A short scope statement.
- Confirmed facts.
- Needs Confirmation, if any.
- The likely owning code path.
- The best first test or check.

Do not

- Do not draft a patch.
- Do not widen into unrelated cleanup.
- Do not treat fixture-only drafts as runtime features.
