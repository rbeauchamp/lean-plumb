import StrictLean.Checker.Lake
import StrictLean.Checker.Producer
import StrictLeanPolicy.Claim

/-! Exact request snapshots. Lake supplies dependency roots; Git supplies observed base
and working-tree state where available. Path-only packages retain file bytes instead.
These are IO observations, not kernel authentication of a filesystem or compiled artifact.
Build outputs, VCS internals and scratch/cache directories are outside the source snapshot. -/
namespace StrictLean.Checker.Snapshot
open Lean System StrictLeanPolicy

/-- An actual dependency observation, including dirty/path state, not only a lockfile pin. -/
structure DependencyObservation where
  package : String
  root : FilePath
  revision : Option String
  dirty : Bool
  state : Json
  deriving BEq

private def excluded (path : FilePath) : Bool :=
  path.components.any fun part => [".git", ".lake", ".cache", "tmp"].contains part

private def fileBytes (root : FilePath) (relative : String) : IO Json := do
  let path := root / relative
  if !(← path.pathExists) then return Json.mkObj [("path", toJson relative), ("bytes", Json.null)]
  let bytes ← IO.FS.readBinFile path
  return Json.mkObj [("path", toJson relative), ("bytes", toJson (bytes.toList.map UInt8.toNat))]

/-- Git state includes an exact binary diff and each untracked file's actual bytes.
An unversioned path package is observed directly. No shell parser or digest is used. -/
def dependency (package : String) (root : FilePath) : IO DependencyObservation := do
  let root ← IO.FS.realPath root
  let head ← runProcess root "git" #["rev-parse", "HEAD"]
  let top ← runProcess root "git" #["rev-parse", "--show-toplevel"]
  let ownRepository ← if top.succeeded then
    pure ((← IO.FS.realPath (FilePath.mk top.stdout.trimAscii.toString)) == root)
    else pure false
  if head.succeeded && ownRepository then
    let selectors := #["--", ".", ":(exclude)**/.lake/**", ":(exclude).lake/**",
      ":(exclude)**/.cache/**", ":(exclude).cache/**", ":(exclude)tmp/**"]
    let diff ← runProcess root "git" (#["diff", "--binary", "--no-ext-diff", "--no-textconv", "HEAD"] ++ selectors)
    let names ← runProcess root "git" (#["ls-files", "--others", "--exclude-standard", "-z"] ++ selectors)
    unless diff.succeeded && names.succeeded do
      throw <| IO.userError s!"dependency state unavailable: {package}"
    let untracked := (names.stdout.splitOn (String.singleton '\x00')).filter (!·.isEmpty)
    let files ← (untracked.filter (fun name => !excluded (FilePath.mk name))).toArray.mapM (fileBytes root)
    let revision := head.stdout.trimAscii.toString
    if revision.isEmpty then throw <| IO.userError s!"empty dependency revision: {package}"
    return {
      package, root, revision := some revision, dirty := !diff.stdout.isEmpty || !files.isEmpty,
      state := Json.mkObj [("root", toJson root.toString), ("revision", toJson revision),
        ("diff", toJson diff.stdout), ("untracked", toJson files)] }
  let entries ← root.walkDir fun path => pure (!excluded (FilePath.mk
    ("/".intercalate (path.normalize.components.drop root.normalize.components.length))))
  let mut relativeFiles := #[]
  for path in entries do
    if !(← path.isDir) then
      relativeFiles := relativeFiles.push
        ("/".intercalate (path.normalize.components.drop root.normalize.components.length))
  let files ← (relativeFiles.qsort (· < ·)).mapM (fileBytes root)
  return {
    package, root, revision := none, dirty := true,
    state := Json.mkObj [("root", toJson root.toString), ("files", toJson files)] }

/-- Resolve dependency names/locations through the frozen Lake discovery. -/
def dependencies (inventory : Lake.SurfaceInventory) : IO (Array DependencyObservation) :=
  inventory.dependencies.mapM fun (name, root) => dependency name root

/-- Check the actual dependency working state again at the request's terminal boundary. -/
def dependenciesUnchanged (before : Array DependencyObservation) : IO Unit := do
  for observed in before do
    unless (← dependency observed.package observed.root) == observed do
      throw <| IO.userError s!"dependency snapshot changed: {observed.package}"

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
