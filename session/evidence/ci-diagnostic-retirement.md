# Temporary diagnostic retirement (CI repair phase)

Reviewed starting HEAD: `1f9b14bbd919fb5b26e1dcccffa7509e929bdea5`.

Hosted run [35244799453](https://github.com/rbeauchamp/strict-lean/actions/runs/35244799453)
restored both exact cache keys, then stopped during A1 setup with
`dependency pin/dirty mismatch: mathlib`. No A/B/A build measurements were
collected. The log does not expose the differing dependency revision or paths;
it does not establish whether restored source, Git metadata, or copying caused
the mismatch. Do not infer revision-correlated build cost from this attempt.

The temporary diagnostic job, dispatch input, local action, harness, and handoff
are removed as required by allocation083's temporary-surface removal contract
and the current removal-first instruction. No replacement or retry is added.
Historical preparation and failed attempts remain in Git history and hosted logs.

Ordinary verification failed separately at the unchanged 420-second deadline in
both run 35244799453 and [job 105281154409](https://github.com/rbeauchamp/strict-lean/actions/runs/35244522038/job/105281154409).
**The ordinary timeout is unresolved. This removal does not fix or satisfy CI
acceptance.** Earlier diagnostic-only restrictions prohibit checker/Lean changes
and local Lean compilation; this phase does not override them. The outer executor
must resolve the scope of a subsequent ordinary-verification repair.

Local validation parsed the workflow into a normalized YAML model and confirmed
that only the temporary job and dispatch input were removed. The required verify
job retains unchanged configuration and step content, all required gates, and existing budgets; default
workflow dispatch remains available. `git diff --check` passed. No Lean build,
acceptance run, hosted dispatch, push, or pipeline control was performed.

Focused independent review found no defects in the removal or this disposition.
Workflow comparison excludes the removed job-separator blank line.
