# Contributing

Thanks for contributing to JsonSchema.

## Before opening an issue

- Check whether the problem or idea has already been reported.
- Include a minimal reproducible example.
- State the affected draft.
- State whether the change affects runtime behavior or fixture-only test data.
- Mention any URI or reference lookup impact.
- Mention any translation impact in enUS and ptBR when relevant.
- Include the schema and input JSON when they matter for reproduction.

## Recommended flow

1. Open an issue for a bug or a feature.
2. Describe the current behavior and the expected behavior.
3. Make the change in a small, focused branch.
4. Update or add tests.
5. Open a pull request with a clear summary of the impact.

## Minimum PR criteria

- The new or corrected behavior is covered by a test.
- The change is consistent with the current architecture.
- There is no obvious regression in the supported drafts.
- Public documentation is updated when the contract changes.
- The PR does not mix unrelated fixes.
- The affected draft is identified explicitly.
- Runtime behavior and fixture-only changes are not conflated.
- Translation updates are included when error text changes.
- URI or reference impact is called out when applicable.

## Repo-specific review points

- Which draft is affected?
- Is this runtime behavior or fixture-only data?
- Does this touch enUS, ptBR, or both?
- Does this affect URI parsing, base URI handling, reference lookup, anchors, or dynamic anchors?

## AI contributions

- Use AI for drafting, triage, and organization, not as a substitute for human review.
- Do not send code without local validation.
- Do not invent APIs, drafts, or behaviors that are not confirmed in the repository.
- Review names, contracts, and messages before opening the PR.
- If there is uncertainty, mark the affected part as Needs Confirmation.

## Style and compatibility

- Preserve the existing Delphi style.
- Avoid broad renaming unless it is necessary.
- Do not add external dependencies without a clear justification.

## Testing

- Update or add tests when a change touches validation, translation, URI resolution, or draft compatibility.
- Prefer the smallest test that fails before the fix and passes after it.

## Communication

- Keep PR comments objective.
- Explain why the change exists, not only what changed.
