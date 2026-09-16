# Project producer evidence

ENGINE-01's producer increments add independent extraction keys, replay receipts,
completed documentation observations, closure witnesses and source bindings. They do **not** complete ENGINE-01 or
POLICY-04's global `Accepted` construction. The [coverage map](rule-coverage.md) and
[policy acceptance contract](policy-acceptance.md) retain the remaining obligations.

## Implemented paths

`Probe.environmentReport` freezes `(owning module, declaration name)` keys from
`Probe.ownedConstants` before constructing declaration observations. It freezes ordinary
and valid registered executable roots before executing their walks. Registered roots may
be private or imported. All registrations remain in the declaration observations even
when several registrations share one root. No policy-success filter defines either census.
Execution omitted for logical-only fence inspection is `none`; an inspected empty root
set is `some #[]`.

`Admission.validate` returns `IO (Except ProducerReport.AdmissionFailure ProducerReport.AdmissionReceipt)`.
A successful receipt's required keys come from
safe, nonpartial original kernel entries in the replay scope. It calls the same pinned
`Environment.replay`, checks that every required entry is present in the resulting kernel,
and records the admitted keys. Replay scope includes owned dependencies and the existing
reporter closure where required; it may exceed the reported surface. Imported unowned
modules remain trusted. The receipt records this completed operation; serialization does
not authenticate replay and carries no proof of the Lean implementation.

`Environment.loadReportCoreAtSearchPath` loads imported server/private extension data,
freezes the public `@[strict_lean_material]` selector from the completed owned environment,
and calls the existing `Linter.Documentation` observer and `Lean.findDocString?`.
Module observations include declaration-free modules. Markdown and Verso module metadata,
Verso declaration docs and inherited docs follow the same Lean lookup semantics as native
feedback. Private declarations and unregistered public declarations do not acquire SL5002
obligations. Registration completeness and text fidelity remain **R-DOC** review.

The project gate now emits SL5001 for a missing claimed module doc and SL5002 for a missing
docstring on a selected declaration, in both fresh and incremental project modes. It does
not depend on whether native feedback was imported or enabled. SL5001 uses module attribution;
SL5002 uses authenticated declaration ranges when available, otherwise module attribution.
Neither detector imposes headings, lengths, or a universal all-public-declarations rule.
File/fence results retain their existing scoped enforcement; global mode/job composition is #7.

## Transport and consumer boundary

`Report.Collected` adds extraction keys to the pure policy report.
`Checker.ProducerReport.Environment` adds the operational receipts and owns their JSON decoder:

- `census`: requested modules, declaration keys, optional execution root keys and root/module history requests;
- `admission`: replay modules, required keys and observed admitted keys;
- `documentation`: every module's presence, frozen material keys and exact optional docstrings;
- `histories`: one completed source receipt or explicit unavailable outcome for every requested module;
- `sourceBindings`: exact loaded-owned module/path/text snapshots;
- each execution root now retains its `closure` account described below.

Keeping transport validation in the checker layer avoids replaying its implementation from
the force-loaded reporter in every inspection. The trusted loader validates these fields before returning. The operational JSON decoder
validates them again: no duplicate/missing keys, output-derived narrowing, unmatched selector
results, omitted replay receipt, or unmatched required/admitted entries. Project and grouped
fence consumers also compare the census's module array and execution availability with their
original request. A direct interactive `audit_dump_json` has no trusted loader receipt and
cannot pass this decoder. Unknown fields and missing fields are refused. These additional
unreleased report fields live inside the existing registry/result envelope; worker binding
and its version remain separate. `--legacy-json-out` omits the new fields and retains its
prior record shape. Use canonical `--json-out` to consume producer evidence.

These guards reconcile supplied data. They do not prove truthful external extraction, source
identity, a complete execution-edge/history census, or complete claim-indexed jobs. #7 must
bind these raw keys to the exact claim/snapshot and construct the existing pure `Census` and
`AdmissionObservation`; no serialized flag substitutes for that work. #13 still owes exact
policy-example integration, the full twenty-rule source-owned corpus and integrated delivery
evidence; the closure/source increment below does not close the issue. An empty diagnostic list is not `Accepted` or full semantic conformance.

## Source-bound replacement histories

The execution walk registers each `(root, module)` history request before consulting the
loader. Repeated lookups share one module receipt within that report. The loader retains the
Lean-resolved path, exact bytes before and after the isolated worker, and the returned ordered
replacement edges. Its existing worker packet binds the stage, module, path, bytes, producer
and toolchain; changed source or unsupported evaluator paths yield `unavailable`, never a
completed receipt. This also preserves earlier choices overwritten by later attributes.

Producer/decoder admission requires unique requests, exact module receipt coverage in canonical
name order, known roots/modules, nonempty source paths and byte equality. A runtime-replacement
boundary must have a registered request. Completed execution requires its replacement edge in
a completed history; unavailable history requires unresolved execution for every requesting
root. Logical-only inspection has no execution roots, requests or history receipts. Legacy
JSON omits the added history account.

These are linked operational observations under the existing Lean/process/imported-library
trust boundary. They do not authenticate arbitrary serialized source claims or establish the
complete extraction of reached nodes/edges, source authenticity, or global `Accepted`.
The closure/source account below extends the supplied observations and their binding. A
temporarily changed source restored between observations remains outside what before/after
byte equality establishes. #7 retains global claim/job composition.

The `producers` diagnostic now also runs `scripts/history_checks.py`: real fresh/incremental
project and file invocations check overwritten history, an unsupported source evaluator, and
fresh restoration. Actual returned records are mutated through the Lean decoder to qualify
missing requests/receipts/edges, changed bytes, missing paths and concealed unavailability.
The existing structural campaign remains separately scoped; this does not report it PASS.

## Source-owned examples and qualification

The first two source pairs are [SL5001](../../examples/rules/SL5001/) and
[SL5002](../../examples/rules/SL5002/). Each correction preserves exactly
`∀ n : Nat, n = n`, with the same proof and no new assumptions. Only documentation is added.
They are isolated from positive libraries and copied byte-for-byte into a disposable
Core-only adopter as `Example.lean`.

Run `./scripts/verify.sh diagnostics producers` for the bounded operational campaign.
It invokes the actual fresh project, incremental and build-lint entrypoints for each fixed/violation/restored source,
checks exact stable ID, detail, primary location, related locations and result status,
requires unique output and exact embedded source/selector/type/axiom evidence on every invocation,
then mutates a real returned report through its actual Lean decoder. The original valid
report is re-admitted after each intended refusal. A standalone executable additionally has
positive/owned-axiom/restored controls; each carries module documentation so the intended
axiom violation is isolated. Restored controls start with empty root build output. Optional raw export:

```sh
python3 scripts/producer_checks.py --evidence tmp/producer-examples.json
```

The export embeds exact source bytes and canonical diagnostic/result data, including the
checker build identity. Its temporary observation URIs identify the actual checked source;
consumers render the embedded source and its repository path, not a now-removed scratch file.
This supplies scoped source/evidence inputs, not the future site's complete typed expectation
validator. CI runs this named campaign separately from the unchanged unpartitioned ordinary
420-second acceptance. No unrun broader campaign is claimed PASS. Older structural-campaign
manifests still need reconciliation with the `StrictLeanPolicy` root before that campaign
can establish its broader claims; the small adopter qualifies the changed standalone path.

The collectors and documentation lookups reuse Lean 4.33.1 APIs. No con-leche code is imported;
the existing complete-census design credit remains in [design influences](design-influences.md).

## Reached closure and source snapshot account

The closure increment records `ExecutionRoot.closure` from the **actual**
`Probe.executionWalk`. Each first visit retains its structural name, available owning
module and the index of the earlier visit that queued it. The initial visit is the
root. The sorted `nodes` census is exactly the set of these visits, with no duplicate
visits. The producer retains every ordinary eligible root (including unused roots), plus
explicitly registered private/imported roots. Unregistered internal/private declarations
remain in the logical declaration census; they do not become ordinary execution roots.

The following channels remain separate; their union is a conservative traversal relation,
not a selected or minimal runtime call graph. `compilerEdges` belongs to `ExecutionRoot`;
the remaining fields belong to its `closure` account:

| Field | Observation and use |
| --- | --- |
| `compilerEdges` | Retained IR calls, closures and initialization dependencies. |
| `logicalEdges` | Constants used by the logical bodies the existing walk follows. |
| `candidateEdges` | All inspected constant-equality simplification candidates, including inactive candidates. |
| `historyEdges` | Replacement choices from completed, source-bound module histories. |
| `currentReplacementEdges` | Current `implemented_by` choices, retained even when history is unavailable. |
| `activeSimplificationEdges` | Active simplifications used by the replacement-only cycle check; each is also a candidate. |
| `helperEdges` | Explicit opaque-to-partial-helper traversal. |
| `requiredCode` / `unavailableCode` | Exact retained-code obligations and the unavailable subset; a nonempty unavailable subset requires unresolved execution. |

Every enqueue site records its edge and a parent visit together. Visited-name suppression
terminates ordinary recursion without deleting self edges. Retained IR dependencies now use
the declaration step of Lean's pinned
[`IR.CollectUsedDecls.collectDecl`](https://github.com/leanprover/lean4/blob/819816b2e0a3bf405af45ae5c7af2491d8f5bee6/src/Lean/Compiler/IR/EmitUtil.lean):
`collectUsedDecls` also inserts the declaration itself synthetically, so filtering its
result by inequality incorrectly discarded genuine recursive calls. This is a specialized
pinned compiler API, not a promised stable extension interface; upgrades must requalify
its semantics. No upstream code is copied. Existing source/boundary/IR obligations and
replacement-cycle refusal remain in force.

`StrictLeanPolicy.ExecutionClosure.Valid` checks the supplied census, discovery witnesses,
canonical edge channels, endpoints, code obligations and unresolved requirement.
`ExecutionRoot.Valid` additionally reconciles boundary names, replacement targets and
compiler callers. `ProducerReport.Environment.validate` calls `admitExecution` at producer
and decoder boundaries, reconciles visits with available module attribution, requires exact
candidate/replacement boundary coverage and binds each historical edge set to its actual
module receipt. Missing or inconsistent observations refuse inspection; no omitted record
becomes a clean result.

### Exact proof scope

All three theorems below compile over the executed admission definitions in
`StrictLeanPolicy/Admission.lean`. They quantify over arbitrary supplied records, not a
separate graph model:

- `ExecutionClosure.discovery_induction`: if every visit has the checked root/earlier-parent
  witness, any predicate true of the root and preserved by each recorded edge holds at
  every visit. Its transitive axioms are exactly `propext`, `Quot.sound`.
- `ExecutionClosure.nodes_induction`: with `Valid`, the same predicate holds for every
  name in `nodes`. Its transitive axioms are exactly `propext`, `Classical.choice`, `Quot.sound`.
- `admitExecution_preserves`: a successful `admitExecution roots = .ok inventory` retains
  exactly `roots` and proves `ExecutionValid roots`. Its transitive axioms are exactly
  `propext`, `Classical.choice`, `Quot.sound`.

The induction uses the strictly earlier parent index, not another graph search. These
results establish connectedness and structural admission of supplied observations. They
**do not prove completeness or authenticity of Lean environment/IR extraction**, that a
candidate edge executes, machine-code correspondence, or intended-specification adequacy.
Reflexive constant equalities remain in the candidate set. An active `csimp` self-edge
therefore satisfies the active-edge subset invariant while its replacement-only cycle
remains unresolved (SL3001); an inactive reflexive candidate does not create an active
cycle. Ordinary recursive IR self-edges remain a separate channel.

The existing pure execution/Plan/Observation interfaces consume this strengthened admitted
inventory; global required jobs and construction of `Accepted` remain #7.

### Source and configuration binding

`ProducerReport.SourceBinding` retains module, actual path and exact source text. Project
checking captures Lake's root-package source map and manifest/Lake/toolchain/dependency-lock
configuration before building. Requests carry the frozen sources; producer and parent
compare the report's loaded-owned subset with that request. The loader captures source
before importing the environment and checks it after inspection. Completed owned histories
must use the same path and text. Frontend transcripts must match that snapshot. All supplied
declaration ranges are checked against it, including declarations without diagnostics.
Locations and result exports reuse the frozen text; they do not recapture newer text as
if it had been checked. Canonical file and project results retain `scope.configuration`
as path/optional-text pairs; an absent file is represented by `null`. File inspection
additionally binds the isolated source to the original compilation input; grouped documentation and fixture inspection receive the
exact `Compilation.spec.source` values instead of recapturing them after compilation.
Both standalone documentation and combined project/documentation checking retain the
project source map and configuration frozen before dependency building through fence
compilation, grouped inspection and the final result. Worker requests use `sourceBindings`
as their sole source map; loader module/path pairs are projections of those bindings.
A detected source/configuration mismatch prevents success; the project adapter reports
SL2005/incomplete, including missing or unreadable previously frozen source/configuration.
Read failures preserve the underlying IO reason. Initial environment/setup failures remain SL2001;
only re-reading existing frozen evidence receives this normalization. The original file
path uses the shared guard, and combined mode checks its parent snapshots on declaration
worker failure as well as success.
`python3 scripts/documentation_source_checks.py` qualifies both public
documentation paths with changed and missing dependency/configuration inputs and fresh
restored positives. Its `--source-read-only` selection additionally checks original-file
and declaration-build read failures, initial setup classification and restored positives;
these observations do not establish universal IO correctness.

This is exact observation equality, not a filesystem lock or source-to-olean theorem.
Lake build semantics, compiler/imported dependency authenticity, filesystem reads and the
absence of an undetected change-and-restore race remain trusted boundaries. Imported
unowned source is inspected only when required by an existing history obligation; this
does not add full-Mathlib analysis to Core-only adopters. Producer revision still identifies
its elaboration, not authenticated whole-binary provenance.

Owned logical replay failures and source coverage/range admission failures cross declaration and grouped-fence workers as typed
`ProducerReport.Outcome.admissionFailed`, carrying `AdmissionFailure.detail`. The shared
`Environment.validateSourceEvidence` guard supplies typed source-evidence refusal directly;
the producer and decoder use the same predicate, without classifying exception text. Public project,
file and documentation adapters emit SL2005/incomplete with that original reason and scope.
Documentation retains its SL4002/SL4004 finding alongside the typed refusal, using fence
context without manufacturing a valid declaration range. `SourceBinding.withUnchanged`
owns the before/after comparison around each frozen-input
operation. It retains the operation's result or IO exception, rechecks exact sources and
configuration, then returns a typed snapshot failure (rendered as SL2005/incomplete) or preserves the original
outcome when snapshots are unchanged. Initial capture still has setup semantics.
Environment imports, report workers, grouped decoding, file compilation/inspection,
project/file dependency builds and documentation use that same owner. The original
standalone file is frozen before dependency builds. Batch compilation creates snippet
files in its parent before dispatch; workers consume those files without rewriting them.
Failed builds, crashed workers and decoding failures cannot skip their owner's recheck.
A transported refusal is consumed only after worker-packet validation. Independently,
the parent's own snapshot check can return a typed refusal even when a worker crashes
or a packet is malformed; this does not accept or authenticate that worker result.
When snapshots are unchanged, the original worker or decoding failure is preserved. The selftest consumer renders the same detail as a diagnostic
fixture failure; compatibility IO wrappers have no public diagnostic consumer.
The four accepted-example kinds are unchanged. Expected INCOMPLETE diagnostics are separate
diagnostic demonstrations, never accepted conformance or accepted positive/rejection examples;
the full corpus and its matching/export adapter are a separate #13 increment.

The [closure verification record](../../session/evidence/issue-13-closure-verification.md)
records the proved domain, exact axiom sets, focused qualification and pending delivery gates.
