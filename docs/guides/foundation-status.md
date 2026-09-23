# Proof-driven engineering foundation status

This is the bounded implementation baseline for [Project 9](https://github.com/users/rbeauchamp/projects/9),
established by [#38](https://github.com/rbeauchamp/strict-lean/issues/38).
It adds no normative rule and does not claim whole-checker verification or full
repository conformance. Its purpose is to make the remaining foundation work
executable without repeating established proofs or weakening their statements.

## Baseline and scope

The source baseline is `708507199f693aa330b0c87086402d89d813da1b` on
2026-09-18. Lean is `4.34.0`, compiler commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`; Mathlib is
`5ed2965256430c3649e86755f9576b54eca72435`. The documentation project uses
Lean `4.34.0` and Verso `cad4b633e75ea769b851f12f9ca3b4f0dfcc625f`.
The tracked toolchain and manifests remain authoritative at later revisions.

The selected scope is rows F01–F12 below and the explicit successor obligations.
References identify definitions to inspect, not a replacement module/declaration
inventory. Claimed coverage comes from Lake's elaborated root-package libraries,
`getModuleArray`, executable roots, and Lean environment attribution, through
[`Lake.surfaceInventory`](../../lean/StrictLean/Checker/Lake.lean).
Additional imported modules must still be reconciled; the `modules` facet is not
silently substituted for the configured array.

The [manifest](../../foundation_manifest.json) claims `StrictLeanPolicy`,
`StrictLeanVerification`, `StrictLeanQualification`, `Audit`, and `AuditApp`,
plus the standalone `auditApp` root `Main`. The operational `StrictLean` library
and its checker executables remain excluded from the conforming proof surface;
`Fixtures` remains isolated. A library's Standard-Logical upper bound is not
every declaration's exact axiom set.

Global integration has one owner: [#7](https://github.com/rbeauchamp/strict-lean/issues/7),
with [PR #33](https://github.com/rbeauchamp/strict-lean/pull/33). The #38 baseline
above remains historical. The current implementation below includes PR #33's
environment-indexed integration at `e19018e47b73ac732853ad90297bcc94d15854b3`
and the [retained-role repair](../../session/evidence/ci-role-retention.md).
The [corpus projection receipt](../../session/evidence/ci-corpus-projection.md)
records the subsequent exact qualifier correspondence, adapter reviews and
current local qualification evidence, preserving earlier failed attempts.
That checkpoint's hosted ordinary gate exceeded 420 seconds; local success does
not establish hosted readiness. Implementation linkage is present, while final
qualification, exact-head hosted CI and integrated delivery remain separate gates.

## Component and obligation inventory

Status notation: **E** = existing type/construction/theorem establishes the stated
Lean relation; **L** = missing global execution linkage on this baseline;
**R** = a selected adapter relation still needs explicit evidence;
**T** = trusted acquisition/execution or semantic-review boundary. Several may
apply to different parts of one row. An R is a project obligation, not a claim
that every helper needs a separately named theorem.

| ID | Definition and actual consumer | Existing guarantee and remaining obligation | Status / owner |
| --- | --- | --- | --- |
| F01 | [`ExecutableContract`, `run`, `run_eq`](../../lean/StrictLean/Contract.lean); [`Collect.executableContract?`](../../lean/StrictLean/Collect.lean) feeds collected declarations and policy `ContractOK`. | The field proves exactly `R f`; `run` is definitionally `f`. Recognition checks the elaborated closed registration and executable root, not intended adequacy or every caller. Preserve supported universes, full domain and root coverage; review the required relation independently. | **E/T**; #39, reporting #42. |
| F02 | [`Inventory`, `admitInventory`, `admitExecution`](../../lean/StrictLeanPolicy/Admission.lean); [`Policy.admitScope`](../../lean/StrictLean/Checker/Policy.lean) is called by project/file/fence inspection. | Admitted values carry validity; exact admission retains input observations, and execution admission has a preservation theorem. The adapter first checks frontend coordinates, then admits inventory and computes roles. #39: `admitScope` runs `checkedScope` (`ScopeContract`): first coordinate refusal in transcript order, then exactly `admitInventory` with `authorize`; success iff every coordinate check and `InventoryValid` hold, retaining both arrays. Supplied transcripts are not authenticated. | Core and adapter **E**, acquisition **T**; #41. |
| F03 | [`policyFor`, `foundationFor`, `declarationFailure`](../../lean/StrictLeanPolicy/Decision.lean); `Policy.ruleFor`, `reasonFor`, `labelOf` in project/file gates; [`Linter.Rules.declarations`](../../lean/StrictLean/Linter/Rules.lean) for local feedback. | Existing equivalences cover membership, policy, all six classification outcomes and ordered first failure. #39: `request` runs `checkedRequest` (`RequestContract`, by spelling); `ruleFor` runs `checkedRule` (`RuleContract`) over `policyFor`, with `ruleForFailure_injective` and `reasonFor_eq_some_iff`. Environment collection remains separate. | Core and adapter **E**, collection **T**; #41. |
| F04 | [`executionFailureRecords`, `executionSummary`](../../lean/StrictLeanPolicy/Execution.lean); `Policy.executionFailureRecords`, `executionFailures` and gate rendering. | Empty pure failures iff `ExecutionOK` for every admitted finite inventory and mode. #39: `Policy.executionFailureRecords` is the decision's own records (identity); `executionRule` is injective; `executionSummary` runs `checkedSummary` (`SummaryContract`). Counts describe observations of a conservative account, not a minimal native call graph. | Decision, projection and counts **E**, extraction **T**; reporting #42. |
| F05 | [`CensusOK`, `requiredJobs`, `Plan`, `admitPlan`](../../lean/StrictLeanPolicy/Plan.lean); [`accept`, `Accepted.report`](../../lean/StrictLeanPolicy/Acceptance.lean). | Coordinator-fixed requests retain the full claim and separate environment inventories. Plan fields require exact derived jobs and claim; accepted evidence requires completeness and policy for those inputs. The actual freeze/finish callers consume this evidence. Final delivery evidence remains open. | Core and linkage **E/T**; delivery **#7 only**. |
| F06 | [`ResultState.insertResult`, `collect`](../../lean/StrictLeanPolicy/ResultState.lean); [`finalize`](../../lean/StrictLeanPolicy/Acceptance.lean); [`Common.admitIndexedWorkerResults`](../../lean/StrictLean/Checker/Common.lean). | Insertion and full-sequence collection retain unknown, duplicate and binding refusals. `finalize_iff` relates actual raw occurrences to exact required-slot policy coverage; split IO collection/acceptance carries equality to this finalizer. #39: `admitIndexedWorkerResults` and `mapWorkQueue` run `checkedIndexedResults` (`IndexedResultsContract`). Packet decoding and worker execution remain distinct. | Collection, finalization and worker projection **E**, transport **T**; #41. |
| F07 | [`evaluate`, `checkedEvaluation`](../../lean/StrictLeanQualification/Checks.lean); [`Qualification.requireChecks`](../../lean/StrictLean/Qualification/Support.lean) calls `checkedEvaluation.run`. | Exact success iff all supplied assertions hold, first false assertion, and append/bind composition are already proved and consumed. The empty list succeeds. The evaluator cannot establish that an adapter supplied all needed assertions or truthful IO observations. Retain the implementation and inspect changed callers; do not rebuild a generic assertion framework. | **E/T**; reuse #39/#40, boundary account #41. |
| F08 | [`AuditApp.RequiredContracts`, `checkedExecutable`](../../lean/AuditApp/Limiter.lean); [`Main`](../../lean/Main.lean) invokes the contract with `requiredContracts`. | Admission, updates, frames, exact success/refusal and strict composition concern the actual runner. The intrinsic bound alone would not prove those relations. [`Refinement`](../../lean/AuditApp/Refinement.lean) relates that runner to finite abstract paths. Retain as the reference pattern; it is not a theorem about checker orchestration or OS effects. | **E/T**; reuse #39; no selected application rewrite. |
| F09 | [`CanonicalSet` decisions and `ExactlyOne`](../../lean/StrictLeanPolicy/Collections.lean), used by admission/role/plan predicates; [`Economy.sumTo_csimp`](../../lean/Audit/Economy.lean) illustrates proved replacement. | Std supplies extensional collections and laws; adjacent-order and singleton-head equivalences already avoid redundant work. The arithmetic example proves one universal identity and an equality of executable definitions. Preserve duplicate-rejection versus set-normalization semantics and separate kernel reduction from compiler replacement. | **E/T**; bounded economy review #40. |
| F10 | [`AxiomGate.auditSurfaceAt`, `auditSurface`, `auditFile`, `run`](../../lean/StrictLean/Checker/AxiomGate.lean); [`Documentation.auditBuiltProject`](../../lean/StrictLean/Checker/Documentation.lean), [`DocFenceAudit.run`](../../lean/StrictLean/Checker/DocFenceAudit.lean); sample [`policy` target](../../examples/build-lint/lakefile.lean). | Actual project/file/fence/build-lint success consumes accepted evidence; project-with-docs consumes same-snapshot `CombinedAccepted`. The [success-call-site map](policy-acceptance.md) distinguishes workers/help/local feedback and incremental modes from fresh conformance. The private fence finalizer consumes unchanged admitted task output. | Linkage **E/T**; delivery **#7 only**, reporting #42. |
| F11 | [`Workspace.withRootWorkspace`](../../lean/StrictLean/Checker/Workspace.lean), `Lake.surfaceInventory`, [`SourceBinding`](../../lean/StrictLean/Checker/SourceBinding.lean), [`Admission.validate`](../../lean/StrictLean/Checker/Admission.lean), [`Frontend`](../../lean/StrictLean/Checker/Frontend.lean), [`ProducerReport`](../../lean/StrictLean/Checker/ProducerReport.lean). | Existing source/configuration, complete inventory, compiler and replay observations are bound to the accepted request and terminally reconciled. Policy validity does not authenticate their observations, filesystem, external processes or native code. Qualification and the [boundary table](policy-acceptance.md) remain required; no wholesale proof of these mechanisms is selected. | Bound integration implemented; acquisition **T**; #7, explicit adapter boundary #41. |
| F12 | [`ResultProtocol`](../../lean/StrictLean/Checker/ResultProtocol.lean), [`RuleDiagnostics`](../../lean/StrictLean/Checker/RuleDiagnostics.lean), existing gate/fence renderers and [`rule coverage`](rule-coverage.md). | Public accepted projections consume `AcceptedRun.report`; typed diagnostics or serialized success flags cannot reconstruct acceptance. Exact scope, executable identity, foundation/execution boundaries and residual-review presentation remain #42's selected reporting work. Positive/rejection/teaching/incomplete distinctions remain. | Global linkage **E**, projection **R/T**; #7 then #42. |

## Read-back of the essential relations

These are readings of existing elaborated declarations, not proposed substitute
models. Quantifiers over the displayed inputs are universal unless explicitly
existential; implicit inputs and typeclass assumptions still matter.

- **Contract:** for any universe-polymorphic `α`, implementation `f : α` and
  predicate `R : α → Prop`, `ExecutableContract f R` contains `R f`.
  `run_eq` proves its `run = f`. Neither `R := fun _ => True` nor the name of a
  theorem establishes the intended requirement. A dependent result type may
  already establish that requirement; no duplicate proof field is needed.
- **Admission:** `admitInventory_exact ds ts h` assumes
  `h : InventoryValid ds ts` and returns exactly those arrays with their proof.
  It does not assert that arbitrary input is valid. `admitExecution_preserves`
  quantifies over roots and a returned inventory: a successful admission implies
  exact input-root retention and `ExecutionValid roots`. Nonanonymous/unique
  identities, coordinates and closure relations concern supplied data.
- **Classification:** `policyFor_none_iff i roles d r` equates no refusal with
  `d ∈ i.declarations ∧ DeclarationOK d r roles.native roles.helpers`.
  `foundationFor_iff` similarly equates each successful label with membership
  and `ClassificationOK`. `roles : Roles i` binds authorization to that
  inventory. `executionFailureRecords_empty_iff i c` equates no failures with
  `ExecutionOK i c`; in report mode trusted boundaries may remain, but unresolved
  paths do not satisfy the relation. No statement authenticates extraction.
- **Insertion:** `insertResult_success_iff` quantifies over key/payload types,
  `[Ord κ]`, `[TransOrd κ]`, `[LawfulEqOrd κ]`, fixed `required`, fixed `bound`,
  `[DecidableRel bound]`, current state, key and payload. Success exists iff the
  key is required, its lookup is empty, and binding holds. `insertResult_frame`
  additionally assumes a successful returned state and `other ≠ key`; every
  other lookup is unchanged. Public construction enforces subset/binding
  validity, not a history of insertions or latest-state/single-use discipline.
- **Acceptance:** for `c : Claim`, `i : Census`, `p : Plan c i`,
  `roles : CensusRoles i` and `s : ResultTable p`, `accept_iff` states
  `(∃ a, accept p roles s = .ok a) ↔ CompleteFor p s ∧ AllPolicyOK p roles s`.
  `CompleteFor` includes `PlanOK` and a completed observation at every required
  slot; `AllPolicyOK` requires its exact stage policy. `accepted_report_identity`
  preserves the claim/census/jobs/table. `accepted_covers_slot` assumes
  `slot < p.jobs.size` and gives one lookup, its full job key, policy, and unique
  lookup value. These do not assert that an arbitrary census is adequate or that
  some external worker truly executed. Negative/teaching expectation acceptance
  does not establish positive program conformance.
- **Assertion sequence:** `evaluate_success checks` is iff all supplied Boolean
  assertions are true. `evaluate_error checks label` supplies an existential
  satisfied prefix, first false check with that label, and unevaluated suffix.
  `evaluate_append` is exact `Except.bind` composition. Duplicate labels are
  permitted; an empty input satisfies the conjunction. Caller obligation coverage
  is separate from this evaluator's universal correctness.
- **Stateful example:** `runChecked_success ops l final` is iff `Fits ops l`
  and `final = run ops l`. `runChecked_error` identifies a fitting prefix whose
  next grant is full, with final state exactly that prefix's result. Earlier
  updates survive refusal; the suffix does not run. `checkedExecutable` quantifies
  over `RequiredContracts`, natural capacity and operation lists, and specifies
  exact positive-capacity admission plus that same runner. These are unbounded
  Lean naturals; truncated subtraction is justified by the relevant guards.
  They do not prove machine overflow behavior, elapsed time, concurrency,
  resource availability, external liveness or IO effects.

Canonical collection decisions require their actual comparator/equality laws.
Positions and slots are naturals; UTF-8 bytes, character positions and UTF-16
columns remain distinct in frontend/source adapters. Serialized identities and
ordered result occurrences may not be replaced by display strings, set equality
or hashes merely because those alternatives look equivalent.

## Selected successor deliverables

### #7: complete the existing acceptance integration

F05/F06/F10/F11/F12 retain #7's full scope. Its independent inventory and fixed
plan must determine required work before result admission. Every applicable
project, file, fence, build-lint and combined project-with-docs success must
consume evidence for that same request/mode. Internal worker success and
help/configuration output remain distinct. Preserve source admission, provenance,
all rule/example categories and unknown refusal; do not weaken global identity
to repair composition collisions. Use the existing PR, not a second collector.

The PR #33 CI repair retains this document's #38 baseline above. Its current
environment-indexed census, exact occurrence collector and public success-path
integration are tracked in [the repair receipt](../../session/evidence/ci-environment-census.md).
F05/F06/F10/F11/F12 are not marked closed until the applicable proof, independent
review, complete cold acceptance and diagnostic evidence is recorded there and
delivery is integrated. The successor boundaries below remain unchanged; #39 is
not a prerequisite for completing #7.

### #39: close the selected component relations

The finite implementation set is: `Policy.admitScope`; the profile/request and
declaration/execution failure projections in `Policy`; the pure
`executionSummary` count relation; and any worker sequence/projection relation
not already discharged by #7 for `Common.admitIndexedWorkerResults`.

Admission success must retain the exact declaration/transcript inputs and roles
for that inventory. Completeness is conditional on the existing coordinate check
and inventory predicate; refusal must retain their current order. Projections
must preserve the selected request, diagnostic category/root/detail and order.
Summary counts describe their actual categories, including root-unresolved
entries and unresolved boundary entries; they are not counts of distinct runtime
paths. Worker output must cover exactly the requested slot sequence without
dropping duplicates, rebinding payloads or substituting a shorter plan.

Reuse F01/F07/F08 and #7's final APIs. Use reduction, existing proofs or required
proof-bearing interfaces where sufficient. No generic admission/state/runner DSL
is selected: current recurrence justifies shared evidence, not another framework.
Keep specifications independently reviewable so deleting a proof cannot silently
delete its requirement. Semantic review still owns adequacy and caller coverage.

#### #39 delivery

Each requirement is a named `Prop` definition, separate from its proof. A closed
`ExecutableContract` registration proves that definition about the actual
implementation. Callers execute the registration's `run`, which is definitionally
that implementation. Deleting the proof therefore breaks every caller, and a
weakened definition is visible to review.

| Registration | Implementation | Required relation | Callers |
| --- | --- | --- | --- |
| [`checkedScope`](../../lean/StrictLean/Checker/Policy.lean) | private `admitScopeImpl` via `Policy.admitScope` | `ScopeContract`: (1) with `ts.toList = before ++ t :: after`, every `before` check `.ok ()` and `validateCoordinates ds t = .error e`, the result is `.error e`; (2) when every coordinate check succeeds, the result is exactly `(admitInventory ds ts).map (⟨·, authorize ·⟩)`; (3) success iff every coordinate check succeeds and `InventoryValid ds ts`; (4) success retains `ds` and `ts`. `Roles.eq_authorize` already fixes the roles. | project, file, fence, rule-example, acceptance freeze, environment census and self-test inspection |
| `checkedRequest` | private `requestImpl` via `Policy.request` | `RequestContract`: no claim gives `.classification`; `.teaching` iff compiler-trusting; `.conforming q` iff `profile.toString = q.spelling`. `Profile.parse?_eq_some_iff` states the spelling input meaning. | `ruleFor`; `Acceptance.conformingProfile` |
| `checkedRule` | private `ruleForImpl` via `Policy.ruleFor` | `RuleContract`: `none` iff `policyFor … (request claim) = none`, and `some (ruleForFailure f)` iff that decision is `some f`. With `ruleForFailure_injective` and `policyFor_ordered`, the rule is the first failed requirement's. `reasonFor_eq_some_iff` gives the same relation for applicability text. | project/file gates, fence and rule-example audits, `reasonFor` |
| [`checkedSummary`](../../lean/StrictLeanPolicy/Execution.lean) | `executionSummary`, now a named `ExecutionSummary` | `SummaryContract`: roots and boundaries are observation counts, checked/trusted are filter counts, and `unresolved` equals the number of `executionUnresolved` records of `executionFailureRecords` for every claim. `executionSummary_partition` proves checked + trusted + unresolved boundaries = boundaries. | `Policy.executionSummary`, both gate renderers |
| [`checkedIndexedResults`](../../lean/StrictLeanPolicy/ResultState.lean) | `@admitIndexedResults`, universe-fixed `α : Type` | `IndexedResultsContract`: `.ok out` iff `out.size = count`, every `binding i out[i]`, and `responses.Perm ((List.range count).zip out.toList)`. Duplicates, unknown or missing slots, rebound payloads and shorter plans are refused. Every satisfying array is returned. | `Common.admitIndexedWorkerResults` (compile batch), `Common.mapWorkQueue` |

The `Policy.ExecutionFailure` record was replaced by an alias of the decision's
own record type. The gate consumes those records, so kind, root, detail and order
are preserved by identity. The total bridge `executionRule` is injective, and
`RuleDiagnostics.executionFinding` no longer has an unreachable wrong-rule branch.
`SourceAudit.compileBatch` no longer repeats the size and binding checks that
`checkedIndexedResults` proves. It keeps the IO check that each source snapshot
is unchanged.

Limits: `ScopeContract` is conditional on the existing `validateCoordinates`
check and on `InventoryValid`. Neither authenticates the supplied transcripts.
`IndexedResultsContract` concerns decoded responses; JSON transport, child
completion and payload truth remain trusted. The `Policy` registrations are in
the excluded operational `StrictLean` library. They are kernel-checked by
`lake build` (warnings are errors), but the axiom gate does not audit them until
#41 moves them to a claimed surface. The ordinary gate recognizes `checkedSummary`
and `checkedIndexedResults` on `StrictLeanPolicy`; the latter exercises a
type-polymorphic implementation. Recognition is unchanged.

Exact axiom sets on Lean 4.34.0: `{}` for `ruleForFailure_injective`,
`executionRule_injective` and `Profile.parse?_eq_some_iff`. Every other new
theorem above has `{propext, Classical.choice, Quot.sound}`.

No new scenario control was added. The existing invalid-evidence and restored
controls on the actual `admitIndexedWorkerResults` consumer (`PolicyQualification.transport`)
still pass. They qualify detection; they are not correctness evidence. The
contracts above are the correctness evidence.

### #40: complete a bounded economy pass

Review these four candidates and either implement a justified simplification or
record the specific reason to retain the current form:

1. `CompleteFor` already uses `p.valid` through `completeFor_iff_slots`, with
   decision and finalizer correspondence proofs. The CI repair also retains
   admitted role receipts instead of reauthorizing at each job, with exact
   equality to recomputation. These are implemented; do not repeat them as
   missing work. Keep runtime and hosted evidence scoped to their receipts.
2. Repeated inventory membership in `policyFor`/`foundationFor` and their callers:
   investigate a reused lawful membership decision/index with proved equivalence,
   preserving invalid-inventory precedence and the fixed observed inventory.
3. `Checks.evaluate_error`/`evaluate_append` and the selected worker fold:
   reuse existing list/monadic laws where they simplify exact first-refusal and
   composition proofs. Do not rewrite the already proved evaluator solely for
   shorter source; `mvcgen` is optional, not a migration objective.
4. Existing `CanonicalSet`/`ExactlyOne` decisions and `Audit.Economy`: retain and
   reuse their equivalences, Std laws, and analytic proof pattern. Do not repeat
   a previously completed optimization or replace the teaching recursion whose
   elaboration/reduction behavior is explicitly the subject of the example.

No speedup is established by this candidate list. Any new cost claim identifies
elaboration/search, artifact, kernel or native execution cost. Derive eliminated
work first; measure only an unresolved empirical decision with a stated budget
and criterion. Preserve the required foundation profile and exact statements.

### #41: bring the selected pure adapters into the conforming surface

The migration set is the pure implementations selected in #39, plus the accepted
assembly/projection definitions delivered by #7 where they are still excluded.
Reconcile this set after #7/#39; definitions already conforming need no duplicate
move. Separate reusable pure policy projections from frontend/IO imports and
connect their callers. Narrow manifest exclusions only with supported coverage;
file moves or theorem wrappers alone are not closure. F11's extraction, source,
kernel-replay and process mechanisms retain explicit trusted boundaries and
their existing qualification requirements. No wholesale migration of every
operational helper, parser or renderer is a prerequisite.

### #42 and #43: report and reconcile the established scope

#42 covers the existing project/file/fence/build-lint result projections and
human/machine reporting in F04/F10/F12. Derive scope and mechanical success from
the accepted evidence, retain exact implementation/requirement identity and
foundation/execution boundaries, and expose the relevant existing residual-review
identifiers. A displayed identifier is not a completed review. Preserve stable
diagnostics and source attribution; version any necessary transport change with
its actual consumers. Full editor workflows and website delivery stay in Project 8.

#43 closes this inventory after the selected work is integrated and reviewed,
with final proof/compiler, applicable qualification, ordinary acceptance and CI
evidence. A selected obligation cannot be closed by renaming it a trusted
boundary. Larger discoveries require separately scoped follow-ups; they do not
silently turn this project into a whole-runtime or whole-repository rewrite.
Then update #14/#15/#10 with the settled APIs and next executable tasks and
release the foundation scheduling hold while preserving other native blockers.

## Evidence and maintenance

The native `lake exe axiomGate -- --incremental --legacy-json-out <report>`
inspection completed successfully on this baseline. Its Lake-derived inventory
and attributed declaration counts were as follows. Suffixes below have the
library prefix; `(root)` denotes the module named exactly as the library.

| Surface | Modules | Attributed declarations |
| --- | --- | ---: |
| `StrictLeanPolicy` | `(root)`, `Specification`, `Identity`, `Claim`, `Decision`, `Pattern`, `Foundation`, `Execution`, `Admission`, `Domain`, `RoleSpecification`, `Plan`, `Collections`, `Codec`, `Observation`, `ResultState`, `Acceptance` | 3649 |
| `StrictLeanVerification` | `(root)` | 101 |
| `StrictLeanQualification` | `Checks`, `Json`, `Evidence`, `Registry`, `Launcher`, `Template`, `Website`, `Producer`, `History`, `Native` | 443 |
| `Audit` | `(root)`, `Research`, `Basic`, `Economy`, `Server`, `DocPrelude`, `DocClaims` | 313 |
| `AuditApp` and standalone executable | `(root)`, `Limiter`, `Refinement`, `Demo`; standalone `Main` | 196 |

These are inventory observations, not proof-volume or completeness metrics.
This incremental inspection is not ordinary acceptance or fresh-source conformance.
An ad hoc `lean --run` inventory probe hit an IR-interpreter assertion before
returning an inventory; it supplies no successful inventory evidence or established
root-cause diagnosis. The native checker supplied the inventory above. A separate
non-running Lean probe successfully elaborated the selected type/axiom queries.

The baseline read-back inspected the existing declarations on the pinned Lean
toolchain, including their elaborated types and transitive axioms. This is scoped
evidence, not a new proof of the collector or the IO mechanisms. The inspected
axiom sets are:

| Exact set | Inspected declarations |
| --- | --- |
| Empty | `ExecutableContract.run_eq`; `AuditApp.admit_exact`. |
| `{propext}` | `StrictLeanPolicy.exactlyOne_iff_head`; `StrictLeanQualification.evaluate_append`. |
| `{propext, Quot.sound}` | `CanonicalSet.adjacentOrdered_iff`; qualification `evaluate_success`, `evaluate_error`, `checkedEvaluation`; `AuditApp.runChecked_success`, `runChecked_error`; `Economy.sumTo_eq_closedSum`, `sumTo_csimp`. |
| `{propext, Quot.sound, Classical.choice}` | Policy `admitInventory_exact`, `admitExecution_preserves`, `policyFor_none_iff`, `foundationFor_iff`, `executionFailureRecords_empty_iff`, `admitPlan_exact`, `ResultState.insertResult_success_iff`, `insertResult_frame`, `accept_iff`, `accepted_report_identity`, `accepted_covers_slot`, `CanonicalSet.normalized_iff_ordered`; `AuditApp.checkedExecutable`. |

Unqualified policy names in this table are in `StrictLeanPolicy`; qualification
names are in `StrictLeanQualification`. Universe parameters remain those of the
elaborated declarations. These sets describe these proofs, not the minimum
foundations of their propositions or a ranking of software assurance.

Issue #38 changes this guide and its index only. It does not change Lean source,
normative requirements, manifests, detection behavior or proof statements.
Relevant review rows are SCOPE-02/03/05, TYPE-01/05, THEOREM-03/07/10,
BUILD-03, DOC-02 and DOGFOOD-03/04 at this guide's scope. No new mutation campaign
or optional serialized-graph claim follows from this planning delivery.
The delivery PR records focused inspection, independent semantic review, exact
head CI and merged-main evidence separately; an existing proof or green build
does not complete F05/F10's remaining delivery gates.

Successors update these same rows with exact integrated definitions, changed
coverage, evidence and remaining boundaries. Keep the source baseline distinguishable
from later closure; do not append another competing status document. Repository
workflow and deadlines remain in [AGENTS.md](../../AGENTS.md); normative meaning
remains in the [standard](../standard/README.md).
