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

## Validation outstanding at the prior checkpoint

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

### Cold ordinary acceptance

Signed source checkpoint: `79402149208c15e336fe6385f7df08246c2cde98` (`G`),
tree `7cff64d74cd763a9ba61476c7a4269183bb14011`. The worktree was clean before
and after the command. Existing root build output was moved to
`tmp/environment-warm-build`; `.lake/build` was absent when verification began.
Pinned dependency artifacts remained provisioned. No root artifact cache was present.

`/usr/bin/time -p ./scripts/verify.sh` exited 0 in **276.37 seconds**, under the
unchanged 420-second group deadline. Raw log: `tmp/environment-cold420.log`.
Registry metadata, seven invalidating registry CLI controls and 36 native bridge
controls passed. Combined acceptance finalized **7,272 project jobs and 97
documentation jobs**: 70/70 positive fences, 23/23 negatives, 1/1 teaching, no failures.
This closes the observed local invalid-inventory failure on that exact source head;
it is not hosted CI, independent semantic review or issue #7 closure.

Retained production coverage: 40 modules, 5,237 declarations. Surface counts are
StrictLeanPolicy 17/4,179; StrictLeanVerification 1/106;
StrictLeanQualification 10/443; Audit 7/313; AuditApp plus Main 5/196
(modules/declarations). Exact module arrays and per-declaration axiom sets are in
the five `environment-production-packets-shared.json.packet-*.json` artifacts.
The collision lemma and both whole-run transfer theorems each have exactly
`{propext, Quot.sound, Classical.choice}` in those production observations.
Explicit coherence hypotheses are separate from those logical axioms.

### Native input-inventory port

The first runtime attempt (`tmp/environment-input-inventory.log`) passed its
incremental positive but failed the intended-reason assertion. The old subprocess
helper merged stderr into stdout; the native port had retained only stdout for
that assertion. Refusal checks now examine stdout plus stderr, retaining the
nonzero exit, exact reason, incomplete status, absence of authority, actual new
module build witness, and fresh restoration requirements. The same original
merged-stream meaning is restored for documentation dependency/history refusals.
`tmp/environment-resume-build10.log` records successful native compilation.

`lake exe qualify input-inventory` then exited 0. All 16 phases passed in
`tmp/environment-input-inventory-streams.log`: incremental and build-lint root
addition controls (including built-artifact witnesses), and edit/removal controls
through both documentation commands, each with positive/restored acceptance.
These subsequent changes affect diagnostic oracles only. The full cold result
above belongs to `7940214`, not a claim of acceptance rerun on the later checkpoint.

`lake exe qualify documentation-dependencies` also exited 0; log
`tmp/environment-documentation-dependencies.log`. Both `docFenceAudit` and
`ruleExamples` passed positive/mutation/restored phases, with actual dependency
byte mutation during the prerequisite build and the intended snapshot refusal.
The final combined project/documentation positive required both authority fields.

`lake exe qualify acceptance-snapshots dependencies` exited 0; log
`tmp/environment-dependency-snapshots.log`. Git and non-Git controls passed ignored
imported/unimported source selection, unrelated byte exclusion, custom build output,
source/toolchain/addition refusals, restoration, and actual public accepted results.

All results remain conditional on truthful Lean/Lake extraction, actual compiler
and replay observations, source/filesystem stability, process completion and native
execution. No source theorem authenticates the OS, serialization provenance or
compiled binary. There is no full conformance or issue-closure claim here.
