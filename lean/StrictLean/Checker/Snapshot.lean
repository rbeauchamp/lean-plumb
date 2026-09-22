import StrictLean.Checker.Lake
import StrictLean.Checker.Producer
import StrictLeanPolicy.Claim

/-! Exact request snapshots of Lake-resolved sources and configuration, with nominal
Git revisions and input-scoped dirty status where available. These are IO observations,
not kernel authentication of a filesystem or compiled artifact. The request state is
derived purely from the exact captures (`stateOfCore`) and carried with its derivation
invariant. The terminal decision always executes the retired observation/state `BEq`
chain on the completed values; only the state construction is cached and reused at
proved equal captures. -/
namespace StrictLean.Checker.Snapshot
open Lean System StrictLeanPolicy

/-- Pure request-state derivation from exact captures. The `mkObj` shape and key
order are exactly the state previously built inside `dependency`; request bytes
are unchanged. -/
def stateOfCore (root : String) (revision : Option String)
    (sourceCaptures : Array (Name × String × String × String))
    (configurationCaptures : Array (String × Option (String × ByteArray))) : Json :=
  Json.mkObj [("root", toJson root), ("revision", toJson revision),
    ("sources", toJson (sourceCaptures.map fun (module, path, canonical, source) =>
      Json.mkObj [("module", toJson module), ("path", toJson path),
        ("canonical", toJson canonical), ("source", toJson source)])),
    ("configuration", toJson (configurationCaptures.map fun (path, entry) =>
      match entry with
      | none => Json.mkObj [("path", toJson path), ("bytes", Json.null)]
      | some (canonical, bytes) => Json.mkObj [("path", toJson path),
        ("canonical", toJson canonical), ("bytes", toJson (bytes.toList.map UInt8.toNat))]))]

/-- Equal captures give equal request state (kernel-only congruence); this holds
for any comparator, including the opaque core `Json` `BEq`. -/
theorem stateOfCore_congruence {root root' : String} {revision revision' : Option String}
    {sourceCaptures sourceCaptures' : Array (Name × String × String × String)}
    {configurationCaptures configurationCaptures' :
      Array (String × Option (String × ByteArray))}
    (hr : root = root') (hv : revision = revision')
    (hs : sourceCaptures = sourceCaptures')
    (hc : configurationCaptures = configurationCaptures') :
    stateOfCore root revision sourceCaptures configurationCaptures
      = stateOfCore root' revision' sourceCaptures' configurationCaptures' := by
  rw [hr, hv, hs, hc]

/-- Any request-state difference implies a difference in the exact captures, so
every input change visible to the request state still changes the executed
comparison. -/
theorem captures_ne_of_stateOfCore_ne {root root' : String} {revision revision' : Option String}
    {sourceCaptures sourceCaptures' : Array (Name × String × String × String)}
    {configurationCaptures configurationCaptures' :
      Array (String × Option (String × ByteArray))}
    (h : stateOfCore root revision sourceCaptures configurationCaptures
      ≠ stateOfCore root' revision' sourceCaptures' configurationCaptures') :
    ¬(root = root' ∧ revision = revision' ∧ sourceCaptures = sourceCaptures'
      ∧ configurationCaptures = configurationCaptures') := by
  intro he
  rw [he.1, he.2.1, he.2.2.1, he.2.2.2] at h
  exact h rfl

/-- Exact dependency captures at one freeze point: the raw bytes/texts observed
by fresh reads, before any request-state construction. -/
structure DependencyCaptures where
  project : FilePath
  package : String
  root : FilePath
  revision : Option String
  dirty : Bool
  sourcePaths : Array (Name × FilePath)
  sourceCaptures : Array (Name × String × String × String)
  configurationCaptures : Array (String × Option (String × ByteArray))

/-- An actual dependency observation: exact captures plus the request state
derived from them, including dirty/path state, not only a lockfile pin. The
`state_sound` field carries the derivation invariant by type, so any carried
state value is known to be the pure derivation of the carried captures. -/
structure DependencyObservation where
  project : FilePath
  package : String
  root : FilePath
  revision : Option String
  dirty : Bool
  sourcePaths : Array (Name × FilePath)
  sourceCaptures : Array (Name × String × String × String)
  configurationCaptures : Array (String × Option (String × ByteArray))
  state : Json
  state_sound : state = stateOfCore root.toString revision sourceCaptures configurationCaptures

/-- The carried request state is exactly the pure derivation of the carried
captures (kernel-only). -/
theorem observation_state_sound (o : DependencyObservation) :
    o.state = stateOfCore o.root.toString o.revision o.sourceCaptures o.configurationCaptures :=
  o.state_sound

/-- Retained observation shape: captures plus the request state freshly derived
from them. -/
def observe (fresh : DependencyCaptures) : DependencyObservation where
  project := fresh.project
  package := fresh.package
  root := fresh.root
  revision := fresh.revision
  dirty := fresh.dirty
  sourcePaths := fresh.sourcePaths
  sourceCaptures := fresh.sourceCaptures
  configurationCaptures := fresh.configurationCaptures
  state := stateOfCore fresh.root.toString fresh.revision fresh.sourceCaptures
    fresh.configurationCaptures
  state_sound := rfl

/-- Complete a fresh capture into the retained observation shape. At proved
exact equality of the request-state inputs it reuses the retained request-state
value instead of rebuilding it; otherwise it rebuilds from the fresh captures.
Every completed value is a `DependencyObservation`, so the derivation invariant
holds by type in both branches. -/
def completeObservation (before : DependencyObservation) (fresh : DependencyCaptures) :
    DependencyObservation :=
  if h : before.root = fresh.root ∧ before.revision = fresh.revision ∧
      before.sourceCaptures = fresh.sourceCaptures ∧
      before.configurationCaptures = fresh.configurationCaptures then
    { project := fresh.project, package := fresh.package, root := fresh.root,
      revision := fresh.revision, dirty := fresh.dirty, sourcePaths := fresh.sourcePaths,
      sourceCaptures := fresh.sourceCaptures,
      configurationCaptures := fresh.configurationCaptures,
      state := before.state,
      state_sound := by rw [← h.1, ← h.2.1, ← h.2.2.1, ← h.2.2.2]; exact before.state_sound }
  else
    { project := fresh.project, package := fresh.package, root := fresh.root,
      revision := fresh.revision, dirty := fresh.dirty, sourcePaths := fresh.sourcePaths,
      sourceCaptures := fresh.sourceCaptures,
      configurationCaptures := fresh.configurationCaptures,
      state := stateOfCore fresh.root.toString fresh.revision fresh.sourceCaptures
        fresh.configurationCaptures,
      state_sound := rfl }

/-- Cache-reuse equality: at proved equality of the request-state inputs the
completed observation carries the retained cached value (kernel-only). -/
theorem completeObservation_reuse {before : DependencyObservation} {fresh : DependencyCaptures}
    (h : before.root = fresh.root ∧ before.revision = fresh.revision ∧
      before.sourceCaptures = fresh.sourceCaptures ∧
      before.configurationCaptures = fresh.configurationCaptures) :
    (completeObservation before fresh).state = before.state := by
  unfold completeObservation
  rw [dite_eq_left h]

/-- The cached retained value equals any fresh construction at the same captures
(kernel-only congruence). With `completeObservation_reuse`, the executed
comparator therefore receives exactly the retired values even on cache reuse,
while the comparator itself stays opaque and always executes. -/
theorem stateOfCore_reuse_eq {before : DependencyObservation} {fresh : DependencyCaptures}
    (h : before.root = fresh.root ∧ before.revision = fresh.revision ∧
      before.sourceCaptures = fresh.sourceCaptures ∧
      before.configurationCaptures = fresh.configurationCaptures) :
    before.state = stateOfCore fresh.root.toString fresh.revision fresh.sourceCaptures
      fresh.configurationCaptures := by
  rw [before.state_sound, h.1, h.2.1, h.2.2.1, h.2.2.2]

/-- The retained complete observation/state `BEq` decision: exactly the retired
structural `BEq` chain, same field set and order, over the carried request-state
values. This predicate always executes; nothing is substituted for its result. -/
def legacyBeq (a b : DependencyObservation) : Bool :=
  (a.project == b.project) && (a.package == b.package) && (a.root == b.root) &&
    (a.revision == b.revision) && (a.dirty == b.dirty) && (a.state == b.state) &&
    (a.sourcePaths == b.sourcePaths)

/-- The retained terminal decision over observation arrays: the retired
`Array.isEqv`/`BEq` shape over `legacyBeq`, executed on the completed fresh
values. Size correspondence is checked first, as in the retired array `BEq`. -/
def terminalBeq (fresh : Array DependencyCaptures) (before : Array DependencyObservation) : Bool :=
  fresh.size = before.size &&
    Array.isEqv (Array.zipWith completeObservation before fresh) before legacyBeq

/-- Fresh exact configuration capture: original path, canonical path and raw
bytes, with presence preserved. -/
private def captureConfiguration (path : FilePath) :
    IO (String × Option (String × ByteArray)) := do
  if !(← path.pathExists) then return (path.toString, none)
  let canonical ← IO.FS.realPath path
  let bytes ← IO.FS.readBinFile canonical
  return (path.toString, some (canonical.toString, bytes))

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

def captureDependency (project : FilePath) (package : String) (root : FilePath)
    (sourcePaths : Array (Name × FilePath)) (configurationPaths : Array FilePath) :
    IO DependencyCaptures := do
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
  return {
    project := project, package := package, root := root, sourcePaths := sourcePaths,
    revision := revision, dirty := dirty,
    sourceCaptures := sourceCaptures, configurationCaptures := configurationCaptures }

/-- Fresh captures of every dependency input, resolved through the frozen Lake
discovery. Every read and Git observation is taken here on every call. -/
def dependenciesCaptures (inventory : Lake.SurfaceInventory) :
    IO (Array DependencyCaptures) :=
  timedPhase "dependency snapshot capture" <| inventory.dependencies.mapM fun entry =>
    captureDependency inventory.root entry.package entry.root
      (entry.sources.map fun source => (source.module, source.source))
      entry.configurationPaths

/-- Resolve dependency names/locations through the frozen Lake discovery,
completing each fresh capture with its request state derived from that capture. -/
def dependencies (inventory : Lake.SurfaceInventory) : IO (Array DependencyObservation) :=
  return (← dependenciesCaptures inventory).map observe

/-- Reconcile the frozen Lake root and dependency inputs at the terminal boundary.
Every fresh read and Git observation is retaken; the executed decision is the
retired comparison on the completed values, with only the request-state
construction reused at proved equal captures. -/
def inputsUnchanged (inventory : Lake.SurfaceInventory)
    (before : Array DependencyObservation) : IO Unit := do
  let current ← timedPhase "terminal Lake inventory" <| Lake.surfaceInventory inventory.root
  unless current.root == inventory.root && current.leanLibDir == inventory.leanLibDir &&
      current.leanPath == inventory.leanPath && current.leanSrcPath == inventory.leanSrcPath &&
      current.libraries == inventory.libraries && current.executables == inventory.executables do
    throw <| IO.userError "root inventory changed: Lake modules, targets or source identities"
  unless terminalBeq (← dependenciesCaptures current) before do
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
        ("package", toJson dep.package), ("state", dep.state)]))]).compress⟩
    toolchain := ⟨Lean.versionString, Lean.githash, Producer.identity.sourceRevision⟩
    dependencies := deps.map fun dep => {
      package := dep.package, nominalRevision := dep.revision, dirty := dep.dirty, files := #[] } }

end StrictLean.Checker.Snapshot
