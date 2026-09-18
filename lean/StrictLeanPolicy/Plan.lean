import StrictLeanPolicy.Claim
import StrictLeanPolicy.Decision
import StrictLeanPolicy.Execution

/-! A frozen data census and a concrete required-job relation. The required jobs are
computed before result admission from the claim and census, never from returned successes.
The IO adapter is responsible for faithfully obtaining configuration, Lake and source data. -/
namespace StrictLeanPolicy
open Lean (Name)

inductive TargetKind where
  | library | executable
  deriving Repr, DecidableEq

/-- Actual Lake target observation, retaining its semantic module array. -/
structure DiscoveredTarget where
  kind : TargetKind
  name : String
  modules : Array Name
  deriving Repr, DecidableEq

/-- Parsed target classification: none excludes, some names the owning positive surface. -/
structure TargetAssignment where
  kind : TargetKind
  name : String
  surface : Option String
  deriving Repr, DecidableEq

/-- Frozen observations and independently collected keys. No field records policy success.
Material declarations are the explicit public evidence-registration census; its adequacy
remains semantic review. Imported modules are separate from claimed owned modules. -/
structure Census where
  policy : Inventory
  execution : ExecutionInventory
  modules : Array ModuleKey
  importedModules : Array ModuleKey
  moduleSources : Array (ModuleKey × SourceSnapshot)
  importedSources : Array (ModuleKey × SourceSnapshot)
  unclassifiedRootImports : Array ModuleKey
  admissionDeclarations : Array DeclarationKey
  declarations : Array DeclarationKey
  roots : Array RootKey
  materialDeclarations : Array DeclarationKey
  fences : Array FenceKey
  configuredTargets : Array TargetAssignment
  discoveredTargets : Array DiscoveredTarget
  deriving DecidableEq

def Census.allModules (i : Census) : Array ModuleKey := i.modules ++ i.importedModules

def Census.allModuleSources (i : Census) : Array (ModuleKey × SourceSnapshot) :=
  i.moduleSources ++ i.importedSources

def snapshotSources (c : Claim) : Array SourceSnapshot :=
  c.val.snapshot.sources ++ c.val.snapshot.dependencies.flatMap (·.files)

def moduleNames (ms : Array ModuleKey) : Array Name := ms.map (·.name.name)

def declarationNames (ds : Array DeclarationKey) : Array (Name × Name) :=
  ds.map (fun d => (d.moduleKey.name.name, d.name.name))

/-- Exact target partition, including excluded targets and standalone-executable conflicts.
Each positive surface owns its library and any separately classified executable roots. -/
def TargetPartitionOK (c : Claim) (i : Census) : Prop :=
  i.configuredTargets.toList.Pairwise (fun a b => (a.kind, a.name) ≠ (b.kind, b.name)) ∧
  i.discoveredTargets.toList.Pairwise (fun a b => (a.kind, a.name) ≠ (b.kind, b.name)) ∧
  (∀ a ∈ i.configuredTargets, ∃ t ∈ i.discoveredTargets, a.kind = t.kind ∧ a.name = t.name) ∧
  (∀ t ∈ i.discoveredTargets, t.name ≠ "" ∧ t.modules ≠ #[] ∧
    (t.kind = .executable → t.modules.size = 1) ∧
    ∃ a ∈ i.configuredTargets, a.kind = t.kind ∧ a.name = t.name) ∧
  (∀ a ∈ i.configuredTargets, ∀ owner ∈ a.surface, ∃ s ∈ c.val.surfaces, s.target = owner) ∧
  (∀ s ∈ c.val.surfaces,
    (∃ a ∈ i.configuredTargets, a.kind = .library ∧ a.name = s.target ∧ a.surface = some s.target) ∧
    canonicalNames (s.modules.map (·.name)) = canonicalNames
      ((i.discoveredTargets.filter (fun t => i.configuredTargets.any (fun a =>
        a.kind == t.kind && a.name == t.name && a.surface == some s.target))).flatMap (·.modules))) ∧
  (∀ a ∈ i.configuredTargets, a.kind = .library → ∀ owner ∈ a.surface, a.name = owner) ∧
  (∀ a ∈ i.configuredTargets, a.kind = .executable →
    ∀ t ∈ i.discoveredTargets, t.kind = .executable → t.name = a.name →
      ∀ n ∈ t.modules, ∀ lib ∈ i.discoveredTargets, lib.kind = .library →
        (a.surface.isSome = true → n ∉ lib.modules) ∧
        (∀ owner ∈ c.val.surfaces, lib.name = owner.target → n ∉ lib.modules))
set_option synthInstance.maxSize 1024 in
instance (c : Claim) (i : Census) : Decidable (TargetPartitionOK c i) := by
  unfold TargetPartitionOK; infer_instance

/-- Exact admitted key/data reconciliation and claim bindings. These checks cannot establish
that the external environment traversal or source scan omitted nothing; that is the collector
boundary. They do prevent a returned policy table from defining its own required census. -/
def CensusOK (c : Claim) (i : Census) : Prop :=
  uniqueNames (moduleNames i.allModules) ∧
  (∀ m ∈ i.allModules, m.snapshot.val = c.val.snapshot) ∧
  i.moduleSources.map (·.1) = i.modules ∧
  (∀ entry ∈ i.moduleSources, entry.2 ∈ c.val.snapshot.sources) ∧
  i.importedSources.toList.Pairwise (fun a b => a.1 ≠ b.1) ∧
  (∀ entry ∈ i.importedSources, entry.1 ∈ i.importedModules ∧ entry.2 ∈ snapshotSources c) ∧
  i.unclassifiedRootImports = #[] ∧
  (∀ m ∈ i.importedModules, ∀ target ∈ i.discoveredTargets, m.name.name ∈ target.modules →
    ∃ assignment ∈ i.configuredTargets, assignment.kind = target.kind ∧
      assignment.name = target.name ∧ assignment.surface.isSome = true) ∧
  (∀ d ∈ i.admissionDeclarations, d.moduleKey ∈ i.allModules) ∧
  i.admissionDeclarations.toList.Pairwise (· ≠ ·) ∧
  (∀ d ∈ i.policy.declarations, d.isUnsafe = false → d.isPartial = false →
    (d.module, d.name) ∈ declarationNames i.admissionDeclarations) ∧
  declarationNames i.declarations = i.policy.declarations.map (fun d => (d.module, d.name)) ∧
  declarationNames i.roots = i.execution.roots.map (fun r => (r.module, r.name)) ∧
  (∀ d ∈ i.declarations, d.moduleKey ∈ i.modules) ∧
  (∀ r ∈ i.roots, r.moduleKey ∈ i.allModules) ∧
  (∀ d ∈ i.materialDeclarations, d ∈ i.declarations) ∧
  i.materialDeclarations.toList.Pairwise (· ≠ ·) ∧
  i.fences.toList.Pairwise (· ≠ ·) ∧
  (∀ f ∈ i.fences, f.document ∈ c.val.snapshot.sources) ∧
  (∀ r ∈ i.execution.roots, ∀ b ∈ r.boundaries, b.module ∈ moduleNames i.allModules) ∧
  (match c.val.scope with
   | .project => TargetPartitionOK c i ∧
       canonicalNames (moduleNames i.modules) = canonicalNames
         (c.val.surfaces.flatMap (fun s => s.modules.map (·.name))) ∧ i.fences = #[]
   | .file source .. => i.modules.size = 1 ∧ i.fences = #[] ∧ i.moduleSources.map (·.2) = #[source]
   | .editor n source .. => moduleNames i.modules = #[n.name] ∧ i.fences = #[] ∧
       i.moduleSources.map (·.2) = #[source]
   | .documentation docs => i.modules = #[] ∧ i.declarations = #[] ∧ i.roots = #[] ∧
       ∀ f ∈ i.fences, f.document ∈ docs)
set_option synthInstance.maxSize 1024 in
instance (c : Claim) (i : Census) : Decidable (CensusOK c i) := by
  unfold CensusOK
  cases c.val.scope <;> infer_instance

/-- A module's profile is derived from its positive assignment, never a result payload. -/
def profileForModule (c : Claim) (m : Name) : Option ConformingProfile :=
  match c.val.scope with
  | .project => (c.val.surfaces.find? (fun s => s.modules.any (fun n => n.name == m))).map (·.profile)
  | .file _ p _ | .editor _ _ p _ => some p
  | .documentation _ => some .standardLogical

def executionForModule (c : Claim) (m : Name) : Option ExecutionClaim :=
  match c.val.scope with
  | .project => (c.val.surfaces.find? (fun s => s.modules.any (fun n => n.name == m))).map (·.execution)
  | .file _ _ e | .editor _ _ _ e => some e
  | .documentation _ => none

/-- A shared root must meet each requesting surface's execution obligation. The requests
come from the owned ordinary declaration or each retained executable-contract registration. -/
def rootRequests (c : Claim) (i : Census) (root : Name) : Array ExecutionClaim :=
  (i.policy.declarations.filter (fun d => d.name == root ||
    d.executableContract.any (fun contract => contract.root == root))).filterMap
      (fun d => executionForModule c d.module)

/-- Jobs use the existing stage/subject vocabulary; this pair is a projection of JobKey,
not a second identity scheme. Fixed array order supplies deterministic result slots. -/
def stageSubjects (i : Census) : Stage → Array JobSubject
  | .configuration | .discovery | .build | .admission | .documentScan | .graph => #[.scope]
  | .declarationPolicy => i.declarations.map .declaration
  | .execution => i.roots.map .root
  | .transcript => (i.modules.filter (fun m => i.policy.declarations.any (fun d =>
      d.module == m.name.name && declarationNeedsTranscript d.isUnsafe d.isPartial d.kind d.name))).map .module
  | .history => (i.allModules.filter (fun m => i.execution.roots.any (fun r => r.boundaries.any
      (fun b => b.module == m.name.name && b.boundary == .runtimeReplacement)))).map .module
  | .origin => (i.allModules.filter (fun m => i.execution.roots.any (fun r => r.boundaries.any
      (fun b => b.module == m.name.name && b.boundary == .nativeRuntime)))).map .module
  | .documentationPresence => i.modules.map .module ++ i.materialDeclarations.map .declaration
  | .example => i.fences.map .fence

/-- Required jobs are derived from mandatory mode stages and census subjects before results. -/
def requiredJobs (c : Claim) (i : Census) : Array (Stage × JobSubject) :=
  (requiredStages c).toArray.flatMap (fun stage => (stageSubjects i stage).map (stage, ·))

/-- Concrete plan validity checks the census, derived keys, profile assignments and root
request coverage. Unknown module ownership cannot default to a permissive profile. -/
def PlanOK (c : Claim) (i : Census) : Prop :=
  c.val.snapshot.toolchain.leanVersion = "4.34.0" ∧
  c.val.snapshot.toolchain.compilerCommit = "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b" ∧
  CensusOK c i ∧ (requiredJobs c i).toList.Pairwise (· ≠ ·) ∧
  (∀ job ∈ requiredJobs c i, StageSubjectCompatible job.1 job.2 = true) ∧
  (∀ d ∈ i.declarations, (profileForModule c d.moduleKey.name.name).isSome = true) ∧
  (∀ r ∈ i.roots, rootRequests c i r.name.name ≠ #[]) ∧
  (.execution ∈ requiredStages c → ∀ d ∈ i.policy.declarations,
    ∀ contract ∈ d.executableContract, contract.failure = none →
      ∃ root ∈ i.roots, root.name.name = contract.root)
set_option synthInstance.maxSize 1024 in
instance (c : Claim) (i : Census) : Decidable (PlanOK c i) := by unfold PlanOK; infer_instance

/-- The fixed JobKeys exactly realize the independently derived plan. Admission cannot
accept a caller-selected shorter list, duplicates, or another claim's keys. -/
structure Plan (c : Claim) (i : Census) where
  jobs : Array JobKey
  valid : PlanOK c i
  exactJobs : jobs.map (fun k => (k.stage, k.subject)) = requiredJobs c i
  exactClaim : ∀ k ∈ jobs, k.claim = c

/-- Validate the proposed keyed realization without dropping any record. -/
def admitPlan (c : Claim) (i : Census) (jobs : Array JobKey) : Except String (Plan c i) :=
  if hp : PlanOK c i then
    if hj : jobs.map (fun k => (k.stage, k.subject)) = requiredJobs c i then
      if hc : ∀ k ∈ jobs, k.claim = c then .ok ⟨jobs, hp, hj, hc⟩
      else .error "job belongs to a different claim"
    else .error "jobs do not exactly realize the required plan"
  else .error "invalid census or plan"

/-- Every valid keyed realization is admitted with its exact projections. -/
theorem admitPlan_exact (c : Claim) (i : Census) (p : Plan c i) :
    admitPlan c i p.jobs = .ok p := by
  unfold admitPlan
  rw [dite_eq_left p.valid, dite_eq_left p.exactJobs, dite_eq_left p.exactClaim]
end StrictLeanPolicy
