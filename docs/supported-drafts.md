# Supported Drafts

## Runtime support matrix

| Draft | Runtime support | Notes |
| --- | --- | --- |
| Draft 6 | Yes (100%) | Confirmed in the source and selected by the public entry point. |
| Draft 7 | Yes | Confirmed in the source and selected by the public entry point. |
| Draft 2019-09 | Yes | Confirmed in the source and selected by the public entry point. |
| Draft 2020-12 | Yes | Confirmed in the source and selected by the public entry point. |

## Historical fixtures only

| Draft | Where it appears | Status |
| --- | --- | --- |
| Draft 3 | test fixtures | Historical fixture only, not confirmed runtime support |
| Draft 4 | test fixtures | Historical fixture only, not confirmed runtime support |
| draft-next | test fixtures | Historical fixture only, not confirmed runtime support |

## Selection rules

- An explicit draft parameter wins.
- If there is no explicit draft and the schema does not declare `$schema`, validation falls back to Draft 2020-12.
- If the schema declares `$schema`, that value drives selection.

## Editorial rule

- Do not describe fixture-only drafts as runtime features.
