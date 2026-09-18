# Policy proofs and their execution boundary

Strict Lean proves its pure policy decisions over admitted observations. It does
not claim that these proofs verify the Lean compiler, source collectors, filesystem,
JSON parser, registry adapter, or a user's intended specification.

The [domain guide](policy-domain.md) describes the input types. The
[acceptance contract](policy-acceptance.md) remains the design contract for complete
project integration. Normative meaning comes from [chapter 8](../standard/8-tooling-and-machine-audit.md).

## What the theorems establish

All names below are in `StrictLeanPolicy`. Source files are under
`lean/StrictLeanPolicy/`. The quantifiers range over finite data values; proof fields
and stated hypotheses are part of the domain, not evidence of external execution.

| Property | Authoritative declarations | Exact meaning |
| --- | --- | --- |
| Least foundation | `Foundation.leastFoundation_spec`, `leastFoundation_ext`; `Decision.foundationFor_least` | Every axiom set contained in Standard-Logical receives its least containing profile. Membership-preserving order/duplicate changes preserve that profile. The actual public classifier uses this same result for inventory-bound roles. This does not find the weakest possible proof of a proposition. |
| Native teaching and recursive helpers | `RoleSpecification.NativeTeachingOK`, `RecursiveHelperOK`; `Decision.authorizedNativeAxioms_iff`, `authorizedUnsafeRecHelpers_iff` | A name is authorized exactly when an inventory record satisfies every named role component. Ordered groups/chains and occurrence uniqueness are retained. The predicates include the observed replay, whole-value and equation checks; they do not prove those observations truthful. |
| Classifier and diagnostic outcomes | `Decision.foundationFor_iff`, `declarationFailure_iff`, `policyFor_ordered`; `Specification.OrderedDecision.unique` | Each of the six foundation classes has its exact meaning. Declaration diagnostics select the first failed named requirement, with invalid inventory membership checked first. This does not prove renderer strings or summary counts. |
| Declaration policy | `Decision.policyFor_none_iff`, `policyFor_conforming_iff` | `policyFor` decision success is equivalent to inventory membership and the independent declaration requirements. A conforming request requires its permitted foundation, safety relation and recorded contract obligations. Teaching never relaxes a conforming profile. |
| Execution policy | `Execution.executionFailureRecords_empty_iff` | No failures is equivalent to no unresolved paths and the applicable relation at every reported boundary. Report mode permits reported trust; checked mode permits checked evidence or the typed native-runtime origin account. |
| Result insertion | `ResultState.insertResult_success_iff`, `insertResult_lookup`, `insertResult_frame` and refusal theorems | Insertion succeeds exactly for a fresh required key with a valid payload binding, installs that payload, and preserves every other lookup. Unknown keys, duplicate results and invalid bindings return a refusal, with no replacement state. |
| Concrete acceptance | `Plan.requiredJobs`, `PlanOK`; `Acceptance.accept_iff`, `accept_sound`, `accept_complete` | Acceptance requires the fixed claim/census-derived jobs, their completed result slots and each applicable policy relation. Completeness is over the supported finite observations, not elaboration, theorem search, source discovery or external liveness. |
| Report identity | `Acceptance.accepted_report_identity`, `accepted_covers_slot` | The report projects the exact claim, census, ordered jobs and result map. Every planned slot has one correctly bound policy observation. |
| Expected compiler diagnostics | `Pattern.matchesPattern_iff`, `orderedLiterals_iff` | Matching is the declared valid pattern's ordered leftmost-split relation within one effective-error message. Producer completion and effective-error extraction remain operational. |

File prefixes in this table identify the source file, not extra Lean namespaces.
For example, the actual theorem name is `StrictLeanPolicy.accept_iff`.

The least-foundation proof uses containment in the three permitted sets. The
collection laws reuse Std's extensional ordered structures. Generated-role
validators execute decidable component propositions, so there is no unconnected
reference evaluator. `ExactlyOne` has a proved decision procedure that considers
only the possible first-element witness and still requires equality to the complete
singleton sequence. This avoids repeated witness scans by construction; no
wall-clock performance improvement is claimed.

The prior generated-role loops and the new relations agree on the admitted
unique-name domain by guard-by-guard source review and focused qualification.
The new validator-to-relation equivalence is machine-checked. No theorem of
unrestricted equality with the prior loops on malformed duplicate-name arrays is
claimed.

## Actual consumers

Paths in this table start at `lean/StrictLean/`.

| Operational caller | Proved pure function | Remaining boundary |
| --- | --- | --- |
| `Checker/Policy.admitScope` | `admitInventory`, `authorize` | Fresh frontend/FileMap checks, actual source and compiler observation acquisition. |
| `Checker/Policy.ruleFor` / `reasonFor` | `policyFor` | Exhaustive mapping to the sole registry and its existing subreasons. |
| `Checker/Policy.labelOf` / `classify` | `foundationFor` | Actual transitive `Lean.collectAxioms` results and module ownership. |
| `Checker/Policy.executionFailureRecords` / `executionFailures` | `executionFailureRecords` | Root/closure collection, retained compiler edges, correspondence admission, source history and canonical runtime origins. |
| `Checker/Common.admitIndexedWorkerResults` | `ResultState.insertResult` | Child completion, strict packet decoding and exact request/source binding. |
| `Checker/Documentation.matchesPattern` | `matchesPattern` | Structural fence scanning, supported-pattern diagnostic text, and completed effective-error extraction. |
| `Checker/Acceptance` compatibility import | `accept` and `Accepted.report` | POLICY-04 (#7) must make every actual audit success renderer/exit consume the result, and compose project/documentation results under one snapshot. That integration is not delivered by the pure theorem. |

Source extraction and transport qualification remain necessary. The existing
`Admission.validate`, fresh frontend attribution, canonical pinned `.olean`
origin check and conservative execution walk remain operational gates. A proof
about an exactness/replay field does not prove the underlying Lean value equality
or compiler run. A private constructor alone would not establish hostile
in-process unforgeability either.

## Rule-ID linkage

These are the existing stable identities from the sole registry. Theorems operate
on typed observations; the adapter's exhaustive `failureId` mapping supplies IDs.
The table does not claim the rules' external collectors or residual review are proved.

| Rule IDs | Proved relation and actual consumer | Limit |
| --- | --- | --- |
| SL1001, SL1002, SL1003 | `declarationFailure_iff` / `policyFor_ordered` select project-axiom, hole and unknown-dependency failures; `Checker.Policy.ruleFor` maps them. `foundationFor_iff` supplies exact classification through `labelOf`/`classify`. | Actual ownership and transitive axiom acquisition remain operational. |
| SL1004 | Same declaration outcome theorems plus `authorizedNativeAxioms_iff`, consumed by `admitScope`/`ruleFor`. | Native authorization permits teaching only; transcript/replay truth is external. |
| SL1005 | `foundationFor_least`, `leastFoundation_ext`, `policyFor_conforming_iff` and ordered outcome equivalence; `labelOf`/`ruleFor`. | Least containing profile of observed axioms, not least possible axioms for the proposition. |
| SL1006 | `authorizedUnsafeRecHelpers_iff`, `policyFor_conforming_iff` and ordered outcome equivalence; `admitScope`/`ruleFor`. | Exact helper observations are checked; acquisition authenticity and execution coverage remain separate. |
| SL1007 | `ContractOK` and declaration outcome equivalence through `ruleFor`. | Recorded contract failures are enforced. Probe's proposition/root extraction, proof admission and adequacy are not proved by this relation. |
| SL2004 | `policyFor_ordered` places invalid-inventory membership refusal first; `ruleFor` maps it to coverage. `CensusOK`/`PlanOK` also contribute to future composite acceptance. | Membership refusal does not establish complete Lake/environment ownership acquisition. |
| SL3001, SL3002 | `executionFailureRecords_empty_iff` and `boundaryFailures_empty_iff`; `Checker.Policy.executionFailureRecords`/`executionFailures`. | Theorems cover supplied unresolved paths and boundaries, not complete root/closure discovery or external runtime correctness. |
| SL4003 | `matchesPattern_iff` and `orderedLiterals_iff`; `Checker.Documentation.matchesPattern`. | One effective error under the restricted grammar; producer completion and error extraction are operational. Typed policy-negative expectation integration remains #7/#13. |
| SL2001–SL2005, SL4001–SL4004, SL5001–SL5002 | Concrete `PlanOK`, `StageOK` and named scope/build/admission/document/example/presence predicates compose through `accept_iff` and `accepted_report_identity`. | Data-level composite guarantee. #7 must populate authentic complete observations and route global success through `Accepted`; #13 supplies missing collectors, presence checks and example adapters. This row does not claim those features are already integrated. |

## Complete observations and example expectations

`Census` records frozen module/declaration/root/fence identities and their source
bindings separately from policy outcomes. `requiredJobs` derives applicable
subjects from the fixed claim's mandatory stages. `Plan` requires the supplied
`JobKey` array to equal that derivation, with every key belonging to the same claim.
Natural-number result slots are positions in that exact array, not new semantic
identities or caller-selected requirements. Recorded successful executable-contract
roots must be represented in execution modes. Known root-target imports must agree
with positive target assignments; the collector must also report unclassified root
imports. History observations bind the exact module/source pair. These checks do
not establish external census completeness or repair the remaining ordinary-root
selector qualification assigned to #7/#13.

`JobObservation` separates completion state, exact snapshot and stage-specific
fields. `StageOK` checks the appropriate relation for the stage and subject; an
unrelated payload constructor cannot pass. Missing, crashed, cancelled,
unsupported and incomplete observations cannot become accepted results.

`ExampleExpectationOK` distinguishes positive elaboration, completed compiler
rejection, completed policy rejection and compiler-trusting teaching. Expected
elaborated observations bind group modules and role transcripts to the fixed
fences' original bytes; policy assessment selects the current example unit. Expected
policy diagnostics retain stable identity tokens, optional subreason, exact
primary location and related locations. Matching requires the configured ordered
list with no additional diagnostics. The sole registry adapter validates identity
vocabulary and authentic locations. A completed rejection observation is not
itself proof that the external producer performed that work; #7/#13 must establish
that linkage through their actual invocation and packet boundaries.

Accepting a negative or teaching expectation never supplies conforming positive
program evidence. Documentation examples retain their logical-only scope;
execution correspondence and narrower foundation claims need their own evidence.
All applicable residual semantic-review accounts remain required. A mechanically
accepted report is not full standard conformance.

## Evidence and supported domain

The implementation targets the [supported toolchain](../../README.md#supported-toolchain).
The pure policy library itself imports Init/Std and its own modules, not Mathlib
or the excluded operational checker.

The [original delivery evidence](../../session/evidence/issue-6-verification.md) records the
then-current Mathlib revision, declaration and
axiom census, applicable diagnostics, independent reviews and complete acceptance
result. Explicit theorem hypotheses are distinct from transitive logical axioms.
The manifest's Standard-Logical profile is an upper bound, not a claim that every
proof uses all three permitted axioms. Optional serialized-graph checking and
unrun broader operational campaigns are separate claims.

## Reuse and attribution

Lean supplies structural names and the observed compiler semantics; Init/Std
supplies collections, equality, string operations and their laws. The diagnostic
pattern consumer is adapted from this repository's existing implementation, with
structural termination and explicit policy linkage.

Con-leche's authors/contributors, maintained by Joachim Breitner at Lean FRO,
are credited for the design influence of [canonical semantic representations][propwhen]
and [complete indexed assembly with checked admission][installed]. No con-leche
code, model or theorem is imported, and its kernel/model guarantees are not claimed
for Strict Lean. See the [contribution-specific attribution guide](design-influences.md).

[propwhen]: https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Kernel/PropWhen.lean
[installed]: https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean
