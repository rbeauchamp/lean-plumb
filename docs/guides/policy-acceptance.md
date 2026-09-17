# Policy acceptance and implementation linkage

The POLICY-01 design is implemented by the pure `StrictLeanPolicy` contracts and
operational adapters described below. The [domain guide](policy-domain.md) identifies
admitted data; the [proof guide](policy-proofs.md) gives theorem hypotheses and caller
linkage. [Issue 7 evidence](../../session/evidence/issue-7-verification.md) distinguishes
implemented boundaries, scoped observations and delivery gates still pending.
The [architecture](linter-architecture.md) owns the product and the
[coverage map](rule-coverage.md) owns the twenty rules and nine residual accounts.
Normative meaning remains [chapter 8](../standard/8-tooling-and-machine-audit.md)
and the [chapter 9 checklist](../standard/9-compliance-audit.md).

Con-leche and its authors/contributors, maintained by Joachim Breitner at Lean FRO,
are credited for [complete indexed result assembly][installed] and
[canonical representations with semantic equality][propwhen]. These are design
influences, not imported proofs or copied code. The Strict Lean guarantee
is conditional on observations; it is not con-leche's kernel/model theorem.

## 1. Observed call flow and every success boundary

Paths below start at `lean/StrictLean/`. This source inventory covers actual audit
successes and the intentional non-audit routes. It is not a proof that external
acquisition or the compiled executable is correct. `Checker/Acceptance` is now the
operational bridge, re-exporting the pure API without duplicating policy decisions.

| Invocation / success owner | Required evidence and external boundary |
| --- | --- |
| `AxiomGate.auditSurfaceAt`: fresh project | `Acceptance.freeze` reconciles coordinator-selected Lake modules, source/configuration/dependency state, completed report/replay inventories and origins. `Acceptance.finish` calls `finalize`; success text and `ResultProtocol.writeAccepted` consume its `AcceptedRun.report`. Fresh isolated source build and all existing warning, ownership, exclusion, source and replay guards remain. |
| Same function: `--incremental`, `--build-lint` | The same full policy plan uses `incrementalProject`; cached Lake build artifacts do not cache policy decisions. Build-lint has no second exit-code-only PASS branch. |
| `AxiomGate.auditSurface`: `--with-docs` | The child returns a request-bound `SurfaceProduction` packet containing raw build and inspection observations. The parent waits, reconciles each surface with its own manifest/Lake assignments, recomputes policies, and uses `combineAccepted` on independently accepted project/docs plans with one exact snapshot and Markdown inventory. `CombinedAccepted` is required before combined success. |
| `AxiomGate.auditFile`: explicit conforming profile | Actual compilation and full source/replay/execution observations yield a `freshFile` plan and `AcceptedRun`. `FileSourceBinding` retains both the requested URI and the temporary compiled URI with exact byte equality. Producer/transcript paths are not rewritten. Dependencies remain incremental; this is no whole-project claim. |
| Same function: no profile / compiler-trusting | `CLASSIFIED`, with no conforming `Claim` or accepted-positive receipt. Teaching does not supply logical conformance. |
| `Documentation.auditBuiltProject` and `DocFenceAudit.run` | Freeze all Markdown bytes, original fence spans and task identities before compiling. Group observations retain every unit and authenticate roles against the whole reconciled inventory; policy selection is per original fence. `finishDocuments` calls `finalize`; zero-fence documents still need discovery/build/scan jobs. Terminal inventory/source/configuration/dependency checks remain. |
| `RuleExamples.documentation` | Retains the documentation driver's dependent accepted package. Canonical positive completion additionally requires a nonempty all-positive fence inventory; negative/teaching expectations remain classified. The adapter verifies the original requested documents before emitting accepted metadata. |
| `RuleExamples.inspectNegative`, `RuleExampleQualification`, `Website` | Diagnostic production and exact source/configuration/mode/registry/location qualification retain their separate proof-bearing example APIs. A rejected policy example or an INCOMPLETE diagnostic demonstration is not an audit-success certificate. The four example kinds remain distinct; demonstrations discharge none of them. |
| `FreshChecker.run` | Separate `serializedGraph` claim. `GraphPlanOK` freezes selected roots and supplied import coverage before checker processes; `finishGraph` finalizes actual checked roots against that inventory. External `leanchecker` success remains an observed process result, not a kernel proof of its semantics. |
| `FreshChecker --plan-only`; all help branches | Planning/help completion only, explicitly no audit certificate. |
| `AxiomGate.run`: `--declaration-report-worker`, `--frontend-worker`, `--replacement-history-worker`, `--compile-batch-worker`, `--inspection-group-worker`, `--diagnostic-worker`, `--surface-worker` | Completed raw production only. Strict request/schema/producer/source binding, indexed collection and joins remain. Surface workers suppress audit-success text and leave canonical status incomplete until parent reconstruction. No decoder constructs `Accepted`. |
| Native editor hooks, registry export/validation, site validation, selftests and qualifiers | Existing local observations or scoped diagnostics; no fresh/incremental whole-project certificate. Editor snapshot results are not promoted to global acceptance. |
| `scripts/verify.sh` | Fixed public `axiomGate --with-docs` invocation follows builds and other required checks. The shell's zero exit records completed execution of those commands, not a separate Lean proof. Full cold-root acceptance retains the hard420 deadline. |

The surface worker retains each source-capture prefix for failure reporting. After capture
returns, it compares the complete module/path/byte array with the coordinator's frozen
request before build or inspection. A prefix is not a completed inventory. Parent and
terminal source/configuration guards remain separate. The focused
`python3 scripts/acceptance_checks.py --group sources --evidence tmp/acceptance-sources.json`
diagnostic checks two Lake-discovered sources, shortened/reordered/extra request refusals,
retained source accounts and positive restoration; it does not prove IO extraction.
Its evidence destination is initialized as a new incomplete attempt before binary/setup
reads, retains obtained records on failure, and becomes completed only after every case
and restoration. A killed process cannot promote the current incomplete receipt. Graph
invocations likewise invalidate recognizable absolute result destinations before argument
parsing or root discovery, and relative destinations once their project root is resolved.

Dependency snapshots use Lake's buildable library domains and executable roots to retain
module identities, canonical source paths and exact bytes independently of Git ignore
rules. Library roots whose globs admit their submodules include those submodules even
when the configured target array selects only the root. Git state and dependency
configuration presence/bytes remain additional observations. Terminal checks rediscover the Lake domain and reread
these same inputs, refusing newly added or removed sources; filesystem acquisition and change-and-restore races remain trusted
boundaries. No whole-workspace file scan substitutes for this Lake source inventory.

Standalone documentation and rule-example documentation callers capture dependencies
before their prerequisite build and pass that observation into `auditBuiltProject`.
The combined project/documentation route passes its existing pre-build observation
alongside its shared snapshot. The documentation adapter performs no replacement
capture; it rechecks the supplied dependency observation before finalization.

Project census construction retains failures until the existing policy diagnostic pass
has completed. Unavailable history still prevents acceptance, while its producer-linked
execution findings retain SL3001, `execution-unresolved` and root locations in fresh,
incremental and build-lint modes. A stored census error is raised if no typed policy
failure already refuses the run; it is never replaced by an empty census.

The focused `python3 scripts/acceptance_snapshot_checks.py` diagnostic exercises ignored
Git-backed dependency source/configuration mutations with restoration, and the SL3001
project control through fresh, incremental and build-lint invocations. It checks typed
root/source attribution and absence of acceptance on unavailable history. These are
scoped operational controls, not a proof of IO extraction or a full acceptance run.

`Common.mapWorkQueue`, `admitIndexedWorkerResults` and documentation's task collector
execute `ResultState.collect`; no result slot is overwritten. Group reconciliation
may share identical overlapping imported observations, but never deduplicates job
responses or positive owned declarations. The full admission module/required/admitted
inventories survive the infrastructure partition.

`InfrastructureOrigin` is limited to exact reporter, codec and conditional collector
identities. The IO adapter compares canonical actual artifacts with the running
checker's artifacts; `InfrastructureOK` binds receipts, disjoint ownership and all
observed incoming imports. Public Contract/Diagnostic/StructuralName interfaces do
not imply a whole-library exemption. Ordinary excluded imports remain forbidden.

The pure `Accepted`, `Finalized`, `AcceptedRun` and `CombinedAccepted` constructors
require their stated proofs. Operational raw records, `AcceptedReport`, renderer
strings and generic diagnostic JSON remain data APIs; they do not authorize success.
The success owners above consume the dependent package, and typed
`ResultProtocol.writeAccepted` cannot take a raw report. Constructor visibility is
an ergonomic boundary, not hostile in-process unforgeability. `acceptance` JSON is
rendered metadata only: a parent decodes raw production and recomputes evidence.

## 2. Claim, identity and completeness

### Claim domain

`Claim` contains `Scope`, positive profile assignments, execution assignments,
`EvidenceMode`, requested stages, source/configuration snapshot and supported
toolchain/dependency identity. A project may assign different profiles to different
surfaces: do not collapse its manifest to one maximum profile. `ConformingProfile`
has exactly Kernel-only, Choice-Free, Standard-Logical. Separate `InspectionRequest`
constructors cover no-profile classification and compiler-trusting teaching inspection;
neither constructs a conforming claim.

`EvidenceMode` retains architecture spellings `editorSnapshot`, `incrementalProject`,
`freshProject`, `documentationExample`, `serializedGraph` and adds **`freshFile`**.
`Scope` distinguishes project, file, documentation set and editor module snapshot.
A fresh single-file audit retains its own mandatory stages, scope, mode and renderer.
Registry/result schema1 already includes `freshFile`.
Unsupported scope/mode/stage combinations are rejected by `admitClaim`, not coerced.

Project policy, documentation results and semantic review are separate components.
A completed mechanically accepted project report keeps R-INTENT, R-INVARIANT,
R-LAWS, R-BOUNDARY, R-NONVACUITY, R-DOC, R-COST and R-QUALIFY explicitly unresolved
where applicable; it is not full standard conformance. R-GRAPH is requested separately.
Editor mode admits only its declared completed snapshot checks and lists pending
stages. It has no conversion to fresh/incremental project acceptance.

### Keys and collection meaning

Use Lean `Name` structurally, not `toString`/`String.toName` round trips. Encode the
anonymous/str/num constructor tree reversibly, with tagged components and natural
numbers; anonymous is allowed as a prefix, refused as a module/declaration identity.
Empty string components are preserved for declaration names (Lean can construct them),
not trimmed or conflated with anonymous. Source identities retain exact snapshot bytes
and logical URI; a digest may index storage but digest equality alone is not byte equality.
Dependency Git pins do not prove an unmodified checkout: record actual dirty/path state
as an IO observation. Full filesystem/process authenticity is outside the pure theorem.

| Key | Equality / multiplicity |
| --- | --- |
| Module | Snapshot identity + exact module `Name`; source mapping must be functional. Same module in two claimed surfaces is refused as ambiguous ownership, even with equal profiles. Excluded/excluded overlap may be deduplicated only for the module inventory; target classifications remain distinct. |
| Declaration | Snapshot + owning module + exact constant `Name`; one canonical record. Names shared across independent fence environments remain distinct by snapshot/unit. |
| Executable root | Snapshot + root module/name. Multiple valid registrations for one root share closure work but each registration remains a required declaration/contract obligation. |
| Boundary | Root key + reached declaration + kind + optional replacement target + evidence occurrence. Multiple candidates/history observations are legitimate; preserve their distinct occurrence identities. |
| Fence | Document snapshot + opening/body/closing byte spans + marker kind and expected pattern. Synthesized `DocFence_N` names are temporary transport names, never permanent identity. |
| Job | Claim identity + stage tag + exact subject key; group transport contains individual job keys. Attempts are transport metadata, not new required jobs. |

Required-key sets use canonical duplicate-free sorted collections backed by existing
Std ordered structures, with proved lookup/membership laws. The semantic specification
uses finite membership and unique lookup, independent of storage order. Serialization
sorts by structural keys; work order is separately retained for deterministic diagnostics.
Transcript evaluator chains and mutual-group sequences are **ordered**, not sets.
Axiom lists, module sets and closure edges have set semantics; canonicalization preserves
membership. Duplicate observations for one job are rejected even when payloads match;
retries must discard the prior attempt before admitting a single completed result.
Malformed names/tags/schema, unknown jobs, extra results, contradictory observations,
stale snapshots and unmatched source ranges fail admission. Never overwrite a filled slot.

A project requires at least one claimed nonempty library; retain the baseline refusal
of empty discovered libraries, even exclusions. A real module with zero declarations,
a valid source file with zero declarations, an empty execution-root set, and Markdown
with no Lean fences are allowed **only after their discovery/build/scan jobs complete**.
An empty worker response cannot substitute for an empty authoritative census.

### Independent census and fixed plan

Collection proceeds in explicit phases. (1) Freeze Lake targets, sources, manifest and
Markdown domain. (2) Complete the mode's build/import/admission stages and obtain a census
of owned declaration keys, registered/ordinary roots, and required source/transcript jobs
from the completed environment and source scan. (3) Freeze the required policy jobs before
collecting their results. Closure discovery retains the complete reached-node/edge census
and explicit unresolved paths; a missing closure does not yield an empty boundary set.

Census and policy observations may be extracted in the same process, but the census is
created by traversal before filtering or mapping policy outcomes. It is never computed
from returned successful results. A discovery worker itself has a predeclared required
job; missing/crashed discovery prevents plan finalization. A group worker sends its
census and keyed observations separately and the coordinator reconciles both against
its already requested modules/jobs. That comparison does not independently prove that
the census equals Lean's environment: the extraction linkage is an explicit IO/Lean
boundary, with qualification and source review. No count or hash closes that boundary.

## 3. Independent predicates and executable APIs

The following is mathematical interface notation, **not compiling Lean**. `c` is an
admitted claim, `i` a frozen inventory, `r` the raw keyed result table. `payload(r,k)`
is defined only at its unique completed entry. All quantifiers range over these exact
values; no predicate below is defined as “the checker returned true.”

```text
PlanOK(c,i) := exact configured target partition and source identities
             ∧ mode/stage compatibility ∧ unique subject/job identities
             ∧ required jobs derived from the independent census
CompleteFor(c,i,r) := PlanOK(c,i)
             ∧ keys(r) = requiredJobs(c,i)
             ∧ each key has exactly one terminal completed result
             ∧ every payload binds to c, i, its subject and requested stage
PolicyOK(c,i,k,o) := the applicable conjuncts in the table below
AllPolicyOK(c,i,r) := ∀ k ∈ requiredJobs(c,i), PolicyOK(c,i,k,payload(r,k))
Accepted(c,i,r) := { report with exact c,i,r projections
                  // CompleteFor(c,i,r) ∧ AllPolicyOK(c,i,r) }
accept(c,i,r) : Except AcceptanceFailure (Accepted(c,i,r))
accept_sound : accept(c,i,r) = ok a → CompleteFor(c,i,r) ∧ AllPolicyOK(c,i,r)
accept_complete : CompleteFor(c,i,r) ∧ AllPolicyOK(c,i,r)
                  → ∃ a, accept(c,i,r) = ok a
insertResult(c,i,s,k,o) : Except AdmissionFailure (ResultState(c,i))
```

`ResultState` carries unique keys, a subset of the fixed plan and valid payload bindings;
empty construction and every insertion preserve that invariant. No unchecked mutation
or generic raw JSON constructor returns this state. Failure preserves the prior state;
completion cannot discard an error, unknown or pending slot. `accept_complete` concerns
the fully supported finite data domain, **not** completeness of elaboration, theorem
search, source discovery or detection of arbitrary intended specifications.

| Predicate / normative requirement | Meaning independent of decision code | Actual adapter to change |
| --- | --- | --- |
| `ScopeOK` (§8.1–8.4) | Exact classified targets/modules, required ownership/source/origin bindings; no excluded imports or unattributed requested declarations. | Lake/Manifest → `auditSurfaceAt`; file and grouped inspection admission. |
| `AdmissionOK` (§8.3) | Completed logical admission receipt matches owned dependency census and snapshot; no skipped replay, unsupported admission or emitted warning for a positive fresh claim. | `Environment`/`Admission`, build/compiler receipts. Receipt truth beyond its decoded contents is an explicit operational assumption. |
| `FoundationOK` (§8.5) | No owned logical axiom; no `sorryAx`, unknown or compiler axiom; each exact axiom member belongs to the surface's permitted set. | Typed replacement of `reasonFor`, `labelOf`. Teaching native evidence is a separate result predicate. |
| `SafetyOK` (§8.4) | No unsafe/partial flag unless the exact supported recursive-helper relation holds; helper is not logical proof evidence. | Shared role validator and declaration decision. |
| `ContractOK` (§8.5, §8.12) | Every registered obligation targets the exact supported implementation/predicate, with completed admission and no recorded contract failure. Registration adequacy remains review. | `Probe.executableContract?` → domain adapter; no weakened predicate synthesized in policy. |
| `ExecutionOK` (§8.6) | Every required root's closure is accounted for, no unresolved paths/states; report mode permits reported trusted boundaries, checked mode permits only checked evidence or authenticated native-runtime substrate. | `executionWalk`/origin/correspondence adapters → pure execution decision. |
| `DocumentOK` (§8.7) | Complete structural scan; positives warning-free with logical admission/Standard-Logical policy; negative source rejection has one effective-error match; trusted teaching has compiler evidence and is not positive conformance. | `Documentation.auditTasks` and final aggregation. Execution is not implied. |
| `DocumentationPresenceOK` (§5.1/§5.3; SL5001/SL5002) | Every claimed completed module has module-doc metadata; each public declaration explicitly registered as material-claim evidence has a docstring. Registration completeness and prose fidelity remain R-DOC. | #13 collects module-doc metadata and `findDocString?` for the independently frozen module/registration census; #7 requires those jobs for project and applicable completed-editor scope. |
| `ExampleExpectationOK` (website checked examples) | Exactly the configured positive, compiler-rejection, policy-diagnostic or trusted-teaching expectation holds for the exact source snapshot; see below. | #12 typed expectations → #13 checker → #15 example aggregation; same #7 keyed acceptance contract. |
| `StageOK` (§8.2–8.3, §8.8–8.12) | Required producers completed for this exact mode; absence, crash, unknown or unsupported state is incomplete. | All worker returns and audit/render/exit adapters in §1. Optional graph stages only when requested. |

Mandatory stages are derived by `requiredJobs` from scope/mode and the fixed rule
applicability predicates, never a caller-selected subset for a whole-project claim.
Fresh project requires configuration/discovery, fresh warning-free build, logical
admission, every owned declaration's policy, all execution roots/closures, required
transcripts/history/origins, and documentation-presence jobs. Incremental project has
the same policy obligations with incremental build evidence. FreshFile requires its
fresh warning-free unit compilation/admission, declaration policy and execution closure;
it does not acquire whole-project or documentation-presence coverage. Ordinary fences
retain §8.7's narrower logical-only contract. Editor completion lists its completed
applicable checks and pending stages; module-doc presence waits for module completion,
and registered-public-declaration presence waits for that declaration and its registration.
Serialized graph requires every selected graph root checked, never mere planning.

For website fixtures, `ExampleExpectation` is a tagged sum: positive acceptance;
compiler rejection with a nonempty effective-error pattern; policy rejection with a
nonempty typed expected-diagnostic specification; or authenticated trusted teaching.
A policy-negative source may elaborate successfully (for example SL1001). Its job
requires completed real checker rejection for the exact source/configuration/mode,
an exact match to expected stable rule ID, subreason where specified, and the expected
primary/related source ranges or explicit module/project location. Reject additional
unexpected diagnostics unless the typed expectation explicitly lists them. #12 owns
the only RuleId vocabulary and validates expectation IDs; the core compares transported
stable identity values supplied by that adapter, not a second registry. A pure equality
check on those values does not prove the adapter's ID mapping. Compiler crashes, wrong
source, missing locations, malformed output or incomplete checks satisfy neither negative
variant. These outcomes construct accepted **example expectations**, never conforming
positive program evidence. Docs aggregation fixes the kind of each expected job before
execution, and keeps negative/trusted counts separate from positives.

Unavailable-analysis rules also have separately labelled **diagnostic demonstrations**:
completed authentic production with exact source/configuration/mode, registry ID, reason and
primary/related locations, while the audit result remains INCOMPLETE. These are outside the
four accepted-example kinds and cannot discharge `ExampleExpectationOK`, positive conformance,
or an accepted rejection. Crashes, stale sources, cancellation, missing responses and unrelated
failures do not qualify. Each correction requires its applicable completed positive checks.
The [source-owned corpus contract](rule-examples.md) records concrete page inputs and limits.

Each predicate must be elaborated as a declarative relation over data, with named
components corresponding to these requirements; its decision function is proved sound
and complete against it. Data-level evidence can be constructed with proof fields by
any Lean client that supplies the proof. Private constructors are an ergonomic boundary,
not a claim of adversarial in-process unforgeability. Operational receipt constructors
stay in the trusted adapter; the pure theorem explicitly assumes their interpretation.

## 4. Domain and role proofs

`DeclarationKind` covers all eight `ConstantInfo` variants. `BoundaryKind` covers the
eight §8.6 kinds and `Correspondence` has checked/trusted/unresolved, with evidence
indexed by kind. Use a separate six-way `FoundationClass`: the three logical labels,
hole, unknown-axiom, compiler-trusting. Parse failures are errors, never a new permitted
constructor. `ConformingProfile` cannot contain compiler-trusting. Codecs prove
`decode(encode x) = ok x`; accepted canonical external spellings re-encode identically.
Legacy pretty names are display only; do not promise reversible identity for them.

For axiom set A, define K = ∅, C = {propext, Quot.sound},
S = C ∪ {Classical.choice}. Logical classification returns the least of K ⊆ C ⊆ S
containing A. Prove containment and minimality for every A ⊆ S, not by enumerating
sample programs. Empty A is Kernel-only; duplicate/order changes do not alter the label.
For other A retain diagnostic precedence: hole, then unknown, then compiler-trusting.
Declaration refusal precedence stays: owned axiom (authorized teaching exception only),
hole, unknown, escape hatch, compiler trust, executable-contract failure, profile excess.
Malformed input is refused **before** policy precedence. Execution reports every
unresolved path; deterministic rendering follows frozen plan order, not worker timing.

`RecursiveHelperOK(decls,transcripts,h)` is the conjunction of **all** guards currently
in `authorizedUnsafeRecHelpers`: same-module def/base linkage; range-less internal partial
opaque-hinted safe helper with no extern/replacement; structural/well-founded whole-value
and generated-equation exactness and defeq observations; equation axiom bound; safe regular
recursive base, identical type/universes; helper axiom subset; nonempty mutual group and
exact ordered helper-name transform, self-reference; unique same introducing command,
exact literal/nested binder attribution, pinned evaluators and complete introduced group.
Do not collapse exactness and definitional comparison, or set-normalize ordered groups.

`NativeTeachingOK(decls,transcripts,a)` retains **all** guards in
`authorizedNativeAxioms`: internal safe proposition axiom, exact Boolean shape and successful
replay, permitted dependency set; same-module safe proposition parent of supported kind,
exact parent-use shape, unique direct user; nested exact ranges; unique introducing command
shared with parent; literal declaration, pinned complete evaluator chain and one native
range. Names only locate candidates. This evidence only permits teaching classification;
it never relaxes a conforming profile.

Freeze these relations as independently written component predicates, then prove the
**executed** typed validators return evidence iff the relation holds on supported records.
Their input records include the actual data-level observations presently tested (including
exact-value/equation/replay flags). A proof about those flags does not prove they truthfully
represent an environment: `Probe`, fresh `Frontend`, canonical artifact checks and completed
kernel admission retain responsibility for that linkage. A free Bool/name array supplied
by a consumer is not an authenticated role. `Policy.reasonFor` must consume validated
role evidence bound to the whole declaration/transcript inventory, not caller whitelists.

## 5. Pure module boundary and migration

The root namespace and Lake library **`StrictLeanPolicy`** use the umbrella
`lean/StrictLeanPolicy.lean`. Imports are acyclic and remain within Init/Std and
the pure library. Foundation and role specifications support declaration decisions;
Plan derives required jobs, Observation defines stage predicates, and Acceptance
assembles complete results. Codec defines a pure tagged wire tree.
JSON parsing/printing stays in `Checker/PolicyCodec.lean`; prove decoded-tree codec laws
in Codec and qualify the operational parser, including duplicate-field rejection.
A tree-codec theorem is not a theorem about JSON text parsing. No Environment, Meta,
Frontend, IO execution, native evaluation, partial/unsafe, Report, RuleDescriptor or
Mathlib import belongs in the pure policy library.

`Checker/PolicyDomain.lean` remains a compatibility import. `Checker/Acceptance.lean`
re-exports the pure definitions and assembles observations through them; it defines no
duplicate policy. Operational `Checker/Policy.lean` is the adapter/legacy renderer;
`Checker/PolicyCodec.lean` handles worker/report JSON. Move transcript **data** shapes
into the pure domain (including source/range/evaluator keys); `Frontend` imports them,
never vice versa. `Report` can serialize typed domain observations; pretty strings are
non-authoritative. Registry ID/payload/rendering stays owned by #12; it maps typed policy
failures to the existing twenty IDs and preserves subreasons. The pure core does not
import the registry, so no cycle forms when diagnostics import policy types.

The `lean_lib StrictLeanPolicy` has `.andSubmodules` discovery, a positive
Standard-Logical manifest entry as an initial upper bound, and explicit ordinary
acceptance build coverage. Report every declaration's **actual** least label and exact
axioms; reduce the upper bound only after checking the complete import/proof closure.
This root avoids both the excluded `StrictLean` glob and `Environment.loadReportCore`'s
whole-`StrictLean` trusted overlay, which would otherwise mask fresh proof modules.
Audit, AuditApp/Main and the operational StrictLean exclusion remain. Teach tooling and
guides the new library via Lake discovery, not hardcoded declaration/file lists.

| Owner | Deliverable and gate |
| --- | --- |
| #5 POLICY-02 | Domain/codec admission and universal representation/codec/collection laws, typed roles/claims/records, canonical keys, invariant-preserving state API, compatibility adapters. Wire every policy caller to typed input; preserve detector behavior on supported baseline data, with explicit fail-closed extensions for malformed/duplicate data and positive file warnings. Record unavailable #6 theorems as pending, not proved. |
| #6 POLICY-03 | Remaining Specification/Decision/Acceptance theorems: least-label proof, decision iff predicates, exact role evidence, insertion/frame laws, accepted soundness/completeness and report identity. Check actual functions used by #5; no duplicate reference evaluator assumed equivalent. |
| #7 POLICY-04 | Freeze census/plan, validate all worker packets and every success boundary in §1, consume Accepted values in renderers/exit adapters, compose project+docs under one snapshot. Refuse empty/missing/duplicate/mismatched responses through public paths. Remove obsolete raw success APIs only after accounting for all callers. |
| #12 CATALOG | Keep one registry; add `freshFile`, share scope/status identities with core; accepted diagnostics export is read-only projection, never certificate input. |
| #13 ENGINE | Shared semantic collectors for current-document and imported modules; complete census/roots/role extraction and typed outcomes for all twenty rules; two scoped doc-presence checks retained. |
| #14 ADOPTION | All actual Lake lint/build/editor adapters consume the same outcome; cached policy re-evaluation and source-located links retained; freshFile and snapshot modes honestly labeled. |
| #10 DELIVERY / #15 WEBSITE | Reconcile residual semantic accounts and same-revision rule/example/status exports. No accepted data report is full conformance; site consumes status, not exit code alone. |
| #8/#9 optional | Separate requested graph/export jobs and result type; absence cannot block core policy/site delivery. No new export format or adapter selected here. |

Native dependency refinements: #13 requires #5’s shared domain as well as #12;
#15 requires #7’s complete example-result boundary as well as #12/#13. Both edges
are acyclic and leave optional #8/#9 outside core prerequisites.

Manifest schema stays 2. Freeze new worker transport schema 1, independent of #12's
registry/result schema 1: schemaVersion, producer/toolchain identity, claim/snapshot,
job key, stage and raw payload; require exact keys, tags, types and supported versions.
All parent and worker executables must use that protocol together; reject mixed versions.
Reject duplicate JSON object fields before map construction (ordinary parsed maps may
lose duplicates), unknown fields, duplicate identities and out-of-range machine values.
Use Nat for semantic indices; checked conversion for UInt32 exit codes and byte offsets.
Wire results carry observations, never serialized Lean proofs or an authoritative accepted
flag. Revalidate and rerun the pure decision after decoding. Bind path remapping to display
fields, replacing `writeRemappedJson`'s text-wide replacement; immutable identity stays intact.

Preserve legacy text subreasons on supported inputs. Introduce the versioned result format
explicitly, not as a silent reinterpretation of old optional `--json-out`; retain old output through `--legacy-json-out PATH`, mutually exclusive with the new
`--json-out PATH`, with no certificate import. #12/#7 document the transition and update
consumers together before removing any legacy output option.
No promise of exact legacy JSON bytes, broader supported inputs or improved runtime is made.

## 6. Cache/pin decision, evidence and remaining obligations

**No new acceleration/certificate API is selected.** The existing replacement correspondence
cache in `Probe.environmentReport` stores checked results by name pair in one fixed environment;
replacement-history memoization is scoped to one report. Preserve these scopes. A future
cross-environment cache would need equality of all relevant inputs plus revalidated evidence
and a proof that varying candidate data cannot weaken acceptance. None is justified here.
Generated-role and canonical runtime recognition determine policy authority; they are not
untrusted acceleration hints. Profiles, scope and pins likewise are normative configuration,
not freely variable candidate data. Con-leche's [parameterized pin/check pattern][installed]
is a reference for separating these roles, not a reason to make our trust pins optional.
No speculative scheduling or fast/reference implementation is proposed.

This delivery is a source-grounded design. It changes no Lean implementation or checked Lean
example, and claims no new compiler result, axiom coverage, performance or full compliance.
The inspected root pins remain Lean 4.33.1 (`819816b2e0a3bf405af45ae5c7af2491d8f5bee6`),
Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`. Earlier PRODUCT-01 runtime results are
historical, scoped evidence; they do not prove these new contracts. Full implementation
acceptance remains one **unpartitioned `./scripts/verify.sh` with a hard 420-second deadline**
including cold root builds after pinned dependency/coreutils/ShellCheck setup.

Applicable design review rows: SCOPE-01–05, TYPE-01–03/06, THEOREM-01/03/06/07,
FOUND-01–05, DECL-01–04, COMP-01–04, BUILD-01–04, DOC-01–05 and DOGFOOD-03/05,
for the proposed contracts and their linkage only. This is not a PASS claim for those
rows over all repository surfaces. TYPE-04/05 and remaining theorem/doc/dogfood rows
are unchanged; all residual accounts still apply to eventual full conformance.

#5–#7 must retain §8.8 positive/intended-reason/restored controls for profiles,
holes/axioms, generated-role forgeries, owned-module attribution, replay bypass,
correspondence, warnings and fence protocol. Pure universal proofs replace neither
source extraction nor process/transport integration qualification. Changed worker
protocols require public-entrypoint controls for omitted/duplicate/substituted keys,
wrong modes/snapshots, worker crash and malformed versions. Changed Library/overlay
coverage requires a fresh imported-client control and exact Lake inventory checks.
Use `./scripts/verify.sh diagnostics` with an applicable existing partition
(`fixtures`, `structural`, `cli`, `environments`, `build-policy`) and add focused
controls where absent; do not report an unrun campaign PASS. `serialized-graph`
remains separate. No timing experiment is necessary for this design; if implementation
cost becomes decision-bearing, define its measurement and resource budget then.

Implemented proof coverage is recorded in the [domain](policy-domain.md) and
[proof](policy-proofs.md) guides, with exact axiom evidence in their delivery records.
Remaining **implementation obligations** are assigned rather than silently assumed:
#7/#13 establish collector/worker linkage and acceptance at all call sites;
#12/#14/#15 qualify schema/editor/site consumers.
Unsupported compiler versions, incomplete census/admission, ambiguous role origin and
unresolved execution are decided refusals. No unresolved design choice blocks starting #5;
any failed proof or pin capability blocks its specific guarantee and must be reported.

[installed]: https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean
[propwhen]: https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Kernel/PropWhen.lean
