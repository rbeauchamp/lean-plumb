import StrictLean.Qualification.Project
import StrictLean.Checker.Snapshot

/-! Native retention of dependency snapshot and SL3001 history controls. These
observations qualify trusted Lake/filesystem boundaries, not universal IO behavior. -/
namespace StrictLean.Qualification.DependencySnapshot
open Lean System

def success (result : IO.Process.Output) : IO Unit :=
  requireChecks [⟨result.stdout ++ result.stderr, result.exitCode == 0⟩]

def removeFile (path : FilePath) : IO Unit := do
  if ← path.pathExists then IO.FS.removeFile path

def toolchain (root target : FilePath) : IO Unit := do
  IO.FS.writeBinFile (target / "lean-toolchain") (← IO.FS.readBinFile (root / "lean-toolchain"))

def manifest (project : FilePath) (claim : String) : IO Unit :=
  writeJson (project / "foundation_manifest.json") (Json.mkObj [
    ("schema-version", toJson (2 : Nat)), ("surfaces", toJson #[Json.mkObj [
      ("library", toJson "Example"), ("claim", toJson claim), ("execution", toJson "report"),
      ("rationale", toJson "Exact frozen-input qualification.")]]),
    ("excluded-libraries", toJson (#[] : Array Json)),
    ("excluded-executables", toJson (#[] : Array Json))])

def accepted (result : Json) : Bool :=
  (result.getObjValAs? String "status").toOption == some "completed" &&
    (result.getObjVal? "acceptance").toOption.isSome

private def control (project dependency : FilePath) : IO Unit := do
  let inventory ← StrictLean.Checker.Lake.surfaceInventory project
  let before ← StrictLean.Checker.Snapshot.dependencies inventory
  let some observed := before.find? (·.package == "dep")
    | throw <| IO.userError "dependency missing"
  requireChecks [⟨"ignored imported module", observed.sourcePaths.any (·.1 == `Dep.Generated)⟩,
    ⟨"buildable unimported module", observed.sourcePaths.any (·.1 == `Dep.Unimported)⟩]
  let unchanged := StrictLean.Checker.Snapshot.inputsUnchanged inventory before
  unchanged
  let snapshot ← IO.ofExcept <| StrictLean.Checker.Snapshot.make inventory.root #[] #[] before
  let marker := "R4_SYNTHETIC_UNRELATED"
  let encoded := (toJson (marker.toUTF8.toList.map UInt8.toNat)).compress
  requireChecks [⟨"unrelated bytes excluded", !snapshot.val.configuration.source.contains marker &&
    !snapshot.val.configuration.source.contains encoded⟩]
  for name in #[".env", "unrelated.txt"] do
    IO.FS.writeFile (dependency / name) "R4_SYNTHETIC_CHANGED"
  unchanged
  let built ← StrictLean.Checker.Lake.buildTargets project #["Example"]
  requireChecks [⟨built.output, built.succeeded⟩,
    ⟨"custom dependency build directory", ← (dependency / "build/lib/lean/Dep.olean").pathExists⟩]
  unchanged
  for name in #["Dep/Generated.lean", "lean-toolchain", "Dep/New.lean"] do
    let path := dependency / name
    let original ← if ← path.pathExists then pure (some (← IO.FS.readFile path)) else pure none
    IO.FS.writeFile path (original.getD "" ++
      if name == "lean-toolchain" then "\n" else "\ndef added : Nat := 9\n")
    let changed ← unchanged.toBaseIO
    match original with
    | some text => IO.FS.writeFile path text
    | none => IO.FS.removeFile path
    match changed with
    | .ok _ => throw <| IO.userError s!"accepted changed dependency input: {name}"
    | .error error => requireChecks [⟨"intended dependency refusal", error.toString.contains "dependency snapshot changed:"⟩]
    unchanged

def check (group : String) : IO Unit := do
  requireChecks [⟨"known snapshot group", #["all", "dependencies", "history"].contains group⟩]
  let root ← rootDirectory
  withScratch root "snapshot-history" fun scratch => do
    let dependency := scratch / "dependency"
    IO.FS.createDirAll (dependency / "Dep")
    IO.FS.writeFile (dependency / "lakefile.toml")
      "name = \"dep\"\nbuildDir = \"build\"\n[[lean_lib]]\nname = \"Dep\"\nglobs = [\"Dep\"]\n"
    IO.FS.writeFile (dependency / "Dep.lean") "import Dep.Generated\n"
    IO.FS.writeFile (dependency / "Dep/Generated.lean") "def generated : Nat := 3\n"
    IO.FS.writeFile (dependency / "Dep/Unimported.lean") "def unimported : Nat := 4\n"
    toolchain root dependency
    IO.FS.writeFile (dependency / ".gitignore") "Dep/Generated.lean\nDep/Unimported.lean\nDep/New.lean\nlean-toolchain\n.lake/\n"
    IO.FS.writeFile (dependency / ".env") "R4_SYNTHETIC_UNRELATED"
    for args in #[#["init", "-q"], #["add", "."], #["-c", "user.name=Snapshot Control", "-c",
        "user.email=snapshot@example.invalid", "-c", "commit.gpgsign=false", "commit", "-qm", "dependency control"]] do
      success (← run dependency "git" args)
    IO.FS.writeFile (dependency / "unrelated.txt") "R4_SYNTHETIC_UNRELATED"
    let project := scratch / "project"
    IO.FS.createDirAll project
    toolchain root project
    IO.FS.writeFile (project / "lakefile.toml")
      "name = \"snapshot_control\"\n[[require]]\nname = \"dep\"\npath = \"../dependency\"\n[[lean_lib]]\nname = \"Example\"\n"
    IO.FS.writeFile (project / "Example.lean") "import Dep\n/-! Snapshot control. -/\n"
    success (← run project "lake" #["update"] cleanEnv)
    if group != "history" then
      manifest project "standard-logical"
      for kind in #["git", "non-git"] do
        if kind == "non-git" then IO.FS.removeDirAll (dependency / ".git")
        for path in #[dependency / "build", project / ".lake/build"] do
          if ← path.pathExists then IO.FS.removeDirAll path
        for name in #[".env", "unrelated.txt"] do
          IO.FS.writeFile (dependency / name) "R4_SYNTHETIC_UNRELATED"
        control project dependency
        IO.FS.removeDirAll (dependency / "build")
        let output := scratch / s!"scope-{kind}.json"
        let (result, packet) ← observeProject root project output #[]
        success result
        let encoded := packet.compress
        requireChecks [⟨"accepted dependency scope", accepted packet⟩,
          ⟨"unrelated filenames excluded", !encoded.contains ".env" && !encoded.contains "unrelated.txt"⟩]
        for marker in #["R4_SYNTHETIC_UNRELATED", "R4_SYNTHETIC_CHANGED"] do
          requireChecks [⟨"unrelated content excluded", !encoded.contains marker &&
            !encoded.contains (toJson (marker.toUTF8.toList.map UInt8.toNat)).compress⟩]
        IO.println s!"dependency snapshot {kind}: PASS"
    if group == "dependencies" then return
    IO.FS.writeFile (project / "lakefile.toml") "name = \"history_control\"\n[[lean_lib]]\nname = \"Example\"\n"
    removeFile (project / "lake-manifest.json")
    success (← run project "lake" #["update"] cleanEnv)
    manifest project "standard-logical"
    for (mode, flags) in #[("fresh", #[]), ("incremental", #["--incremental"]), ("build-lint", #["--build-lint"])] do
      for (phase, fixture) in #[("positive", "Fixed.lean"), ("negative", "Violation.lean"), ("restored", "Fixed.lean")] do
        IO.FS.writeBinFile (project / "Example.lean") (← IO.FS.readBinFile (root / "examples/rules/SL3001" / fixture))
        if phase != "negative" then clearBuild project
        let (result, packet) ← observeProject root project (scratch / s!"{mode}-{phase}.json") flags
        if phase != "negative" then
          success result
          requireChecks [⟨"accepted history", accepted packet⟩]
        else
          let findings ← IO.ofExcept (packet.getObjValAs? (Array Json) "diagnostics")
          let historyFindings := findings.filter (fun d => (d.getObjValAs? String "id").toOption == some "SL3001")
          requireChecks [⟨"history incomplete", result.exitCode != 0 &&
            (packet.getObjValAs? String "status").toOption == some "incomplete" &&
            (packet.getObjVal? "acceptance").toOption.isNone⟩,
            ⟨"not setup failure", !findings.any (fun d => (d.getObjValAs? String "id").toOption == some "SL2001")⟩,
            ⟨"history diagnostic present", !historyFindings.isEmpty⟩,
            ⟨"identity root", historyFindings.any (fun d => (do
              let args ← d.getObjVal? "arguments"
              args.getObjVal? "root").toOption == some (nameJson "identity"))⟩,
            ⟨"exact source location", historyFindings.all (fun d => (do
              let loc ← d.getObjVal? "location"
              pure ((← loc.getObjValAs? String "kind") == "source" &&
                (← loc.getObjValAs? String "uri").endsWith "Example.lean")).toOption == some true)⟩,
            ⟨"unresolved history", (result.stdout ++ result.stderr).contains "execution-unresolved"⟩]
        IO.println s!"snapshot history {mode}/{phase}: PASS"
end StrictLean.Qualification.DependencySnapshot
