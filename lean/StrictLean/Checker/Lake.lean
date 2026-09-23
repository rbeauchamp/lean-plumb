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
  deriving Repr, BEq

/-- Exact source locations already discovered through Lake for root-package
modules. Reuse these for frontend history instead of a module-prefix search. -/
def SurfaceInventory.moduleSources (inventory : SurfaceInventory) : Array (Name × FilePath) :=
  inventory.libraries.flatMap (fun library => library.sources.map fun source =>
    (source.«module», source.source)) ++
    inventory.executables.map (fun executable => (executable.root, executable.source))

private def checkSource (repo : FilePath) (what : String)
    (moduleName sourceRaw : String) : IO FilePath := do
  let source := FilePath.mk sourceRaw
  let mut invalidSource := moduleName.isEmpty || sourceRaw.isEmpty
    || source.extension != some "lean" || !(← source.pathExists)
  if !invalidSource then
    invalidSource := !(← pathWithin source repo)
  if invalidSource then
    throw <| IO.userError s!"lake-query-malformed: {what} has invalid source"
  return ← IO.FS.realPath source

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
      let modules := libModules.map (·.name)
      let mut sources : Array SourceEntry := #[]
      for libModule in libModules do
        let moduleName := libModule.name
        let source ← checkSource repo s!"{library} module {moduleName}"
          moduleName.toString libModule.leanFile.toString
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
      let root := exe.root.name
      let source ← checkSource repo s!"executable {executable}"
        root.toString exe.root.leanFile.toString
      if executable.isEmpty || root.isAnonymous || executables.any (·.executable == executable)
          || executables.any (·.root == root) then
        throw <| IO.userError s!"lake-query-malformed: invalid executable {executable}"
      executables := executables.push { executable, root, source }
    let leanPath := #[leanLibDir] ++ ws.leanPath.toArray
    let leanSrcPath := ws.leanSrcPath.toArray
    let dependencies ← (ws.packages.extract 1 ws.packages.size).mapM fun package => do
      let names ← IO.mkRef ({} : NameSet)
      for library in package.leanLibs do
        let mut globs := library.config.globs
        for root in library.roots do
          if library.config.globs.any (·.matches root) &&
              (← (Lean.modToFilePath library.srcDir root "").isDir) then
            globs := globs.push (.submodules root)
        for glob in globs do
          glob.forEachModuleIn library.srcDir fun name => do
            names.modify (·.insert name)
      let mut sources := #[]
      for name in (← names.get).toArray.qsort Name.quickLt do
        let some resolved := ws.findModule? name
          | throw <| IO.userError s!"lake-query-malformed: dependency module {name} is unresolved"
        if resolved.pkg.keyName != package.keyName then continue
        let source ← checkSource package.dir s!"dependency module {name}"
          name.toString resolved.leanFile.toString
        sources := sources.push { «module» := name, source }
      for exe in package.leanExes do
        if sources.any (·.module == exe.root.name) then continue
        -- Dependencies may declare unused executables without shipping their
        -- sources. Capture existing roots; terminal rediscovery still detects
        -- their addition/removal. Claimed root-package targets remain required.
        if !(← exe.root.leanFile.pathExists) then continue
        let source ← checkSource package.dir s!"dependency executable {exe.name}"
          exe.root.name.toString exe.root.leanFile.toString
        sources := sources.push { «module» := exe.root.name, source }
      let root ← IO.FS.realPath package.dir
      let configurationPaths := #[package.configFile, package.manifestFile,
        package.dir / "lean-toolchain", package.dir / "lakefile.lean", package.dir / "lakefile.toml"]
        |>.toList.eraseDups.toArray
      pure ({ package := package.baseName.toString, root, sources, configurationPaths } : DependencyInventory)
    let root ← IO.FS.realPath repo
    return { root, leanLibDir, leanPath, leanSrcPath, libraries, executables, dependencies }

/-- Build the targets with the inherited Lean search paths removed, so the
build resolves modules only through the workspace being built. -/
def buildTargets (repo : FilePath) (targets : Array String) : IO ProcessResult :=
  runProcess repo "lake" (#["build"] ++ targets) scrubbedLeanPathEnv

/-- Build the claimed Lake targets and require success with no warnings.
Returns the diagnostic lines to report on failure. -/
def buildCheckedObservation (repo : FilePath) (targets : Array String)
    (mode : String) : IO (ProcessResult × Option (Array String)) := do
  let build ← buildTargets repo targets
  if build.succeeded && (warningLines build.output).isEmpty then return (build, none)
  let diagnostics :=
    -- A warning's payload (the unused simp argument, the hint) sits on the
    -- continuation lines after its head; report the whole block.
    if !(warningLines build.output).isEmpty then diagnosticBlocks build.output isWarningLine
    -- Lean's expected type and supplied proof are continuation lines. Keep
    -- that context so public-gate qualification can identify the obligation.
    else if !(errorLines build.output).isEmpty then outputLines build.output
    else takeLast 20 (outputLines build.output)
  return (build, some (#[s!"FAIL[build-failed]: positive surface did not build {mode} and warning-free"]
    ++ diagnostics))

/-- Compatibility diagnostic projection. Acceptance callers retain the process observation. -/
def buildChecked (repo : FilePath) (targets : Array String)
    (mode : String) : IO (Option (Array String)) := do
  return (← buildCheckedObservation repo targets mode).2

def transitiveImports (repo : FilePath) (moduleName : String) : IO (Array String) := do
  jsonStringArray s!"transitive imports for {moduleName}" <|
    ← lakeQuery repo s!"+{moduleName}:transImports"

end StrictLean.Checker.Lake
