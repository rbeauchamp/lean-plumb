import StrictLean.Probe
import StrictLean.Checker.Common
import StrictLean.Checker.Admission

/-!
Trusted environment loading for checker policy. The fully qualified reporter
is called directly; audited syntax extensions cannot replace the observation.
-/

namespace StrictLean.Checker.Environment

open Lean System

/-- The checker-owned probe modules force-imported into every report so the
trusted reporter is always available: the probe and its transitive imports
inside the checker library. They are never part of an audited surface, so
their presence in an environment is not evidence about the claimed modules. -/
def probeModuleNames : Array String :=
  #["StrictLean.Probe", "StrictLean.Report", "StrictLean.Contract"]

/-- The probe modules no claimed module may import. `StrictLean.Contract`
is the published contract interface (docs/standard/8 §8.12) and is the one checker module
a claimed surface imports by design; the probe and its report records are
checker tooling that reach an audited environment only through the force
import, never through a claimed module's own imports. -/
def probeOnlyModuleNames : Array String :=
  #["StrictLean.Probe", "StrictLean.Report"]

/-- The checker-owned probe module force-imported into every report so the
trusted reporter is always available. It is never part of an audited surface. -/
def probeModuleName : String := "StrictLean.Probe"

/-- Re-elaboration recovers overwritten `implemented_by` choices that neither
the final attribute map nor optimized IR preserves. Isolate the frontend's
initializers, and memoize once per module in one audit invocation. -/
private def replacementHistory (sourceRoots : Array FilePath)
    (moduleSources : Array (Name × FilePath)) (moduleName : Name) :
    IO (Except String (Array (Name × Name))) := do
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
      let searchPath := System.SearchPath.toString (← Lean.searchPathRef.get)
      let result ← IO.Process.output {
        cmd := (bin / "axiomGate").toString
        args := #["--replacement-history-worker", moduleName.toString, source.toString,
          output.toString]
        env := #[("LEAN_PATH", some searchPath)] }
      if result.exitCode != 0 then
        throw <| IO.userError s!"{result.stdout}{result.stderr}"
      let json ← IO.ofExcept <| Json.parse (← IO.FS.readFile output)
      let edges : Array (String × String) ← IO.ofExcept <| fromJson? json
      return .ok <| edges.map fun (reference, target) => (reference.toName, target.toName)
  catch error => return .error error.toString

private unsafe def loadReportCoreAtSearchPath (modules : Array String) (sourceRoots : Array FilePath := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO StrictLean.Report.Environment := do
  if modules.isEmpty || modules.toList.eraseDups.length != modules.size then
    throw <| IO.userError "environment report requires unique nonempty modules"
  unsafe Lean.enableInitializersExecution
  let requested := modules.map String.toName
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
  timedPhase "kernel admission" <| Admission.validate env ownedModules
  let histories ← IO.mkRef ({} : NameMap (Except String (Array (Name × Name))))
  let loadHistory (moduleName : Name) := do
    if let some result := (← histories.get).find? moduleName then return result
    let result ← replacementHistory sourceRoots moduleSources moduleName
    histories.modify (·.insert moduleName result)
    return result
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
  | .ok (report, _) => return report

/-- Lean resolves a whole module prefix at the first matching directory.
A fresh project that builds only `Contract` must not mask the trusted probe,
and putting the entire checker output first would mask fresh audited modules.
Expose only the checker-owned prefix ahead of the audited search roots. -/
private unsafe def loadReportCore (modules : Array String) (sourceRoots : Array FilePath := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO StrictLean.Report.Environment := do
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
unsafe def loadReportCurrentSearchPath (modules : Array String)
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO StrictLean.Report.Environment :=
  loadReportCore modules #[] moduleSources ownedOutput includeExecution includeModuleOrigins

/-- Load exact modules through Lean's import semantics and return their typed
declaration report. Extra search roots are temporary and restored afterward. -/
unsafe def loadReport (modules : Array String)
    (extraSearchRoots : Array FilePath := #[]) (sourceRoots : Array FilePath := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO StrictLean.Report.Environment := do
  let selfLib ← checkerPackageLibDir
  let oldSearchPath ← Lean.searchPathRef.get
  Lean.searchPathRef.set (extraSearchRoots.toList ++ selfLib.toList ++ oldSearchPath)
  try loadReportCore modules sourceRoots moduleSources ownedOutput includeExecution includeModuleOrigins
  finally Lean.searchPathRef.set oldSearchPath

end StrictLean.Checker.Environment
