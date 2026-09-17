# Project producer evidence

ENGINE-01's first producer increment adds independent extraction keys, replay receipts,
and completed project documentation observations. It does **not** complete ENGINE-01 or
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

`Admission.validate` now returns `Checker.ProducerReport.AdmissionReceipt`. Its required keys come from
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

`Report.Collected` adds extraction keys to the unchanged pure policy report.
`Checker.ProducerReport.Environment` adds the operational receipts and owns their JSON decoder:

- `census`: requested modules, declaration keys, optional execution root keys and root/module history requests;
- `admission`: replay modules, required keys and observed admitted keys;
- `documentation`: every module's presence, frozen material keys and exact optional docstrings;
- `histories`: one completed source receipt or explicit unavailable outcome for every requested module.

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
`AdmissionObservation`; no serialized flag substitutes for that work. #13 still owes complete
closure/source producer linkage, exact policy-example integration and the full twenty-rule
source-owned corpus. An empty diagnostic list is not `Accepted` or full semantic conformance.

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
complete reached-node/edge census, source identity across every stage, or global `Accepted`.
A temporarily changed source restored between observations is outside what before/after byte
equality establishes. #13/#7 retain the broader snapshot and producer composition obligations.

The `producers` diagnostic also runs `StrictLean.Qualification.History`: real fresh/incremental
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
lake exe qualify producers --evidence tmp/producer-examples.json
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
