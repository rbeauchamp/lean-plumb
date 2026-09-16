import StrictLean.Checker.PolicyCodec
import StrictLean.Probe
import StrictLean.Checker.Common
import StrictLean.Checker.Admission
import StrictLean.Checker.SourceBinding
import StrictLean.Linter.Documentation

/-!
Trusted environment loading for checker policy. The fully qualified reporter
is called directly; audited syntax extensions cannot replace the observation.
-/

namespace StrictLean.Checker.Environment

open Lean System
open scoped StrictLean.Report

/-- The checker-owned probe modules force-imported into every report so the
trusted reporter is always available: the probe and its transitive imports
inside the checker library. They are never part of an audited surface, so
their presence in an environment is not evidence about the claimed modules. -/
def probeModuleNames : Array String :=
  #["StrictLean.Probe", "StrictLean.Report", "StrictLean.Contract", "StrictLean.Checker.PolicyCodec"]

/-- The probe modules no claimed module may import. `StrictLean.Contract`
is the published contract interface (docs/standard/8 §8.12) and is the one checker module
a claimed surface imports by design; the probe and its report records are
checker tooling that reach an audited environment only through the force
import, never through a claimed module's own imports. -/
def probeOnlyModuleNames : Array String :=
  #["StrictLean.Probe", "StrictLean.Report", "StrictLean.Checker.PolicyCodec"]

/-- The checker-owned probe module force-imported into every report so the
trusted reporter is always available. It is never part of an audited surface. -/
def probeModuleName : String := "StrictLean.Probe"

/-- The reporter also force-loads this public, neutral name codec. Its presence is
not a source import of excluded policy machinery. Validate the exact durable artifact
before distinguishing it from a claimed module's ordinary imports. -/
private def forcedPublicModule (report : StrictLean.Checker.ProducerReport.Environment) (name : Name)
    (description : String) : IO Name := do
  let origins := report.moduleOrigins.filter (·.name == name)
  let some origin := origins[0]? | throw <| IO.userError s!"missing {description} origin"
  unless origins.size == 1 do throw <| IO.userError s!"ambiguous {description} origin"
  let some lib ← checkerPackageLibDir | throw <| IO.userError "checker library path unavailable"
  let expected ← IO.FS.realPath (Lean.modToFilePath lib name "olean")
  unless (← IO.FS.realPath origin.olean) == expected do
    throw <| IO.userError s!"{description} origin mismatch"
  return name

def forcedStructuralName (report : StrictLean.Checker.ProducerReport.Environment) : IO Name :=
  forcedPublicModule report `StrictLean.StructuralName "structural-name codec"

/-- The extracted constructor is also force-loaded by Probe. Its artifact must
be the checker's exact artifact. Unlike the neutral name codec, it remains in
the excluded-library scan whenever another module actually imports it. -/
def forcedCollectorOnly (report : StrictLean.Checker.ProducerReport.Environment) : IO (Option Name) := do
  let name ← forcedPublicModule report `StrictLean.Collect "shared collector"
  if report.moduleOrigins.any (fun origin =>
      !probeModuleNames.contains origin.name.toString && origin.imports.contains name) then
    return none
  return some name

/-- Re-elaboration recovers overwritten `implemented_by` choices that neither
the final attribute map nor optimized IR preserves. Isolate the frontend's
initializers, and memoize once per module in one audit invocation. -/
private def replacementHistory (sourceRoots : Array FilePath)
    (moduleSources : Array (Name × FilePath)) (moduleName : Name) :
    IO ProducerReport.HistoryOutcome := do
  try
    let olean ← Lean.findOLean moduleName
    let alongside := olean.withExtension "lean"
    -- Owned modules use their exact Lake-resolved source. Prefix-based source
    -- search can otherwise stop at an unrelated dependency directory such as
    -- proofwidgets/Widget before reaching the adopter's actual Widget.lean.
    let source ← if let some (_, source) := moduleSources.find? (·.1 == moduleName) then
        pure source
      else if ← alongside.pathExists then pure alongside else
        Lean.findLean (sourceRoots.toList ++ (← Lean.getSrcSearchPath) ++
          [(← Lean.findSysroot) / "src" / "lean"])
          moduleName
    let some bin := (← IO.appPath).parent
      | throw <| IO.userError "checker binary directory unavailable"
    withScratch (← IO.currentDir) "replacement-history" fun scratch => do
      let output := scratch / "history.json"
      let sourceBefore ← IO.FS.readFile source
      let request := sourceWorkerRequest "history" moduleName source sourceBefore
      let searchPath := System.SearchPath.toString (← Lean.searchPathRef.get)
      let result ← IO.Process.output {
        cmd := (bin / "axiomGate").toString
        args := #["--replacement-history-worker", (StrictLean.RegistryCodec.nameJson moduleName).compress, source.toString,
          output.toString]
        env := #[("LEAN_PATH", some searchPath)] }
      if result.exitCode != 0 then
        throw <| IO.userError s!"{result.stdout}{result.stderr}"
      let json ← IO.ofExcept <| StrictLean.Checker.PolicyCodec.parse (← IO.FS.readFile output)
      let payload ← IO.ofExcept <| readWorkerPacket request json
      let sourceAfter ← IO.FS.readFile source
      unless sourceAfter == sourceBefore do
        throw <| IO.userError "replacement history source changed"
      let edges : Array (Name × Name) ← IO.ofExcept <| fromJson? payload
      return .completed source.toString sourceBefore sourceAfter edges
  catch error => return .unavailable error.toString

private unsafe def loadReportCoreAtSearchPath (modules : Array Name) (sourceRoots : Array FilePath := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO (Except ProducerReport.AdmissionFailure ProducerReport.Environment) := do
  if modules.isEmpty || modules.toList.eraseDups.length != modules.size then
    throw <| IO.userError "environment report requires unique nonempty modules"
  let mut resolvedSources := moduleSources
  for name in modules do
    if !resolvedSources.any (·.1 == name) then
      -- Compiled verbatim snippets live alongside their exact isolated source.
      -- Ordinary project modules already have authoritative Lake source entries.
      let source := (← Lean.findOLean name).withExtension "lean"
      resolvedSources := resolvedSources.push (name, source)
  let sourceBindings ← SourceBinding.capture resolvedSources
  unsafe Lean.enableInitializersExecution
  let requested := modules
  let importNames :=
    if requested.contains probeModuleName.toName then requested
    else requested.push probeModuleName.toName
  let imports := importNames.map fun module =>
    ({ module, importAll := true } : Import)
  let env ← timedPhase "environment imports" <| importModules imports {} 0 (loadExts := true) (level := .private)
  let ownedModules := requested ++ moduleSources.map (·.1) |>.filter
    (fun name => !probeModuleNames.contains name.toString)
  if let some root := ownedOutput then
    for name in env.header.moduleNames do
      if !ownedModules.contains name && !probeModuleNames.contains name.toString then
        if ← pathWithin (← Lean.findOLean name) root then
          throw <| IO.userError s!"unexpected-project-module: kernel-admission cannot classify {name}"
  let admissionResult ← timedPhase "kernel admission" <| Admission.validate env ownedModules
  if let .error failure := admissionResult then return .error failure
  let .ok admission := admissionResult
    | throw <| IO.userError "unreachable admission outcome"
  -- Freeze the selector from the completed environment before reading docstrings.
  -- Loading server/private data above is necessary for both Lean doc formats.
  let own := StrictLean.Probe.ownedConstants env requested.toList
  let mut selected := #[]
  for (name, _) in own do
    if StrictLean.Linter.Documentation.selected env name then
      let some idx := env.getModuleIdxFor? name
        | throw <| IO.userError s!"material declaration has no module: {name}"
      selected := selected.push (env.header.modules[(idx : Nat)]!.module, name)
  let documentation : StrictLean.Checker.ProducerReport.DocumentationObservation := {
    modules := ← requested.mapM fun name => do
      return (name, ← IO.ofExcept <| StrictLean.Linter.Documentation.modulePresent env name)
    materialDeclarations := selected
    declarations := ← selected.mapM fun key => do
      return (key, ← Lean.findDocString? env key.2)
  }
  let histories ← IO.mkRef ({} : NameMap ProducerReport.HistoryOutcome)
  let loadHistory (moduleName : Name) := do
    if let some result := (← histories.get).find? moduleName then return result.edges
    let result ← replacementHistory sourceRoots resolvedSources moduleName
    histories.modify (·.insert moduleName result)
    return result.edges
  let ctx : Elab.Command.Context := {
    fileName := "<trusted-environment-probe>"
    fileMap := FileMap.ofString ""
    snap? := none
    cancelTk? := none
  }
  let state := Elab.Command.mkState env
  match ← timedPhase "declaration report" <| EIO.toIO' <|
      (StrictLean.Probe.environmentReport requested.toList loadHistory includeExecution includeModuleOrigins).run ctx |>.run state with
  | .error ex => throw <| IO.userError (← ex.toMessageData.toString)
  | .ok (report, _) =>
    let historyTable ← histories.get
    let historyKeys := StrictLeanPolicy.canonicalNames (historyTable.toArray.map (·.1))
    let historyRecords ← historyKeys.mapM fun name => do
      let some outcome := historyTable.find? name
        | throw <| IO.userError "producer-history: missing recorded lookup"
      pure (name, outcome)
    let report : ProducerReport.Environment := {
      toCollected := report
      admission := some admission
      documentation := some documentation
      histories := historyRecords
      sourceBindings := sourceBindings.filter (fun s => report.modules.contains s.moduleName)
    }
    SourceBinding.unchanged report.sourceBindings
    IO.ofExcept report.validate
    return .ok report

/-- Lean resolves a whole module prefix at the first matching directory.
A fresh project that builds only `Contract` must not mask the trusted probe,
and putting the entire checker output first would mask fresh audited modules.
Expose only the checker-owned prefix ahead of the audited search roots. -/
private unsafe def loadReportCore (modules : Array Name) (sourceRoots : Array FilePath := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO (Except ProducerReport.AdmissionFailure ProducerReport.Environment) := do
  let some selfLib ← checkerPackageLibDir
    | throw <| IO.userError "trusted checker library directory unavailable"
  withScratch (← IO.currentDir) "probe-search" fun overlay => do
    let probeDirectory ← IO.FS.realPath (selfLib / "StrictLean")
    let linked ← runProcess overlay "ln" #["-s", probeDirectory.toString,
      (overlay / "StrictLean").toString]
    if !linked.succeeded then
      throw <| IO.userError s!"could not expose trusted probe prefix: {linked.output}"
    let oldSearchPath ← Lean.searchPathRef.get
    Lean.searchPathRef.set (overlay :: oldSearchPath)
    try loadReportCoreAtSearchPath modules sourceRoots moduleSources ownedOutput includeExecution includeModuleOrigins
    finally Lean.searchPathRef.set oldSearchPath

/-- Load exact modules using the already configured search path. This variant
supports bounded parallel, read-only imports while a caller owns the global
search-path scope. -/
unsafe def loadReportCurrentSearchPathOutcome (modules : Array Name)
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO (Except ProducerReport.AdmissionFailure ProducerReport.Environment) :=
  loadReportCore modules #[] moduleSources ownedOutput includeExecution includeModuleOrigins

/-- Load exact modules through Lean's import semantics and return their typed
declaration report. Extra search roots are temporary and restored afterward. -/
unsafe def loadReportOutcome (modules : Array Name)
    (extraSearchRoots : Array FilePath := #[]) (sourceRoots : Array FilePath := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO (Except ProducerReport.AdmissionFailure ProducerReport.Environment) := do
  let selfLib ← checkerPackageLibDir
  let oldSearchPath ← Lean.searchPathRef.get
  Lean.searchPathRef.set (extraSearchRoots.toList ++ selfLib.toList ++ oldSearchPath)
  try loadReportCore modules sourceRoots moduleSources ownedOutput includeExecution includeModuleOrigins
  finally Lean.searchPathRef.set oldSearchPath

/-- Compatibility wrapper for callers that report all incomplete inspection failures
at their own stage. Public rule adapters use the typed outcome variant above. -/
unsafe def loadReportCurrentSearchPath (modules : Array Name)
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO ProducerReport.Environment := do
  IO.ofExcept <| (← loadReportCurrentSearchPathOutcome modules moduleSources ownedOutput
    includeExecution includeModuleOrigins).mapError (·.detail)

unsafe def loadReport (modules : Array Name)
    (extraSearchRoots : Array FilePath := #[]) (sourceRoots : Array FilePath := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO ProducerReport.Environment := do
  IO.ofExcept <| (← loadReportOutcome modules extraSearchRoots sourceRoots moduleSources ownedOutput
    includeExecution includeModuleOrigins).mapError (·.detail)

end StrictLean.Checker.Environment
