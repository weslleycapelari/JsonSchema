---
name: hardening-regression
description: Use when a JsonSchema regression needs a narrow reproduction, a failing test, and a minimal fix.
---
# Hardening Regression

Purpose

Lock down a specific JsonSchema regression with a narrow test and the smallest safe fix.

Repository facts to keep in view

- JsonSchema is a Delphi library for JSON Schema validation.
- Runtime support is confirmed for Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.
- Draft 3, Draft 4, and draft-next appear only in historical test fixtures unless a source file explicitly says otherwise.
- Validation messages are maintained in enUS and ptBR.
- Validation flows through walkers, visitors, and a resource registry.

Workflow

- Reproduce the problem in the narrowest case you can.
- Identify the exact draft, code path, or translation branch that fails.
- Add or adjust the smallest test that demonstrates the regression before the fix when practical.
- Make the minimal code change that makes that test pass.
- Validate the fix with the targeted test first, then the nearest relevant checks.

Precision rules

- Keep runtime behavior, fixture-only data, and translation wording separate.
- If the change touches validation text, update enUS and ptBR together.
- If the change is draft-specific, keep the regression test draft-specific too.
- Do not expand the task into cleanup or refactoring.
- Do not lock in a broad behavioral change when a narrow fix will do.

Confirmation gate

- If the draft, runtime support, or fixture-only status is ambiguous, stop and confirm before writing the regression test or fix.

Output format

- Reproduction case.
- Root cause.
- Test added or adjusted.
- Minimal fix.
- Verification results.
- Open questions, if any.
