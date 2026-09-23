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
#41 adds the claimed `StrictLeanCore` library; see the #41 delivery below.

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
| F02 | [`Inventory`, `admitInventory`, `admitExecution`](../../lean/StrictLeanPolicy/Admission.lean); [`Policy.admitScope`](../../lean/StrictLean/Checker/Policy.lean) is called by project/file/fence inspection. | Admitted values carry validity; exact admission retains input observations, and execution admission has a preservation theorem. The adapter first checks frontend coordinates, then admits inventory and computes roles. #39: `admitScope` runs `checkedScope` (`ScopeContract`): first coordinate refusal in transcript order, then exactly `admitInventory` with `authorize`; success iff every coordinate check and `InventoryValid` hold, retaining both arrays. Supplied transcripts are not authenticated. #41: `checkedScope` is on claimed `StrictLeanCore` and quantifies over every coordinate check; the adapter passes `Frontend.validateCoordinates`, which runs the claimed `checkedCoordinates` (`CoordinateContract`: success iff `CoordinatesAgree`, refusal with the first unmet obligation in traversal order) at Lean's LSP UTF-16 column function (see #41 delivery). | Core and coordinate check **E** (claimed); Lean's UTF-16 column function and acquisition **T**; #41 (this delivery). |
| F03 | [`policyFor`, `foundationFor`, `declarationFailure`](../../lean/StrictLeanPolicy/Decision.lean); `Policy.ruleForMember`, `labelOfMember`, `classifyMember` (#40) in project/file gates, with `ruleFor`, `reasonFor`, `labelOf` kept for arbitrary input; [`Linter.Rules.declarations`](../../lean/StrictLean/Linter/Rules.lean) for local feedback. | Existing equivalences cover membership, policy, all six classification outcomes and ordered first failure. #39: `request` runs `checkedRequest` (`RequestContract`, by spelling); `ruleFor` runs `checkedRule` (`RuleContract`) over `policyFor`, with `ruleForFailure_injective` and `reasonFor_eq_some_iff`. #40: per-declaration callers iterate the admitted inventory and run the member forms `checkedMemberFailure`/`checkedMemberFoundation`/`checkedMemberRule`, equal to `policyFor`/`foundationFor`/`ruleFor` on every member, without the membership scan. Environment collection remains separate. #41: these projections, `labelOf`/`labelOfMember` and the registry they map to are on claimed `StrictLeanCore`; `classify`/`classifyMember` stay adapter renderers. | Core and projections **E** (claimed), collection **T**; #41 (this delivery). |
| F04 | [`executionFailureRecords`, `executionSummary`](../../lean/StrictLeanPolicy/Execution.lean); `Policy.executionFailureRecords`, `executionFailures` and gate rendering. | Empty pure failures iff `ExecutionOK` for every admitted finite inventory and mode. #39: `Policy.executionFailureRecords` is the decision's own records (identity); `executionRule` is injective; `executionSummary` runs `checkedSummary` (`SummaryContract`). Counts describe observations of a conservative account, not a minimal native call graph. #41: `executionRule` is on claimed `StrictLeanCore`; `executionFailures` text stays an adapter renderer. | Decision, projection and counts **E**, extraction **T**; reporting #42. |
| F05 | [`CensusOK`, `requiredJobs`, `Plan`, `admitPlan`](../../lean/StrictLeanPolicy/Plan.lean); [`accept`, `Accepted.report`](../../lean/StrictLeanPolicy/Acceptance.lean). | Coordinator-fixed requests retain the full claim and separate environment inventories. Plan fields require exact derived jobs and claim; accepted evidence requires completeness and policy for those inputs. The actual freeze/finish callers consume this evidence. Final delivery evidence remains open. #41: the pure census assembly is on claimed `StrictLeanCore`. `surfaceAssignments`, `conformingProfile`, `histories`, the environment-job lookup and documentation-evidence selection have contracts. `accept` decides the other stages of `observations` again. | Core and linkage **E/T**; delivery **#7 only**. |
| F06 | [`ResultState.insertResult`, `collect`](../../lean/StrictLeanPolicy/ResultState.lean); [`finalize`](../../lean/StrictLeanPolicy/Acceptance.lean); [`Common.admitIndexedWorkerResults`](../../lean/StrictLean/Checker/Common.lean). | Insertion and full-sequence collection retain unknown, duplicate and binding refusals. `finalize_iff` relates actual raw occurrences to exact required-slot policy coverage; split IO collection/acceptance carries equality to this finalizer. #39: `admitIndexedWorkerResults` and `mapWorkQueue` run `checkedIndexedResults` (`IndexedResultsContract`). Packet decoding and worker execution remain distinct. #41: the decision was already claimed; the adapter only decodes JSON and renders refusal text. | Collection, finalization and worker projection **E**, transport **T**; #41 (this delivery). |
| F07 | [`evaluate`, `checkedEvaluation`](../../lean/StrictLeanQualification/Checks.lean); [`Qualification.requireChecks`](../../lean/StrictLean/Qualification/Support.lean) calls `checkedEvaluation.run`. | Exact success iff all supplied assertions hold, first false assertion, and append/bind composition are already proved and consumed. The empty list succeeds. The evaluator cannot establish that an adapter supplied all needed assertions or truthful IO observations. Retain the implementation and inspect changed callers; do not rebuild a generic assertion framework. #40: success and first-refusal now reuse the shared `forM_eq_ok`/`forM_eq_error` laws, also used by `admitScope`, via `evaluate_eq_forM`; statements unchanged. #41 moved `forM_eq_error` to claimed `StrictLeanPolicy.Traversal`; success now reuses the existing `Guards.listForM_eq_ok`. | **E/T**; boundary account #41 (this delivery). |
| F08 | [`AuditApp.RequiredContracts`, `checkedExecutable`](../../lean/AuditApp/Limiter.lean); [`Main`](../../lean/Main.lean) invokes the contract with `requiredContracts`. | Admission, updates, frames, exact success/refusal and strict composition concern the actual runner. The intrinsic bound alone would not prove those relations. [`Refinement`](../../lean/AuditApp/Refinement.lean) relates that runner to finite abstract paths. Retain as the reference pattern; it is not a theorem about checker orchestration or OS effects. | **E/T**; reuse #39; no selected application rewrite. |
| F09 | [`CanonicalSet` decisions and `ExactlyOne`](../../lean/StrictLeanPolicy/Collections.lean), used by admission/role/plan predicates; [`Economy.sumTo_csimp`](../../lean/Audit/Economy.lean) illustrates proved replacement. | Std supplies extensional collections and laws; adjacent-order and singleton-head equivalences already avoid redundant work. The arithmetic example proves one universal identity and an equality of executable definitions. Preserve duplicate-rejection versus set-normalization semantics and separate kernel reduction from compiler replacement. #40 retained these unchanged (see #40 delivery). | **E/T**; #40 review complete. |
| F10 | [`AxiomGate.auditSurfaceAt`, `auditSurface`, `auditFile`, `run`](../../lean/StrictLean/Checker/AxiomGate.lean); [`Documentation.auditBuiltProject`](../../lean/StrictLean/Checker/Documentation.lean), [`DocFenceAudit.run`](../../lean/StrictLean/Checker/DocFenceAudit.lean); sample [`policy` target](../../examples/build-lint/lakefile.lean). | Actual project/file/fence/build-lint success consumes accepted evidence; project-with-docs consumes same-snapshot `CombinedAccepted`. The [success-call-site map](policy-acceptance.md) distinguishes workers/help/local feedback and incremental modes from fresh conformance. The private fence finalizer consumes unchanged admitted task output. | Linkage **E/T**; delivery **#7 only**, reporting #42. |
| F11 | [`Workspace.withRootWorkspace`](../../lean/StrictLean/Checker/Workspace.lean), `Lake.surfaceInventory`, [`SourceBinding`](../../lean/StrictLean/Checker/SourceBinding.lean), [`Admission.validate`](../../lean/StrictLean/Checker/Admission.lean), [`Frontend`](../../lean/StrictLean/Checker/Frontend.lean), [`ProducerReport`](../../lean/StrictLean/Checker/ProducerReport.lean). | Existing source/configuration, complete inventory, compiler and replay observations are bound to the accepted request and terminally reconciled. Policy validity does not authenticate their observations, filesystem, external processes or native code. Qualification and the [boundary table](policy-acceptance.md) remain required; no wholesale proof of these mechanisms is selected. #41 lists these as the remaining adapters of the narrowed exclusion. | Bound integration implemented; acquisition **T**; #7, explicit adapter boundary #41 (this delivery). |
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
| [`checkedScope`](../../lean/StrictLeanCore/Policy.lean) | private `admitScopeImpl` via `Policy.admitScope` | `ScopeContract`: (1) with `ts.toList = before ++ t :: after`, every `before` check `.ok ()` and `validateCoordinates ds t = .error e`, the result is `.error e`; (2) when every coordinate check succeeds, the result is exactly `(admitInventory ds ts).map (⟨·, authorize ·⟩)`; (3) success iff every coordinate check succeeds and `InventoryValid ds ts`; (4) success retains `ds` and `ts`. `Roles.eq_authorize` already fixes the roles. | project, file, fence, rule-example, acceptance freeze, environment census and self-test inspection |
| `checkedRequest` | private `requestImpl` via `Policy.request` | `RequestContract`: no claim gives `.classification`; `.teaching` iff compiler-trusting; `.conforming q` iff `profile.toString = q.spelling`. `Profile.parse?_eq_some_iff` states the spelling input meaning. | `ruleFor`, `ruleForMember` (#40); `Acceptance.conformingProfile` |
| `checkedRule` | private `ruleForImpl` via `Policy.ruleFor` | `RuleContract`: `none` iff `policyFor … (request claim) = none`, and `some (ruleForFailure f)` iff that decision is `some f`. With `ruleForFailure_injective` and `policyFor_ordered`, the rule is the first failed requirement's. `reasonFor_eq_some_iff` gives the same relation for applicability text. | `reasonFor`; through `MemberRuleContract` (#40), the project/file gates, fence and rule-example audits now run `checkedMemberRule` |
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
#41 moves them to a claimed surface (done; see #41 delivery). The ordinary gate recognizes `checkedSummary`
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

#### #40 delivery

The bounded candidate set is the four candidates above, plus the uniqueness and
traversal proofs the issue lists. Two changes were selected; the others are
retained for the reasons given.

| Candidate | Decision | Before → after, and reason |
| --- | --- | --- |
| 1. `CompleteFor` / `PlanOK` | Retained | Already derived from `p.valid` (`completeFor_iff_slots`); role receipts are retained, not reauthorized. Nothing left to remove. |
| 2. Inventory membership in `policyFor`/`foundationFor` callers | **Replaced** | Every product per-declaration caller iterated the inventory it had just admitted, yet each call re-decided `d ∈ i.declarations`. The new member forms take the membership proof from iteration (`for h : d in inventory.declarations`), so no scan runs. `policyFor`/`foundationFor` are unchanged for arbitrary input, including invalid-inventory precedence. |
| 3a. Pure `Except` traversal proofs | **Replaced** | `Policy`'s private `forM_ok`/`forM_first` repeated the induction behind `evaluate_success`/`evaluate_error`. Both now reuse `StrictLeanQualification.forM_eq_ok`/`forM_eq_error` (#41: `forM_eq_error` is in `StrictLeanPolicy.Traversal`, and the success law is `StrictLeanPolicy.Guards.listForM_eq_ok`); `evaluate_eq_forM` identifies the unchanged recursive `evaluate` with `checks.forM Check.step`. `forM_first` (one direction) became the `←` half of an exact first-refusal equivalence. |
| 3b. `evaluate_append` via core `List.forM_append` | Retained | The core law is for any lawful monad; using it raises this theorem's exact set from `{propext}` to `{propext, Quot.sound}`. The five-line induction keeps `{propext}`. |
| 3c. Worker fold `mapM_ok`, `Template.mapM_related` | Retained | They prove different conclusions: indexed pointwise versus `List.Forall₂`. A shared `Forall₂` form would import Batteries into `StrictLeanPolicy` solely to shorten proofs. #39 already gave both worker callers one permutation characterization. |
| 3d. `Std.Do`/`mvcgen` | Not adopted | The selected programs are pure `Except` traversals, and the laws above discharge them directly. |
| 4. `CanonicalSet`/`ExactlyOne`, `Audit.Economy` | Retained | These equivalences are already the derived decisions (adjacent order, singleton head, `sumTo_csimp`). The teaching recursion is itself the subject. |
| Uniqueness (`distinct_iff`) | Retained | This is already a hash-set cardinality decision with a proved equivalence to `Pairwise (· ≠ ·)`. |
| Verbose `classify` listing in `auditSurface` | Retained | It lists a filtered, sorted copy, so membership would need a `qsort` permutation proof. The listing is verbose-only. |

New registrations. Each requirement is a named `Prop`, separate from its proof:

| Registration | Implementation | Required relation | Callers |
| --- | --- | --- | --- |
| [`checkedMemberFailure`](../../lean/StrictLeanPolicy/Decision.lean) | `memberFailure i roles d member request := declarationFailure d request roles.native roles.helpers` | `MemberFailureContract`: for all `i`, `roles : Roles i`, `d`, `member : d ∈ i.declarations` and `request`, the result equals `policyFor i roles d request`. | `Policy.ruleForMember`; `Linter.Rules.declarations` |
| `checkedMemberFoundation` | `memberFoundation i roles d member := labelOf d.axioms roles.native` | `MemberFoundationContract`: `foundationFor i roles d = .ok (memberFoundation i roles d member)` for every member; the member form has no error case. | `Policy.labelOfMember`, and through it `classifyMember` |
| [`checkedMemberRule`](../../lean/StrictLeanCore/Policy.lean) | private `ruleForMemberImpl` via `Policy.ruleForMember decl claim scope member` | `MemberRuleContract`: equals `ruleFor decl claim scope` for every `member : decl ∈ scope.inventory.declarations`. Therefore `RuleContract` and first-failure precedence carry over unchanged. | project gate `auditSurfaceAt`, file gate `auditFile`, `Documentation.assessPositive`, rule-example policy audit, self-test `renderFileAudit` |

Supporting theorems are `labelOf_member` (`labelOf decl scope = .ok (labelOfMember …)`) and
`classifyMember_eq` (`classifyMember decl scope member = classify decl scope`).
The shared traversal laws are `forM_eq_ok`/`forM_eq_error`; since #41 they are
[`Guards.listForM_eq_ok`](../../lean/StrictLeanPolicy/Guards.lean) and
[`forM_eq_error`](../../lean/StrictLeanPolicy/Traversal.lean). The first
is success iff every element succeeds; the second is refusal with `e` iff some split
`before ++ x :: after` has every `before` element succeeding and `f x = .error e`.
`EvaluationContract` and `ScopeContract` are unchanged.

Caller linkage. `ScopeContract` (4) gives `scope.inventory.declarations = ds` for the
array each caller admitted, and `admitInventory_exact` does the same for the linter.
So iterating the inventory visits the same sequence as before. Each element's rule,
reason and classification are equal by the contracts above. IO effects in the
loop bodies keep their order, and diagnostics, findings and snapshots are unchanged.
The file gate now computes one rule per declaration; its reason is `reasonFor`'s by
definition. Its unreachable "internal rule classification mismatch" branch is gone.

Structural saving (native execution only; no timing is claimed or needed). The
derived `DecidableEq Declaration` has no pointer shortcut. Deciding membership of the
`k`-th element therefore compares it with each of the `k` earlier records, which fail at
`name`. It then compares all fields of the equal record, including strings and arrays.
One decision over each of `n` members did `n(n+1)/2` such comparisons, and `n` of them
were full-record. Now it does none. Per declaration, the project gate removed one scan
plus two per violation. The file gate removed two, plus, per violation,
two scans and one duplicate rule computation; its self-test mirror removed two. `assessPositive` removed two per unit
declaration, the rule-example audit removed one plus one per violation, and the editor
snapshot removed one. The prototype `examples/rule-reference-prototype/Probe.lean` still uses
`reasonFor`. For proofs, the saving is reuse, not size: one pair of traversal
inductions now serves the evaluator and scope admission, where two separate ones did
before. Source lines grew, since `forM_eq_error` proves both directions and
`forM_first` proved one. No artifact size, elaboration time or kernel time was measured,
and none is claimed. No compiler replacement (`csimp`, `implemented_by`) was added.

Exact axiom sets on Lean 4.34.0 are as follows. `{}` for `evaluate_eq_forM`.
`{propext}` for `evaluate_append`, unchanged. `{propext, Quot.sound}` for `forM_eq_ok`,
`forM_eq_error`, `evaluate_success`, `evaluate_error` and `checkedEvaluation`; the last
three are unchanged. `{propext, Classical.choice, Quot.sound}` for
`checkedMemberFailure`, `checkedMemberFoundation`, `checkedMemberRule`, `labelOf_member`,
`classifyMember_eq` and `checkedScope`, the last unchanged. All are within each
library's Standard-Logical claim.

Evidence (local, warm, observations only). Each row names the head or base it was
observed on. None is evidence for the final rebased head, whose acceptance is its
exact-head CI run.

| Check | Observed on | Result |
| --- | --- | --- |
| `./scripts/verify.sh` | this change over base `4aa6c89` | PASS, 121 s. 40 owned modules, 5377 declarations. The gate recognizes `checkedMemberFailure` and `checkedMemberFoundation` on `StrictLeanPolicy`. |
| `./scripts/verify.sh docs` | this change over base `4aa6c89` | PASS, 126 s (70/70, 23/23, 1/1) |
| `./scripts/verify.sh` | head `2f090ab` (this change over `8de0e85`) | PASS, 121 s. 41 owned modules, 5431 declarations. The gate recognizes `checkedMemberFailure` and `checkedMemberFoundation`. |
| `./scripts/verify.sh docs` | head `2f090ab` (this change over `8de0e85`) | PASS, 82 s |
| `diagnostics fixtures` | this change over base `4aa6c89` | PASS, 173 s |
| `diagnostics cli` | this change over base `4aa6c89` | PASS, 358 s (60 `axiomGate --file` invocations: file gate and self-test mirror) |
| `diagnostics rule-examples 1/2`, `2/2` | this change over base `4aa6c89` | PASS, 130 s and 92 s (rule-example policy audit) |
| `diagnostics build-policy` | this change over base `4aa6c89` | PASS, 282 s (`--build-lint` through the changed project-gate loop) |

These diagnostics qualify detection on the changed paths; they are not correctness
evidence. The two acceptance steps exercise the project gate and `assessPositive`,
and the editor linter (`Linter.Rules`) through the ordinary step's native-linter
qualification. The structural, environments, producers and history diagnostics were not
run locally, since their capabilities are unchanged; CI Diagnostics covers them.
Axiom sets came from `#print axioms` on the built modules.

Limits. The member forms decide nothing about non-members; `policyFor` remains the API
for arbitrary input. The new core registrations are on the claimed `StrictLeanPolicy`
surface. `checkedMemberRule` shares the #39 `Policy` limit: it is kernel-checked by
`lake build` but not audited by the gate until #41. The shared traversal laws live in
`StrictLeanQualification.Checks`, which `Checker/Policy.lean` imports; a #41 move of
`checkedScope` into a claimed policy module must move or restate them. (#41 moved `forM_eq_error` and reused `Guards.listForM_eq_ok`; see above.) No scenario control was added.
The contracts are the correctness evidence; qualification detects, it does not prove.

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

#### #41 delivery

The exclusion held the selected pure components in `Checker/Policy.lean` and #7's pure
census assembly in `Checker/Acceptance.lean`. They now live in a new claimed library, [`StrictLeanCore`](../../lean/StrictLeanCore/Policy.lean):
a Lake `.submodules` glob, manifest claim `standard-logical`, execution `report`. The
policy library may not import the rule registry (see
[policy acceptance §5](policy-acceptance.md#5-pure-module-boundary-and-migration)), and
the rule projections need it. So the registry moved with them. Moved declarations keep
their names and namespaces. These call sites changed:

- `AxiomGate` renders `surface.execution.spelling`, since `Manifest.Surface.execution`
  is now `StrictLeanPolicy.ExecutionClaim` itself.
- `Acceptance.historyObservations` only concatenates the reports' outcomes and runs
  `checkedHistories`.
- `Frontend.validateCoordinates` is now `checkedCoordinates.run lspUtf16Column`, and
  `Diagnostic.sourceFromReport` is `sourceFromReportWith lspUtf16Column`.
- `observations` runs `checkedEnvironmentJob` for environment jobs.
- `checkedScope` and `evaluate_success` use `Guards.listForM_eq_ok` for the success law.

| Component | Now in | Change and reason |
| --- | --- | --- |
| `PolicyScope`, `admitScope` via `checkedScope` (`ScopeContract`) | `StrictLeanCore.Policy` | `ScopeContract` now quantifies over every coordinate check `check : CoordinateCheck`, with the same four clauses. The adapter `Policy.admitScope ds ts` is `checkedScope.run Frontend.validateCoordinates ds ts`. Instantiating the contract at that check gives the #39 relation exactly. |
| `validateCoordinates`, now `coordinateCheck` (`checkedCoordinates`, `CoordinateContract`) | [`StrictLeanCore.Coordinates`](../../lean/StrictLeanCore/Coordinates.lean) | New contract, for every UTF-16 column function. Success holds exactly when `CoordinatesAgree`: each command's `added` equals its `addedDeclarations` names; each command, evaluator and binding range has positive lines, round-trips through the transcript's `FileMap` at both ends, and starts no later than it stops; and each declaration of the transcript's module has ranges that convert against the snapshot (`RangesConvert`). Refusal is exactly the message of the first unmet entry of `coordinateObligations`, listed in traversal order (`Decides`, `FirstUnmet`). The loops became `List.forM` traversals, and the inventory guard became `commandInventory`. Order and messages are unchanged. |
| `SourceCandidate`, `admitSource`, `SourceLocation`; `sourceFromReport`'s conversion, now `sourceFromReportWith` with `reportedRange` (`reportedRange_eq`) | [`StrictLeanCore.Source`](../../lean/StrictLeanCore/Source.lean) | Moved from `StrictLean.Diagnostic`, with the UTF-16 column as a parameter `Utf16Column`. `Diagnostic` keeps `lspUtf16Column` (Lean's `FileMap.leanPosToLspPos`), `sourceFromReport` at that column, and the LSP range renderers. The module imports only `Lean.Data.Position` and the policy domain. |
| `Profile`, `request` (`checkedRequest`), `Profile.parse?_eq_some_iff` | `StrictLeanCore.Policy` | Moved unchanged. |
| `ruleFor` (`checkedRule`), `ruleForMember` (`checkedMemberRule`), `reasonFor`, `reasonFor_eq_some_iff`, `applicability_ruleForFailure_injective` | `StrictLeanCore.Policy` | Moved unchanged. |
| `labelOf`, `labelOfMember`, `labelOf_member` | `StrictLeanCore.Policy` | Moved unchanged. |
| `executionRule`, `executionRule_injective` | `StrictLeanCore.Policy` | Moved unchanged. |
| Registry `RuleId`, `Rule` (`ruleForFailure`, `descriptor`) | `StrictLeanCore.RuleId`, `StrictLeanCore.Rule` | Moved from `StrictLean.RuleId`/`StrictLean.Rule`. `StrictLean.Diagnostic` imports the new module. |
| `forM_eq_error` | [`StrictLeanPolicy.Traversal`](../../lean/StrictLeanPolicy/Traversal.lean) | Moved from `StrictLeanQualification.Checks`, which now imports it. The statement is unchanged. The module imports only `Init`. The success law `forM_eq_ok` was not moved: `checkedScope` and `evaluate_success` use the existing `StrictLeanPolicy.Guards.listForM_eq_ok` instead. |
| `conformingProfile` (`checkedConformingProfile`, `ConformingProfileContract`) | [`StrictLeanCore.Assembly`](../../lean/StrictLeanCore/Assembly.lean) | New contract: success exactly with the conforming profile of the same spelling, and refusal exactly for compiler-trusting. It is proved by reduction to the new `request_contract` (`RequestContract` stated about `request`). Nothing downstream rechecks a surface's profile. |
| `surfaceAssignments` (`checkedSurfaceAssignments`, `SurfaceAssignmentsContract`) | `StrictLeanCore.Assembly` | New contract: success exactly with one `SurfaceAssigned` claim surface per manifest surface, in order. That relation fixes the library name, the execution claim, the profile of the manifest's spelling, and the modules: the first same-named Lake library's modules followed by each claimed executable's first same-named root. The implementation was restated as a per-surface `mapM` with the same refusals and messages. Nothing downstream rechecks profile or execution. |
| `configuredTargets`, `discoveredTargets` | `StrictLeanCore.Assembly` | Moved unchanged, without a contract. They are total field projections of the manifest and Lake records, so a contract would restate them. The claimed `TargetPartitionOK` checks them against each other and against the contracted claim surfaces. |
| `FrozenEnvironment`, `Frozen`, `frozenEnvironmentRoles` (`_eq`), `modulePresence` (`_iff`), `observations` | `StrictLeanCore.Assembly` | Moved unchanged except as below and in the next two rows, without a new contract of their own. The claimed `accept` decides again every stage but documentation presence. `ResultBound` and `PolicyOK` fix key, snapshot and completion, and `StageOK`/`LocalStageOK` bind each record to its job's subject and census; for example, a declaration must be in the inventory with the key's module and name. For those stages a wrong choice is refused, and the remaining risk is a spurious refusal. |
| Evidence selection, now `checkedEnvironmentEvidence` (`DocumentationEvidenceContract`) | `StrictLeanCore.Assembly` | New soundness contract, because `LocalStageOK` checks only that a docstring is present, not whose it is. A success reports the presence of the only record with the job's module name, or with its module and declaration names; a refusal fails closed. `observations` runs this registration on the environment `checkedEnvironmentJob` selects. |
| Environment lookup, now `checkedEnvironmentJob` (`EnvironmentJobContract`) | `StrictLeanCore.Assembly` | New contract for every environment job, documentation slots included. Success means exactly one frozen environment has the job's `census.request.key`, and the evidence is that environment's `checkedEnvironmentEvidence` result for the job's stage and subject. A missing or duplicate key is refused. `observations` runs this registration. |
| History assembly, now `histories` (`checkedHistories`, `HistoriesContract`); `ProducerReport.HistoryOutcome` | `StrictLeanCore.Assembly` | New contract: success exactly when every outcome completed, with one exact copy (module, path, before and after sources, replacement edges) per outcome in order. An unavailable history is refused, never dropped. `HistoryOK` cannot tell whether the replacement edges were copied faithfully, so this is not decided again downstream. `historyObservations` now only concatenates the reports' outcomes and runs this. The unsupported-evaluator list stays empty here: the operational `--replacement-history-worker` refuses a module with unsupported evaluators, so such a history arrives unavailable and is refused. |
| Manifest records (`Manifest.Surface`, `Manifest`, exclusions) and Lake inventory records (`Lake.SurfaceInventory` and parts) | `StrictLeanCore.Assembly` | Data types moved so the contracts can state them. Parsing and Lake loading stay in `Checker/Manifest.lean` and `Checker/Lake.lean`. |
| `mapM_eq_ok` | `StrictLeanPolicy.Traversal` | Was private `mapM_ok` in `ResultState`. It is now shared by `checkedIndexedResults`, `checkedSurfaceAssignments` and `checkedHistories`; the statement is unchanged. |
| `checkedSummary`, `checkedIndexedResults`, `checkedMemberFailure`, `checkedMemberFoundation`; #7's `Plan`, `ResultState`, `accept`, `finalize`, `combineAccepted` | `StrictLeanPolicy` | Already claimed, so not moved again. |

The narrowed exclusion keeps the following. Each item is a total projection, observes
something external, or only renders text around a claimed decision.

- `Diagnostic.lspUtf16Column` is Lean's `FileMap.leanPosToLspPos` column.
  `Frontend.validateCoordinates` and `sourceFromReport` pass it to the claimed
  `checkedCoordinates` and `sourceFromReportWith`. It stays outside the claimed closure
  because `Lean.Data.Lsp.Utf16` imports `Lean.Environment`. The contracts hold for every
  column function, so they do not verify Lean's UTF-16 arithmetic. That arithmetic is a
  pinned toolchain function, trusted in the same way as `FileMap.toPosition`, which is
  `partial` and which the contracts treat as opaque.
- `Checker/Acceptance.historyObservations` only concatenates each report's outcomes
  (`flatMap`) before running `checkedHistories`.
- `Checker/Policy.lean` keeps the text renderers `executionFailures`,
  `describeBoundary`, `classify` and `classifyMember`, with `classifyMember_eq`.
- `Common.admitIndexedWorkerResults` and `mapWorkQueue` decode worker JSON and render
  refusal text around the claimed `checkedIndexedResults`.
- `Checker/Acceptance`'s `freeze`, `finish`, `buildObservation` and `sourceSnapshots`
  read IO-derived records and hand them to the claimed plan and finalizer.
  `ResultProtocol`'s JSON projections are #42's reporting work.
- The F11 mechanisms stay trusted: Workspace, Lake inventory, SourceBinding, Admission
  replay, Frontend transcript production, ProducerReport and Probe. They use `IO`,
  `Environment` or `Meta`.
- The #51/#52 transport-admission theorems were not in the #39 selection. They keep
  their in-module `collectAxioms` ceiling.

Caller linkage. Every #39/#40 caller still executes the same registration's `run`.
`Policy.admitScope` now passes the frontend check, itself `checkedCoordinates.run`, to
the core registration. `sourceFromReport` callers (`Findings`, and `DiagnosticCodec`
and `RegistryChecks` through `admitSource`) run the moved claimed definitions. The
unchanged callers now run the new registrations. `surfaceAssignments` is called by the
project gate `auditSurfaceAt` (including build-lint), `FreshChecker` and the
environment-census qualification. `conformingProfile` is called by the file gate. All seven excluded checker executables reach these definitions through
`Checker.Policy`, by way of `Manifest` and `Lake`: `axiomGate`, `docFenceAudit`,
`freshChecker`, `checkerSelftest`, `qualify`, `ruleExamples` and
`ruleExampleQualification`. The claimed `auditApp` does not use them.

Coverage, from ordinary acceptance on Lean 4.34.0 and Mathlib `5ed29652`, on this
delivery's final Lean sources rebased onto main `ecd78bc`:

- 6 claimed libraries, 49 owned modules and 6586 owned declarations. #40's head
  `e2d00b5` had 41 modules and 5446 declarations. Main added
  `StrictLeanQualification.CorpusWindow` in #55.
- The excluded `StrictLean` library has 71 modules, down from 73 on main.
- `StrictLeanCore` has 6 modules and 1064 attributed declarations: `Assembly` 381,
  `Coordinates` 61, `Policy` 188, `Rule` 293, `RuleId` 96 and `Source` 45.
- Exact axiom sets across those 1064: 768 `{}`, 108 `{propext}`, 13
  `{propext, Quot.sound}` and 175 `{propext, Classical.choice, Quot.sound}`.
- The gate recognizes ten registrations on `StrictLeanCore`: `checkedScope`,
  `checkedRequest`, `checkedRule`, `checkedMemberRule`, `checkedCoordinates`,
  `checkedConformingProfile`, `checkedSurfaceAssignments`, `checkedHistories`,
  `checkedEnvironmentEvidence` and `checkedEnvironmentJob`.
- Execution coverage for `StrictLeanCore`: 408 roots and 3242 boundaries (489 checked,
  2753 trusted), 0 unresolved. The trusted boundaries are reported Lean core and runtime
  mechanisms, not verified ones.

Named axiom sets, from `#print axioms`:

| Set | Declarations |
| --- | --- |
| `{}` | `Profile.parse?_eq_some_iff`, `executionRule_injective`, `ruleForFailure_injective`, `RuleId.parse_spelling`, `RuleId.all_nodup` |
| `{propext}` | `RuleId.spelling_injective`, `RuleId.mem_all`, `modulePresence_iff`, `decides_pure`, `decides_guard` |
| `{propext, Quot.sound}` | `forM_eq_error`, `RuleId.route_injective`; `Guards.listForM_eq_ok`, `evaluate_success`, `evaluate_error`, `checkedEvaluation` (unchanged) |
| `{propext, Classical.choice, Quot.sound}` | `checkedCoordinates`, `coordinateCheck_decides`, `coordinateObligations_hold`, `commandCoordinates_decides`, `rangeCoordinates_decides`, `sourceFromReportWith_decides`, `reportedRange_eq`, `Decides.ok_iff`, `Decides.bind`, `decides_forM`, `decides_forM_map`, `firstUnmet_append`, `all_iff_not_firstUnmet`, `checkedEnvironmentJob`, `checkedScope`, `checkedRequest`, `request_contract`, `checkedRule`, `checkedMemberRule`, `reasonFor_eq_some_iff`, `applicability_ruleForFailure_injective`, `labelOf_member`, `checkedConformingProfile`, `checkedSurfaceAssignments`, `checkedHistories`, `checkedEnvironmentEvidence`, `frozenEnvironmentRoles_eq`, `mapM_eq_ok` |

Moved declarations keep the sets they had before the move. `checkedScope` and
`evaluate_success` keep theirs after switching to `Guards.listForM_eq_ok`.

Limits. The core contracts concern supplied declarations, transcripts, and manifest,
Lake and history records. They do not authenticate how transcript bytes were acquired, and
they do not verify Lean's UTF-16 column function. They also do not authenticate manifest
parsing, Lake loading, environment extraction, compiler or
worker processes, JSON transport, or native code. Report mode reports the trusted
runtime boundaries; it does not verify them. `classifyMember_eq` and the adapter
renderers remain kernel-checked by `lake build` only. No scenario control was added:
the contracts are the correctness evidence, and the existing controls qualify
detection.

Evidence (local, warm, observations only). "Final" means this delivery's Lean sources
rebased onto main `ecd78bc`. `16d694b` preceded the coordinate, environment-job, history
and documentation-evidence contracts, the traversal-law collapse and the rebase:

| Check | Lean sources | Result |
| --- | --- | --- |
| `./scripts/verify.sh` | final | PASS, 172 s. 6 claimed libraries, 49 owned modules, 6586 declarations; all ten `StrictLeanCore` registrations recognized |
| `./scripts/verify.sh docs` | final | PASS, 178 s (70/70, 23/23, 1/1); only this table changed afterwards |
| `checkerSelftest --forced-collector-only` | final | PASS, 313 s (fresh positive, excluded-source refusal, restored) |
| `diagnostics fixtures` | final | PASS, 129 s |
| `diagnostics environments` | `16d694b` | PASS, 204 s |
| `diagnostics build-policy` | `16d694b` | PASS, 266 s |
| `diagnostics structural` | `16d694b` | FAIL, 211 s; pre-existing: the same 37 failure labels as main `fa62dd1` (300 s) |

The `structural` partition fails with 37 failures, and main `fa62dd1` fails with the
same 37 failure labels. Its `structuralManifestText` omits libraries that the
repository now has, so most controls are refused as an unclassified library (SL2002)
before reaching their intended diagnostic. The rest (the unknown-library wording,
correspondence and init-module-origin controls) fail the same way on main. It
therefore gives no import-boundary evidence for this change.

For the changed import boundary, the existing `checkerSelftest --forced-collector-only`
control uses the real manifest, including `StrictLeanCore`. It runs a fresh positive,
then refuses a claimed module that imports the excluded `StrictLean.Collect`, then runs
a restored positive. Its mutation targets `AuditApp`, not `StrictLeanCore`. It covers
the new surface only because the gate applies one import check to every claimed
library.

The fixtures partition runs the policy fixtures through `admitScope` and
`ruleForMember`. The environments partition covers packaging, including external
adoption of the changed Lake package. The build-policy partition runs `--build-lint`
through the project gate's census assembly. `cli` was not run: the file gate reaches
the same definitions through a front door this change does not touch. Ordinary
acceptance runs the final history and evidence assembly on the real project. That
includes the environment-census qualification's omitted, duplicate and rebound
environment and source-binding mutations. CI Diagnostics runs producers, history and
both rule-example shards.

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
