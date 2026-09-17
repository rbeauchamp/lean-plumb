# Issue 13: frozen-input ownership on failed exits

Starting HEAD: `94070754107360f414392f4744be38a119e4d584`.
Comparison base: `b64747b7ce16d5850c11f9798d46dfa5fe5b9b17`.
R8/R9 are authorized repairs inside the existing review phase. Issue #13 remains
partial; ordinary420, signed pipeline commits, exact-head CI and integration remain
outer-executor gates.

## Structural invariant and trust

The earlier R4/R6/R7 repairs preserved individual typed paths but did not account
for every failed exit of a frozen-input owner. R8 and R9 were confirmed by tracing
those exits. `SourceBinding.withUnchanged` now owns a single ordering: check captured
sources/configuration, retain the operation's result or IO exception, check those
same snapshots again, then return a typed snapshot failure or preserve the original
result/exception. The shared comparisons preserve original IO detail. No generic
exception string authorizes admission failure; the old CLI prefix remap is removed.
Pure report/source and transcript binding checks also return the existing typed
`AdmissionFailure`. No range, replay, execution or ownership predicate is weakened.

This is structural reasoning about the executed IO owner, compiler checked, not a
pure theorem about filesystem behavior. No pure proof or theorem statement changes.
All prior proof/axiom evidence keeps its original conditional domain. Filesystem,
Lean/compiler/extraction, imported base and serialized transport authenticity remain
trusted boundaries; before/after equality does not detect change-and-restore.

## Producer/consumer and exit inventory

| Owner | Frozen inputs and covered operation/exits | Consumer |
| --- | --- | --- |
| `SourceBinding.capture` / `configuration` | Initial capture; failure before an input is frozen retains setup semantics | Enclosing caller; no generic remap |
| `auditSurfaceAt` | Config before manifest/Lake discovery; source map before build. Nested guards cover build results, IO errors, joined inspections and rendering. Build snapshots are checked before rendering SL2003 | Existing SL2005 context adapter |
| `auditFile` | Config, dependencies and original standalone file before dependency build; all later returns/errors. Original file is included even outside Lake inventory | Existing file context adapter |
| `DocFenceAudit.run` | Copied-project config/source scopes encompass fresh build and documentation, including build rejection/exception | Documentation-mode SL2005 context |
| Combined `auditSurface` | Config guards discovery; parent docs inputs guard child spawn/wait, child return, docs invocation and final result decoding/rendering | Project context adapter or preserved documentation findings |
| `Environment.loadReportCoreAtSearchPath` | Resolved source map guards imports/initializers, replay refusal, selectors, history/probe, validation and successful report | Existing `Except AdmissionFailure Environment` |
| Declaration/group worker adapters | Request snapshots guard all loader/validation exits; original packet remains exact-bound | Existing strict `ProducerReport.Outcome` |
| Group coordinator | Original compiled identities guard capture; captured source map guards process failure, packet/decode/census/transcript and report exits | Typed grouped result; documentation retains fence ID plus SL2005 |
| Direct compilation | Source written before frozen guard; compiler/diagnostic exits, including thrown IO and completed rejection | Typed `Except AdmissionFailure Compilation`; file or selftest consumer |
| Batch compilation | Parent creates exact snippet files before guarded dispatch; workers consume without rewriting. Process/packet/indexed decode and source checks are guarded | Typed batch result; documentation maps refusal to fence findings |
| `inspectOutcome` | Exact compiled snippet guards capture; captured module map guards loader and frontend exits, including typed failures | File adapter |
| `Documentation.auditTasks` | Project/config scope surrounds compilation and all exits; successful batch establishes snippet scope through metadata reads and all inspection groups | Existing typed `Result.admissionFailure` |
| `auditBuiltProject` | Frozen project/config scope covers discovery, tasks, early returns and rendering | SL2005/incomplete; ordinary findings unchanged |
| Compatibility inspection/selftest | Compatibility IO wrappers retain detail; current public registry routes use typed APIs. Compatibility current-search inspection is also guarded | Diagnostic-only failure; no public exception-text classification |
| Frontend/history/diagnostic workers | Existing source observations and specialized unavailability/rejection contracts remain; their enclosing owner independently checks its full frozen map on any return/exception | Existing frontend/history/diagnostic contracts |

Transported failures require valid worker packets. A parent can separately observe
snapshot loss after a crashed worker or malformed packet and return that typed
failure; it does not authenticate or accept the failed worker. If snapshots are
unchanged, original setup/build/compiler/worker/decoder behavior is retained.
These scopes cover completed and exception returns, not a killed coordinator or
arbitrary process compromise. Initial partial file creation remains setup; it does
not claim an already-frozen compilation.

## Verification and review

Pinned Lean: `4.33.1`, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`.
Mathlib lock remains `0df444a360eaa60ab8c11dca51a86af692955474`.
The single focused repair round used:

```sh
lake build axiomGate docFenceAudit +StrictLean.Checker.CheckerSelftest:olean
python3 scripts/frozen_exit_checks.py
python3 scripts/fence_evidence_checks.py
```

The focused build passed (97 jobs). Initial attempts caught an IO monad inference
issue, a missing `do` and a UInt32 result inference issue; all were corrected before
runtime qualification. Review also caught a String/Option field adapter typo before
the first build. See [build attempts](issue-13-frozen-exit-repair-build-attempts.txt)
and [successful build](issue-13-frozen-exit-repair-build.txt). This is compiler evidence
for affected modules, not a complete fresh declaration/axiom census or ordinary420.

All **44 new public invocations** passed:
[exit-path qualification](issue-13-frozen-exit-repair-qualification.txt).
They use disposable adopters within this worktree, clearing root build output and
using unique output files before each invocation:

- Both documentation routes: a fence initializer changes its captured source path
  only during axiomGate import, preserving SL4002 plus SL2005/incomplete. Deleting
  that source and throwing during import yields the same typed classification.
- Both documentation routes: an unchanged initializer throws a message beginning
  with `producer-source:`. It remains only SL4002/incomplete, without SL2005.
- Fresh project, incremental project, file dependency and standalone documentation
  builds: deleting and then reading the source forces an actual build failure;
  missing frozen evidence yields SL2005. Unchanged type-error builds retain their
  original diagnostics (SL2003/incomplete for canonical axiomGate output).
- File dependency building also deletes the independently frozen original standalone
  file; it is refused as SL2005 even though absent from the Lake source inventory.
- Failed snippet compilation in both documentation routes and direct file mode
  retains source-evidence refusal. Lost configuration during a failed project build
  is separately refused as SL2005.
- Positive and restored controls require success; every unexpected SL2005 is refused.
  Canonical output checks the complete expected diagnostic list, incomplete impact,
  original source detail and context location. Import controls require actual grouped
  inspection. These are diagnostic demonstrations, not accepted negative conformance.

All **18 affected R7 fence controls** also passed:
[fence regression output](issue-13-frozen-exit-repair-fences.txt). These retain range
and replay refusal, ordinary axiom/compiler findings and restored positives through
both routes after the compilation/inspection ownership changes.

No pre-repair runtime reproduction is claimed: R8/R9 were confirmed by source and
control-flow tracing. The controls observe the actual public entrypoints; they do
not establish universal extraction or serialization authenticity. Unchanged proofs
and unrelated campaigns were not rerun. No full test/lint suite, ordinary420, push,
PR, CI or integration command ran in this phase.

## Independent final branch and inventory reviews

Two distinct existing contexts used Codex `gpt-6-astra`, supported `high` effort,
without edits, builds/tests, delegation or pipeline control:

- `/root/branch_semantic_review`: CLEAN for the final branch from the comparison
  base plus this repair. Explicitly traced every frozen owner through normal,
  typed-refusal and IO-error returns, checked guide/type wording and demanded the
  unchanged-source exception control. No additional semantic defect found.
- `/root/branch_compiler_review`: CLEAN for that final branch and the recorded
  owner/exit inventory after confirming its field-type correction and the compiler
  annotation fixes. Inspected exact packet/source/census/transcript/history/closure
  linkage and the actual qualification mutations; no additional defect found.

These are final branch re-reviews in the existing independent contexts, not newly
fresh contexts. The earlier distinct fresh full-branch reviews remain recorded in
`issue-13-full-branch-review.md`. R8/R9 supersede earlier broad assertions of complete
source-refusal propagation, including the R7 consumer audit: its range/replay controls
remain valid observations but did not cover snapshot errors or failed build exits.
Completeness of this scoped repair is argued from the owner/exit inventory, not test
counts. Neither these reviews nor qualification close #13 or establish global Accepted.
Ordinary420, signed pipeline commits and exact-head CI remain outer-pipeline gates.
