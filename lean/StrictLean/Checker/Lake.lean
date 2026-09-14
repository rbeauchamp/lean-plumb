import StrictLean.Checker.Common
import StrictLean.Checker.Manifest
import StrictLean.Checker.Workspace

/-! Lake-semantic module, source, dependency, and build discovery. -/

namespace StrictLean.Checker.Lake

open Lean System
open StrictLean.Checker

structure RootInventory where
  libraries : Array String
  leanLibDir : FilePath
  deriving Repr

structure SourceEntry where
  «module» : String
  source : FilePath
  deriving Repr

structure LibraryInventory where
  library : String
  modules : Array String
  sources : Array SourceEntry
  deriving Repr

structure ExecutableInventory where
  executable : String
  root : String
  source : FilePath
  deriving Repr

structure SurfaceInventory where
  leanLibDir : FilePath
  leanPath : Array FilePath
  leanSrcPath : Array FilePath
  libraries : Array LibraryInventory
  executables : Array ExecutableInventory
  deriving Repr

/-- Exact source locations already discovered through Lake for root-package
modules. Reuse these for frontend history instead of a module-prefix search. -/
def SurfaceInventory.moduleSources (inventory : SurfaceInventory) : Array (Name × FilePath) :=
  inventory.libraries.flatMap (fun library => library.sources.map fun source =>
    (source.«module».toName, source.source)) ++
    inventory.executables.map (fun executable => (executable.root.toName, executable.source))

private def checkSource (repo : FilePath) (what : String)
    (moduleName sourceRaw : String) : IO FilePath := do
  let source := FilePath.mk sourceRaw
  let mut invalidSource := moduleName.isEmpty || sourceRaw.isEmpty
    || source.extension != some "lean" || !(← source.pathExists)
  if !invalidSource then
    invalidSource := !(← pathWithin source repo)
  if invalidSource then
    throw <| IO.userError s!"lake-query-malformed: {what} has invalid source"
  return source

/-- Obtain every root-package Lean library and executable, exact module, and
exact source from Lake's own elaborated package model. This loads the checked
project's workspace in-process, so `lakefile.lean` and `lakefile.toml`
projects share one discovery path and need no custom Lake facets. -/
def surfaceInventory (repo : FilePath) : IO SurfaceInventory :=
  Workspace.withRootWorkspace repo fun ws => do
    let pkg := ws.root
    let leanLibDir := pkg.leanLibDir
    if leanLibDir.toString.isEmpty then
      throw <| IO.userError "lake-query-malformed: root leanLibDir is empty"
    let mut libraries : Array LibraryInventory := #[]
    for lib in pkg.leanLibs do
      let library := lib.name.toString
      let libModules ← lib.getModuleArray
      let modules := libModules.map (·.name.toString)
      let mut sources : Array SourceEntry := #[]
      for libModule in libModules do
        let moduleName := libModule.name.toString
        let source ← checkSource repo s!"{library} module {moduleName}"
          moduleName libModule.leanFile.toString
        sources := sources.push { «module» := moduleName, source }
      if library.isEmpty || modules.isEmpty || libraries.any (·.library == library)
          || modules.toList.eraseDups.length != modules.size then
        throw <| IO.userError s!"lake-query-malformed: invalid library {library}"
      libraries := libraries.push { library, modules, sources }
    if libraries.isEmpty then
      throw <| IO.userError "lake-query-malformed: no root Lean libraries"
    let mut executables : Array ExecutableInventory := #[]
    for exe in pkg.leanExes do
      let executable := exe.name.toString
      let root := exe.root.name.toString
      let source ← checkSource repo s!"executable {executable}"
        root exe.root.leanFile.toString
      if executable.isEmpty || root.isEmpty || executables.any (·.executable == executable)
          || executables.any (·.root == root) then
        throw <| IO.userError s!"lake-query-malformed: invalid executable {executable}"
      executables := executables.push { executable, root, source }
    let leanPath := #[leanLibDir] ++ ws.leanPath.toArray
    let leanSrcPath := ws.leanSrcPath.toArray
    return { leanLibDir, leanPath, leanSrcPath, libraries, executables }

/-- Build the targets with the inherited Lean search paths removed, so the
build resolves modules only through the workspace being built. -/
def buildTargets (repo : FilePath) (targets : Array String) : IO ProcessResult :=
  runProcess repo "lake" (#["build"] ++ targets) scrubbedLeanPathEnv

/-- Build the claimed Lake targets and require success with no warnings.
Returns the diagnostic lines to report on failure. -/
def buildChecked (repo : FilePath) (targets : Array String)
    (mode : String) : IO (Option (Array String)) := do
  let build ← buildTargets repo targets
  if build.succeeded && (warningLines build.output).isEmpty then return none
  let diagnostics :=
    -- A warning's payload (the unused simp argument, the hint) sits on the
    -- continuation lines after its head; report the whole block.
    if !(warningLines build.output).isEmpty then diagnosticBlocks build.output isWarningLine
    -- Lean's expected type and supplied proof are continuation lines. Keep
    -- that context so public-gate qualification can identify the obligation.
    else if !(errorLines build.output).isEmpty then outputLines build.output
    else takeLast 20 (outputLines build.output)
  return some (#[s!"FAIL[build-failed]: positive surface did not build {mode} and warning-free"]
    ++ diagnostics)

def transitiveImports (repo : FilePath) (moduleName : String) : IO (Array String) := do
  jsonStringArray s!"transitive imports for {moduleName}" <|
    ← lakeQuery repo s!"+{moduleName}:transImports"

end StrictLean.Checker.Lake
