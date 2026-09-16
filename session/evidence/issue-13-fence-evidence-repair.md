# Issue 13: grouped-fence typed evidence repair

Starting HEAD: `f8b383ff34b82aa678372b0be047c4a9696dbcaa`.
Comparison base: `b64747b7ce16d5850c11f9798d46dfa5fe5b9b17`.
This records the authorized R7 repair inside the existing review phase. Issue #13
remains partial; signed commits, ordinary420, authoritative test/lint, exact-head CI
and integration remain the outer executor's responsibility.

## Finding and implementation linkage

R7 was confirmed by tracing an omitted consumer of the existing typed outcome.
`inspectGroupWorker` called the throwing compatibility loader, so a malformed
fence-owned declaration range lost its `AdmissionFailure` classification before
`Documentation.auditTasks`. The catch produced only SL4002/incomplete.

The worker now uses `loadReportCurrentSearchPathOutcome` and serializes the existing
`ProducerReport.Outcome` inside the unchanged request-bound worker packet. Its old
`GroupReport` codec, which transported an always-empty transcript array, is removed.
The coordinator decodes that strict outcome, checks the original frozen sources,
and returns `Except AdmissionFailure GroupReport`. Successful reports retain their
source/census/transcript checks. Documentation retains the typed failure and emits
SL2005/incomplete with its original detail alongside SL4002 (or SL4004 for teaching).
The location is the actual fence context, never a manufactured declaration range.
Generic exceptions do not acquire typed admission authority.

The consumer audit covered project/incremental declaration workers, file inspection,
grouped documentation, and CheckerSelftest. Project/file paths already preserve the
typed result. The selftest explicitly renders its typed failure as fixture failure.
The compatibility `Environment.loadReport`, `SourceAudit.inspectCurrentSearchPath`,
and `compileAndInspect` paths have no current public diagnostic callers; their
throwing wrappers do not feed another public registry adapter. No other analogous
public omission was found.

This changes transport and rendering, not the source-range predicate, kernel replay,
closure admission or pure proofs. Existing implementation-linked refusal guarantees
and their conditional proof/axiom evidence remain unchanged. No new pure proof or
axiom check is claimed. Compiler, IO, extraction, imported-base trust and the limits
of before/after equality remain unchanged. Applicable scope is documentation source
admission and diagnostic preservation under module 8, DOC-04/05 and MUT-02–04, not
whole-standard conformance or global Accepted.

## Focused verification

Pinned Lean: `4.33.1`, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`.
Mathlib remains locked to `0df444a360eaa60ab8c11dca51a86af692955474`.

Commands for the single focused repair round:

```sh
lake build axiomGate docFenceAudit +StrictLean.Checker.CheckerSelftest:olean
python3 scripts/fence_evidence_checks.py
```

The initial build found a record-literal syntax error in the new failure mapping.
After correcting that syntax, the focused build passed (97 jobs). See
[initial build](issue-13-fence-evidence-repair-build-initial.txt) and
[successful build](issue-13-fence-evidence-repair-build.txt).

All **18 public invocations** passed; see
[qualification output](issue-13-fence-evidence-repair-qualification.txt).
Each of `docFenceAudit` and `axiomGate --with-docs` ran an initial positive followed
by four isolated negatives and their fresh restored positives. Project source stays
valid and unchanged; the Markdown fence alone receives each mutation:

- Line-zero range metadata: exactly SL4002 plus SL2005/incomplete and the original
  `producer-source: source coverage or coordinates mismatch` detail.
- Invalid owned kernel replay: the same IDs/impact and original kernel-admission
  reason identifying `admissionFalse`.
- Ordinary owned axiom: SL4002 plus SL1001/violation, without SL2005.
- Compiler type error: SL4002/violation, without SL2005.

The first three controls require the actual grouped inspection phase. Canonical
combined output checks the complete ordered diagnostic set, modes, impacts, original
typed detail and fence context; restored controls require completed status, no
findings and one positive pass. Root build artifacts are cleared before every
invocation. These are diagnostic observations, not universal extraction or transport
authenticity proofs. No full repository suite, ordinary420 or CI ran in this phase. No pre-repair runtime
reproduction is claimed; the original defect was confirmed by source tracing.

## Independent focused re-review

The two distinct prior review contexts independently inspected the frozen R7 repair
using Codex `gpt-6-astra`, supported `high` effort, without edits, builds, tests,
delegation or pipeline control:

- `/root/branch_semantic_review`: CLEAN for typed failure preservation, fence context,
  unchanged refusal semantics and all existing public consumers.
- `/root/branch_compiler_review`: CLEAN for exact packet/source binding, strict outcome
  decoding, successful-report checks and public consumer coverage.

Both were informed of the subsequent syntax-only correction. These are focused
follow-ups, not fresh full-branch or full-conformance verdicts. The prior R6 combined
controls mutated `Example.lean` before documentation inspection. They did not qualify
fence-local refusal; the earlier claim of complete malformed-range propagation is
superseded for this path. The distinct full-branch reviews retain only their unaffected
scope, as recorded in `issue-13-full-branch-review.md`.
