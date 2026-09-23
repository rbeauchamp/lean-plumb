# Build-lint dependency capture cost

## Scope

This change replaces only the dependency dirty decision: one unrestricted `git status`
per dependency root and the pure `Snapshot.dirtyOf` decision, in place of a
pathspec-limited status over every declared input. Dependency bytes are still read and
UTF-8-decoded, and the terminal recheck still recaptures them. See
[policy acceptance](../../docs/guides/policy-acceptance.md) for why they are retained.
This partial reduction is the intended deliverable.

## Local receipts

Host: Apple M4 Pro. Load averages are 1-minute values.

| Command | Head | Result | Wall |
| --- | --- | --- | --- |
| `./scripts/verify.sh diagnostics build-policy` | `7085071` (before issue 7) | PASS | 184.41 s |
| `./scripts/verify.sh diagnostics build-policy` | `96ed742` (after issue 7) | killed at deadline, 26 of 27 controls | 420.01 s |
| `./scripts/verify.sh diagnostics build-policy` | `c860a45` (this change) | PASS; partition 271 s; load 10.8 at start, 8.0 at end | 275.4 s |
| `./scripts/verify.sh diagnostics environments` | `c860a45` (this change) | killed at deadline in `clean-checkout/fresh-checker` | 420.05 s |

- `c860a45` (`c860a4508f8f1610c9216c949e96b23702a76fd5`) is this change on parent
  `b0f1ccb`. The branch commit `c5bcd69` is the same change on base `54d83ae`; the two
  differ only in `session/evidence/issue-7-verification.md` and
  `session/session-context.md`, which came from the base. No Lean input differs.
- In the `environments` run, the external-adopter phase took 103.1 s, down from 173.9 s.
  The timeout is the `clean-checkout/fresh-checker` phase: a cold build plus a fresh
  audit of every claimed root. Dependency capture is not the cause; see
  [contributing](../../docs/guides/contributing.md). That partition remains INCOMPLETE.
- The `build-policy` log is kept outside the repository, at Firstmate
  `data/strict-lean-buildlint-capture-cost/build-policy.log`.

These are observed completions on one host, not runtime bounds. They do not cover the
later documentation and usage-string edits, which change no checker behavior.
