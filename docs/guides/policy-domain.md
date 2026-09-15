# Typed policy domain and admission

`StrictLeanPolicy` is the public, pure library used by the checker. Import
`StrictLeanPolicy` for its current domain and admission APIs. The normative meaning
of the rules remains in [the standard](../standard/README.md); the
[policy acceptance contract](policy-acceptance.md) describes the remaining semantic
proofs and complete-result integration.

Every normative requirement needs an explicit coverage disposition. Mechanically
checkable requirements become checks; other requirements need Lean proof evidence
or identified semantic review. Words such as **MUST** and **SHOULD** in a practical
guide do not create additional standard rules. A recommendation retains the
standard's stated latitude. The [coverage map](rule-coverage.md) records the
mechanical contributions and residual obligations.

## What is checked by construction

| Interface | Guarantee | Boundary |
| --- | --- | --- |
| Closed categories in `Domain` | Declaration kinds, boundary kinds, correspondence, foundation classes, conforming profiles, modes, safety, reducibility, recursion origin and evaluator roles have explicit constructors and spelling parsers. | Unsupported tags are refused. Pretty types, messages and evidence descriptions remain open text. |
| `Identity`, `canonicalNames`, `canonicalEdges` | Identities preserve Lean's actual `Name` constructors. Set-valued observations have sorted, duplicate-free projections with exact membership. | Nonanonymous identity does not establish ownership or extraction authenticity. Mutual groups and evaluator chains retain their order. |
| `BoundaryEvidence kind` | Replacement equality, simplification equality and opaque-body admission are distinct. A trusted native-runtime observation carries matching origin data. | The record observes compiler/kernel work; strings and serialized proof fields cannot authenticate that work. |
| `admitBoundaryEvidence` | Successful admission preserves correspondence, detail and native origin; incompatible extra evidence is refused. Every representable value round-trips. | Canonical path acquisition remains an operational check. |
| `Inventory`, `admitInventory` | Declaration and transcript identities are unique, references are structural, set fields are canonical, safety fields agree, and transcripts bind source bytes, supported compiler identity and valid coordinates. | An inventory is not an independently complete declaration census. |
| `Roles inventory`, `authorize` | Role arrays equal the actual validators' results for this exact admitted inventory. Declaration decisions require membership in the same inventory. | Independent semantic equivalence of these validators is subsequent proof work. |
| `ExecutionInventory`, `admitExecution` | Root identities and boundary occurrences are unique; references and native-origin module bindings are valid. | Closure completeness still depends on the operational collector. |
| `Claim`, `admitClaim`, typed keys | Scope/mode combinations, positive profiles, exact source/configuration/dependency observations and key bindings are explicit. | A requested claim is not an accepted result. Teaching and no-profile inspection remain separate. |
| `ResultState`, `insertResult` | Each occupied key belongs to the fixed required set and satisfies its binding relation. Insertion rejects an occupied slot, including an identical repeat. | Direct proof-bearing construction enforces the stated invariant; completeness and accepted-result soundness are separate obligations. |

The core imports Init/Std and its own modules. It does not import the operational
reporter, frontend, registry, Mathlib or IO execution. `Specification` and
`Acceptance` expose the current admission dependencies without inventing the
subsequent independent policy predicates or an `Accepted` success alias.
`Checker.PolicyDomain` and `Checker.Acceptance` are compatibility re-exports.

## Connection to execution

Lean/Lake observations retain structural names through discovery, reports,
transcripts and worker requests. The operational reporter converts compiler
categories directly to the closed domain. `Checker.Policy` adapts admitted data to
the sole rule-ID registry and existing text subreasons; it does not accept free
arrays authorizing generated roles. Execution failures and summaries use the same
admitted execution inventory.

Worker parsing rejects duplicate JSON fields before constructing a map. Record
parsers reject unknown and missing fields, unsupported tags and bounded numeric
overflow. Versioned response packets retain the request and producer/toolchain
identity. The parent waits for child exit before checking the response. Compilation
batches use `ResultState` to admit indexed payloads against their requested source
and artifact paths, then require all requested slots. Source workers additionally
bind their exact input text.

This local request/result validation does not supply the future whole-project
census, fixed job plan, accepted result or project/documentation composition.
Those remain tracked by POLICY-03/POLICY-04. The current core fence-expectation
record also does not replace the registry's checked example interface: successor
integration must retain exact diagnostic IDs, subreasons and source locations,
validate IDs through the sole registry, and refuse incomplete outcomes.

## Compatibility and evidence

Positive `freshFile` claims reject warnings, including warnings emitted after a
source disables `warningAsError`. No-profile inspection remains classification.
Compiler-trusting teaching inspection cannot construct a conforming profile.

Versioned diagnostics retain structural identities. `--legacy-json-out` projects
names to display strings and retains the legacy record shape. Only identified
legacy display-path fields are remapped; proof text, pretty types and diagnostic
prose are unchanged. Legacy output is not accepted evidence.

The pure library is a separate Standard-Logical manifest surface, discovered by
Lake's `.andSubmodules`, and is included in `./scripts/verify.sh`. Its exact axiom
inventory is obtained by the same fresh declaration gate as the other positive
surfaces. The ordinary command retains its hard 420-second deadline. Parser,
worker, generated-role, warning and execution controls qualify operational
boundaries; they do not prove universal correctness of compiler extraction or
full standard conformance.

After building the checker, `lake exe checkerSelftest --policy-domain-only`
qualifies strict transport, actual external-adopter public imports, forbidden
probe imports, recursion-helper execution coverage and positive-file warnings.
`--policy-transport-only` repeats just the parser/decoder/admission controls.
Run these diagnostics under the same 420-second timeout; they do not replace
ordinary acceptance. The existing `./scripts/verify.sh diagnostics fixtures`
retains the declaration, generated-role, execution-policy and Markdown controls.

The pinned compiler leaves some generated recursive-datatype helpers without
standalone IR. The probe recognizes the inductive/recursor relationship for that
specific absence, while retaining the helper as a root with its full source,
runtime-boundary and replacement-history checks. Retained compiler edges still
require IR. Public controls include both an authored tagged lookalike and a
runtime-modified genuine helper.

The universal results cover the actual category/name codecs, structural ordering,
canonical set projections, evidence admission, inventory/claim admission and result
insertion. JSON text parsing, filesystem/process authenticity and the remaining
semantic decision/acceptance theorems are distinct claims.

## Reuse and attribution

Std supplies extensional ordered sets/maps and their laws; Lean supplies structural
names, compiler observations and operational coordinate conversion. The duplicate
JSON-field parser reuses Lean's scalar parser and adapts its container recursion
with the source's Apache-2.0 credit in `Checker.PolicyCodec`.

Con-leche's [PropWhen][propwhen] and [Installed][installed] informed canonical
representation and complete indexed assembly. This library does not import
con-leche code or claim its proofs establish Strict Lean policy.

[propwhen]: https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Kernel/PropWhen.lean
[installed]: https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean
