# Issue7 accepted-result integration evidence

Status: implementation checkpoint on `codex/strict-lean-7-integration`, based on
`f9b54f7b7b2094f3b9063e2bf0d156eaefe4d9be` (tree
`9310eef85ce8fbe9ee3ce961b62a7e9e45790d07`). This is not a completed delivery receipt.
Native blockers6/13 were closed at intake; the current issue body, including the narrow
authenticated-infrastructure amendment, governs. No downstream14/15/10 implementation.

## Implemented guarantee and exact API

The pure definitions are in `lean/StrictLeanPolicy/`:

- `ResultState.collect s inputs` executes `insertResult` for every supplied pair, without
  filtering or overwriting. `collect_success_iff` characterizes success by `BatchOK`:
  distinct required keys, initially vacant, bound to their supplied values.
  `collect_lookup`/`collect_empty_lookup` give exact input-to-table correspondence.
- `finalize p roles inputs : Except FinalizationFailure (Finalized p roles inputs)`
  executes that collector then `accept`. `finalize_iff` is universal over the full
  response list and independently supplied plan; success iff `InputsOK p roles inputs`.
  There is no worker-completeness hypothesis. `finalized_covers_input` returns a supplied,
  correctly bound, policy-satisfying observation for each required slot.
- `AcceptedRun c` retains census/plan/roles/input list/`Finalized` at the same claim index.
  `AcceptedRun.report` projects `Accepted.report`; `acceptedRun_claim` is exact identity.
- `combineAccepted documents project documentation` returns `CombinedAccepted pc dc documents`
  only for fresh-project and exact-documentation claims under equal snapshots.
  `combined_policy` retains both full completeness/policy conclusions;
  `combined_reports_same_snapshot` retains report and snapshot identities.
- `InfrastructureOK` checks disjoint, narrowly eligible canonical-artifact receipts and
  all supplied incoming imports. `AdmissionOK` retains the full replay module inventory
  as well as required/admitted declaration keys. No ordinary imported/excluded module
  becomes positive through this partition.
- `FileSourceBinding` preserves requested and temporary compiled URIs with proved equal
  bytes. `GraphPlanOK` freezes selected roots and supplied coverage; `GraphOK` cannot
  accept a shorter selection returned by workers. Graph execution remains separate.

[Elaborated signatures and exact axiom output](issue-7-signatures.txt) were obtained by
`lake env lean session/evidence/issue-7-signatures.lean` after targeted owner builds.
All listed collection/finalizer/composition/partition theorems use exactly
`propext`, `Classical.choice`, `Quot.sound`; `fileSourceBinding_bytes` uses no axioms.
No theorem uses `sorryAx`. These hypotheses and transitive axioms are distinct from
IO/runtime assumptions. Full fresh declaration/axiom coverage remains pending.

## Execution and success map

The current [source-backed invocation inventory](../../docs/guides/policy-acceptance.md#1-observed-call-flow-and-every-success-boundary)
identifies the exact owners, including non-audit modes. The core theorem-to-call map is:

| Success/collection owner | Executed definition and theorem |
| --- | --- |
| `Checker.Common.mapWorkQueue`, `admitIndexedWorkerResults`; `Documentation.auditTasks` | `ResultState.collect`; `collect_success_iff`, `collect_lookup`, `collect_empty_lookup`. |
| `Checker.Acceptance.finish` → `AxiomGate.auditSurfaceAt`, explicit-positive `auditFile` | `finalize`; `finalize_iff`, `finalized_covers_input`, `accepted_covers_slot`, `accepted_report_identity`. |
| `Documentation.finishDocuments` → `auditBuiltProject`, `DocFenceAudit.run`, `RuleExamples.documentation` | Same full-domain finalizer plus `ExampleExpectationOK`/`DocumentOK`; original fence spans/group units and terminal source checks remain operational. |
| `AxiomGate.auditSurface` combined final success | Parent decodes/reconciles raw `SurfaceProduction`, recomputes `Acceptance.finish`, then `combineAccepted`; `combined_policy`, `combined_reports_same_snapshot`. |
| `FreshChecker.finishGraph` → `FreshChecker.run` audit success | Same `finalize`; frozen `GraphPlanOK` and `GraphOK`; actual process completion remains an IO observation. |
| `ResultProtocol.writeAccepted`, all audit success text | `AcceptedRun.report`, `acceptedRun_claim`, `accepted_report_identity`. Rendering is not universally proved and serialized metadata never supplies a proof. |

Public proof-bearing constructors require their stated evidence. Raw producer records,
generic diagnostic JSON and `AcceptedReport` are data, not authority. Help/planning,
internal workers, native local diagnostics, registry/site validation, policy-negative
production and diagnostic demonstrations intentionally have no global audit certificate.
All twenty rule identities and supported stages remain unchanged. Four accepted example
kinds are retained; INCOMPLETE demonstrations are separate.

## Scoped observations so far

Supported Lean4.33.1, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`, Mathlib
`0df444a360eaa60ab8c11dca51a86af692955474`. Targeted builds have elaborated pure owner
modules and project/file/docs/graph/qualifier consumers. These are incremental checks,
not cold-root ordinary acceptance.

Initial native build failed on continuation indentation in a new renderer (14.67s).
After correction, `gtimeout --signal=KILL 180s lake build axiomGate` passed102 jobs in12.35s.
Input SHA256 records and full logs are retained in the owned `tmp/issue-7/pilot-01/` directory.
The first pilot used nonexistent `--result-out` and was refused; corrected invocations use
`--json-out`. The first combined negative pattern used lowercase `type mismatch`; Lean's
actual `Type mismatch` was correctly refused with no escaped acceptance metadata.

Under the corrected fixture, public-route observations were:

| Route | Observed result |
| --- | --- |
| Incremental project | PASS9.503s; completed/incrementalProject,7 accepted jobs. |
| Combined fresh project/docs | Restored PASS17.140s;7 project/5 documentation jobs, positive and compiler-negative fences. |
| Explicit positive file | PASS9.177s; completed/freshFile with accepted metadata. |
| No-profile file | PASS6.966s as classified/freshFile, no acceptance metadata. |

Exact commands, fixture bytes/hashes, expected/actual outcomes and durations are in
`tmp/issue-7/pilot-02/routes.json` and `pilot-03/routes.json`; the complete groups took25.33s
and33.32s under their180s bounds. The initial pilot preceded the stronger pure composition
package and later report fields; it is not exact-input qualification of those later changes.
### Maintained transport diagnostics

All four `scripts/acceptance_checks.py` groups passed on the refreshed native binary
`2a9b2a823ef5b42d3421140624f6da4b3b6f3c1514733d35b927eb955cc1c8a7`:

| Group | Records | Observed wall time | Boundary qualified |
| --- | ---: | ---: | --- |
| surface | 9 | 133.54s | Missing output, duplicate inspections, misindexed modules, stale request identity. |
| evidence | 7 | 109.19s | Unknown declaration category, conflicting source bytes, failed build observation. |
| fences | 7 | 118.02s | Missing, duplicate and unknown-index compilation results. |
| process | 5 | 67.73s | Worker exit17 and actual8.047s timeout, canonical incomplete/no acceptance, restoration. |

Every group contains an initial positive and fresh restoration after each fault. Each
ran under179s TERM/180s KILL; the controller kills and joins its detached child group on
its own timeout or outer termination. This diagnostic budget is separate from ordinary420.
The native build passed120 jobs in18.70s. Exact source hashes, commands, raw results and
logs are in `tmp/issue-7/qualification-01/{input.json,build.log,<group>.json,<group>.log}`.
These observations supplement the universal proofs; they do not establish correctness
by sampling or authenticate arbitrary external processes.

The approved compatibility repair subsequently moved the legacy `build policy linter: PASS`
label into `auditSurfaceAt`, after obtaining `AcceptedRun.report`, using a default-false
renderer flag passed only from build-lint's incremental route. There is no outer
exit-code-only success branch. Its native build passed102 jobs in10.73s; refreshed binary
SHA256 `bafe9cbb07cefc55421b012545c860b29294568396f394abc109b945b672d679`.
`build-02-input.json` records before/after source identities. The packet receipts precede
this change: their codecs, raw dispatcher, collector/finalizer, source guards and tested
false-flag branch are unchanged. They are reused for those unchanged claims, not presented
as exact-final-binary executions. The changed build-lint rendering requires its own check.

### Small public routes and retained failures

The initial small-route control passed standalone positive/negative documentation and the
positive documentation adapter, then correctly refused a trusted marker around an ordinary
kernel proof; aggregate30.70s. That refusal is retained in `qualification-01/routes.*`.
Using the existing SL1004 native-decision fixture, the corrected group passed108.62s:

| Route | Observed result |
| --- | --- |
| Standalone positive/negative fences | PASS11.416s, accepted documentation jobs. |
| All-positive documentation adapter | PASS9.330s, completed with4 accepted jobs. |
| Standalone teaching fence | PASS12.186s, compiler-trusting expectation only. |
| Teaching documentation adapter | PASS9.930s, classified with4 accepted expectation jobs. |
| Zero declarations and zero Lean fences | PASS16.366s,5 project plus3 documentation jobs. |
| Graph plan-only | PASS7.306s, planned with no certificate. |
| Actual small serialized graph | PASS41.929s,4 accepted graph jobs; not the full optional repository campaign. |

Exact commands, fixture bytes, binary identities, results and logs are retained in
`tmp/issue-7/qualification-02/routes.{py,json,log}`. The combined route uses the refreshed
axiomGate binary; documentation/graph binaries retain their unchanged input identity.

The existing `checkerSelftest --build-lint-only` diagnostic then reached the180-second
coordination bound and was killed (observed180.01s). Its progress labels record completed
controls, not the final aggregate verdict. This attempt is **INCOMPLETE**, not PASS; its
full log is `qualification-02/build-policy.log`. The incomplete attempt is retained.

Firstmate subsequently authorized the existing separate diagnostic420 bounds for the two
unchanged campaigns. The current authority is [the policy-domain guide](../../docs/guides/policy-domain.md)
(diagnostic commands and420 bound), `AGENTS.md`'s diagnostic rule, and the build-policy
partition/deadline owner in `scripts/verify.sh`. `CheckerSelftest.runBuildPolicy` and
`--build-lint-only` both call `BuildLintQualification.qualify`; no selector or control changed.

| Existing full diagnostic | Aggregate result | Observed wall time |
| --- | --- | ---: |
| `gtimeout --signal=KILL 420s .lake/build/bin/checkerSelftest --build-lint-only` | PASS, all build-policy controls and final aggregate verdict. | 282.68s |
| `gtimeout --signal=KILL 420s .lake/build/bin/checkerSelftest --policy-domain-only` | PASS, strict transport/public external-adopter paths, intended refusals/restorations and positive-file warning controls. | 220.03s |

These ran sequentially with pinned dependency artifacts already available. Exact head,
modified/untracked source hashes, native binary hashes and commands are in
`tmp/issue-7/qualification-03/input.json`; full logs are `build-policy.log` and
`policy-domain.log` in the same directory. Both exited0 and emitted their final aggregate
PASS; no matching owned diagnostic compiler children were observed afterward. The exclusive
window was released. These are separate diagnostic results, not ordinary acceptance,
performance guarantees, or evidence that cold-root420 has passed.

### Recurring verification placement

Ordinary `./scripts/verify.sh` remains one complete cold-root420 invocation. Its existing
pure-library, executable and diagnostic-owner build targets transitively check all new
proofs/adapters, and its actual `--with-docs` path consumes the same-snapshot acceptance.
The workflow documents that coverage without adding duplicate builds or transport groups.
Full ordinary, producer, corpus, site and all required hosted checks remain mandatory.

The four maintained transport groups run when their worker dispatch, packet codecs,
join behavior, request reconstruction or output ownership changes. They qualify actual
IO linkage that the finite-observation theorems do not authenticate. Universal
`collect_success_iff`/`finalize_iff` and the report/composition theorems already enforce
all supplied-key coverage/binding/policy properties; scenarios are not their proof.
After fixes, rerun invalidated diagnostic claims and explicitly identify unchanged
relevant inputs before reusing others. Do not append these multi-minute campaigns to
every ordinary acceptance run or combine them into a substitute acceptance result.

## Pending delivery gates

- Retain the initial180s incomplete build-lint attempt and subsequent full diagnostic
  passes. Rerun focused packet/route/adopter/build claims where later changes invalidate
  their relevant inputs; no current report claims every receipt ran on one final binary.
- Complete cold-root `./scripts/verify.sh` within hard420; no grace, override or acceptance
  assembled from separate inner checks. Coordinate expensive runs with Firstmate.
- Reconcile new declaration/axiom inventory and every required issue7 acceptance criterion.
- Independent fresh-context proof and integration review, full no-mistakes at Codex/Astra
  medium, signed implementation/fix commits, exact-head hosted checks and PR delivery.
- Firstmate integration, actual merged-main CI, issue/Project8 reconciliation, publication
  of the [successor14/10 handoff](issue-7-successor-handoff.md) and owned cleanup. No release or visibility change.

## Trust and attribution

Proofs concern supplied finite observations, exact collection and approved predicates.
They do not authenticate Lean/Lake traversal, filesystem reads, JSON parsing, source
freshness between observations, OS scheduling/signals, compiled binaries or semantic
contract adequacy. Existing fresh builds, canonical paths, source/configuration guards,
full kernel replay, compiler/role/transcript/history extraction and packet checks remain.
Dependency identity records observed Git base/diff/untracked state or path file observations
inside the exact configuration snapshot; it is not a proof of a whole filesystem or a
fresh rebuild of every dependency. Lean's pointer-equality shortcut has full structural
fallback and the existing compiled-runtime trust boundary; no hash equality is substituted.

Con-leche's authors/contributors, maintained by Joachim Breitner at Lean FRO, are credited
for `CheckedRecord`, `collectChecks`, `FullyChecked` and the proof-bearing `checkDeclsIO`
architecture. No con-leche code/proofs are imported. All residual semantic-review accounts
and the explicit external-runtime limits remain; mechanical acceptance is not whole-standard
semantic conformance or a proof that an external checker process is correct.
