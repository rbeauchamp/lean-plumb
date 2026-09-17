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

/-- Exact reporter identities used only to select authentication obligations. Membership
alone never grants an exemption. Contract remains the public contract interface. -/
def reporterModuleNames : Array Name :=
  #[`StrictLean.Probe, `StrictLean.Report, `StrictLean.Contract, `StrictLean.Checker.PolicyCodec]

/-- These implementation imports remain forbidden through ordinary dependencies. -/
def reporterOnlyModuleNames : Array Name :=
  #[`StrictLean.Probe, `StrictLean.Report, `StrictLean.Checker.PolicyCodec]

/-- Only the existing force-loaded reporter, public name codec and conditional collector
can enter the infrastructure partition. This is not a whole-library exemption. -/
def infrastructureModuleNames : Array Name :=
  reporterModuleNames ++ #[`StrictLean.StructuralName, `StrictLean.Collect]

/-- Canonical-artifact equality for one exact infrastructure module and snapshot. The
adapter obtains both paths independently from actual resolution and the checker library;
this type proves equality of those observations, not filesystem or compiler authenticity. -/
structure InfrastructureOrigin where
  moduleKey : ModuleKey
  actual : String
  expected : String
  eligible : moduleKey.name.name ∈ infrastructureModuleNames
  nonempty : actual ≠ ""
  agrees : actual = expected
  deriving DecidableEq

/-- Refuse unsupported identities, absent origins and mismatched canonical artifacts. -/
def admitInfrastructureOrigin (key : ModuleKey) (actual expected : String) :
    Except String InfrastructureOrigin :=
  if hn : key.name.name ∈ infrastructureModuleNames then
    if hp : actual ≠ "" then
      if he : actual = expected then .ok ⟨key, actual, expected, hn, hp, he⟩
      else .error "infrastructure artifact origin mismatch"
    else .error "empty infrastructure artifact origin"
  else .error "unsupported infrastructure module"

/-- Every authenticated candidate is retained unchanged; no arbitrary fallback module
or artifact is substituted. Incoming-import checks remain a whole-census obligation. -/
theorem admitInfrastructureOrigin_exact (origin : InfrastructureOrigin) :
    admitInfrastructureOrigin origin.moduleKey origin.actual origin.expected = .ok origin := by
  unfold admitInfrastructureOrigin
  rw [dif_pos origin.eligible, dif_pos origin.nonempty, dif_pos origin.agrees]

/-- A standalone file is compiled in an isolated module. Retain both identities and
exact byte equality; this does not authenticate either filesystem read. -/
structure FileSourceBinding where
  requested : SourceSnapshot
  compiled : SourceSnapshot
  sameBytes : requested.source = compiled.source
  deriving DecidableEq

def admitFileSourceBinding (requested compiled : SourceSnapshot) : Except String FileSourceBinding :=
  if h : requested.source = compiled.source then .ok ⟨requested, compiled, h⟩
  else .error "standalone source copy differs from requested file"

theorem fileSourceBinding_bytes (binding : FileSourceBinding) :
    binding.requested.source = binding.compiled.source := binding.sameBytes

/-- Frozen observations and independently collected keys. No field records policy success.
Material declarations are the explicit public evidence-registration census; its adequacy
remains semantic review. Imported modules are separate from claimed owned modules. -/
structure Census where
  policy : Inventory
  execution : ExecutionInventory
  modules : Array ModuleKey
  importedModules : Array ModuleKey
  infrastructure : Array InfrastructureOrigin := #[]
  origins : Array ModuleOrigin := #[]
  infrastructureSources : Array (ModuleKey × SourceSnapshot) := #[]
  moduleSources : Array (ModuleKey × SourceSnapshot)
  fileSource : Option FileSourceBinding := none
  importedSources : Array (ModuleKey × SourceSnapshot)
  unclassifiedRootImports : Array ModuleKey
  admissionModules : Array ModuleKey := #[]
  admissionDeclarations : Array DeclarationKey
  declarations : Array DeclarationKey
  roots : Array RootKey
  materialDeclarations : Array DeclarationKey
  fences : Array FenceKey
  graphRoots : Array ModuleKey := #[]
  graphCoverage : Array (ModuleKey × Array ModuleKey) := #[]
  configuredTargets : Array TargetAssignment
  discoveredTargets : Array DiscoveredTarget
  deriving DecidableEq

def Census.infrastructureModules (i : Census) : Array ModuleKey := i.infrastructure.map (·.moduleKey)

def Census.allModules (i : Census) : Array ModuleKey :=
  i.modules ++ i.importedModules ++ i.infrastructureModules

def Census.allModuleSources (i : Census) : Array (ModuleKey × SourceSnapshot) :=
  i.moduleSources ++ i.importedSources ++ i.infrastructureSources

def snapshotSources (c : Claim) : Array SourceSnapshot :=
  c.val.snapshot.sources ++ c.val.snapshot.dependencies.flatMap (·.files)

def moduleNames (ms : Array ModuleKey) : Array Name := ms.map (·.name.name)

def declarationNames (ds : Array DeclarationKey) : Array (Name × Name) :=
  ds.map (fun d => (d.moduleKey.name.name, d.name.name))

/-- The complete loaded import census binds every infrastructure receipt. Direct import
edges are inspected for every loaded module, including ordinary dependencies. Collect
is infrastructure only in its existing force-only case. Positive ownership is disjoint. -/
def InfrastructureOK (c : Claim) (i : Census) : Prop :=
  (∀ m ∈ i.infrastructureModules, m ∉ i.modules ∧ m ∉ i.importedModules ∧
    m.snapshot.val = c.val.snapshot) ∧
  uniqueNames (i.origins.map (·.name)) ∧
  canonicalNames (i.origins.map (·.name)) = canonicalNames (moduleNames i.allModules) ∧
  (∀ receipt ∈ i.infrastructure, ∃ origin ∈ i.origins,
    origin.name = receipt.moduleKey.name.name ∧ origin.olean = receipt.actual) ∧
  (∀ origin ∈ i.origins, ∀ imported ∈ origin.imports,
    imported ∈ reporterOnlyModuleNames → origin.name ∈ reporterModuleNames ∧
      ∃ receipt ∈ i.infrastructure, receipt.moduleKey.name.name = origin.name) ∧
  (∀ receipt ∈ i.infrastructure, receipt.moduleKey.name.name = `StrictLean.Collect →
    ∀ origin ∈ i.origins, `StrictLean.Collect ∈ origin.imports → origin.name ∈ reporterModuleNames) ∧
  i.infrastructureSources.toList.Pairwise (fun a b => a.1 ≠ b.1) ∧
  (∀ entry ∈ i.infrastructureSources,
    entry.1 ∈ i.infrastructureModules ∧ entry.2 ∈ snapshotSources c)
set_option synthInstance.maxSize 1024 in
instance (c : Claim) (i : Census) : Decidable (InfrastructureOK c i) := by
  unfold InfrastructureOK; infer_instance

/-- The admitted partition never supplies positive ownership or an ordinary import. -/
theorem infrastructure_disjoint (c : Claim) (i : Census) (h : InfrastructureOK c i)
    (m : ModuleKey) (hm : m ∈ i.infrastructureModules) : m ∉ i.modules ∧ m ∉ i.importedModules :=
  ⟨(h.1 m hm).1, (h.1 m hm).2.1⟩

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

/-- Optional graph selection and import coverage are frozen before checker processes.
The relation proves exact accounting of supplied coverage, not Lean import extraction. -/
def GraphPlanOK (c : Claim) (i : Census) : Prop :=
  if c.val.mode = .serializedGraph then
    i.graphRoots ≠ #[] ∧ i.graphRoots.toList.Pairwise (· ≠ ·) ∧
    i.graphCoverage.map (·.1) = i.graphRoots ∧
    (∀ root ∈ i.graphRoots, root ∈ i.modules) ∧
    (∀ entry ∈ i.graphCoverage, entry.1 ∈ entry.2 ∧ ∀ m ∈ entry.2, m ∈ i.modules) ∧
    ∀ m ∈ i.modules, ∃ entry ∈ i.graphCoverage, m ∈ entry.2
  else i.graphRoots = #[] ∧ i.graphCoverage = #[]
instance (c : Claim) (i : Census) : Decidable (GraphPlanOK c i) := by
  unfold GraphPlanOK; infer_instance

/-- Exact admitted key/data reconciliation and claim bindings. These checks cannot establish
that the external environment traversal or source scan omitted nothing; that is the collector
boundary. They do prevent a returned policy table from defining its own required census. -/
def CensusOK (c : Claim) (i : Census) : Prop :=
  InfrastructureOK c i ∧ GraphPlanOK c i ∧
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
  uniqueNames (moduleNames i.admissionModules) ∧
  (∀ m ∈ i.admissionModules, m.snapshot.val = c.val.snapshot) ∧
  (∀ d ∈ i.admissionDeclarations, d.moduleKey ∈ i.allModules ∧ d.moduleKey ∈ i.admissionModules) ∧
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
   | .file source .. => i.modules.size = 1 ∧ i.fences = #[] ∧
       ∃ binding ∈ i.fileSource, binding.requested = source ∧ i.moduleSources.map (·.2) = #[binding.compiled]
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

/-- Bucket selection only: collisions are resolved by full structural stage/subject
equality, including snapshots, source bytes and every constructor field. Omitting these
fields from the hash does not omit them from the original uniqueness relation. -/
private def jobSubjectBucket : JobSubject → UInt64
  | .scope => 0
  | .module k => hash k.name.name
  | .declaration k | .root k => hash (k.moduleKey.name.name, k.name.name)
  | .boundary k => hash (k.root.name.name, k.occurrence)
  | .fence k => hash (k.document.uri, k.body.start)

local instance : BEq (Stage × JobSubject) := ⟨fun a b => decide (a = b)⟩
local instance : LawfulBEq (Stage × JobSubject) where
  eq_of_beq h := of_decide_eq_true h
  rfl {a} := by change decide (a = a) = true; exact decide_eq_true rfl
local instance : Hashable (Stage × JobSubject) := ⟨fun key => jobSubjectBucket key.2⟩
local instance : LawfulHashable (Stage × JobSubject) where
  hash_eq _ _ h := eq_of_beq h ▸ rfl

/-- The index decides the exact stage/subject relation required by PlanOK, not full
JobKey uniqueness (which would be weaker when claims differ). Ordered jobs are untouched. -/
theorem requiredJobs_distinct_iff (c : Claim) (i : Census) :
    (Std.ExtHashSet.ofList (requiredJobs c i).toList).size = (requiredJobs c i).toList.length ↔
      (requiredJobs c i).toList.Pairwise (· ≠ ·) :=
  distinct_iff _

/-- Concrete plan validity checks the census, derived keys, profile assignments and root
request coverage. Unknown module ownership cannot default to a permissive profile. -/
def PlanOK (c : Claim) (i : Census) : Prop :=
  c.val.snapshot.toolchain.leanVersion = "4.33.1" ∧
  c.val.snapshot.toolchain.compilerCommit = "819816b2e0a3bf405af45ae5c7af2491d8f5bee6" ∧
  CensusOK c i ∧ (requiredJobs c i).toList.Pairwise (· ≠ ·) ∧
  (∀ job ∈ requiredJobs c i, StageSubjectCompatible job.1 job.2 = true) ∧
  (∀ d ∈ i.declarations, (profileForModule c d.moduleKey.name.name).isSome = true) ∧
  (∀ r ∈ i.roots, rootRequests c i r.name.name ≠ #[]) ∧
  (.execution ∈ requiredStages c → ∀ d ∈ i.policy.declarations,
    ∀ contract ∈ d.executableContract, contract.failure = none →
      ∃ root ∈ i.roots, root.name.name = contract.root)
set_option synthInstance.maxSize 1024 in
instance (c : Claim) (i : Census) : Decidable (PlanOK c i) := by
  letI : Decidable ((requiredJobs c i).toList.Pairwise (· ≠ ·)) :=
    decidable_of_iff _ (requiredJobs_distinct_iff c i)
  unfold PlanOK
  infer_instance

/-- The indexed implementation decides the same proposition as the prior finite scan. -/
theorem planOK_decide_eq_previous (c : Claim) (i : Census) :
    decide (PlanOK c i) = @decide (PlanOK c i) (by unfold PlanOK; infer_instance) := by
  congr

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

/-- Any decision of the identical plan predicate preserves every admission outcome,
including ordered realization, exact claim equality and the original refusal precedence. -/
theorem admitPlan_decision_eq (c : Claim) (i : Census) (jobs : Array JobKey)
    (decision : Decidable (PlanOK c i)) :
    admitPlan c i jobs = @dite (Except String (Plan c i)) (PlanOK c i) decision
      (fun hp =>
        if hj : jobs.map (fun k => (k.stage, k.subject)) = requiredJobs c i then
          if hc : ∀ k ∈ jobs, k.claim = c then .ok ⟨jobs, hp, hj, hc⟩
          else .error "job belongs to a different claim"
        else .error "jobs do not exactly realize the required plan")
      (fun _ => .error "invalid census or plan") := by
  by_cases hp : PlanOK c i <;> simp [admitPlan, hp]

/-- Every valid keyed realization is admitted with its exact projections. -/
theorem admitPlan_exact (c : Claim) (i : Census) (p : Plan c i) :
    admitPlan c i p.jobs = .ok p := by
  unfold admitPlan
  rw [dif_pos p.valid, dif_pos p.exactJobs, dif_pos p.exactClaim]
/-- Realize all independently derived jobs; mapM refuses rather than discarding an
unsupported subject. The existing plan admission checks the complete resulting array. -/
def buildPlan (c : Claim) (i : Census) : Except String (Plan c i) := do
  let jobs ← (requiredJobs c i).mapM fun (stage, subject) => admitJobKey c stage subject
  admitPlan c i jobs

end StrictLeanPolicy
