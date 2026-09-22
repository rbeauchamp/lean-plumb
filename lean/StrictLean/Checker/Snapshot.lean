import StrictLean.Checker.Lake
import StrictLean.Checker.Producer
import StrictLeanPolicy.Claim

/-! Exact request snapshots of Lake-resolved sources and configuration, with nominal
Git revisions and input-scoped dirty status where available. These are IO observations,
not kernel authentication of a filesystem or compiled artifact. The request state is
derived purely from the exact captures (`stateOf`), and the terminal comparison
decides capture equality directly. -/
namespace StrictLean.Checker.Snapshot
open Lean System StrictLeanPolicy

/-- An actual dependency observation, including dirty/path state, not only a
lockfile pin. The capture fields hold the exact bytes/texts observed at this
freeze point; `stateOf` derives the request state from those captures alone. -/
structure DependencyObservation where
  project : FilePath
  package : String
  root : FilePath
  revision : Option String
  dirty : Bool
  sourcePaths : Array (Name × FilePath)
  sourceCaptures : Array (Name × String × String × String)
  configurationCaptures : Array (String × Option (String × Array UInt8))
  deriving BEq

/-- Fresh exact configuration capture: original path, canonical path and raw
bytes, with presence preserved. -/
private def captureConfiguration (path : FilePath) :
    IO (String × Option (String × Array UInt8)) := do
  if !(← path.pathExists) then return (path.toString, none)
  let canonical ← IO.FS.realPath path
  let bytes ← IO.FS.readBinFile canonical
  return (path.toString, some (canonical.toString, bytes))

/-- Pure request-state derivation from exact captures. The `mkObj` shape and key
order are exactly the state previously built inside `dependency`; request bytes
are unchanged. -/
def stateOfCore (root : String) (revision : Option String)
    (sourceCaptures : Array (Name × String × String × String))
    (configurationCaptures : Array (String × Option (String × Array UInt8))) : Json :=
  Json.mkObj [("root", toJson root), ("revision", toJson revision),
    ("sources", toJson (sourceCaptures.map fun (module, path, canonical, source) =>
      Json.mkObj [("module", toJson module), ("path", toJson path),
        ("canonical", toJson canonical), ("source", toJson source)])),
    ("configuration", toJson (configurationCaptures.map fun (path, entry) =>
      match entry with
      | none => Json.mkObj [("path", toJson path), ("bytes", Json.null)]
      | some (canonical, bytes) => Json.mkObj [("path", toJson path),
        ("canonical", toJson canonical), ("bytes", toJson (bytes.toList.map UInt8.toNat))]))]

/-- Request state of one observation, purely derived from its exact captures. -/
def stateOf (dep : DependencyObservation) : Json :=
  stateOfCore dep.root.toString dep.revision dep.sourceCaptures dep.configurationCaptures

/-- Equal captures give equal request state (kernel-only congruence). -/
theorem stateOfCore_congruence {root root' : String} {revision revision' : Option String}
    {sourceCaptures sourceCaptures' : Array (Name × String × String × String)}
    {configurationCaptures configurationCaptures' :
      Array (String × Option (String × Array UInt8))}
    (hr : root = root') (hv : revision = revision')
    (hs : sourceCaptures = sourceCaptures')
    (hc : configurationCaptures = configurationCaptures') :
    stateOfCore root revision sourceCaptures configurationCaptures
      = stateOfCore root' revision' sourceCaptures' configurationCaptures' := by
  rw [hr, hv, hs, hc]; rfl

/-- Any request-state difference implies a difference in the exact captures, so
every input change visible to the request state still changes the terminal
capture comparison. -/
theorem captures_ne_of_stateOfCore_ne {root root' : String} {revision revision' : Option String}
    {sourceCaptures sourceCaptures' : Array (Name × String × String × String)}
    {configurationCaptures configurationCaptures' :
      Array (String × Option (String × Array UInt8))}
    (h : stateOfCore root revision sourceCaptures configurationCaptures
      ≠ stateOfCore root' revision' sourceCaptures' configurationCaptures') :
    ¬(root = root' ∧ revision = revision' ∧ sourceCaptures = sourceCaptures'
      ∧ configurationCaptures = configurationCaptures') := by
  intro he
  rw [he.1, he.2.1, he.2.2.1, he.2.2.2] at h
  exact h rfl

/-- Equal observations give equal request state. -/
theorem stateOf_congruence {a b : DependencyObservation}
    (hr : a.root = b.root) (hv : a.revision = b.revision)
    (hs : a.sourceCaptures = b.sourceCaptures)
    (hc : a.configurationCaptures = b.configurationCaptures) :
    stateOf a = stateOf b :=
  stateOfCore_congruence hr hv hs hc

private def inputsDirty (root : FilePath) (paths : Array FilePath) : IO Bool := do
  let mut offset := 0
  while offset < paths.size do
    -- Consecutive, nonempty slices preserve the input order and multiplicity.
    -- Bound both argv entries and UTF-8 bytes (including each terminating NUL).
    -- An oversized individual path stays a singleton, leaving its failure to Git/OS.
    let mut stop := offset + 1
    let mut bytes := paths[offset]!.toString.utf8ByteSize + 1
    while stop < paths.size && stop - offset < 512 do
      let nextBytes := paths[stop]!.toString.utf8ByteSize + 1
      if bytes + nextBytes > 96 * 1024 then break
      bytes := bytes + nextBytes
      stop := stop + 1
    let status ← runProcess root "git" (#["--literal-pathspecs", "status", "--porcelain=v1",
      "-z", "--untracked-files=all", "--ignored=matching", "--"] ++
      (paths.extract offset stop).map (·.toString))
    unless status.succeeded do throw <| IO.userError "dependency input status unavailable"
    if !status.stdout.isEmpty then return true
    offset := stop
  return false

def dependency (project : FilePath) (package : String) (root : FilePath)
    (sourcePaths : Array (Name × FilePath)) (configurationPaths : Array FilePath) : IO DependencyObservation := do
  let root ← IO.FS.realPath root
  let sourceCaptures ← sourcePaths.mapM fun (name, path) => do
    let canonical ← IO.FS.realPath path
    let bytes ← IO.FS.readBinFile canonical
    let some text := String.fromUTF8? bytes
      | throw <| IO.userError s!"dependency source is not UTF-8: {path}"
    pure (name, path.toString, canonical.toString, text)
  let configurationCaptures ← configurationPaths.mapM captureConfiguration
  let head ← runProcess root "git" #["rev-parse", "HEAD"]
  let top ← runProcess root "git" #["rev-parse", "--show-toplevel"]
  let ownRepository ← if top.succeeded then
    pure ((← IO.FS.realPath (FilePath.mk top.stdout.trimAscii.toString)) == root)
    else pure false
  let revision ← if head.succeeded && ownRepository then do
      let revision := head.stdout.trimAscii.toString
      if revision.isEmpty then throw <| IO.userError s!"empty dependency revision: {package}"
      pure (some revision)
    else pure none
  let dirty ← if revision.isSome then inputsDirty root (sourcePaths.map (·.2) ++ configurationPaths)
    else pure true
  return { project, package, root, sourcePaths, revision, dirty,
    sourceCaptures, configurationCaptures }

/-- Resolve dependency names/locations through the frozen Lake discovery. -/
def dependencies (inventory : Lake.SurfaceInventory) : IO (Array DependencyObservation) :=
  timedPhase "dependency snapshot capture" <| inventory.dependencies.mapM fun entry =>
    dependency inventory.root entry.package entry.root (entry.sources.map fun source => (source.module, source.source))
      entry.configurationPaths

/-- Reconcile the frozen Lake root and dependency inputs at the terminal boundary. -/
def inputsUnchanged (inventory : Lake.SurfaceInventory)
    (before : Array DependencyObservation) : IO Unit := do
  let current ← timedPhase "terminal Lake inventory" <| Lake.surfaceInventory inventory.root
  unless current.root == inventory.root && current.leanLibDir == inventory.leanLibDir &&
      current.leanPath == inventory.leanPath && current.leanSrcPath == inventory.leanSrcPath &&
      current.libraries == inventory.libraries && current.executables == inventory.executables do
    throw <| IO.userError "root inventory changed: Lake modules, targets or source identities"
  unless (← dependencies current) == before do
    throw <| IO.userError "dependency snapshot changed: Lake inventory or source/configuration state"

/-- Exact request bytes include configuration presence/absence and actual dependency state.
Additional imported sources (for example history) are included by the coordinator only
after matching their own before/after producer binding against current source bytes. -/
def make (root : FilePath) (configuration : Array (FilePath × Option String))
    (sources : Array SourceSnapshot) (deps : Array DependencyObservation) : Except String AdmittedSnapshot :=
  admitSnapshot {
    sources
    configuration := ⟨root.toString, (Json.mkObj [
      ("configuration", toJson (configuration.map fun (path, text) => (path.toString, text))),
      ("dependencies", toJson (deps.map fun dep => Json.mkObj [
        ("package", toJson dep.package), ("state", stateOf dep)]))]).compress⟩
    toolchain := ⟨Lean.versionString, Lean.githash, Producer.identity.sourceRevision⟩
    dependencies := deps.map fun dep => {
      package := dep.package, nominalRevision := dep.revision, dirty := dep.dirty, files := #[] } }

end StrictLean.Checker.Snapshot
