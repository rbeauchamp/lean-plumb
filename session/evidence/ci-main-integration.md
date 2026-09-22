# CI main integration: stopped at first substantive validation failure

## Identities and custody

- Assigned CI/ci-1 fix in existing run `01M2QNJRBW9M8WC4ZNZ3QQHG8G` only.
- Starting HEAD: `5d4d4feb7d97fb8bb99eb11362e351554d3196f9`; clean detached worktree.
- Fetched main initially: `fdc43bf1aeefd27c105720cbb5e2d5e745c1eeb4`.
- Signed merge: `6103c5c35c84f5e3c3928381f34e345738d9a447`.
- Parents, in order: `5d4d4feb7d97fb8bb99eb11362e351554d3196f9`,
  `fdc43bf1aeefd27c105720cbb5e2d5e745c1eeb4`.
- Merge tree: `9de6806f7ebfc5815db62685d9d1a294047a5adf`; Git signature status `G`.
- Both parent ancestries checked with `git merge-base --is-ancestor`.
- No pipeline controls, push, PR/default-branch merge, caller edits, package installation,
  or daemon operation performed. This evidence note was written after validation and is
  not part of the tested merge tree.

## Conflict policies

- `.github/workflows/ci.yml`: adopt upstream removal of the nonessential shell resource
  report; preserve acceptance comments and required sequential producer420/history420,
  ordinary420, corpus and site checks.
- `scripts/verify.sh`: use upstream minimal shell deadline owner and Lean driver.
  Add the smallest separate history mode to `StrictLeanVerification`; exact argument
  selection and nonempty-command proofs cover the new constructor. No deadline increase.
- `foundation_manifest.json`: retain all upstream claimed surfaces/executable exclusions;
  include `StrictLeanPolicy` once with the branch's accepted-result rationale.
- `docs/guides/contributing.md`: retain accepted-result guidance and split budgets;
  adopt Lean qualification/prototype commands.
- `docs/guides/engine-producers.md`: retain separate history scope and accepted-result
  boundaries; name the upstream Lean history implementation.
- `scripts/rule_example_checks.py`: accept deletion. Its prior writer optimization remains
  in merge ancestry; no Python resurrection or writer optimization port.

Upstream corpus source retains ordered two-producer consumption, per-record JSON
checkpoints, source/checker snapshots, primary/control records, and final real Lean
consumer admission. This is source review, not successful corpus execution on this merge.
Upstream changes also replace per-child timers with one group-wide campaign deadline and
remove the prototype's project-owned widget; these are inherited upstream contracts.
Four branch-added Python diagnostics remain existing migration debt, with their controls
preserved. The qualification guide now states that limitation rather than claiming all
repository diagnostics are Python-free. They were not executed.

## Review and scoped checks

- Fresh-context proof and integration reviewers configured as Codex/gpt-6-astra/medium.
  Both returned scoped source-review CLEAN after one documentation claim was narrowed
  and independently rechecked. They did not compile or claim runtime/axiom coverage.
- Fixer PID 63825 observed argv: `codex exec -m gpt-6-astra -c
  model_reasoning_effort="medium" ...`. Reviewer launch argv was not independently observed.
- `lean lean/StrictLeanVerification.lean`: PASS, including exact parser/selection proofs.
- `./scripts/verify.sh diagnostics history unexpected`: expected usage refusal, exit 1.
- Git diff checks passed; no unresolved merge entries remained before the signed commit.
- Pinned Lean: `v4.33.1`; Mathlib revision:
  `0df444a360eaa60ab8c11dca51a86af692955474`.

## Cold acceptance: FAIL, no retry

Immediately before compiling, the process scan found no Lean/Lake/compiler contention.
Prior root `.lake/build` and `.lake/config` were moved, not deleted, into
`tmp/ci-main-integration/pre-merge-root-build` and `pre-merge-root-config`. Pinned dependency
artifacts remained provisioned. The actual unchanged outer command ran once:

`/usr/bin/time -p ./scripts/verify.sh`

At merge `6103c5c...`, it exited 1 after **332.41 seconds**, before the 420-second deadline:

`FAIL: invalid policy inventory: anonymous, duplicate, or malformed identity`

Observed before failure: 171 build jobs completed, registry metadata checks passed,
seven registry CLI controls passed, and 36 native controls passed. The declaration
report counted five libraries, one executable, 40 owned modules, and 5,015 declarations.
That count is not successful inventory admission, accepted declaration/axiom coverage,
or full conformance. No terminal accepted `tmp/axiom-report.json` was produced. The
complete declaration phase reported 197775ms. Documentation acceptance was not reached.

Raw evidence remains under `tmp/ci-main-integration/`: `driver-check.log`,
`history-extra-argument.log`, and `cold420.log`. Prior failed artifacts were preserved.
The reported hosted history timeout remains historical failed evidence at
https://github.com/rbeauchamp/strict-lean/actions/runs/35261472547/job/105337992389 .

Per the explicit stop-on-first-substantive-failure instruction, no repair retry,
producer420, history420, corpus, site, or additional acceptance run followed. A final
process scan found no remaining Lean/Lake/compiler descendants; compiler allocation
is released. The failure's specific malformed identity has not been diagnosed.

## Newer main and remaining work

During the cold run, main advanced. Read-only remote verification and fetch pinned
`259ebee37fd41146596df1d169bab94dbdcd78f9` (PR #35). Its parent is `fdc43bf...`; its only
changes are `StrictLeanVerification.lean` and `StrictLean/Qualification/Main.lean`.
It combines registry/native dispatch and producer/history dispatch. Independent source
review found the ordinary combination compatible; the explicit separate-gate contract
must take precedence over the upstream combined producer recipe during reconciliation.
Its additional standalone combined producer command does not replace required gates.

**This newer main is fetched but not merged.** The current signed merge must not be
called latest-main integration. The first substantive validation failure triggered the
required stop before further merge/source work. Remaining work: reconcile that newer
main with actual merge ancestry, diagnose the inventory-admission failure, obtain focused
review, and complete the required checks under unchanged limits. The outer executor
owns continuation, phase advancement, publication and exact-head hosted CI.
