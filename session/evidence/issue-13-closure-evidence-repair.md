# Reflexive simplification and typed source-evidence repair

Starting HEAD: `e58c783be00134d88ec192b575316cf7873b9887`.
Branch comparison base: `b64747b7ce16d5850c11f9798d46dfa5fe5b9b17`.
This is the existing no-mistakes review phase, covering authorized R5/R6 repairs.
The outer executor retains signed commits, ordinary420, authoritative test/lint,
exact-head CI and protected integration. Issue #13 remains partial and open.

## Executed definitions and unchanged guarantees

R5 was an extraction/invariant mismatch: the candidate extractor discarded equal
constant heads, although pinned Lean admits an active reflexive `csimp` replacement.
Removing that exclusion retains the required candidate for every such active edge.
`ExecutionClosure.Valid`, its active-edge subset requirement, discovery witnesses,
all admission proofs and replacement-only-cycle detection are unchanged. An active
self-edge remains SL3001/incomplete; an inactive reflexive candidate is not an active
cycle. Ordinary recursive IR edges still use visited closure and remain separate.

R6 was a typed-refusal transport gap. The existing source-map/range predicate now has
one owner, `ProducerReport.Environment.validateSourceEvidence`, returning
`Except AdmissionFailure Unit`. The loader returns that exact typed failure before
full report admission, while `Environment.validate` and its decoder call the same
guard and preserve the original detail. Existing `Outcome.admissionFailed`, worker
packet/request/source binding and parent adapters deliver SL2005/incomplete. No
exception substring creates this outcome, and generic setup exceptions keep their
existing paths. Invalid ranges remain rejected; diagnostics use project/file context
rather than inventing a source coordinate.

No pure proof definition or theorem statement was altered, so no new theorem axiom
check is claimed or required by this repair. Prior proof evidence retains its exact
conditional scope. The producer helper is compiled Lean code reusing the unchanged
predicate, not an independent model. Compiler/IO/extraction and imported-library
trust, the change-and-restore limitation, and global Accepted obligations remain.

## Focused verification

Pinned Lean: `4.33.1`, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`.
Mathlib lock: `0df444a360eaa60ab8c11dca51a86af692955474`.

After all implementation/qualification fixes, this single focused round exited zero:

```sh
lake build axiomGate
python3 scripts/closure_evidence_checks.py
```

The build completed successfully over 90 jobs, compiling the changed `StrictLean.Probe`,
`Checker.ProducerReport`, `Checker.Environment` and their affected executable dependencies.
See [build output](issue-13-closure-evidence-repair-build.txt). This is not a fresh complete
declaration/axiom census or ordinary acceptance run.

All **18 actual public invocations** passed. See
[qualification output](issue-13-closure-evidence-repair-qualification.txt).

- Reflexive simplification: fresh and incremental project each run inactive positive,
  active-cycle negative and restored inactive positive. The canonical report retains
  the self candidate in all three; only the active case has the active self-edge and
  unresolved cycle. It must emit exactly SL3001/incomplete for the replacement-only
  cycle. Every phase also requires an ordinary recursive function's retained IR
  self-edge without unresolved execution.
- Source ranges: fresh project, incremental project, file and combined documentation
  each run a positive range, actual line-zero metadata installed through Lean's
  `addDeclarationRanges`, and a fresh restored positive. The proposition and proof
  remain unchanged. Negatives require exactly SL2005/incomplete and the original
  `producer-source: source coverage or coordinates mismatch` detail, with no invented
  source-range location. Positives require completed status and no diagnostics.

Every restoration clears adopter root build output, and result paths are unique.
The defects were confirmed by source/API tracing before repair; no pre-repair runtime
reproduction is claimed. The observations qualify these actual paths, not universal
collector or serialization authenticity. Unchanged campaigns were not rerun, and no
complete repository test/lint or ordinary420 command ran in this phase.

## Independent recheck of invalidated review claims

The distinct semantic and compiler/transport contexts from the prior full-branch
review each inspected the frozen R5/R6 repair using Codex `gpt-6-astra`, supported
`high` effort. They did not edit, run builds/tests, delegate or control the pipeline.

- `/root/branch_semantic_review`: **CLEAN**. Reflexive candidates preserve the active
  subset invariant and cycle distinction; the typed helper preserves the prior
  predicate exactly and links loader/decoder refusal. Guide and qualification scope
  match the code; closure proofs remain unchanged.
- `/root/branch_compiler_review`: **CLEAN**. Extraction now matches pinned Lean's
  constant-replacement shape; typed refusal reaches all four qualified public paths
  while setup exceptions remain separate. No further defect found in this repair.

These are focused follow-ups, not new full-branch reviews. Earlier full-branch claims
about reflexive candidate completeness and malformed-range propagation were invalidated
by R5/R6 and are superseded here; unaffected review evidence keeps its original scope.
Ordinary420, exact-head CI and the remaining ENGINE-01/#13 work remain outer-pipeline gates.

R7 qualification correction: the combined-mode range control above mutates project
`Example.lean`, so it fails before fence inspection. It does not establish typed
propagation for a mutation inside a Markdown fence. That omitted consumer and the
invalidated review claim are repaired and separately qualified in
[the grouped-fence repair record](issue-13-fence-evidence-repair.md).
