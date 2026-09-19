# PR #33 environment census CI repair

This receipt belongs to the assigned CI repair in run
`01M2QNJRBW9M8WC4ZNZ3QQHG8G`. The outer executor retains pipeline, publication,
remote issue and merge control. This file does not mark issue #7 complete.

## Source and integration

Starting clean head: `036edb93c51de5a374f85eac0e4ff82ef79d5edd`.
Fetched main: `ce929840a6128e83b2a8eb90d492110d19f2d1ba`.
Signed two-parent merge: `d104b65821f501451c48d8e3f84cb7ad7b628fa5`, signature `G`.
Parents are the starting head and fetched main, in that order. No prior branch
commit or evidence was removed. Fresh-context merge review passed its scoped
source checks; this was not compiler or acceptance evidence.

Observed toolchain: Lean 4.34.0, compiler
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, arm64 macOS.
The local Mathlib checkout matches the manifest at
`5ed2965256430c3649e86755f9576b54eca72435`. Upstream Verso and website pins remain.

## Defect and invariant

The historical hosted check refused `invalid policy inventory`; it did not time
out. Its log does not contain the complete offending producer packets. The prior
[collision disposition](ci-inventory-collision.md) remains historical evidence.
The source defect was concatenating independently loaded environments before
`Policy.admitScope`, and reconciling roots/replay/history across that artificial
environment. Distinct legitimate declarations named `main` violate bare-name
uniqueness only in the concatenation.

The repair retains the original full project `Claim` and one `Census`/`Plan`/
`ResultState`/`finalize`/`Accepted` path. Coordinator-fixed environment requests
carry exact snapshots, ordinals and module assignments. Each environment retains
its complete policy/transcript/execution/replay/source/origin data and dependent
roles. Global target classification, discovery and build obligations remain once.
Local job subjects include their environment; root requests, histories and replay
cannot borrow another environment's observations. Local admission is unchanged.
No entrypoint was renamed, filtered or hidden.

## Proof and execution map

- `inventoryValid_append_false_of_shared_name`: universally, members of opposite
  declaration arrays with equal names imply the concatenated inventory is invalid,
  for every transcript array. This proves the defect class, not historical packet
  authenticity.
- `census_exact_requests`, `census_exact_modules`, `census_project_partition`,
  `census_environment_unique`, `requiredJobs_environment_coverage`: admitted census
  hypotheses retain the complete request partition and derived local jobs.
- `environmentStageOK_resolves`, `environmentStageOK_wrong_key`,
  `accepted_environment_resolves`: accepted local evidence resolves in the exact
  bound environment, using its own roles and unchanged local predicates.
- Existing `collect_success_iff`, `finalize_iff`, `finalized_covers_input` and
  `accepted_report_identity` retain occurrence collection, full required slots,
  policy obligations and exact returned data. Combined acceptance retains its full
  project claim, exact document inventory, modes and structural snapshot equality.

Pure-library builds passed after compiler-driven proof repairs. The public
`axiomGate`, `docFenceAudit` and `freshChecker` adapters compiled; the native
environment diagnostic and `qualify` compiled. Raw root build logs are in
`tmp/environment-build.log`, `tmp/environment-proof-build.log` and
`tmp/environment-diagnostic-setup.log`; the second contains an intermediate failed
proof build and must not be relabeled a passing run.

Fresh-context semantic review found no concrete weakening of the new policy
guards, but identified an incomplete whole-run compatibility obligation: the first
declaration/execution preservation lemmas alone do not prove all-stage old-flat or
singleton finalizer preservation. That obligation remains open until its additional
checked transfer and focused independent review are recorded here.

## Remaining validation

Native retained-packet qualification, migrated legacy controls, fresh-context
implementation review, complete unpartitioned cold ordinary420, separate required
producer/history/rule-example gates, and site qualification are not yet recorded
as passing. Hosted checks and delivery belong to the outer executor.

The four retained Python diagnostic sources are not executed. Their uncovered
public transport, dependency snapshot, prerequisite-build dependency and terminal
input-inventory controls are being ported to Lean before retirement.

## Continuation checkpoint, 2026-09-18

Preserved merge `d104b65821f501451c48d8e3f84cb7ad7b628fa5` and every incoming
uncommitted repair. No compiler child remained at entry. The existing pinned
cache setup had decompressed 8,906 artifacts; two were unavailable upstream.
No package installation, host configuration, pipeline control or publication ran.

The expanded `LocalEvidenceTransfer.sound/refl`, `GlobalEvidenceTransfer.sound/refl`,
`finalize_reindexed` and `finalize_singleton_transfer` now compile on Lean 4.34.0.
Global transfer uses structural evidence correspondence, not an assumed new
policy judgment. These are conditional transfer theorems over the actual
`finalize` and occurrence lists. Instantiation of all coherence hypotheses for
the former flattened collector remains a focused proof-review obligation; this
receipt does not claim that compiler success closes that obligation.

`lake build StrictLeanPolicy qualify axiomGate docFenceAudit ruleExamples` passed
in `tmp/environment-resume-build6.log`. Subsequent native builds passed, ending
with `tmp/environment-resume-build9.log`. Compiler errors in the new transfer
proofs and diagnostic ports were repaired without changing production policy.
Documentation-dependency restorations now clear owned root/dependency artifacts;
root-inventory positive controls also require acceptance authority.

The retained-packet command passed under its original 420-second wrapper:

```
lake exe qualify environments --evidence tmp/environment-production-packets-shared.json
```

Its log is `tmp/environment-production-packets-shared.log`. The completed receipt
references five complete raw packet files beside it. Sixteen records include the
build, concatenation refusal, complete positive, omitted/duplicate/rebound/source
mutations, replay omission, cross-environment declaration/root/role substitution,
unresolved execution, wrong snapshot/request, and restored complete positive.
The real collision is `main` owned by `StrictLeanVerification` versus `Main`.
Every unchanged local inventory admits; their concatenation refuses. This is
current production linkage, not authentication of the historical hosted packet.

Preserved unsuccessful attempts: `environment-production-packets.json` refused a
source edit during acquisition; `environment-production-packets-frozen.json`
reached exit 137 with role substitution recorded but no restoration. The
`retained` attempt was stopped with exit 143 after diagnosis of repeated large
snapshot construction. Raw packets now serialize separately from small progress
receipts; the wrong snapshot is constructed once outside the observation map.
These changes preserve the diagnostic inputs/assertions and its deadline.

`acceptance sources` was stopped as an incomplete diagnostic (exit 143); its
receipt is `tmp/environment-acceptance-sources.json`. Its growing receipt repeatedly
embedded large raw results/traces. The port now retains their original bytes in
separate result/trace files referenced by the receipt. This repaired port compiles
but its full runtime qualification, the other migrated groups, and focused
independent repair review remain INCOMPLETE. Historical Python drivers remain
unexecuted and unretired. Ordinary cold acceptance is the next required command;
no passing result for it is claimed in this checkpoint.

All results remain conditional on truthful Lean/Lake extraction, actual compiler
and replay observations, source/filesystem stability, process completion and native
execution. No source theorem authenticates the OS, serialization provenance or
compiled binary. There is no full conformance or issue-closure claim here.
