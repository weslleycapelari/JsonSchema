---
name: independent-review
description: Use when reviewing a JsonSchema change and you need a findings-first assessment.
---
# Independent Review

Purpose

Find defects, regressions, and unsupported claims in a JsonSchema change.

Repository facts to keep in view

- JsonSchema is a Delphi library for JSON Schema validation.
- Runtime support is confirmed for Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.
- Draft 3, Draft 4, and draft-next appear only in historical test fixtures unless a source file explicitly says otherwise.
- Validation messages are maintained in enUS and ptBR.
- Validation flows through walkers, visitors, and a resource registry.

Review rules

- Review the change against the owning code path and the nearest tests.
- Focus on bugs, behavioral regressions, missing tests, and incorrect draft or translation claims.
- Separate confirmed runtime support from historical fixtures.
- Treat claims about Draft 3, Draft 4, or draft-next as unsupported unless the code explicitly confirms otherwise.
- If a claim depends on ambiguous scope or draft support, mark it Needs Confirmation instead of inferring.

Output format

- Lead with findings.
- Sort findings by severity: High, Medium, Low.
- For each finding, include the file or area, the issue, the user impact, and the recommended fix.
- If there are no findings, say so explicitly and mention the main residual risk or test gap.
- Keep the summary brief and secondary.

Review posture

- Be concrete.
- Prefer evidence over speculation.
- Do not spend space on praise or restating the change.
