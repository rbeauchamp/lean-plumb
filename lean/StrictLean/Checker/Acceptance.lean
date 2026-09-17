import StrictLeanPolicy.Acceptance
import StrictLean.Checker.Environment
import StrictLean.Checker.Lake
import StrictLean.Checker.Snapshot

/-! Operational bridge to the pure, request-indexed acceptance boundary. The census
comes from Lake and completed producer extraction before policy jobs are collected.
Raw packets never carry proofs. Canonical path resolution, source stability, Lean/Lake
extraction, process completion and compiled execution remain trusted IO boundaries.
The checked collection architecture is informed by con-leche's CheckedRecord,
collectChecks, FullyChecked and checkDeclsIO; no con-leche dependency is introduced. -/
namespace StrictLean.Checker.Acceptance
open Lean System StrictLeanPolicy
open scoped StrictLean.Report

/-- One independently requested report and its completed raw observations. The expected
module array is supplied by the coordinator's discovery, never copied from the response. -/
structure RequestedInspection where
  expectedModules : Array Name
  report : ProducerReport.Environment
  transcripts : Array StrictLeanPolicy.Frontend.Transcript
  deriving ToJson

instance : FromJson RequestedInspection := ⟨fun value => do
  PolicyCodec.exactFields value ["expectedModules", "report", "transcripts"]
  return {
    expectedModules := ← value.getObjValAs? _ "expectedModules",
    report := ← value.getObjValAs? _ "report", transcripts := ← value.getObjValAs? _ "transcripts" }⟩

/-- Child transport contains raw production only. Parent discovery supplies coverage and
recomputes all policy evidence after process completion. -/
structure SurfaceProduction where
  build : ProcessResult
  inspections : Array RequestedInspection
  deriving ToJson

instance : FromJson SurfaceProduction := ⟨fun value => do
  PolicyCodec.exactFields value ["build", "inspections"]
  return { build := ← value.getObjValAs? _ "build", inspections := ← value.getObjValAs? _ "inspections" }⟩

/-- Retain one exact source per URI; repeated identical file observations are shared,
while conflicting bytes are refused. This normalizes source maps, never job results. -/
def sourceSnapshots (sources : Array ProducerReport.SourceBinding)
    (histories : Array HistoryObservation) (additional : Array SourceSnapshot := #[]) : IO (Array SourceSnapshot) := do
  let mut observed := sources.map fun source => (⟨source.path, source.content⟩ : SourceSnapshot)
  for history in histories do
    unless history.before == history.after &&
        (← IO.FS.readFile history.before.uri) == history.before.source do
      throw <| IO.userError s!"history snapshot changed: {history.moduleName}"
    observed := observed.push history.before
  let mut files : Array SourceSnapshot := #[]
  for source in observed ++ additional do
    if let some previous := files.find? (·.uri == source.uri) then
      unless previous == source do throw <| IO.userError s!"conflicting source snapshot: {source.uri}"
    else files := files.push source
  return files

/-- Positive maxima remain distinct from no-profile and compiler-trusting classification. -/
def conformingProfile : Policy.Profile → Except String ConformingProfile
  | .kernelOnly => .ok .kernelOnly
  | .choiceFree => .ok .choiceFree
  | .standardLogical => .ok .standardLogical
  | .compilerTrusting => .error "compiler-trusting inspection is not a conforming claim"

/-- Construct requested surface assignments solely from the frozen manifest and Lake
inventory, before looking at returned declarations or policy results. -/
def surfaceAssignments (manifest : Manifest.Manifest) (inventory : Lake.SurfaceInventory) :
    Except String (Array SurfaceAssignment) := manifest.surfaces.mapM fun surface => do
  let some library := inventory.libraries.find? (·.library == surface.library)
    | throw "manifest surface missing from Lake discovery"
  let mut modules := library.modules
  for name in surface.executables do
    let some exe := inventory.executables.find? (·.executable == name)
      | throw "manifest executable missing from Lake discovery"
    modules := modules.push exe.root
  return ⟨surface.library, ← modules.mapM admitIdentity, ← conformingProfile surface.claim, surface.execution⟩

def configuredTargets (manifest : Manifest.Manifest) : Array TargetAssignment :=
  manifest.surfaces.flatMap (fun surface =>
    #[⟨.library, surface.library, some surface.library⟩] ++
      surface.executables.map (fun name => ⟨.executable, name, some surface.library⟩)) ++
  manifest.excludedLibraries.map (fun excluded => ⟨.library, excluded.library, none⟩) ++
  manifest.excludedExecutables.map (fun excluded => ⟨.executable, excluded.executable, none⟩)

def discoveredTargets (inventory : Lake.SurfaceInventory) : Array DiscoveredTarget :=
  inventory.libraries.map (fun library => ⟨.library, library.library, library.modules⟩) ++
  inventory.executables.map (fun exe => ⟨.executable, exe.executable, #[exe.root]⟩)

/-- Observed process completion is not a theorem of external process semantics. -/
def buildObservation (process : ProcessResult) : BuildObservation :=
  ⟨process.exitCode.toNat, warningLines process.output, errorLines process.output⟩

/-- Operational observations retained after the independent census has been frozen.
These data do not carry an accepted flag or determine the required stage list. -/
structure Frozen (claim : Claim) where
  census : Census
  plan : Plan claim census
  roles : Roles census.policy
  admission : AdmissionObservation
  moduleDocumentation : Array (Name × Bool)
  declarationDocumentation : Array ((Name × Name) × Option String)
  histories : Array HistoryObservation

private def moduleKey (snapshot : AdmittedSnapshot) (name : Name) : Except String ModuleKey := do
  return ⟨snapshot, ← admitIdentity name⟩

private def declarationKey (snapshot : AdmittedSnapshot) (key : Name × Name) : Except String DeclarationKey := do
  return ⟨← moduleKey snapshot key.1, ← admitIdentity key.2⟩

/-- Overlapping imported observations from separately requested surfaces must agree.
This reconciliation is never used to normalize job responses or owned declarations. -/
private def reconcile [DecidableEq α] (what : String) (key : α → Name)
    (values : Array α) : Except String (Array α) := do
  let mut table : NameMap α := {}
  for value in values do
    if let some previous := table.find? (key value) then
      unless previous = value do throw s!"conflicting {what} observation: {key value}"
    else table := table.insert (key value) value
  return table.toArray.map (·.2)

/-- Preserve all completed histories, including their exact source binding. Unavailable
history cannot be turned into an empty successful observation. -/
def historyObservations (reports : Array RequestedInspection) : Except String (Array HistoryObservation) := do
  let mut histories := #[]
  for inspected in reports do
    for (name, outcome) in inspected.report.histories do
      match outcome with
      | .unavailable detail => throw s!"history unavailable for {name}: {detail}"
      | .completed path before after replacements =>
        histories := histories.push {
          moduleName := name, before := ⟨path, before⟩, after := ⟨path, after⟩,
          replacements, unsupported := #[] }
  -- The operational outcomes are compared through their actual fields; no verdict is reused.
  let mut found : NameMap HistoryObservation := {}
  for history in histories do
    if let some previous := found.find? history.moduleName then
      unless previous.before = history.before ∧ previous.after = history.after ∧
          previous.replacements = history.replacements ∧ previous.unsupported = history.unsupported do
        throw s!"conflicting history observation: {history.moduleName}"
    else found := found.insert history.moduleName history
  return found.toArray.map (·.2)

/-- Reconcile full producer censuses with an independently selected positive domain. Full
replay selection and both replay key arrays survive the infrastructure partition. Sources
must already belong to the same frozen claim; no source or profile is invented here. -/
def freeze (claim : Claim) (positive : Array Name)
    (configured : Array TargetAssignment) (discovered : Array DiscoveredTarget)
    (sources : Array ProducerReport.SourceBinding) (ownedOutput : FilePath)
    (reports : Array RequestedInspection) (fileSource : Option FileSourceBinding := none) : IO (Frozen claim) := do
  let snapshot : AdmittedSnapshot := ⟨claim.val.snapshot, claim.property.2.1⟩
  unless decide (uniqueNames positive) do throw <| IO.userError "duplicate requested positive module"
  let requested := reports.flatMap (·.expectedModules)
  unless decide (uniqueNames requested) && canonicalNames requested == canonicalNames positive do
    throw <| IO.userError "missing, duplicate or unrequested surface inspection"
  let mut rawDeclarations := #[]
  let mut transcripts := #[]
  let mut rawRoots := #[]
  let mut rawOrigins := #[]
  let mut rawInfrastructure := #[]
  let mut rawReplayModules := #[]
  let mut rawRequired := #[]
  let mut rawAdmitted := #[]
  let mut rawMaterial := #[]
  let mut moduleDocs := #[]
  let mut declarationDocs := #[]
  for inspected in reports do
    let report := inspected.report
    IO.ofExcept report.validate
    IO.ofExcept <| (report.validateSourceEvidence).mapError (·.detail)
    IO.ofExcept <| (SourceBinding.validateAgainst sources report).mapError (·.detail)
    IO.ofExcept <| (SourceBinding.transcriptsMatch sources inspected.transcripts).mapError (·.detail)
    unless report.census.modules == inspected.expectedModules && report.census.executionRoots.isSome do
      throw <| IO.userError "producer census differs from independently requested surface"
    let some replay := report.admission
      | throw <| IO.userError "missing completed logical admission"
    let some documentation := report.documentation
      | throw <| IO.userError "missing completed documentation observation"
    rawDeclarations := rawDeclarations ++ report.declarations
    transcripts := transcripts ++ inspected.transcripts
    rawRoots := rawRoots ++ report.execution
    rawOrigins := rawOrigins ++ report.moduleOrigins
    rawInfrastructure := rawInfrastructure ++ (← Environment.infrastructureOrigins snapshot report)
    rawReplayModules := rawReplayModules ++ replay.modules
    rawRequired := rawRequired ++ replay.required
    rawAdmitted := rawAdmitted ++ replay.admitted
    rawMaterial := rawMaterial ++ documentation.materialDeclarations
    moduleDocs := moduleDocs ++ documentation.modules
    declarationDocs := declarationDocs ++ documentation.declarations
  let scope ← IO.ofExcept <| Policy.admitScope rawDeclarations transcripts
  let roots ← IO.ofExcept <| reconcile "execution root" (·.name) rawRoots
  let execution ← IO.ofExcept <| admitExecution roots
  let origins ← IO.ofExcept <| reconcile "module origin" (·.name) rawOrigins
  let infrastructure ← IO.ofExcept <| reconcile "infrastructure origin" (·.moduleKey.name.name) rawInfrastructure
  let histories ← IO.ofExcept <| historyObservations reports
  let modules ← IO.ofExcept <| positive.mapM (moduleKey snapshot)
  let infrastructureNames := infrastructure.map (·.moduleKey.name.name)
  let importedNames := origins.map (·.name) |>.filter fun name =>
    !positive.contains name && !infrastructureNames.contains name
  let importedModules ← IO.ofExcept <| importedNames.mapM (moduleKey snapshot)
  let mut allSources := sources
  for history in histories do
    let binding : ProducerReport.SourceBinding :=
      ⟨history.moduleName, history.before.uri, history.before.source⟩
    if let some previous := allSources.find? (·.moduleName == history.moduleName) then
      unless previous == binding do throw <| IO.userError "history/module source binding conflict"
    else allSources := allSources.push binding
  let sourceFor (key : ModuleKey) : IO (ModuleKey × SourceSnapshot) := do
    let some source := allSources.find? (·.moduleName == key.name.name)
      | throw <| IO.userError s!"missing independently captured source: {key.name.name}"
    return (key, ⟨source.path, source.content⟩)
  let moduleSources ← modules.mapM sourceFor
  let importedSources ← (importedModules.filter (fun m => allSources.any (·.moduleName == m.name.name))).mapM sourceFor
  let infrastructureSources ← ((infrastructure.map (·.moduleKey)).filter
    (fun m => allSources.any (·.moduleName == m.name.name))).mapM sourceFor
  let replayModules ← IO.ofExcept <| (canonicalNames rawReplayModules).mapM (moduleKey snapshot)
  let required ← IO.ofExcept <| (canonicalEdges rawRequired).mapM (declarationKey snapshot)
  let admitted ← IO.ofExcept <| (canonicalEdges rawAdmitted).mapM (declarationKey snapshot)
  let declarations ← IO.ofExcept <| (scope.inventory.declarations.map (fun d => (d.module, d.name))).mapM
    (declarationKey snapshot)
  let rootKeys ← IO.ofExcept <| (execution.roots.map (fun r => (r.module, r.name))).mapM (declarationKey snapshot)
  let material ← IO.ofExcept <| rawMaterial.mapM (declarationKey snapshot)
  let mut unclassifiedRootImports := #[]
  let configuredModules := discovered.flatMap (·.modules)
  for origin in origins do
    if claim.val.scope == .project && !configuredModules.contains origin.name && !positive.contains origin.name &&
        !infrastructureNames.contains origin.name && (← pathWithin origin.olean ownedOutput) then
      unclassifiedRootImports := unclassifiedRootImports.push
        (← IO.ofExcept (moduleKey snapshot origin.name))
  let census : Census := {
    policy := scope.inventory, execution, modules, importedModules, infrastructure, origins,
    moduleSources, fileSource, importedSources, infrastructureSources, unclassifiedRootImports,
    admissionModules := replayModules, admissionDeclarations := required, declarations,
    roots := rootKeys, materialDeclarations := material, fences := #[],
    configuredTargets := configured, discoveredTargets := discovered }
  let plan ← IO.ofExcept <| buildPlan claim census
  return {
    census, plan, roles := scope.roles, admission := ⟨replayModules, required, admitted, #[]⟩,
    moduleDocumentation := moduleDocs, declarationDocumentation := declarationDocs, histories }

private def requireOne (what : String) (values : Array α) : Except String α :=
  match values.toList with
  | [value] => .ok value
  | [] => .error s!"missing required {what} observation"
  | _ => .error s!"duplicate required {what} observation"

/-- Presence observations for modules have no docstring text payload. `some ""` encodes
observed presence only, exactly the existing `DocumentationPresenceOK` predicate. -/
def modulePresence (present : Bool) : Option String := if present then some "" else none

theorem modulePresence_iff (present : Bool) :
    DocumentationPresenceOK (modulePresence present) ↔ present = true := by
  cases present <;> simp [modulePresence, DocumentationPresenceOK]

/-- Each required slot receives its actual stage's observation. Failed lookup returns an
explicit error; unknown stages cannot become a completed empty payload. The caller supplies
the actual build process observation, not a synthesized success from diagnostic counts. -/
def observations {claim : Claim} (frozen : Frozen claim) (build : BuildObservation) :
    Except String (List (Nat × JobObservation)) := do
  let values : Array (Nat × JobObservation) ← frozen.plan.jobs.mapIdxM fun slot key => do
    let evidence ← match key.stage, key.subject with
      | .configuration, .scope =>
          pure (JobEvidence.configuration frozen.census.configuredTargets frozen.census.discoveredTargets)
      | .discovery, .scope => pure <| .discovery frozen.census
      | .build, .scope => pure <| .build build
      | .admission, .scope => pure <| .admission frozen.admission
      | .declarationPolicy, .declaration k => do
          let declaration ← requireOne "declaration" <| frozen.census.policy.declarations.filter
            (fun d => d.module == k.moduleKey.name.name && d.name == k.name.name)
          pure <| .declaration declaration
      | .execution, .root k => do
          let root ← requireOne "execution root" <| frozen.census.execution.roots.filter
            (fun r => r.module == k.moduleKey.name.name && r.name == k.name.name)
          pure <| .execution root
      | .transcript, .module k => do
          pure <| JobEvidence.transcript (← requireOne "transcript" <| frozen.census.policy.transcripts.filter
            (·.module == k.name.name))
      | .history, .module k => do
          pure <| JobEvidence.history (← requireOne "history" <| frozen.histories.filter (·.moduleName == k.name.name))
      | .origin, .module k => do
          let origins := frozen.census.execution.roots.flatMap fun r => r.boundaries.filterMap
            fun b => if b.module == k.name.name then b.account.nativeOrigin? else none
          let some origin := origins[0]? | throw "missing native-runtime origin observation"
          unless origins.all (fun other => decide (other = origin)) do throw "conflicting native-runtime origins"
          pure <| .origin origin
      | .documentationPresence, .module k => do
          let observation ← requireOne "module documentation" <|
            frozen.moduleDocumentation.filter (·.1 == k.name.name)
          pure <| .documentationPresence (modulePresence observation.2)
      | .documentationPresence, .declaration k => do
          let observation ← requireOne "declaration documentation" <|
            frozen.declarationDocumentation.filter (·.1 == (k.moduleKey.name.name, k.name.name))
          pure <| .documentationPresence observation.2
      | _, _ => throw "unsupported observation stage for project/file collector"
    return (slot, ({ key, snapshot := claim.val.snapshot, completion := .completed, evidence } : JobObservation))
  return values.toList

/-- Final operational admission returns evidence indexed by the exact requested claim.
Consumer APIs must keep this package until projecting `AcceptedRun.report`. -/
def finish {claim : Claim} (frozen : Frozen claim) (build : BuildObservation) :
    Except String (AcceptedRun claim) := do
  let inputs ← observations frozen build
  let result ← (finalize frozen.plan frozen.roles inputs).mapError fun failure =>
    s!"acceptance refused: {repr failure}"
  return ⟨frozen.census, frozen.plan, frozen.roles, inputs, result⟩

end StrictLean.Checker.Acceptance
