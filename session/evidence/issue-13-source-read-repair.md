# Frozen evidence read failure repair

Starting HEAD: `f7dfff2531fc0076d2558242dffcd46018c81455`.
Full branch comparison base: `b64747b7ce16d5850c11f9798d46dfa5fe5b9b17`.
This records working-tree R4 repairs in the existing no-mistakes review phase.
Signed commits, ordinary420, authoritative test/lint phases, exact-head CI and delivery
remain owned by the outer executor. Issue #13 remains partial; no Accepted or full
repository-conformance claim is made here.

## Defect and shared boundary

The prior missing-source control expected SL2001 after successful source capture. That
observed result contradicted the registry's SL2005 contract for missing/invalid owned
source evidence. The old transcript is retained as history, not qualification of this
contract; the earlier repair record now states that limitation explicitly.

`SourceBinding.unchanged` now normalizes only errors re-reading an already frozen source,
retaining module, path and the original IO detail under the existing `producer-source:`
classification. The existing public adapter constructs SL2005/incomplete. Successful
reads still require exact equality. Initial capture and genuine setup errors are unchanged.

Two independent full-branch reviews found three related omitted paths. The repairs reuse
the same owners: `configurationUnchanged` locally normalizes errors re-reading frozen
configuration; `auditFile` routes its original-file check through `unchanged`; combined
mode checks retained parent snapshots after its declaration worker exits and before
returning even a failed worker result. No global IO remap, new worker protocol, filesystem
lock or stronger process threat model was introduced.

No pure theorem, closure relation or admission-proof definition changed. The existing
conditional proofs about executed admission and supplied closure records remain applicable.
The added exception handling is an operational guard, not a machine-checked filesystem,
compiler, source-authenticity or change-and-restore theorem.

## Focused execution evidence

Pinned Lean: `4.33.1`, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`.
Mathlib lock: `0df444a360eaa60ab8c11dca51a86af692955474`.

The final focused round completed with exit zero:

```sh
lake build axiomGate docFenceAudit
python3 scripts/documentation_source_checks.py --source-read-only
```

The build completed successfully over 93 jobs, including the affected `SourceBinding`,
`AxiomGate`, `Environment`, `SourceAudit`, `Documentation` and `DocFenceAudit` dependencies
and executables. [Build output](issue-13-source-read-repair-build.txt).
This is compilation of the changed paths, not a new complete module/declaration/axiom audit.

All **28 public invocations** passed. [Qualification output](issue-13-source-read-repair-qualification.txt).

- Seven each through standalone `docFenceAudit` and combined `axiomGate --with-docs`:
  positive, frozen source removal, restored, frozen source made unreadable by directory
  substitution, restored, frozen manifest made unreadable, restored.
- One initial missing project source remains SL2001/incomplete; the next positive restores it.
- Six original `--file` controls: initial missing source SL2001, positive, frozen original
  removed, restored, frozen original made unreadable, restored. The file lies outside the
  configured library inventory, so dependency checks cannot mask the original-file check.
- Seven combined declaration-build controls: positive, source text changed, restored,
  source removed, restored, source made unreadable, restored. These qualify the worker
  failure path before fence compilation, separately from the fence controls.

All combined/file frozen-evidence failures require exactly SL2005 and incomplete status,
with the intended snapshot reason and original missing-file/directory IO detail where
applicable. Positives require completed results without diagnostics and preserve their
proposition/proof. Each public audit uses fresh isolated artifacts for restored controls.
Initial setup is separately required to remain SL2001. These observations qualify the
exercised IO/transport paths, not universal correctness.

An earlier focused round with only the initial shared-source repair passed its 11 controls;
the full-branch findings invalidated any broader closure claim. The final round above
covers those additional repaired paths. Unchanged append/removal configuration and other
history/closure controls were not rerun here; their historical evidence keeps its original
scope. No complete repository suite or acceptance run was executed in this review phase.

## Independent review and remaining delivery

[Full-branch review evidence](issue-13-full-branch-review.md) records two distinct fresh
Codex `gpt-6-astra` high-effort semantic and Lean/compiler/transport contexts, the findings
they made, and CLEAN focused follow-ups after repair. Those full-branch reviews are separate
from earlier focused repair contexts. The reviewed proof/trust limits remain explicit.

The next pipeline phases must run the required ordinary420 and other authoritative gates,
produce signed fix commits and verify exact reviewed-head CI before protected integration.
These scoped results do not complete ENGINE-01/#13, its twenty-rule corpus, or Project 8.
