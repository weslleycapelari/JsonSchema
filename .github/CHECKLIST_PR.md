# Pull Request Checklist

Use this checklist before requesting review.

## Scope

- [ ] The affected draft is explicit.
- [ ] Runtime behavior is separated from fixture-only data.
- [ ] Translation impact is identified when relevant.
- [ ] URI or reference impact is identified when relevant.
- [ ] The change stays within the intended subsystem.

## Verification

- [ ] A relevant test was added or updated.
- [ ] The narrowest useful validation was run.
- [ ] The change was checked against Draft 6.
- [ ] The change was checked against Draft 7.
- [ ] The change was checked against Draft 2019-09.
- [ ] The change was checked against Draft 2020-12.

## Review readiness

- [ ] The code and the documentation agree.
- [ ] enUS and ptBR stay semantically aligned when text changed.
- [ ] No fixture-only draft was described as runtime support.
- [ ] Any remaining uncertainty is marked Needs Confirmation.
- [ ] The PR summary explains the user impact.

## Final check

- [ ] I can explain the change in one sentence.
- [ ] I know what would break if this change regressed.
- [ ] The diff is limited to the intended scope.
