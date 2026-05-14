# Weekly Audit Routine

Use this routine once per week to keep the JsonSchema repository aligned with the current governance baseline.

## Goal

Catch drift early in documentation, draft support claims, translation parity, test coverage, and contributor workflow.

## Inputs

- Recent pull requests.
- Open issues.
- Failing or flaky tests.
- Any new or changed validation messages.
- Any change touching URI, reference resolution, or draft selection.

## Routine

1. Review the last week's changes.
2. Check whether any docs now overstate runtime support.
3. Confirm Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12 still match the public claims.
4. Check whether Draft 3, Draft 4, or draft-next were introduced as runtime features by mistake.
5. Compare enUS and ptBR for any new or changed validation text.
6. Confirm the nearest tests still reflect the intended behavior.
7. Note any items that now need follow-up or human confirmation.

## Output

- Confirmed facts.
- Drift or regression risks.
- Needed fixes.
- Items marked Needs Confirmation.
- Follow-up work for the next week.

## Escalate when

- A doc claims support that the source does not confirm.
- A translation changed in one language only.
- A draft-specific behavior changed without a corresponding test.
- A URI or reference rule changed without clear coverage.
- A release note, changelog entry, or PR template disagrees with the code.
