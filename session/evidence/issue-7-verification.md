# Issue7 accepted-result integration evidence

Current bounded CI repair: [recovery and cleanup receipt](ci-corpus-cleanup.md).
The reviewed signed head `1c7304b40267e2343d65b3b94251b6e9424548f1` passed full
corpus420 in391.55s and cold ordinary420 in237.84s, retaining65/79/72 coverage and
all cleanup before PASS. It accepted7,278 project/97 documentation jobs; current
[exact declaration/axiom coverage](ci-corpus-cleanup-coverage.json) and
[input hashes](ci-corpus-cleanup-inputs.sha256) are retained. The predecessor's
420.02s cleanup failure remains a failure. Full no-mistakes, final-head hosted
checks and integrated delivery remain pending; no phase mark replaces those gates.

Historical [corpus projection receipt](ci-corpus-projection.md),
based on `e19018e47b73ac732853ad90297bcc94d15854b3`, with proof-linked exact
qualifier correspondence and retained raw observations. Final cold acceptance
passed in 224.40 seconds; the required full corpus still fails at 420 seconds.
[Checkpoint coverage](ci-corpus-coverage.json) and
[source binding](ci-corpus-inputs.sha256) preserve that 40-module,
5,238-declaration inventory, including the updated 71-module excluded StrictLean
surface. This is not a completed CI repair. The
[retained-role receipt](ci-role-retention.md) records exact equality of retained
roles to recomputation and the preceding scoped qualification. The
[environment integration receipt](ci-environment-census.md) retains earlier
integration/control evidence. The [compiler dependency memoization receipt](ci-candidate1-memoization.md)
and its timeout remain historical; they are not the current completion status.
Hosted acceptance, downstream issue handoffs and integrated delivery remain open.
Earlier corpus qualification failed at its unchanged 420-second deadline
after 29 qualified phases. Producer/history diagnostics passed; the continuation
receipt keeps these scoped outcomes separate from ordinary acceptance and delivery.
Final retained-role cold acceptance passed in 217.86 seconds and site qualification
passed in 67.66 seconds. [Historical coverage](ci-role-coverage.json) contains all
40 modules and 5,238 declaration/axiom entries. The unsuccessful corpus writer
experiment is removed; its second timeout does not close required qualification.

Historical implementation checkpoint below on `codex/strict-lean-7-integration`, based on
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

### Cold-root failure and independent repair findings

The first cold-root `./scripts/verify.sh` at signed checkpoint
`722aa7e7a526fe6761e6efd1d2fd6c930298a253` (tree
`b2736b522b2923cd5f15a4833468e16d70951831`) **failed**, exit1 after53.688830s.
Root outputs were absent at invocation;119 build jobs, registry/CLI and36 native controls
passed. Combined project auditing then refused `surface worker source inventory mismatch`
before completing declarations or reaching fences. This was not a deadline kill.
`tmp/issue-7/cold420-722aa7e/` retains inputs, log and result; the copied legacy report was
pre-existing and is explicitly not current-run evidence. Its prior root build remains
preserved separately. No full declaration/axiom or ordinary acceptance PASS is inferred.

Independent source/proof review of immutable722aa7e required three bounded repairs:

- R1: `SourceBinding.capture` observes each growing prefix. Its observer now only retains
  progress; exact complete module/path/byte equality is checked once capture returns,
  before build/inspection. All parent, partial-failure and terminal guards remain.
- R2: `FreshChecker` invalidates recognizable absolute output destinations before parsing
  or root discovery, and relative ones once the project root is resolved. Failed arguments
  or root discovery cannot leave an older accepted graph result at a resolvable destination.
- R3: the maintained acceptance diagnostic writes a new incomplete attempt before binary
  or setup reads, atomically retains obtained inputs/records, records handled failures,
  and promotes only after every selected case and restoration. SIGKILL relies on the
  existing incomplete receipt, not a signal handler. Process-group kill/join is retained.

Targeted incremental builds passed: axiomGate102 jobs/17.589s and freshChecker96 jobs/11.497s.
The actual binary SHA256 values were respectively
`42f1f9479c683999964d5e8f54553ff3dff9f0206583c3c31479faca32fc5074` and
`583ddb7b84de33f6db113fb4aeeded1ff24e7adbc270ea994a44640fbc6974cd`.
Inputs and build logs are in `qualification-04/` and `qualification-05/` under
`tmp/issue-7/`; these builds used modified sources atop722aa7e, not a later exact-head run.

The pre-repair native witness retained only `Example` from Lake's exact `[Example, Extra]`
request, reproducing R1 in10.586s. After repair, a first restoration correctly refused a
concurrent guide edit as `dependency snapshot changed: strict_lean`; that failed attempt
is retained. With repository inputs fixed, the five-case source group passed. Following
R3, the final seven-case group passed: two-source combined acceptance, shortened,
reordered and extra-binding refusals, full captured accounts, and fresh restoration after
each mutation. Its receipt stayed incomplete with obtained records during execution and
became completed only at the end. The five graph controls passed: actual positive,
absolute malformed arguments, absolute root-discovery failure, relative malformed
arguments, and actual restored graph acceptance. Missing-binary setup, SIGTERM during
setup and SIGKILL during setup each replaced the seeded old success receipt.

Exact commands, sources, native hashes, raw observations and logs are in
`qualification-05/{sources,graph,lifecycle}.{json,log}` and its two small control scripts;
`sources-mid-attempt.json` retains the observed incomplete state. Each compiler/group
stayed within its authorized180s bound (lifecycle30s); summed child observations were
102.786s for sources and85.675s for graph. These shared-host durations are not isolated
performance evidence. No broad packet, forced-collector, full graph, repeated cold-root
or no-mistakes run was performed in this repair checkpoint.

Relevant-input assessment: no pure collection/finalizer/composition proof changed. R1
changes the combined route's capture boundary; old single-source transport observations
do not establish multi-source behavior or execution on the repaired binary. The new
source group qualifies that boundary; unchanged packet schemas, joins, pure finalization
and producer extraction retain their prior scoped evidence. Direct fresh/incremental,
file and build-lint calls still use no expected worker inventory. R2 invalidates previous
claims about graph early-exit output ownership, now covered by the focused graph group;
graph planning/finalization is unchanged. R3 invalidates any inference from an unchanged
old receipt alone that a new attempt completed. Historical logs/identities remain historical.
Final exact-head ordinary, producer/corpus/site and hosted evidence remains required.

The excluded-root/conditional-collector distinction still needs its current integration
control. Proposed bounded sequence after independent delta review and coordination:
one complete cold-root420 gate; if successful, refresh `checkerSelftest` within180s, then
run the existing `gtimeout --signal=KILL 420s .lake/build/bin/checkerSelftest --forced-collector-only`
separately. It preserves the full manifest, actual fresh positive, source import of excluded
`StrictLean.Collect` with both intended refusal tokens, and restoration. Do not replace it
with a smaller manifest or claim that imported-reporter controls establish this distinction.
Its duration is unknown; timeout remains INCOMPLETE and triggers diagnosis, not retries
or a larger deadline. This proposed sequence has not run.

### Recurring verification placement

Ordinary `./scripts/verify.sh` remains one complete cold-root420 invocation. Its existing
pure-library, executable and diagnostic-owner build targets transitively check all new
proofs/adapters, and its actual `--with-docs` path consumes the same-snapshot acceptance.
The workflow documents that coverage without adding duplicate builds or transport groups.
Full ordinary, producer, corpus, site and all required hosted checks remain mandatory.

The original four transport groups and focused source group run when their worker dispatch, packet codecs,
join behavior, request reconstruction or output ownership changes. They qualify actual
IO linkage that the finite-observation theorems do not authenticate. Universal
`collect_success_iff`/`finalize_iff` and the report/composition theorems already enforce
all supplied-key coverage/binding/policy properties; scenarios are not their proof.
After fixes, rerun invalidated diagnostic claims and explicitly identify unchanged
relevant inputs before reusing others. Do not append these multi-minute campaigns to
every ordinary acceptance run or combine them into a substitute acceptance result.

## Review-phase R1/R2 repairs

Starting HEAD: `4c7af873960578caab34c2d7c7d8abd36c8ad03c`. Repairs remain in the
working tree; the outer pipeline owns the fix commit, ordinary acceptance, CI and delivery.

Dependency acquisition now enumerates Lake's buildable library domains and executable
roots, resolves module ownership through the workspace, and captures canonical paths
and exact UTF-8 source bytes regardless of Git ignore rules. Existing Git/path and
configuration guards remain. Terminal comparison rediscovers the same Lake domain and
compares all observations against the original capture, detecting new ignored modules.
Project census construction captures refusal before the existing policy loop, allowing
root/source-attributed SL3001 findings without permitting an AcceptedRun on missing history.

Focused evidence on Lean `leanprover/lean4:v4.33.1`:

- PASS: `axiomGate` and its import closure, including changed
  `StrictLean.Checker.Lake`, `Snapshot` and `AxiomGate`, compiled from the actual
  worktree sources using an isolated Core-only Lake configuration, warnings as errors
  and interpreter support. Initial syntax/deprecation/type-inference errors were fixed
  before the final warning-free build. Mathlib, Audit surfaces and full declaration/axiom
  coverage were not exercised; this is not ordinary acceptance.
- PASS: `scripts/acceptance_snapshot_checks.py --group dependencies` with the isolated
  checker. Changed ignored source bytes, ignored configuration and a newly added ignored
  buildable module were refused; each restoration passed. Discovery included an
  unimported buildable submodule outside the configured target array.
- PASS: the same driver with `--group history`, across fresh, incremental and build-lint
  public checker invocations: nine positive/refusal/restored controls. Refusals retained
  SL3001, execution-unresolved, identity-root/source attribution, incomplete status and
  no acceptance, without SL2001. Initial fixture setup omitted its lockfile and correctly
  failed the configuration guard; provisioning it before the audit repaired the control.
  History evidence predates only the final dependency-domain rediscovery enhancement;
  these fixtures have no dependencies, so their relevant inputs and behavior are unchanged.
- CLEAN: fresh-context independent static review of both repairs, including the pinned
  Lake buildable-domain formula and the terminal rediscovery refinement. These operational
  observations do not establish universal IO, compiler or extraction correctness.

The isolated build used `tmp/review-build/.lake/build/bin/axiomGate` with the driver's
`--checker` option. Temporary build and probe directories were removed. The regression
driver remains available; complete acceptance, required campaigns and hosted CI remain
separate pending claims.

## Review-phase R3 repair

Starting HEAD: `59d48589c858cbdd50d827f6a392b47d921d23de`; changes and evidence
belong to the assigned review phase, with commits and delivery owned by the outer executor.

`DocFenceAudit.run` and `RuleExamples.documentation` now capture dependency observations
before their prerequisite build and pass that same array through a required
`Documentation.auditBuiltProject` parameter. The adapter's post-build recapture is
removed; its existing terminal comparison precedes finalization. Combined project/docs
passes its original pre-build observations alongside the shared snapshot.

The first focused control exposed a prior R1 compatibility defect: expanding a valid
single-file library root with `andSubmodules` attempted to open an absent submodule
directory. Discovery now retains the configured globs and adds only existing submodule
directories. Root capture, canonical ownership and terminal rediscovery remain intact.

Focused evidence on Lean `leanprover/lean4:v4.33.1`:

- PASS: `axiomGate`, `docFenceAudit`, `ruleExamples` and their import closure, including
  changed `StrictLean.Checker.Documentation`, `DocFenceAudit`, `RuleExamples`, `AxiomGate`
  and `Lake`, compiled warning-free from the actual worktree sources in an isolated
  Core-only Lake build. No Mathlib/Audit surface or full declaration/axiom coverage claim.
- PASS: `python3 scripts/documentation_dependency_checks.py --bin-dir
  tmp/review-r3-build/.lake/build/bin`. Both public standalone documentation commands
  passed positive, changed-during-prerequisite-build refusal, and restored controls.
  The mutation changes a real path dependency from `Dep.n = 1` to `Dep.n = 2` after its
  artifact was built. Each refusal identifies dependency snapshot change and emits no
  accepted result. Combined `axiomGate --with-docs` also passed with both certificates.
- PASS: `scripts/acceptance_snapshot_checks.py --group dependencies` against that same
  isolated checker, retaining ignored source/configuration and added-module refusals
  plus restoration after the enumeration repair.
- CLEAN: fresh-context independent static review of R3 and the single-file library
  repair. Behavioral observations do not prove filesystem or compiler correctness.
- PASS: system skill-creator `quick_validate.py .agents/skills/lean-ci`. The concise
  addition records pre-build capture timing, unchanged observations across consumers,
  and Lake source-domain completeness; validation does not prove agent behavior.

The initial single-file dependency control failed before the enumeration repair; all
listed final controls passed afterward. The temporary Core-only build and fixtures were
removed. Full cold-root420 acceptance, broader campaigns, exact-head CI and delivery
remain separate outer-pipeline gates; none were run in this review phase.

## Review-phase R4 repair

Starting HEAD: `815a5f6f201e88dfdcf5780fa8ca76c9ae1cb02f`. This assigned review
phase removes unrestricted dependency-directory, Git diff and untracked-file byte
capture. Earlier R1/R3 descriptions of broad Git/path capture are superseded here.
Lake-resolved source inputs, actual package configuration/manifest paths, toolchain
and default-config presence, canonical identities and nominal revisions remain bound.
Git dirty status is scoped to these inputs through bounded literal pathspecs; it does
not assert whole-checkout cleanliness. Pre-build capture and terminal rediscovery/byte
comparison remain unchanged, as do typed history refusals.

Focused evidence on Lean `leanprover/lean4:v4.33.1`:

- PASS: warning-free isolated Core-only build of `axiomGate` and its import closure,
  including changed `StrictLean.Checker.Lake` and `Snapshot`, from the actual worktree
  sources. No Mathlib/Audit or complete declaration/axiom audit claim is made.
- PASS: `python3 scripts/acceptance_snapshot_checks.py --checker
  tmp/review-r4-build/.lake/build/bin/axiomGate --group dependencies`, for Git-backed
  and non-Git synthetic path dependencies. Unrelated tracked/untracked fixture bytes
  are absent from snapshot and accepted JSON output; changing those files leaves
  declared-input equality intact. Real cold builds into custom `buildDir = "build"`
  preserve the snapshot and public fresh project acceptance.
- PASS in both fixture kinds: changed ignored source/configuration bytes and newly
  added buildable modules are refused, with positive restoration. All unrelated data
  was synthetic and created inside disposable worktree fixtures; no real credential
  or user-data files were inspected or copied.
- CLEAN: fresh-context independent static review of removal, remaining input coverage,
  terminal checks and executable controls. These observations are scoped qualification,
  not proofs of filesystem acquisition or compiled execution.

The temporary build and fixture directories were removed. Full cold-root420 acceptance,
required broader diagnostics, fix commits, exact-head CI and delivery remain with the
outer pipeline and were not performed in this phase.

## R5/R6 frozen inventory repair

Starting HEAD: `2be75302055e0d8a100977d4d6625dd3aef3c104`; these results cover
its working-tree repair. Root reconciliation now reloads Lake and compares target,
module and canonical source identities even without dependencies. Documentation
callers carry required pre-build Markdown records through the existing adapter.
The finite entrypoint/input-class coverage table is in
[the acceptance guide](../../docs/guides/policy-acceptance.md#frozen-input-coverage-at-operational-entry-points).

- PASS: isolated Core-only `lake build axiomGate docFenceAudit ruleExamples freshChecker`
  against the actual changed sources on Lean `v4.33.1` (111 jobs). An initial helper
  syntax error was corrected before the successful build. This excludes Mathlib,
  Audit dogfood and full repository declaration/axiom coverage.
- PASS: `scripts/input_inventory_checks.py` with those binaries: six root controls
  across incremental/build-lint, including actual successful builds of injected
  unimported axiom modules, intended inventory refusal and restored acceptance;
  ten documentation controls across both public adapters, including edits/removals
  of failing Markdown during prerequisite builds and restored positive results.
- PASS: existing `scripts/documentation_dependency_checks.py` with those binaries:
  six dependency controls and combined project/docs same-snapshot acceptance.
- PASS: lean-ci skill metadata validation and diff whitespace check.
- CLEAN: fresh-context independent static repair review of root equality, canonical
  identities, all documentation callers, the coverage table, zero-item paths and
  preservation of prior dependency/history and teaching-mode repairs. Pure theorem
  definitions were unchanged; these controls do not prove IO acquisition or runtime.

Fixtures and the isolated build were confined to disposable worktree directories.
Full cold-root420 acceptance, broader proof/integration review, signed fix commits and
exact-head CI remain with the outer pipeline; none was performed in this phase.

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
Dependency identity records Lake-resolved source/configuration bytes, nominal Git revision
and input-scoped dirty status inside the exact configuration snapshot; it is not a proof of a whole filesystem or a
fresh rebuild of every dependency. Lean's pointer-equality shortcut has full structural
fallback and the existing compiled-runtime trust boundary; no hash equality is substituted.

Con-leche's authors/contributors, maintained by Joachim Breitner at Lean FRO, are credited
for `CheckedRecord`, `collectChecks`, `FullyChecked` and the proof-bearing `checkDeclsIO`
architecture. No con-leche code/proofs are imported. All residual semantic-review accounts
and the explicit external-runtime limits remain; mechanical acceptance is not whole-standard
semantic conformance or a proof that an external checker process is correct.

### CI timeout repair: share transcript source lines

Assigned CI phase at `504e626f68ddb441a3d6e16202a132ae22a79554` only; no pipeline,
publication or hosted workflow was started by this repair. Check105067810791 in
run35179303502 expired at the unchanged420-second deadline during fence inspection.
Its complete declaration phase took223.385s. A bounded local diagnostic on the
unchanged source completed that phase in133.359s; this was not cold-root acceptance.
Native stack samples identified repeated `String.splitOn` inside
`Frontend.Transcript.validCoordinates`, reached through `InventoryValid` and
`admitInventory` during `Acceptance.freeze`.

Line-taking coordinate helpers factor the existing predicates. The executed transcript
checker derives a line list from its own exact source before traversing commands,
evaluators and bindings. Its declaration-coordinate decision separately shares one
source split across declarations. Public source-taking wrappers preserve their meanings.
`Frontend.Transcript.validCoordinates_eq` and `Ranges.validForLines_eq` are universal,
with no added hypotheses, proving exact equalities by reduction. Reported transitive
axioms of both are `propext`, `Classical.choice`, `Quot.sound` (Standard-Logical).
Temporary kernel-checked reduction proofs additionally reconciled the original
position, UTF16, range and entire `InventoryValid` formulas. `InventoryValid` itself
is unchanged; its new decision instance has that same proposition as its type.
Source/FileMap checks, refusal reasons, snapshot acquisition, worker transport and
accepted-result boundaries are unchanged.

Focused executable `admitInventory` controls passed: Unicode/CRLF/trailing empty line;
zero/nonexistent line, oversized column, reversed range, invalid evaluator/binding
range and mismatched declaration identities refused with the existing inventory error;
each mutation restored to a passing control. UTF16 start/end-column mismatches and
selection outside its full range were also refused and restored. Missing optional
ranges remain permitted.
These controls supplement the universal equality theorem; no source-text test was added.
An exploratory interpreted Lake snapshot probe hit Lean's interpreter unreachable
assertion and supplied no timing evidence; native profiling supplied the diagnosis.

Fresh-context independent repair review: CLEAN for the final scoped proof and execution
linkage. Review of an intermediate attempt caught that a let inside a proposition
was lost in Decidable synthesis. The final explicit executable decision fixes that:
generated C performs two shared splits per fully checked transcript, one for syntax
ranges and one for declaration ranges. Intermediate local decision-helper attempts
failed compilation and were replaced; final build105jobs and focused controls passed.
Reviewed `Admission.lean` SHA256:
`7a8a5a0d0747bcff8f7b757e06299724503630c22a47495999fcad644e096bef`.
This is source/compiler inspection, not a proof of compiled machine-code correctness.
The reusable hoisting/equality lesson was added to `lean-ci`; system skill validation passed.

The first, transcript-only repair passed cold420 in293.294s with declaration phase
124.802s, but did not remove the equivalent declaration-range cost. That result is
superseded by final-source verification below; it is not evidence for the later code.
Logs and bounded profiling observations are under `tmp/ci-timeout/` in the gate worktree.
The attempted snapshot microprobe and temporary proof/control sources were removed.

Final modified-source cold-root `./scripts/verify.sh`: **PASS**, exit0 in289.456s,
root `.lake/build` absent at start, unchanged hard420 deadline. Lean4.33.1,
compiler819816b2e0a3bf405af45ae5c7af2491d8f5bee6,
Mathlib0df444a360eaa60ab8c11dca51a86af692955474. All119 build jobs,
registry/CLI controls and36 native bridge controls passed. The actual project audit
covered29owned modules and4432declarations, all three surfaces Standard-Logical with
execution report mode; finalization accepted6174project jobs and97documentation jobs.
All94fences passed:70conforming positives,23intended rejections,1trusted teaching.
Declaration phase120.377s; fence compilation20.951s; inspection44.158s.
These local observations do not establish hosted performance or a universal time bound.

Exact claimed module arrays (the executable `Main` belongs to the AuditApp assignment):

- Audit: `Audit`, `Audit.Research`, `Audit.Basic`, `Audit.Economy`, `Audit.Server`, `Audit.DocPrelude`, `Audit.DocClaims`.
- AuditApp: `AuditApp`, `AuditApp.Limiter`, `AuditApp.Refinement`, `AuditApp.Demo`, `Main`.
- StrictLeanPolicy: `StrictLeanPolicy`, `StrictLeanPolicy.Specification`, `StrictLeanPolicy.Identity`, `StrictLeanPolicy.Claim`, `StrictLeanPolicy.Decision`, `StrictLeanPolicy.Pattern`, `StrictLeanPolicy.Foundation`, `StrictLeanPolicy.Execution`, `StrictLeanPolicy.Admission`, `StrictLeanPolicy.Domain`, `StrictLeanPolicy.RoleSpecification`, `StrictLeanPolicy.Plan`, `StrictLeanPolicy.Collections`, `StrictLeanPolicy.Codec`, `StrictLeanPolicy.Observation`, `StrictLeanPolicy.ResultState`, `StrictLeanPolicy.Acceptance`.

Normative meaning and modes are unchanged, so no normative prose or fence changes were
needed. Broader diagnostic campaigns were not rerun or relabelled PASS. Final hosted CI,
new commit identity and all outer delivery phases remain with the active executor.

## CI repair: repeated inventory decisions

Assigned CI phase at `12d7a014e6133fb90ad6eec3236e474b0718423d`, for failed
check 105073988305 in run 35181358909. Hosted ordinary acceptance reached the 420s
deadline during fence inspection; it remains a failed run. This phase did not
control the pipeline, publish commits, or start another hosted run.

Native profiling of the existing executable identified pairwise distinctness and
repeated required-key membership in `ExampleAdmissionOK` during documentation
finalization. `uniqueNames` used the same pairwise decision for admitted inventories.
The repair leaves both propositions unchanged and supplies cheaper decisions.
For every `α : Type` with `BEq`, `Hashable`, `LawfulBEq`, and `LawfulHashable`, and
every `xs : List α`, `distinct_iff` proves
`(Std.ExtHashSet.ofList xs).size = xs.length ↔ xs.Pairwise (· ≠ ·)`.
`distinctDecidable` transfers that equality decision to the original proposition.
Both replay arrays use it; required-key membership uses `ExtHashSet.mem_ofList`.
Hash collisions do not authorize equality, and no worst-case linear-time theorem
is claimed. Transitive axioms of the theorem and decision are exactly
`propext`, `Classical.choice`, and `Quot.sound`.

The 107-job development build passed. Executed `admitInventory` and
`ExampleAdmissionOK` controls passed: duplicate declaration, duplicate required or
admitted replay key, missing required declaration, missing admission and failed
replay were refused; positive/restored, reordered admission, empty-name and
structurally distinct-name controls passed. These exercise the actual decisions,
not source-text patterns. The universal equivalence supplies predicate preservation;
the controls do not prove the IO checker. Invocation, transport, snapshot and
collection protocols are unchanged, so their earlier qualification remains scoped
to those unchanged inputs. No broader diagnostic campaign is claimed here.

Fresh-context independent review was CLEAN for proof, decision linkage, collision
semantics and generated-code sharing. Generated C calls the new distinctness
decision and constructs the membership set outside the declaration loop. This is
compiler inspection, not verification of machine code. The three-line lean-ci
guidance addition also received independent review and passed the system skill
validator; the existing skill already covers the general indexed-membership method.

Complete modified-source cold-root `./scripts/verify.sh`: **PASS**, exit 0 in
277.095s, with root `.lake/build` absent at start and the unchanged 420s deadline.
Lean 4.33.1/compiler 819816b2e0a3bf405af45ae5c7af2491d8f5bee6 and
Mathlib 0df444a360eaa60ab8c11dca51a86af692955474. All 119 build jobs,
registry/CLI and 36 native bridge controls passed. The same 29 modules listed above
yielded 4441 owned declarations and 6184 accepted project jobs; all 94 fences passed
(70 positive, 23 negative, 1 teaching), with 97 accepted documentation jobs.
The complete declaration phase took 120.930s. Logs, stack samples and the timed
result are in `tmp/ci-round3/`; temporary Lean probes were removed.
This local observation is not a hosted timing guarantee or an exact-head CI result.
The outer executor owns the repair commit and hosted verification.

## CI repair: JSON layout in worker transport

Assigned CI phase at `ca5595e9d115640c26f75e6d49eaa5bc520214b8`, following
failed verify check105078914633/run35182964695. That hosted run completed the
declaration phase in261.904s, then hit the unchanged420s overall deadline. It
remains FAIL. This phase does not run, push, or control any other pipeline phase.

A bounded local reproduction of `axiomGate --with-docs --legacy-json-out` passed
in241.42s (not ordinary acceptance); its declaration phase took124.402s. Native
stack samples during declaration-worker output and terminal surface-packet output
located work in `Json.pretty`/`Json.render` and `Std.Format.pretty` layout. These
samples identify actual executed work, not its share of all hosted elapsed time.
The two-line repair selects pinned Lean's `Json.compress` in the shared JSON writer
and legacy report writer. No fields, policies, source checks, admissions, worker
joins, deadlines or required commands are removed. Whitespace and object display
order can change; parsed values, array order and embedded source strings are the
contract. Legacy structural path remapping still precedes serialization.

The105-job development build passed. Focused execution of the actual writer,
strict parser, `readWorkerPacket` and `admitIndexedWorkerResults` passed: nested
objects/arrays, empty values, numbers, Unicode, CRLF, control characters, quotes
and backslashes round-tripped; wrong request/schema/producer/extra fields and
missing/duplicate/unknown result slots refused; restored packets passed. Both
serializers' complete55MiB legacy report outputs parsed equal to the original.
One paired write observation was841ms pretty and158ms compact; this is scoped
local evidence, not a hosted speedup or universal serialization theorem. An initial
temporary probe used an unavailable `Except.isError` convenience API; after using
`toOption.isNone`, the probe compiled and all controls passed.

Fresh-context independent review was CLEAN for the two writer changes and the
lean-ci guidance, covering protocol/source-string preservation, legacy remapping,
§8.8 qualification scope and DOGFOOD-03 claim accuracy. Pure Lean policy definitions,
theorems, invocation modes and their existing proof evidence are unchanged. The
system skill validator passed. Native/JSON parser/compiler correctness remain
trusted; no new whole-checker proof or full semantic-compliance claim is made.

The public `scripts/acceptance_checks.py --group surface` diagnostic, wrapped in
420s, recorded eight PASS cases (initial positive; missing/duplicate/misindexed/stale
packet refusals; three intervening restored positives), but timed out before recording
its final restoration. That aggregate attempt is **INCOMPLETE**, not PASS. No surviving
child processes remained. A separate focused final restoration uses the same unchanged
fixture and public combined command; it does not convert the timed-out aggregate into
a passing campaign or partition ordinary acceptance. The raw diagnostic and stack
samples are retained in `tmp/ci-round4/`.

The separate final restored public combined invocation returned exit0 and completed
both accepted results (61.222s including reading/checking its JSON). Thus each selected
packet refusal has a subsequent observed passing control, while the original aggregate
remains INCOMPLETE. Its disposable fixture and temporary serializer probe were removed.

Complete modified-source cold-root `./scripts/verify.sh`: **PASS**, exit0 in256.157s,
with `.lake/build` absent at entry and the unchanged420s deadline. Lean4.33.1,
compiler819816b2e0a3bf405af45ae5c7af2491d8f5bee6,
Mathlib0df444a360eaa60ab8c11dca51a86af692955474. All119 build jobs, registry/CLI
qualification and36 native bridge controls passed. The same29 claimed modules listed
above yielded4441 owned declarations,6184 accepted project jobs and97 documentation
jobs. All94 fences passed (70positive,23negative,1teaching). Declaration phase97.867s;
the complete local result is not a hosted timing guarantee. No pure policy/proof source
changed; exact foundation profiles and report execution modes remain unchanged.

Verified source SHA256:
- `lean/StrictLean/Checker/Common.lean`: `3dd4515e1060e3ecc13aaadebad5b53a492c03a66835cc0935398ba88872405c`.
- `lean/StrictLean/Checker/AxiomGate.lean`: `e736292119d945c71c5dd9a3e1817a40872f84039337dba1e60226f2af0ea326`.

The active executor owns the repair commit, exact-head hosted CI and all remaining
pipeline/delivery phases. No new hosted pass, merge or full campaign pass is claimed.

## CI repair: bounded Git-status batches and phase attribution

Assigned only the active CI repair at HEAD `f4b8fca809ca30e0ab329d79edab8a0d562def3a`,
base tree `9730dda4a562c24797b71edf95fb7f1c877ce2c3`, following failed hosted
check105084494069/run35184816180. The hosted420 deadline failure remains FAIL.
No pipeline control, commit, publication, hosted rerun or other delivery phase was performed.

### Change and preservation argument

`Checker/Snapshot.lean` partitions the identical ordered Lake-selected source/configuration
path array into consecutive nonempty slices of at most512 entries and96KiB of UTF-8
pathname arguments including NUL terminators. One oversized path remains a singleton;
Git/OS failures still refuse. The byte bound excludes fixed arguments, argv pointers and
environment overhead; it is not a universal OS resource-admission theorem. The whole-run
maximum was75130 pathname bytes/512paths with3813 environment bytes.

For array length n, initially offset=0. Each iteration has offset<stop<=n and advances
exactly to stop. Thus consecutive half-open slices cover each input occurrence once,
in its original order, until the existing dirty/error short circuit; exhaustion covers
all inputs. Empty input returns false without executing status. Assuming successful Git
status over stable inputs, nonempty output for a union of literal pathspecs means some
selected input is dirty: OR of batch results is invariant under this partition. Rename
record formatting need not be identical for this Boolean property. External Git semantics,
filesystem/process observations and change-and-restore limits remain trusted.

The literal-pathspec/status options are unchanged. Every executed nonzero status refuses
before checking stdout; process-launch errors propagate. No failure is converted to clean
or dirty success. Regrouping changes command sizes, observation times and which paths share
a command, so no universal equivalence of external resource/concurrency/error traces is
claimed. All canonical-path binding, exact byte/configuration/inventory comparisons,
pre-build captures and terminal recaptures remain; none is cached or removed.
The existing con-leche-inspired accepted-result construction, policies, worker acceptance,
parent recomputation, identities and supported modes are unchanged.

Bounded attribution uses the existing `timedPhase` in Snapshot, AxiomGate and Documentation.
It brackets dependency capture, terminal Lake inventory, raw surface-packet read/parse/decode,
worker/parent freeze and finalization, parent snapshot assembly, documentation freeze,
legacy/surface-packet output and the unchanged human boundary loop. Pure computations use
`IO.lazyPure` so they execute inside the measured IO action. Timers add progress lines and
logging overhead, not omitted diagnostics or altered report values. They measure named
combined work, not isolated CPU, memory pressure, pipe backpressure or scheduler causes.

### Focused qualification and review

`lake build axiomGate docFenceAudit`: PASS105jobs, including final lazy-timing repair.
The real `Snapshot.dependency` interface passed32 controls before and32 after the batching
change: empty/1/63/64/65/511/512/513/1025 inputs; dirty paths on old/new boundaries;
tracked/ignored additions, removals and renames; unrelated artifacts; injected Git command
failure; restored positives; literal metacharacters/Unicode and long-path byte boundaries.
The harness observed real Git argv and asserted exact ordered prefix/full partition and
unchanged options, Boolean/error outcomes and the new count/byte bounds. For1025clean
paths,17calls became3; the long-path case split190+10paths under the byte bound.
These controls isolate Git batching through the configuration-path channel; they do not
pretend that samples prove external Git or process semantics.

The existing `python3 scripts/acceptance_snapshot_checks.py --group dependencies` passed
both Git and non-Git dependency cases: actual Lake-selected ignored/imported/unimported
sources, changed source/configuration, newly discovered source and restored positives,
unrelated synthetic files, custom build outputs and the public fresh checker success route.
No recurring diagnostic campaign or source-string behavior test was added. Unchanged
policy, packet, history-refusal and mode contracts retain their earlier scoped evidence.

Fresh-context independent review was CLEAN after one attribution repair. Generated C
initially showed eager pure computations before their timers; `IO.lazyPure` repaired this,
and focused generated-call review confirmed suspension for finalization/snapshot/freezing
and output conversion. Final skill review was CLEAN; system `skill-creator` validator PASS.
The skill captures the observed eager-timing lesson and the explicitly supplied checked
Acorn arithmetic lesson about symbolic Pow/NPow correspondence in bound, auxiliary proof
and final implementation goal. No new Acorn execution, reachability, liveness or benefit
claim is made. An interpreted root-inventory probe hit the known IR-interpreter unreachable
assertion; its failure log is retained. A native helper using the unchanged Lake inventory
implementation produced the pre/post receipts. This failed probe was not acceptance.

### Whole-run receipt and attribution

Actual unmodified complete cold-root `./scripts/verify.sh`: **PASS**, exit0 in
258.015080125s under the unchanged hard420 limit. Pinned dependency artifacts were already
present; no tool/system installation was performed. Root `.lake/build` was absent at entry;
prior root output/report were preserved under `tmp/ci-round5/` and not reused by the gate.
The command ran once, with `GIT_TRACE2_EVENT` recording subprocess timing during that same
required run. No separate benchmark campaign or stitched acceptance was used.

Lean4.33.1/compiler819816b2e0a3bf405af45ae5c7af2491d8f5bee6,
Mathlib0df444a360eaa60ab8c11dca51a86af692955474. All119buildjobs, registry/CLI and36native
controls passed. The same29owned modules listed earlier yielded4441declarations:
Audit313, AuditApp197, StrictLeanPolicy3931;1649theorems,2359definitions,109recursors,
214constructors,109inductives and1opaque. Exact transitive axiom inventory is retained;
the union is onlyClassical.choice/Quot.sound/propext. All three surfaces remain
Standard-Logical with report execution. Accepted6184project and97documentation jobs;
all94fences passed:70positive,23negative and1teaching.

Observed seconds (nested/concurrent intervals must not be summed as disjoint work):

| Scoped operation | Seconds |
| --- | ---: |
| Seven dependency captures, including bytes and Git | 23.000 |
| Five terminal Lake inventory reloads | 8.706 |
| Git status child time within those captures | 11.055 |
| Complete declaration audit | 98.918 |
| Worker request freeze, including nested rechecks | 15.565 |
| Worker acceptance finalization | 5.760 |
| Parent raw packet read/parse/decode | 5.866 |
| Parent snapshot assembly | 0.423 |
| Parent request freeze | 9.038 |
| Parent acceptance finalization | 5.097 |
| Legacy remap/compress/write | 0.662 |
| Surface packet construction/serialization/write | 2.481 |
| Human execution-boundary rendering/writes | 0.035 |
| Documentation request freeze | 0.001 |
| Fence compilation / inspection | 22.376 / 45.833 |

All182 observed Git status commands succeeded, covering66787 path occurrences across
seven complete captures (9541 per capture). The old64path loop would require154calls per
capture,1078total; the new loop used26per capture,182total. This removes896process starts
by arithmetic on the actual frozen inventory. The remaining Git status child time was
11.055s, so this work is measurable rather than absent; the capture time also includes
source reads and other work. The full local gate passed. No matched whole-run speedup
estimate follows from comparison to historical247.331s or256.157s runs with different
conditions. The retained8311path batch64/512 observation is separate. Hosted margin and
the previous47second parent gap remain UNKNOWN until the outer executor runs exact-head
hosted checks; local timing does not transfer to Linux or prove a universal bound.
All18177human boundary lines exactly match the retained preceding repair's cold log.

The9852-file pre/post hash inventories and actual Lake root/dependency inventories were
identical; HEAD and dirty patch were unchanged throughout. Root bindings include all144
configured library/executable source occurrences, while the positive claim remains29modules.
The tested dirty patch SHA256 was
`3561bc911a3e1c01afbbed030cb68dcb5d7767967999ea60f3231fa93b010048`.
Raw receipts in `tmp/ci-round5/` include inputs-before/after.json, lake-before/after.json,
cold420-result.json, cold420.log, git-trace.jsonl, attribution.json, declaration-axiom-inventory.json,
before/after-controls.json, source-controls.log, output-comparison.json and review.md.

Receipt SHA256:
- `inputs-before.json`: `56343ab7595a960b5d5b35a398b9aef9667113711c22462375cc14e7b9310c0b`.
- `inputs-after.json`: `dfaad97b4e0895e4b5f1bf08be2f103abaa5ade9895cb3cb16ed6663c95367ef`.
- `cold420.log`: `0906f6b8444a2bd8116bed744ad82bfd900a02092f24e31b0bac59469f955388`.
- `tmp/axiom-report.json`: `47081ac777a83a91272aa05049da3e8091d8e74de7bc3ab25ca873f2bafae53b`.

Tested source SHA256:
- `lean/StrictLean/Checker/Snapshot.lean`: `1aa6492c439179e61d5a2199b740072f8260bcf4f2142263e15049a39e76ed4b`.
- `lean/StrictLean/Checker/AxiomGate.lean`: `14013365bdd4245c49a0127a29c2369170a4c11f898b6578ca43426b16ded430`.
- `lean/StrictLean/Checker/Documentation.lean`: `97ee067f6bf61a9b791008825af0c02c8b6cf12da436f58bb01a5124663514c1`.
- `.agents/skills/lean-ci/SKILL.md`: `b309b152d696dc21862e16e1e4785cc7ba090d9f515264ef52afe8d65fd8405c`.

This evidence section was appended after the successful frozen-input run; it is an
evidence-only change, not a changed Lean/configuration/test input. Executable sources and
skill text still match the tested hashes. Normative meaning, public adapters and policies
are unchanged; no normative prose, fixture, manifest or CI command update was needed.

Preserved limits: the original60s adopter timeout stays INCOMPLETE; separate120s/71.233s
diagnostic remains distinct. The packet aggregate420 timeout after eight passes remains
INCOMPLETE; separate61.222s restoration does not convert it to aggregate PASS. Historical
exact-f4b8 local247.331214458s and forced-collector273.587434292s results remain scoped to
their original inputs. P3 historical-status prose remains explicitly deferred to issue14.
The outer executor owns signed publication, exact-head hosted verification including the
Linux producer/rule-example pair and all other checks, merge and cleanup. This is not
CI-ready, issue7closure, full repository compliance or verified compiled-runtime semantics.


## CI gate 6 — same-predicate plan and completeness decisions

Subject: HEAD `2976130c3e3b58373910f934d3d4fd93dea83c07`, tree `3bdb829d19f7ade99f4400db39a5ce7461b5644a`, plus the
reviewed dirty patch `6d89373d737589a2370227b668b29d20766fba9a68ce174251549d2dfe5eb8be`. This is the assigned CI repair
inside the existing pipeline; no pipeline control, push, PR update or hosted rerun
was performed. Hosted297 failed the hard420 gate at documentation inspection;
its full failed log is retained at `tmp/ci-round6/hosted-full.log`, SHA256
`1ae81eec2041528973365178ff5ec2bc6070a79581b7814e669d1f75b673011e`. Prior receipts remain intact.

### Exact repair and preservation interfaces

Changed executable/proof files:
- `lean/StrictLeanPolicy/Acceptance.lean`
- `lean/StrictLeanPolicy/Plan.lean`
- `lean/StrictLean/Checker/Acceptance.lean`
- `lean/StrictLean/Checker/AxiomGate.lean`

`CompleteFor` itself is unchanged. For every implicit `c : Claim`, `i : Census`,
`p : Plan c i`, and `s : ResultTable p`, `completeFor_iff_slots` proves precisely
`CompleteFor p s ↔ ∀ slot ∈ List.range p.jobs.size, ∃ o ∈ s.entries[slot]?,
o.completion = .completed`. The reverse implication pairs slot evidence with the
same `p.valid`. The executable instance transfers the slot decision through this iff;
it never obtains validity from a worker flag and still inspects every required lookup/status.
`completeFor_decide_eq_previous` equates its Boolean result to the former structural
conjunction decision. `accept_decision_eq` and `finalize_decision_eq` quantify arbitrary
decisions of the same proposition and equate complete Except results, preserving
incomplete-before-policy refusal, collection failures before acceptance, exact collected
tables, input multiplicity and accepted report identity. The old decision is an instance
of these universal equalities; no sampled-agreement premise is used.

Plan optimization is deliberately limited to the original required-job uniqueness clause.
`requiredJobs_distinct_iff c i` specializes the established `distinct_iff` to the exact
`(requiredJobs c i).toList : List (Stage × JobSubject)`. There is no replacement by
full JobKey uniqueness and no differently projected relation. Local BEq is `decide (a = b)`
on the full pair; LawfulBEq and LawfulHashable are proved. The bucket hash uses structural
names or fence URI/body position, omitting stage and other fields only from bucket selection.
Full equality retains every stage/constructor/key/snapshot/source/expectation field and
resolves collisions. `planOK_decide_eq_previous` and `admitPlan_decision_eq` preserve the
same predicate and all candidate-admission outcomes, including ordered exactJobs, exactClaim
and original refusal precedence. Untrusted candidates still run PlanOK. Census decisions,
observation association, collector multiplicity and required domain construction are unchanged.
No membership index, observation index or general key framework was added.

Inner timers remain solely in Checker IO. Pure computations are suspended by IO.lazyPure.
`finish` now returns IO to expose construction, collection and acceptance separately;
every computed collection/acceptance result carries its defining equality. The final
result subtype requires equality to the original pure `finalize`, discharged using
`finalize_collection_error` and `finalize_of_collected`. Proof erasure leaves one collector
and one acceptance call, with the same error rendering. All three AxiomGate callers were
adapted. Worker acceptance and parent independent reconstruction remain required.
Snapshot IO, raw report validation, producer reconciliation and human output remain.
The source/theorem map in `docs/guides/policy-acceptance.md` now describes this exact linkage.

### Checks, independent review and identities

Focused Lake builds PASS; all nine new correspondence theorems were inspected with
#print axioms: each has exactly propext, Quot.sound and Classical.choice. No new axiom,
hole, unsafe escape or IO dependency was added to StrictLeanPolicy. Complete fresh
owned admission and per-declaration axiom coverage also passed in the whole gate.

Two fresh-context Codex/gpt-6-astra/medium reviewers independently returned CLEAN:
proof contracts/equality/hash laws and IO/caller/generated-code linkage. Their scoped
coverage and limits are retained in `tmp/ci-round6/reviews.md`. Generated C confirmed
that CompleteFor no longer calls PlanOK, the requiredJobs hash index executes at plan
admission, and timed computations stay inside lazy IO closures. The later one-sentence
source-map correction received a separate CLEAN documentation follow-up. These reviews
are scoped, not full repository-compliance or compiler-correctness claims.

25 executable pure decision/collector controls PASS (`Controls.lean`, `controls.log`):
deliberately colliding fence buckets with different expectations/source bytes, identical
duplicates, mandatory empty-domain slots, missing entries, duplicate/conflicting entries,
unknown keys, wrong key/snapshot bindings, all four noncompleted statuses before policy
failure, wrong policy, ordered/omitted/repeated plan jobs, invalid census, restoration and
report identity. The universal correspondence proofs establish preservation; these controls
only qualify executed interfaces on the pinned runtime.

Public native fresh-file positive / project-axiom SL1001 violation / fresh restored
positive controls PASS after the cold rebuild. Exact output Producer identity is
`2976130c3e3b58373910f934d3d4fd93dea83c07:unreleased-worktree`; binary SHA256 is recorded per phase in
`file-controls.json`. Rejected output contains no acceptance. An earlier attempt used a
fixture name already declared by Lean and failed SL2003; it was corrected and its receipt
is preserved as fixture-setup-*. The first passing pre-cold sequence had inherited
`f4b8fca809ca30e0ab329d79edab8a0d562def3a:unreleased-worktree` from old Producer artifacts.
It remains under pre-cold-file-controls and is NOT evidence for the current request.
The entire focused sequence was repeated using the newly rebuilt 297 dirty producer.
An interpreted inventory helper hit Lean's IR-interpreter unreachable assertion; its log
is preserved. A native helper using actual Lake.surfaceInventory supplied the successful
pre/post inventories. Neither failed setup attempt is relabeled PASS.

The system skill-creator validator passed for the concise generally applicable provenance
lesson in `.agents/skills/lean-ci/SKILL.md`: elaboration-captured HEAD/dirty/configuration
is a build input; equal code bytes are not same-request evidence; rebuild when identity
changes and never transfer old Accepted artifacts. No private paths/details were added there.

### One complete cold-root gate

Actual unmodified `./scripts/verify.sh`: **PASS**, exit 0,
**236.480728959s**, hard 420-second owner unchanged. Root .lake/build was absent at entry;
prior root outputs/report were moved into tmp/ci-round6 and not reused by acceptance.
Pinned dependency artifacts and GNU timeout/ShellCheck were already provisioned; no
package/application/global configuration was changed. There was no standalone benchmark,
partitioned acceptance, timeout override, cached acceptance or second whole-gate attempt.

Tested Lean 4.33.1/compiler 819816b2e0a3bf405af45ae5c7af2491d8f5bee6 and
Mathlib 0df444a360eaa60ab8c11dca51a86af692955474. All 119 build jobs, registry/CLI and 36 native
source controls passed. The same 29 Lake-owned modules yielded 4465 declarations:
Audit 313, AuditApp 197, StrictLeanPolicy 3955; 1667 theorems, 2365 definitions, 109 recursors,
214 constructors, 109 inductives, 1 opaque. The exact module lists and every declaration's
module/name/kind/axioms are retained in coverage.json and declaration-axiom-inventory.json.
Axiom union is only Classical.choice/Quot.sound/propext. All three surfaces retain
Standard-Logical/report mode. Accepted 6211 project and 97 documentation jobs; all 94 fences
passed (70 positive, 23 negative, 1 trusted teaching). Counts are coverage observations, not proofs.

All 9852 pre/post input hashes, canonical paths and actual Lake root/dependency inventories
were unchanged; HEAD and dirty patch also remained identical during the run. The rebuilt
binary reports `2976130c3e3b58373910f934d3d4fd93dea83c07:unreleased-worktree`. This is the actual tested
request identity, not a clean published-head run or a transferable Accepted certificate.

| Whole-gate inner interval | Worker seconds | Parent seconds |
| --- | ---: | ---: |
| Raw report/source/transcript validation (three reports summed per coordinator) | 3.064 | 2.886 |
| Plan construction/admission | 3.445 | 3.124 |
| Observation construction | 0.082 | 0.083 |
| Result collection | 0.003 | 0.003 |
| Completion and all-policy acceptance | 2.364 | 2.006 |
| Outer request freeze | 14.987 | 8.631 |
| Outer finalization | 2.450 | 2.093 |

Complete declaration audit 87.629s; packet parse/decode 5.808s; fence compilation 20.778s,
fence inspection 45.080s. Full phase arrays are in attribution.json. Outer and inner
intervals overlap/nest; they are not additive CPU measurements. Generated linkage shows
that the repeated PlanOK decision is absent and the exact index is used in measured plan
work. The new measurements do not isolate the old individual clauses or establish a
matched causal speedup. Historical clean 297 local 245.680411292s and hosted 420 failure have
different request/environment identities. Sufficient hosted savings remain UNKNOWN.
No additional Census/observation optimization is justified or attempted by these receipts.

Receipt hashes:

- cold420.log: `4e00188eda86cedc9a0bf7413233aebb6861b04d64e602abe779f8fcf595caa9`
- fresh legacy report: `4e878b3799ab3171d94f03cc117d51c567eca90449deb7db83d024c14b09f9e4`
- inputs-before.json: `4ff2989a59864592b160e6423fc4413f4af9e915f821ded445f1fdcca1b75294`
- inputs-after.json: `d76f7d018e72f96cdf2a8137ee7b74a32d6f4a511cf716a7bbd0b207bde9e23b`

Raw receipts, complete command output, failed hosted log, compiled registry identity,
reviewed source hashes, native inventory helper and qualification recipes remain under
`tmp/ci-round6/`. The five reviewed/tested source/skill hashes remain unchanged. The
one-sentence source-map correction and this evidence section were written AFTER the cold
run and recorded separately in final-state.json; no same-request identity is claimed for
that later documentation tree. The outer executor owns final signed-head qualification.
No normative rule, fixture/manifest inventory, runner, deadline or CI command changed.

### Preserved limits and next owner

Historical original 60s adopter timeout remains INCOMPLETE versus the separate 120s/71.233s
diagnostic. Packet 420 aggregate timeout after eight passes remains INCOMPLETE versus the
separate 61.222s restoration. Historical f4b8 forced-collector 273.587s evidence is reused only
for unchanged collection/source-exclusion capabilities under the prior explicit scope;
it is neither a new 297 execution nor repeated merely for relabeling. The new universal
same-proposition/outcome equalities and focused controls cover this decision repair;
transport/parser/snapshot/role/exclusion implementations are unchanged. No unrun broad
campaign is claimed PASS. P3 remains the nonblocking issue 14 carry; no #14/#15/#10 work occurred.

The outer executor must still establish exact published-head local/hosted qualification,
including Linux producer/rule-example and Verso checks. This local result is not checks-ready,
issue 7 closure or integrated delivery. If the next hosted whole gate fails, the authorized
stop condition requires a concrete Firstmate design/runner disposition, not another
automatic microfix chain. Remaining trust includes truthful IO/Lake/environment extraction,
source/serialization/provenance acquisition, compiler/native runtime, external processes
and OS scheduling. The con-leche-inspired fixed-request collection proofs do not verify
those external systems or prove a universal 420-second runtime bound.


## Approved diagnostic-budget follow-up (2026-09-17)

The [diagnostic budget record](issue-7-diagnostic-budget.md) supersedes the pending
combined producer/history gate with two required sequential hard420 invocations.
The explicit combined allowance is up to840; ordinary cold420 and full diagnostic
coverage/order are unchanged. Baseline `0d2d6142192967f4873305cbf1ec5d8227607a36`
passed ordinary hosted acceptance but failed combined420 with history incomplete.
The historical failure remains a failure. The restarted terminal pipeline cannot be
resumed; a signed preserved-branch follow-up and fresh full validation own final-head
local/hosted evidence and independent delta review. This entry claims no new Lean run.
