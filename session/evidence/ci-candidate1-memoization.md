# Candidate1: invocation-local compiler dependency memoization

## Subject and implementation linkage

Starting HEAD: `b424d47c9477df2868c08504987e692b5ef19e8c`, tree
`1b3b4ae9b1cc18c803ed5f036e65694d82e9b939`. This is a dirty-worktree repair,
not a published-head result. Only `lean/StrictLean/Probe.lean` changes executable
source, with SHA256 `e108e415227dbf08dba83a89293e7a97ff7fb940556f954d88b77e1155b73123`.
This handoff and its index link were added after targeted qualification.

The private `compilerDependencies env name` returns `none` for absent
`Lean.IR.findEnvDecl env name`; otherwise it returns exactly
`some (((Lean.IR.CollectUsedDecls.collectDecl compiled env).run {}).snd.order)`.
It reuses the pinned `Lean/Compiler/IR/EmitUtil.lean` collector without filtering,
sorting, or conflating absent and empty IR. `CompilerDependenciesCache env` is a
private `Std.DHashMap` whose value at `name` is
`{ dependencies : Option (Array Name) // dependencies = compilerDependencies env name }`.
Each payload therefore proves the required equality at its environment and key.
A hit returns the stored witness and unchanged map; a miss computes the original
expression once and inserts its reflexive witness. Lawful dependent lookup supplies
key transport and collision handling.

`environmentReport` creates one private reference before sequential root traversal;
`executionWalk` uses `IO.Ref.modifyGet` at the original lookup site. No state crosses
invocations, environments, processes, requests, or worker serialization. Exact
ordered-array equality preserves the consumer transition by substitution, including
queue order, visit parents, compiler edges and compiled-code obligations. Root
census, logical edges, initializer references, actual self edges, extern behavior,
history callbacks/requests, Meta operations, correspondence admission, source/config
checks and policy finalization retain their original boundaries. The con-leche-inspired
accepted-result integration is unchanged; this cache supplies no acceptance authority.

## Proofs, checks and independent review

Five private theorems quantify over arbitrary captured environment, name and typed cache:

- `compilerDependenciesLookup_exact`: returned value equals the original derivation.
- `compilerDependenciesLookup_hit`: a hit returns the stored witness and unchanged map.
- `compilerDependenciesLookup_miss`: a miss returns/inserts the reflexive original value.
- `compilerDependenciesLookup_stored`: the resulting map contains the returned witness.
- `compilerDependenciesLookup_frame`: a distinct key's lookup remains unchanged.

All five exact transitive axiom sets are `propext`, `Classical.choice`, `Quot.sound`
(Standard-Logical). Elaborated signatures and axioms are in
`tmp/ci-candidate1/cache-qualification.log`. These proofs establish equality to the
existing partial collector, not its termination/IR semantics, IO freshness,
machine-code correctness, OS scheduling, or runtime bounds.

Tested Lean 4.33.1/compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`, Mathlib
`0df444a360eaa60ab8c11dca51a86af692955474`:

- Pinned dependency setup `lake exe cache get` completed; setup is not acceptance.
- `lake build +StrictLean.Probe:olean`: PASS, including all five proofs.
- `lake build axiomGate +StrictLean.Checker.HistoryQualification:olean +StrictLean.Probe:c`: PASS.
- Executable equality: PASS for 12 same-environment keys over three passes, exact
  ordered `Option` arrays, cache-domain preservation, absent IR, present empty body,
  extern, initializer and actual recursive self edge. This is scoped observation.
- Generated C inspection confirmed one collector call only in the miss branch,
  hit reuse, and the shared reference. This is not a compiler-correctness proof.
- Fresh-context independent proof/integration review: CLEAN at the source hash
  above; fixer and reviewer both explicitly configured `gpt-6-astra`/`medium`.
  Scope covers dependent interfaces/proof linkage, COMP-01/03/04, DOC-02,
  DOGFOOD-03/04 and applicable MUT-02–04 obligations, not full conformance.
- `git diff --check`: PASS.

The first temporary qualification driver omitted `enableInitializersExecution`
and failed before fixture import. Only that driver was corrected; its failed log
is retained as `cache-qualification-initializer-setup-failure.log`.
The actual targeted binary registry reports
`b424d47c9477df2868c08504987e692b5ef19e8c:unreleased-worktree`, Lean4.33.1,
producer version `unreleased`. This is not an exact published-head certificate.

## Incomplete qualification and compiler contention

Exactly one `scripts/history_checks.py` run under `gtimeout --signal=KILL 420s`
was killed at the deadline (`real 420.07`): **INCOMPLETE**, not PASS. Fourteen of
seventeen public invocation phases passed: all fresh/incremental project controls,
then file positive, unsupported-history, restored and invalid-owned-admission.
The final file restoration, source-change and restoration lack completed evidence.
All seventeen decoder mutation/restoration controls passed, including missing-code
account, omitted roots/visits/boundaries, cyclic discovery, wrong module, and
history/source binding. No retry or deadline change occurred. Surviving same-run
reports and source scratch remain at `tmp/history-controls-zil0atso`.

The mandatory process-only scan before the first compiler launch was empty.
After qualification, a competing workload was present: the root's fresh scan
confirmed Lean PID `37013` (parent `37008`) and Lake PID `55774` (parent `37013`).
No external project files/cwd were inspected or processes controlled. Owned
compiler descendants had exited. Under the allocation's explicit contention stop
condition, ordinary cold `./scripts/verify.sh` was **NOT STARTED**. No old receipt
substitutes for the changed executable inputs; current acceptance remains unresolved.

Raw logs, ordered-array observations, targeted source/config/dependency identity,
producer registry, binary/olean/generated-C hashes and independent review remain
under `tmp/ci-candidate1/`. File identity capture is an operational byte record,
not a substitute for Lake-semantic admission inventory. Original failed hosted
receipts and the diagnostic-retirement record remain intact.

No runner, deadline, coverage, rule, acceptance predicate, pipeline control,
dispatch, publication or caller file changed. Candidate2 was not implemented.
The outer executor owns slot reconciliation, remaining qualification, the unrun
single changed-input cold420, and exact-head hosted verification plus separate
required producer/history/corpus/site checks. No saved seconds, CI closure, full
conformance or merged delivery is claimed.
