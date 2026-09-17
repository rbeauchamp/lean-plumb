# ENGINE-01 closure and source binding: scoped implementation evidence

Baseline `b64747b7ce16d5850c11f9798d46dfa5fe5b9b17`; implementation branch
`fm/strict-lean-13-j7`. This is a partial #13 engine increment. The source-owned
twenty-rule corpus and example/demonstration matching are a separate increment.
Neither increment alone establishes issue completion or global `Accepted`.

## Inputs and boundaries

Checker/examples: Lean **4.33.1**, compiler
`819816b2e0a3bf405af45ae5c7af2491d8f5bee6`; Mathlib
`0df444a360eaa60ab8c11dca51a86af692955474`. Root dependency artifacts were provisioned
before qualification. The separate prototype site still selects Lean 4.33.0 and
Verso `3bdedf29bada13d8103e6c979001c51dcee210c8`; its pinned dependencies were provisioned,
but no site build or browser/editor qualification is claimed here.

The [producer guide](../../docs/guides/engine-producers.md) owns the exact API and
trust account. `Probe.executionWalk` records each first visit and its earlier-parent
witness while retaining separate IR, logical, simplification-candidate, historical,
current-replacement and helper edges. `admitExecution` checks this actual data domain.
The operational producer and decoder reconcile boundary channels, module attribution,
history receipts and source coordinates. Source/configuration snapshots are checked at
build, worker and consumer boundaries; exports reuse their original text. Owned replay
failure now remains typed through workers and produces SL2005/incomplete in project/file
entrypoints. Generic import/setup failures retain their own incomplete path.

These observations and guards do not prove compiler/IO authenticity, complete extraction,
machine-code correspondence, or absence of source changes restored between observations.
Source-to-olean correspondence still relies on Lake/compiler/import semantics. No new
profile exception, runtime authorization or local/global acceptance shortcut is introduced.

## Compiler and proof evidence

The following development build passed, including downstream Plan/Observation/Execution
definitions and checker callers of the strengthened domain:

```sh
lake build +StrictLeanPolicy:olean +StrictLean.Checker.CheckerSelftest:olean +StrictLean.Checker.AxiomGate:olean
```

The focused runner also built `axiomGate` and `HistoryQualification` successfully.
The three new theorem declarations in `StrictLeanPolicy/Admission.lean` compiled and their
exact transitive axiom sets were inspected with `#print axioms` under the same pin:

| Declaration | Exact claim | Axioms |
| --- | --- | --- |
| `ExecutionClosure.discovery_induction` | For arbitrary closure/root/edge data satisfying `DiscoveryOK`, every predicate true at the root and preserved by each recorded edge holds at every visit. | `propext`, `Quot.sound` |
| `ExecutionClosure.nodes_induction` | Under `Valid`, the same induction principle holds for every member of the recorded node census. | `propext`, `Classical.choice`, `Quot.sound` |
| `admitExecution_preserves` | For every input array and returned inventory, successful actual admission preserves exactly that array and establishes `ExecutionValid`. | `propext`, `Classical.choice`, `Quot.sound` |

The first proof is strong induction on the earlier-parent index; the second reuses canonical
membership and the first theorem. These are universal proofs about the executed domain and
admission definitions. They establish connectedness of supplied observations, not truth or
completeness of external extraction. The existing `admitExecution_exact` continues to prove
successful admission for every input satisfying the strengthened relation. No new full
module/declaration/axiom census is reported before ordinary acceptance runs.

## Focused operational qualification

The final changed-scope command completed with exit zero in **291.27 seconds**, bounded by
GNU timeout at **420 seconds**:

```sh
/usr/bin/time -p gtimeout --signal=KILL 420s python3 scripts/history_checks.py
```

Only comments/documentation and handoff records changed after this run; no executed
checker or qualification definition changed. The [retained transcript](issue-13-closure-qualification.txt) records:

- **17 actual checker invocations:** fresh project and fresh file each have positive,
  unsupported-history, restored, invalid-owned-admission, restored, changed-source and
  restored controls; incremental project retains positive, unsupported and restored.
- **17 actual decoder mutation/restoration controls:** the prior eight exact history
  refusals, seven closure refusals and two source-binding refusals. Every mutated report
  must fail with its exact intended decoder message, then the original report is re-admitted.
- Positive sources retain both overwritten implementation choices and the current choice
  in their respective channels, the genuine recursive retained-IR self edge, explicit
  private/imported contract roots, and an independently unregistered private declaration
  in the declaration census. Every restored public control clears root build output and
  uses a unique result path.
- Unsupported history yields only SL3001/incomplete. Actual unchecked owned declaration
  admission and source-change controls yield exactly one SL2005/incomplete with the
  respective `kernel-admission`/`admissionFalse` or `producer-source: source snapshot changed`
  detail. Their sources separately elaborated warning-free before these public runs.

The earlier `./scripts/verify.sh diagnostics producers` attempts **failed overall** in the
new history fixture (138.93s and 151.28s). In both, the unchanged producer portion passed:
18 documentation invocations across fresh/incremental/build-lint, eight producer decoder
mutations with restoration, and three standalone controls. That scoped evidence is reused:
the engine and those controls were unchanged during the subsequent history-fixture repair.
The final successful command above does **not** relabel either combined attempt PASS and
does **not** substitute for ordinary acceptance.

### Counterexamples and fixture corrections

The initial recursive control included `@[noinline]`. Its actual frontend transcript used
`Lean.Compiler.inlineAttrs` evaluators with `pinned = false`; the existing generated-helper
exception therefore correctly refused it with SL1006. Its logical helper equality was
exact and axiom-free, but those facts did not discharge evaluator authentication. The final
control reuses the qualified `SafeRecursion.lean` structural shape without this unsupported
attribute path. This is not a claim that `noinline` or Lean recursion is unsound, nor an
extension of generated-role authorization.

An unregistered private declaration was initially asserted to be an ordinary execution root.
That assertion contradicted §8.6: ordinary roots are eligible noninternal definitions and
opaques; §8.12 adds exact registered private/imported roots. The declaration was present in
the independent owned census. The final fixture checks that unregistered case separately
and supplies full-domain `ExecutableContract` theorems for the additional private root and
`Nat.add`. No missing declaration was concealed by registering it.

Two intermediate fixture errors were ordinary compiler failures: proof-valued `def`
registrations triggered `defProp` warnings, and an incorrectly indented unchecked-declaration
record triggered a parse error. Neither qualified SL2005. The corrected theorem registrations
and record syntax elaborated warning-free before the final run. A decoder mutation initially
violated connectedness before channel attribution; moving its historical edge into the
logical channel preserves the graph and isolates the intended channel guard.

## Delivery gates and successor interface

**Pending:** fresh independent semantic and implementation review, focused repair review
if required, full unpartitioned `./scripts/verify.sh` within 420 seconds (including cold root
builds), exact reviewed-head CI, PR publication and Firstmate integration. The current
implementation pause deliberately leaves those gates to the required no-mistakes workflow.
No current full acceptance, full chapter9 conformance, site, editor or latency claim is made.
The older structural campaign's Policy-root manifest reconciliation remains unrun/not PASS.

Review scope includes SCOPE-02/03/05, TYPE-01/02, THEOREM-01 and the relevant
admission/composition claims, DECL-01/02/03/04, COMP-03/04, BUILD-03/04, DOC-01/02/04,
DOGFOOD-03/04 and MUT-02/03/04. These identify review obligations, not completed row verdicts.
The repository-local review skill's semantic/design and Lean/compiler/transport lenses
must remain independently covered inside no-mistakes; pipeline success alone is insufficient.

Copy this settled engine delta into #13/#7/#14/#15/#10 when reconciling verified integration:

1. `ExecutionRoot.closure` is mandatory. `ExecutionVisit` records name, optional observed
   module and earlier parent index. Consumers must retain every channel and unresolved
   path; `compilerEdges` remains retained IR, never the union of conservative candidates.
   `ProducerReport.Environment.validate` and `admitExecution` are the admission boundaries.
2. `ProducerReport.Environment.sourceBindings` records module/path/exact text. Worker
   requests bind these snapshots. `SourceAudit.inspectGroupCurrentSearchPath` accepts
   `compiledSources` from original `Compilation.spec.source`; grouped callers supply them.
   Report coordinates, frontend transcripts and completed owned histories use the same
   text. Schema1 canonical results retain the new fields; legacy display output omits them.
3. `Admission.validate` returns `IO (Except ProducerReport.AdmissionFailure AdmissionReceipt)`;
   `Environment.loadReportOutcome`, `loadReportCurrentSearchPathOutcome` and
   `SourceAudit.inspectOutcome` preserve that failure. `ProducerReport.Outcome` transports
   either a validated report or this completed owned-admission failure. Public project/file
   adapters emit SL2005/incomplete with its original reason; the old IO wrappers remain for
   compatibility. None of these raw records authenticates an arbitrary external producer.
4. #7 still derives fixed claim-bound jobs and constructs global Accepted. #14 still owns
   actual adoption/editor journeys; #15 still owns site assembly/publication. #13 remains
   open for the integrated twenty-rule corpus, exact matching and complete delivery gates.
5. Keep positive/compilerRejection/policyRejection/trustedTeaching. Intentional INCOMPLETE
   SL2001/SL2005/SL3001 cases are separate diagnostic demonstrations requiring authentic
   terminal diagnostics and exact whole expected ID/subreason/location/source/config/mode
   evidence; they remain incomplete. Expected sets may contain several actual findings.
   Crashes, stale/missing results and unrelated failures satisfy neither kind. Corrections
   require completed positive checks. No new synthetic source ranges or suppression fixes.

Lean compiler/API attribution and the contribution-specific con-leche design credit remain
in the producer/design-influences guides. No upstream code or proofs were copied.
