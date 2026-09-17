import StrictLeanPolicy.Plan
import StrictLeanPolicy.Pattern

/-! Typed raw completion observations and independent policy predicates for the fixed plan.
Receipts are data, not serialized proofs: their truthful acquisition and the registry/location
bridge remain operational assumptions. Pure declaration, execution and expectation decisions
are recomputed over the supplied observations. -/
namespace StrictLeanPolicy
open Lean (Name)

inductive Completion where
  | completed | incomplete | cancelled | crashed | unsupported
  deriving Repr, DecidableEq

structure BuildObservation where
  exitCode : Nat
  warnings : Array String
  errors : Array String
  deriving Repr, DecidableEq

structure AdmissionObservation where
  required : Array DeclarationKey
  admitted : Array DeclarationKey
  failures : Array String
  deriving Repr, DecidableEq

structure HistoryObservation where
  moduleName : Name
  before : SourceSnapshot
  after : SourceSnapshot
  replacements : Array (Name × Name)
  unsupported : Array String
  deriving Repr, DecidableEq

/-- A producer's terminal example outcome is distinct from transport/process completion.
Policy-negative diagnostics come from the real checker/sole-registry adapter, not invented
compiler errors. The pure matcher does not authenticate that operational production. -/
inductive ExampleOutcome where
  | elaborated (inventory : Inventory) (requiredReplay admittedReplay : Array (Name × Name))
      (admissionFailures : Array String)
  | compilerRejection (effectiveErrors : Array String)
  | policyRejection (diagnostics : List ExpectedDiagnostic)
  | incomplete (detail : String)

/-- Explicit temporary-unit mapping permits grouped inspection without conflating its
source units. Each unit retains the original fence identity and exact compiler source. -/
structure ExampleUnit where
  moduleName : Name
  fence : FenceKey
  source : SourceSnapshot
  deriving Repr, DecidableEq

structure ExampleObservation where
  fence : FenceKey
  unitName : Name
  units : Array ExampleUnit
  before : String
  after : String
  warnings : Array String
  declarationCensus : Array (Name × Name)
  outcome : ExampleOutcome

/-- Complete scan of the exact document domain, including no-fence files. -/
structure DocumentObservation where
  documents : Array SourceSnapshot
  fences : Array FenceKey
  structuralFailures : Array String

structure GraphObservation where
  selected : Array ModuleKey
  checked : Array ModuleKey
  covered : Array ModuleKey
  failures : Array String
  plannedOnly : Bool

/-- Evidence constructors constrain stage meaning. A mismatched constructor/subject cannot
satisfy StageOK. Completion alone never substitutes for the applicable field relations. -/
inductive JobEvidence where
  | configuration (assignments : Array TargetAssignment) (targets : Array DiscoveredTarget)
  | discovery (observation : Census)
  | build (observation : BuildObservation)
  | admission (observation : AdmissionObservation)
  | declaration (observation : Declaration)
  | execution (observation : ExecutionRoot)
  | transcript (observation : Frontend.Transcript)
  | history (observation : HistoryObservation)
  | origin (observation : NativeOrigin)
  | documentationPresence (docstring : Option String)
  | documentScan (observation : DocumentObservation)
  | example (observation : ExampleObservation)
  | graph (observation : GraphObservation)

structure JobObservation where
  key : JobKey
  snapshot : Snapshot
  completion : Completion
  evidence : JobEvidence

/-- Snapshot and target observations match the independently fixed configuration account. -/
def ScopeOK (c : Claim) (i : Census) (asgn : Array TargetAssignment)
    (targets : Array DiscoveredTarget) : Prop :=
  asgn = i.configuredTargets ∧ targets = i.discoveredTargets ∧ TargetPartitionOK c i
instance (c : Claim) (i : Census) (a : Array TargetAssignment) (t : Array DiscoveredTarget) :
    Decidable (ScopeOK c i a t) := by unfold ScopeOK; infer_instance

/-- Build source processing succeeded without any emitted warning or error. -/
def BuildOK (o : BuildObservation) : Prop := o.exitCode = 0 ∧ o.warnings = #[] ∧ o.errors = #[]
instance (o : BuildObservation) : Decidable (BuildOK o) := by unfold BuildOK; infer_instance

/-- Every frozen replay key is admitted exactly once, with no skipped/failed observations. -/
def AdmissionOK (i : Census) (o : AdmissionObservation) : Prop :=
  o.required = i.admissionDeclarations ∧ o.admitted.toList.Pairwise (· ≠ ·) ∧
  (∀ d ∈ o.required, d ∈ o.admitted) ∧ (∀ d ∈ o.admitted, d ∈ o.required) ∧ o.failures = #[]
instance (i : Census) (o : AdmissionObservation) : Decidable (AdmissionOK i o) := by
  unfold AdmissionOK; infer_instance

/-- Source coordinates are checked against exact bytes; module/project locations remain
explicit rather than being converted to a fabricated line number. -/
def LocationOK (c : Claim) : PolicyLocation → Prop
  | .source source range => source ∈ snapshotSources c ∧ range.start ≤ range.stop ∧
      String.Pos.Raw.isValid source.source ⟨range.start⟩ = true ∧
      String.Pos.Raw.isValid source.source ⟨range.stop⟩ = true
  | .module key => key.snapshot.val = c.val.snapshot
  | .project snapshot => snapshot.val = c.val.snapshot
instance (c : Claim) (l : PolicyLocation) : Decidable (LocationOK c l) := by
  cases l <;> unfold LocationOK <;> infer_instance

/-- Optional subreason means it is unconstrained; locations and all listed related locations
are exact. List correspondence preserves the configured deterministic diagnostic order. -/
def DiagnosticMatches (c : Claim) (expected actual : ExpectedDiagnostic) : Prop :=
  expected.rule ≠ "" ∧ actual.rule = expected.rule ∧
  (∀ reason ∈ expected.subreason, reason ≠ "" ∧ actual.subreason = some reason) ∧
  actual.primary = expected.primary ∧ actual.related = expected.related ∧
  LocationOK c actual.primary ∧ ∀ location ∈ actual.related, LocationOK c location
instance (c : Claim) (e a : ExpectedDiagnostic) : Decidable (DiagnosticMatches c e a) := by
  unfold DiagnosticMatches; infer_instance

/-- Replay coverage for a fresh example includes every safe nonpartial reported declaration;
its independently supplied owned-dependency census must also be completely admitted. -/
def ExampleAdmissionOK (i : Inventory) (required admitted : Array (Name × Name))
    (failures : Array String) : Prop :=
  required.toList.Pairwise (· ≠ ·) ∧ admitted.toList.Pairwise (· ≠ ·) ∧
  canonicalEdges admitted = canonicalEdges required ∧ failures = #[] ∧
  ∀ d ∈ i.declarations, d.isUnsafe = false → d.isPartial = false → (d.module, d.name) ∈ required
instance (i : Inventory) (r a : Array (Name × Name)) (f : Array String) :
    Decidable (ExampleAdmissionOK i r a f) := by unfold ExampleAdmissionOK; infer_instance

/-- Every role transcript is tied to an exact original source unit in the fixed fence
plan, including grouped environments. Policy assessment selects this fence's declarations
while role authentication still sees the whole reconciled group inventory. -/
def ExampleSourceOK (fences : Array FenceKey) (f : FenceKey) (o : ExampleObservation)
    (i : Inventory) : Prop :=
  o.unitName ≠ .anonymous ∧ o.units.toList.Pairwise (fun a b => a.moduleName ≠ b.moduleName) ∧
  o.units.toList.Pairwise (fun a b => a.fence ≠ b.fence) ∧
  (∃ unit ∈ o.units, unit.moduleName = o.unitName ∧ unit.fence = f) ∧
  (∀ unit ∈ o.units, unit.moduleName ≠ .anonymous ∧ unit.fence ∈ fences ∧ unit.source.uri ≠ "" ∧
    unit.source.source = String.Pos.Raw.extract unit.fence.document.source
      ⟨unit.fence.body.start⟩ ⟨unit.fence.body.stop⟩) ∧
  (∀ d ∈ i.declarations, ∃ unit ∈ o.units, unit.moduleName = d.module) ∧
  (∀ t ∈ i.transcripts, ∃ unit ∈ o.units, unit.moduleName = t.module ∧
    unit.source.uri = t.source ∧ unit.source.source = t.sourceContent)
set_option synthInstance.maxSize 1024 in
instance (fs : Array FenceKey) (f : FenceKey) (o : ExampleObservation) (i : Inventory) :
    Decidable (ExampleSourceOK fs f o i) := by unfold ExampleSourceOK; infer_instance

/-- Example expectation meaning: positive/teaching inspect actual pure policies; compiler
negatives match one effective error; policy negatives require exact completed rejection
observations. Negative/teaching results never supply conforming positive program evidence. -/
def ExampleExpectationOK (c : Claim) (fences : Array FenceKey) (f : FenceKey) (o : ExampleObservation) : Prop :=
  o.fence = f ∧ o.before = String.Pos.Raw.extract f.document.source ⟨f.body.start⟩ ⟨f.body.stop⟩ ∧
  o.after = o.before ∧
  match f.expectation, o.outcome with
  | .positive, .elaborated i required admitted failures =>
      let roles := authorize i
      o.warnings = #[] ∧ o.declarationCensus = i.declarations.map (fun d => (d.module, d.name)) ∧
      ExampleSourceOK fences f o i ∧ ExampleAdmissionOK i required admitted failures ∧
      ∀ d ∈ i.declarations, d.module = o.unitName → DeclarationOK d (.conforming .standardLogical) roles.native roles.helpers
  | .compilerRejection pattern _, .compilerRejection errors =>
      ∃ message ∈ errors, PatternMatch pattern message
  | .policyRejection expected _, .policyRejection actual =>
      expected.length = actual.length ∧
      ∀ pair ∈ expected.zip actual, DiagnosticMatches c pair.1 pair.2
  | .trustedTeaching, .elaborated i required admitted failures =>
      let roles := authorize i
      o.warnings = #[] ∧ o.declarationCensus = i.declarations.map (fun d => (d.module, d.name)) ∧
      ExampleSourceOK fences f o i ∧ ExampleAdmissionOK i required admitted failures ∧
      (∀ d ∈ i.declarations, d.module = o.unitName → DeclarationOK d .teaching roles.native roles.helpers) ∧
      ∃ d ∈ i.declarations, d.module = o.unitName ∧ ∃ n ∈ d.axioms, CompilerAxiom roles.native n
  | _, _ => False

/-- No incomplete terminal outcome satisfies any of the four accepted expectations.
A separately qualified unavailable-analysis demonstration cannot change this predicate. -/
theorem incomplete_example_refused (c : Claim) (fences : Array FenceKey) (f : FenceKey)
    (o : ExampleObservation) (detail : String) (h : o.outcome = .incomplete detail) :
    ¬ ExampleExpectationOK c fences f o := by
  cases f.expectation <;> simp [ExampleExpectationOK, h]

/-- Completed scan and exact frozen fence inventory, including structural failures. -/
def DocumentOK (c : Claim) (i : Census) (o : DocumentObservation) : Prop :=
  (match c.val.scope with | .documentation docs => o.documents = docs | _ => False) ∧
  o.fences = i.fences ∧ o.structuralFailures = #[]
instance (c : Claim) (i : Census) (o : DocumentObservation) : Decidable (DocumentOK c i o) := by
  unfold DocumentOK; cases c.val.scope <;> infer_instance

/-- Presence is the deliberately narrow metadata requirement; content fidelity and the
completeness of material-claim registration remain the separate R-DOC review obligation. -/
def DocumentationPresenceOK (docstring : Option String) : Prop := docstring ≠ none

/-- Native-runtime evidence must agree with every relevant boundary origin observation. -/
def OriginOK (i : Census) (m : ModuleKey) (origin : NativeOrigin) : Prop :=
  origin.moduleName = m.name.name ∧
  ∀ r ∈ i.execution.roots, ∀ b ∈ r.boundaries,
    b.module = m.name.name → b.boundary = .nativeRuntime → b.account.nativeOrigin? = some origin
instance (i : Census) (m : ModuleKey) (o : NativeOrigin) : Decidable (OriginOK i m o) := by
  unfold OriginOK; infer_instance

/-- History is bound to unchanged exact source, with no recorded unsupported evaluator,
missing replay, or current replacement absent from the observed history. -/
def HistoryOK (c : Claim) (i : Census) (m : ModuleKey) (o : HistoryObservation) : Prop :=
  o.moduleName = m.name.name ∧ o.before ∈ snapshotSources c ∧
  (∃ entry ∈ i.allModuleSources, entry.1 = m ∧ entry.2 = o.before) ∧
  o.after = o.before ∧ o.unsupported = #[] ∧
  ∀ r ∈ i.execution.roots, ∀ b ∈ r.boundaries,
    b.module = m.name.name → b.boundary = .runtimeReplacement →
      ∃ target ∈ b.replacement, (b.name, target) ∈ o.replacements
set_option synthInstance.maxSize 1024 in
instance (c : Claim) (i : Census) (m : ModuleKey) (o : HistoryObservation) : Decidable (HistoryOK c i m o) := by
  unfold HistoryOK; infer_instance

/-- Every selected graph root was checked and the resulting closure covers all claimed
modules. Plan-only and missing roots cannot satisfy a serialized-graph expectation. -/
def GraphOK (i : Census) (o : GraphObservation) : Prop :=
  o.plannedOnly = false ∧ o.failures = #[] ∧ o.selected ≠ #[] ∧
  o.selected.toList.Pairwise (· ≠ ·) ∧ o.checked.toList.Pairwise (· ≠ ·) ∧
  (∀ m ∈ o.selected, m ∈ o.checked ∧ m ∈ i.modules) ∧
  (∀ m ∈ o.checked, m ∈ o.selected) ∧ (∀ m ∈ i.modules, m ∈ o.covered) ∧
  ∀ m ∈ o.covered, m ∈ i.allModules
instance (i : Census) (o : GraphObservation) : Decidable (GraphOK i o) := by unfold GraphOK; infer_instance

set_option synthInstance.maxSize 1024 in
instance (c : Claim) (fences : Array FenceKey) (f : FenceKey) (o : ExampleObservation) :
    Decidable (ExampleExpectationOK c fences f o) := by
  unfold ExampleExpectationOK
  cases f.expectation <;> cases o.outcome <;> dsimp <;> infer_instance

/-- Exact stage/subject/evidence correspondence and each applicable normative conjunction.
There is no success case for a mismatched payload constructor or an unrequested subject. -/
def StageOK (c : Claim) (i : Census) (roles : Roles i.policy) (key : JobKey) : JobEvidence → Prop
  | evidence => match key.stage, key.subject, evidence with
    | .configuration, .scope, .configuration assignments targets => ScopeOK c i assignments targets
    | .discovery, .scope, .discovery observed => observed = i
    | .build, .scope, .build observed => BuildOK observed
    | .admission, .scope, .admission observed => AdmissionOK i observed
    | .declarationPolicy, .declaration k, .declaration d =>
        d ∈ i.policy.declarations ∧ d.name = k.name.name ∧ d.module = k.moduleKey.name.name ∧
        ∃ profile ∈ profileForModule c d.module,
          DeclarationOK d (.conforming profile) roles.native roles.helpers
    | .execution, .root k, .execution r =>
        r ∈ i.execution.roots ∧ r.name = k.name.name ∧ r.module = k.moduleKey.name.name ∧
        ∀ request ∈ rootRequests c i r.name,
          r.unresolved = #[] ∧ ∀ b ∈ r.boundaries, BoundaryOK request b
    | .transcript, .module m, .transcript t =>
        t ∈ i.policy.transcripts ∧ t.module = m.name.name ∧
        ∃ entry ∈ i.moduleSources, entry.1 = m ∧ entry.2.uri = t.source ∧ entry.2.source = t.sourceContent
    | .history, .module m, .history observed => HistoryOK c i m observed
    | .origin, .module m, .origin observed => OriginOK i m observed
    | .documentationPresence, .module _, .documentationPresence doc => DocumentationPresenceOK doc
    | .documentationPresence, .declaration _, .documentationPresence doc => DocumentationPresenceOK doc
    | .documentScan, .scope, .documentScan observed => DocumentOK c i observed
    | .example, .fence f, .example observed => ExampleExpectationOK c i.fences f observed
    | .graph, .scope, .graph observed => GraphOK i observed
    | _, _, _ => False

set_option synthInstance.maxSize 2048 in
instance (c : Claim) (i : Census) (roles : Roles i.policy) (k : JobKey) (e : JobEvidence) :
    Decidable (StageOK c i roles k e) := by
  dsimp only [StageOK]
  split <;> (try dsimp only [DocumentationPresenceOK]) <;> infer_instance

/-- Policy acceptance recomputes the applicable field relation for this exact bound snapshot.
The completion tag is an observed terminal producer state, not proof of external execution. -/
def PolicyOK (c : Claim) (i : Census) (roles : Roles i.policy) (o : JobObservation) : Prop :=
  o.key.claim = c ∧ o.snapshot = c.val.snapshot ∧ o.completion = .completed ∧
  StageOK c i roles o.key o.evidence
instance (c : Claim) (i : Census) (roles : Roles i.policy) (o : JobObservation) :
    Decidable (PolicyOK c i roles o) := by unfold PolicyOK; infer_instance

end StrictLeanPolicy
