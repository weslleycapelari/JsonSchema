---
name: sprint-close
description: Use when a JsonSchema task is complete and you need a short, useful handoff.
---
# Sprint Close

Purpose

Close out the task with a concise handoff that another contributor can act on quickly.

Repository facts to keep in view

- JsonSchema is a Delphi library for JSON Schema validation.
- Runtime support is confirmed for Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.
- Draft 3, Draft 4, and draft-next appear only in historical test fixtures unless a source file explicitly says otherwise.
- Validation messages are maintained in enUS and ptBR.
- Validation flows through walkers, visitors, and a resource registry.

Report

- What changed.
- What was verified.
- Which draft or subsystem was affected.
- Any remaining Needs Confirmation items.
- The next sensible follow-up, if one exists.

Style

- Keep it brief.
- Prefer plain facts over narrative.
- Call out whether the change is runtime behavior, translation text, documentation, or fixture-only data.
- Mention tests only when they help the handoff.

Confirmation gate

- If the affected draft or support claim is still uncertain, label it explicitly instead of smoothing it over.
