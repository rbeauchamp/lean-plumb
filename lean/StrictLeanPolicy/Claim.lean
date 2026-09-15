import StrictLeanPolicy.Domain

/-! Claims, snapshots and coverage keys for policy consumers. Claims represent requested
mechanical scope, never an accepted result. Sources and dependency states are exact
observations; the IO collector remains responsible for their truthful acquisition. -/
namespace StrictLeanPolicy

structure ToolchainIdentity where
  leanVersion : String
  compilerCommit : String
  producerRevision : String
  deriving Repr, DecidableEq

/-- A pin alone cannot identify a modified or path dependency; retain its actual files. -/
structure DependencyState where
  package : String
  nominalRevision : Option String
  dirty : Bool
  files : Array SourceSnapshot
  deriving Repr, DecidableEq

structure Snapshot where
  sources : Array SourceSnapshot
  configuration : SourceSnapshot
  toolchain : ToolchainIdentity
  dependencies : Array DependencyState
  deriving Repr, DecidableEq

/-- Structural validity of exact content maps; truthful acquisition stays operational. -/
def Snapshot.Valid (s : Snapshot) : Prop :=
  s.sources.toList.Pairwise (fun a b => a.uri ≠ b.uri) ∧
  (∀ f ∈ s.sources, f.uri ≠ "") ∧ s.configuration.uri ≠ "" ∧
  s.toolchain.leanVersion ≠ "" ∧ s.toolchain.compilerCommit ≠ "" ∧
  s.toolchain.producerRevision ≠ "" ∧
  s.dependencies.toList.Pairwise (fun a b => a.package ≠ b.package) ∧
  (∀ d ∈ s.dependencies, d.package ≠ "" ∧
    d.files.toList.Pairwise (fun a b => a.uri ≠ b.uri) ∧ ∀ f ∈ d.files, f.uri ≠ "")
instance instDecidableSnapshotValid (s : Snapshot) : Decidable s.Valid := by unfold Snapshot.Valid; infer_instance

abbrev AdmittedSnapshot := { s : Snapshot // s.Valid }

def admitSnapshot (s : Snapshot) : Except String AdmittedSnapshot :=
  if h : s.Valid then .ok ⟨s, h⟩ else .error "invalid snapshot identity or content map"

theorem admitSnapshot_exact (s : Snapshot) (h : s.Valid) :
    admitSnapshot s = .ok ⟨s, h⟩ := by simp [admitSnapshot, h]

/-- Snapshot plus exact module identity. Filesystem provenance is not a proof field. -/
structure ModuleKey where
  snapshot : AdmittedSnapshot
  name : Identity
  deriving Repr, DecidableEq

structure DeclarationKey where
  moduleKey : ModuleKey
  name : Identity
  deriving Repr, DecidableEq

abbrev RootKey := DeclarationKey

/-- Distinct observed occurrences are legitimate even for one reached declaration. -/
structure BoundaryKey where
  root : RootKey
  reached : DeclarationKey
  kind : BoundaryKind
  replacement : Option DeclarationKey
  occurrence : Nat
  reachedSnapshot : reached.moduleKey.snapshot = root.moduleKey.snapshot
  replacementSnapshot : ∀ r ∈ replacement, r.moduleKey.snapshot = root.moduleKey.snapshot
  deriving Repr, DecidableEq

inductive FenceExpectation where
  | positive
  | compilerRejection (pattern : String) (nonempty : pattern ≠ "")
  | policyRejection (diagnostics : List String) (nonempty : diagnostics ≠ [])
  | trustedTeaching
  deriving Repr, DecidableEq

/-- Rule ID strings in policy-negative expectations must be validated by the sole
registry adapter. The policy library deliberately defines no second RuleId enumeration. -/
structure FenceKey where
  document : SourceSnapshot
  opening : ByteRange
  body : ByteRange
  closing : ByteRange
  expectation : FenceExpectation
  nonemptyURI : document.uri ≠ ""
  ordered : opening.start ≤ opening.stop ∧ opening.stop ≤ body.start ∧
    body.start ≤ body.stop ∧ body.stop ≤ closing.start ∧ closing.start ≤ closing.stop
  validPositions : ∀ n ∈ [opening.start, opening.stop, body.start, body.stop, closing.start, closing.stop],
    (String.Pos.Raw.isValid document.source ⟨n⟩) = true
  deriving Repr, DecidableEq

inductive Scope where
  | project
  | file (source : SourceSnapshot) (profile : ConformingProfile) (execution : ExecutionClaim)
  | documentation (documents : Array SourceSnapshot)
  | editor (moduleName : Identity) (source : SourceSnapshot)
      (profile : ConformingProfile) (execution : ExecutionClaim)
  deriving Repr, DecidableEq

inductive Stage where
  | configuration | discovery | build | admission | declarationPolicy | execution
  | transcript | history | origin | documentationPresence | documentScan | example | graph
  deriving Repr, DecidableEq

/-- Per-surface assignments preserve distinct selected maxima. -/
structure SurfaceAssignment where
  target : String
  modules : Array Identity
  profile : ConformingProfile
  execution : ExecutionClaim
  deriving Repr, DecidableEq

structure ClaimCandidate where
  scope : Scope
  mode : EvidenceMode
  snapshot : Snapshot
  surfaces : Array SurfaceAssignment
  deriving Repr, DecidableEq

/-- Supported scope/mode combinations. Fresh files never acquire whole-project scope. -/
def ScopeModeCompatible : Scope → EvidenceMode → Bool
  | .project, .freshProject | .project, .incrementalProject | .project, .serializedGraph => true
  | .file .., .freshFile => true
  | .documentation _, .documentationExample => true
  | .editor .., .editorSnapshot => true
  | _, _ => false

/-- Functional source maps and disjoint positive module ownership; empty project libraries
remain unsupported. This does not assert completeness of an external Lake inventory. -/
def ClaimCandidate.Valid (c : ClaimCandidate) : Prop :=
  ScopeModeCompatible c.scope c.mode = true ∧
  c.snapshot.Valid ∧
  (∀ s ∈ c.surfaces, s.target ≠ "" ∧ s.modules.size > 0) ∧
  (c.surfaces.toList.flatMap (fun s => s.modules.toList)).Pairwise (fun a b => a.name ≠ b.name) ∧
  c.surfaces.toList.Pairwise (fun a b => a.target ≠ b.target) ∧
  (match c.scope with
   | .project => c.surfaces.size > 0 ∧ ∀ s ∈ c.surfaces, s.modules.size > 0
   | .file source .. | .editor _ source .. => source ∈ c.snapshot.sources ∧ c.surfaces.isEmpty = true
   | .documentation documents =>
       documents.size > 0 ∧ documents.toList.Pairwise (fun a b => a.uri ≠ b.uri) ∧
       (∀ d ∈ documents, d ∈ c.snapshot.sources) ∧ c.surfaces.isEmpty = true)
instance instDecidableClaimValid (c : ClaimCandidate) : Decidable c.Valid := by
  unfold ClaimCandidate.Valid
  cases c.scope <;> infer_instance

/-- Positive claim data has only conforming profile assignments. Teaching and no-profile
inspection are separate request constructors in Decision, not inhabitants of this type. -/
abbrev Claim := { c : ClaimCandidate // c.Valid }

def admitClaim (c : ClaimCandidate) : Except String Claim :=
  if h : c.Valid then .ok ⟨c, h⟩ else .error "unsupported or malformed policy claim"

/-- All and only valid candidates can be admitted, unchanged. -/
theorem admitClaim_exact (c : ClaimCandidate) (h : c.Valid) :
    admitClaim c = .ok ⟨c, h⟩ := by simp [admitClaim, h]

/-- Whole-project mandatory stages are derived; callers cannot select a shorter list. -/
def requiredStages (c : Claim) : List Stage :=
  match c.val.mode with
  | .freshProject | .incrementalProject =>
      [.configuration, .discovery, .build, .admission, .declarationPolicy, .execution,
       .transcript, .history, .origin, .documentationPresence]
  | .freshFile => [.discovery, .build, .admission, .declarationPolicy, .execution,
      .transcript, .history, .origin]
  | .documentationExample => [.discovery, .build, .documentScan, .example]
  | .serializedGraph => [.configuration, .discovery, .build, .graph]
  | .editorSnapshot => [.discovery, .admission, .declarationPolicy, .execution,
      .transcript, .history, .origin, .documentationPresence]

inductive JobSubject where
  | scope | module (key : ModuleKey) | declaration (key : DeclarationKey)
  | root (key : RootKey) | boundary (key : BoundaryKey) | fence (key : FenceKey)
  deriving Repr, DecidableEq

/-- Stage tags restrict the kind of evidence subject they can request. -/
def StageSubjectCompatible : Stage → JobSubject → Bool
  | .configuration, .scope | .discovery, .scope | .build, .scope
  | .admission, .scope | .documentationPresence, .scope | .documentScan, .scope
  | .graph, .scope => true
  | .build, .module _ | .admission, .module _ | .transcript, .module _
  | .history, .module _ | .origin, .module _ | .documentationPresence, .module _ => true
  | .declarationPolicy, .declaration _ | .documentationPresence, .declaration _ => true
  | .execution, .root _ | .execution, .boundary _ | .graph, .root _ => true
  | .example, .fence _ => true
  | _, _ => false

/-- An attempt identifier is transport metadata, never part of a required job key. -/
structure JobKey where
  claim : Claim
  stage : Stage
  subject : JobSubject
  requiredStage : stage ∈ requiredStages claim
  compatibleSubject : StageSubjectCompatible stage subject = true
  subjectSnapshot : match subject with
    | .scope => True
    | .module k => k.snapshot.val = claim.val.snapshot
    | .declaration k | .root k => k.moduleKey.snapshot.val = claim.val.snapshot
    | .boundary k => k.root.moduleKey.snapshot.val = claim.val.snapshot
    | .fence k => k.document ∈ claim.val.snapshot.sources
  deriving Repr, DecidableEq
end StrictLeanPolicy
