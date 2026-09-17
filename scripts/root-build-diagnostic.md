# Temporary allocation083 handoff

This prepares one explicitly dispatched root-build diagnostic. It does **not** repair
or supersede the original [failed ordinary420 receipt](https://github.com/rbeauchamp/strict-lean/actions/runs/35224671875/job/105213081215).
The outer executor owns publication, remote-head/guard/history checks, exactly one
explicit dispatch, interpretation, subsequent repair, and removal of this job,
local setup action, harness, and handoff before delivery. No dispatch or Lean
compilation was performed during preparation.

## First dispatched attempt and loader repair

[Run 35243312991](https://github.com/rbeauchamp/strict-lean/actions/runs/35243312991)
at `00c6d069cdfb813901890abe9eca2d55ccc12180` failed during setup: the
pinned cache restore bundle uses ES modules, but the adapter saved it as `.cjs`.
Node 24.19.0 rejected its first `import`; no A/B/A measurements were collected.
The adapter now saves that same bundle as `.mjs`. Locally, Node 24.19.0 reproduced
the original syntax failure; the identical `.mjs` bundle passed syntax checking
and executed with an empty environment to the cache-backend-unavailable path
(`cache-hit=false`). This verifies module loading, not hosted cache restoration.

The single authorized dispatch has been consumed. This repair does not authorize
another experiment. The outer executor must resolve further diagnostic allocation
and temporary-surface removal. Both ordinary verification runs (35243312991 and
35243219772) still failed at the unchanged 420-second deadline. No checker repair,
Lean compilation, dispatch, or pipeline control was performed in this fix round.

## Admission and budgets

`root_build_diagnostic` defaults to Boolean false. The distinct job requires
`workflow_dispatch`, true input, `rbeauchamp/strict-lean`, the exact integration
branch ref, and first run attempt. Push, PR, default dispatch and reruns cannot
execute it. Independently authorized future human dispatches are not prevented by
a lock service. Existing triggers, concurrency and the entire `verify` job are
unchanged. Publication and explicit dispatch also run ordinary CI independently;
neither is the root-only allocation. Existing workflow concurrency still applies.

The pinned checkout loads the harness. One GNU `timeout --signal=KILL 300s`
then owns all provisioning: downloading the **same pinned cache action's bundled
restore entrypoint**, both exact-key cache restores, three independent Git clones,
three writable dependency copies, and identity checks. A small local Node24 action
supplies the GitHub runner cache-service context; it does not log that context.
No cache writes, fallback keys, package installation, root builds or cache-miss
recovery occur during setup. Missing exact cache hits mean INCOMPLETE.

A separate single GNU `timeout --signal=KILL 420s` owns all measurement work.
Each sequential root build gets a 120-second POSIX real-time alarm that SIGKILLs
the **same entire outer process group**, including compiler descendants. No child
creates a new session/group. Failure stops the sequence; prior INCOMPLETE receipts
survive SIGKILL. OS scheduling, process-group signal delivery, normal Lake child
reaping, and the hosted runner remain trusted. No retry or acceptance is invoked.

A1 and A2 are `0d2d6142192967f4873305cbf1ec5d8227607a36`;
B is `6c8835a57d0d6f8ab0479a0e6304b7736f6ca1f8`. All root build directories must
be absent before the first build. The harness runs the prescribed ordinary root
prerequisite argv without alteration. Producer identity comes from each freshly
built `axiomGate --registry-out`, not the checkout label alone.

## Evidence and interpretation

`tmp/root-build-diagnostic/receipts/` is emitted into the diagnostic job log even
on failure, including partial receipts. Preserve that log before runner disposal.
There is no successful receipt reuse. Source/configuration/pin/dependency identities
and dirty state are checked before and after each build. The inventory hashes all
non-`.git`/`.lake` input bytes, including ignored source files; dependencies are
separately inventoried against the pinned manifest. Generated `.lake` artifacts
are not represented as source identity. Toolchain executable hashes/version and
built producer identity/binary hash are recorded.

GNU time records wall time, user/system CPU including reaped descendants, and the
largest individual-process RSS high-water mark (not simultaneous aggregate RSS).
Before/after cgroup hierarchy quota/throttling, affinity, CPU, disk, memory, load
and pressure observations permit resource comparison. Missing required metrics
or identities mean INCOMPLETE. Measurements are observational, not formal
verification of Git, Lake, the compiler or OS.

The outer worker applies the predetermined criteria after inspecting resources:

- A endpoint ratio above 1.10: INCONCLUSIVE.
- Stable A endpoints and comparable resources, B at least 1.30 times **each** A:
  flag revision-correlated root-build cost for tracing.
- B within 10% of the bracketed A level: falsifies the narrow inevitable roughly
  50% revision-penalty claim in this monitored environment. Receipts expose both
  endpoint ratios and the arithmetic bracket mean rather than hiding the choice.
- Other ratios or resource mismatches: INCONCLUSIVE.

These are not confidence intervals, evidence of historical contention, or whole
acceptance. Root-only evidence cannot satisfy cold ordinary420, producer420,
history420, corpus/site checks, or exact-head CI. No second experiment is authorized.

## Static validation

Preparation checked unchanged `verify` bytes, a normalized workflow model and all
108 combinations of event/input/repository/ref/attempt categories, actionlint
1.7.7, Bash syntax and ShellCheck for new shell steps, Node syntax, and Python AST
parsing. These checks establish configuration/syntax properties, not hosted
execution. Independent focused source review identified the original multi-step
setup timing gap; the single GNU timeout owner replaces it.

Authoritative GitHub semantics used:
[Boolean inputs](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatchinputs),
[run attempt and ref contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#github-context),
[equality/coercion and conjunction](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions#operators).
`inputs` preserves Booleans; `github.run_attempt` is a numeric string coerced by
`== 1`. GitHub string comparisons are case-insensitive. The conjunction fails
closed for absent input outside explicit dispatch. The workflow already has a
default-branch dispatch entrypoint; the publisher must verify the remote version
and branch before issuing the one authorized dispatch.
