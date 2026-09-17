import StrictLean.Qualification.Project
import StrictLean.Checker.Lake
import StrictLeanQualification.Evidence
import StrictLeanQualification.Template

/-! Source-owned corpus orchestration. Actual detector receipts are admitted by the
existing RuleExampleQualification executable and its proof-linked policy functions.
This adapter does not infer policy from source text. Filesystem/process authenticity
remains trusted. Independent phases use distinct root artifacts and at most two jobs. -/
namespace StrictLean.Qualification.RuleExamples
open Lean System StrictLeanQualification.Evidence

private def get (j : Json) (key : String) : IO Json := IO.ofExcept (field j key)
private def string (j : Json) (key : String) : IO String := IO.ofExcept (text j key)
private def entries (j : Json) (key : String) : IO (Array Json) := IO.ofExcept (array j key)
private def optionalText (j : Json) (key fallback : String) : IO String :=
  match field j key with
  | .error _ => pure fallback
  | .ok value => IO.ofExcept value.getStr?

private def snapshot (paths : Array FilePath) : IO Json := do
  return toJson (← paths.mapM fun path => do
    pure (Json.mkObj [("uri", .str path.toString), ("source", .str (← IO.FS.readFile path))]))

private def configuration (paths : Array FilePath) : IO Json := do
  return toJson (← paths.mapM fun path => do
    let value ← if (← path.pathExists) && !(← path.isDir) then pure (some (← IO.FS.readFile path)) else pure none
    pure (path.toString, value))

private def addPackage (project : FilePath) (name : String) (dir : FilePath) (config : String) : IO Unit := do
  let path := project / "lake-manifest.json"
  let lock ← readJson path
  let packages ← entries lock "packages"
  writeJson path (lock.setObjVal! "packages" (toJson (packages.push (Json.mkObj [
    ("type", .str "path"), ("name", .str name), ("dir", .str dir.toString),
    ("manifestFile", .str "lake-manifest.json"), ("inherited", .bool false), ("configFile", .str config)]))))

private structure Context where
  root : FilePath
  scratch : FilePath
  specs : Json
  checkerPaths : Array FilePath
  checkerBefore : Json

private def produce (ctx : Context) (rule phase : String)
    (sourceText : Option String := none) (producerClaim : Option String := none) : IO Json := do
  let root := ctx.root
  let spec ← get ctx.specs rule
  let case := if phase == "Violation" then "Violation" else "Fixed"
  let project := ctx.scratch / s!"{rule}-{phase}"
  IO.FS.createDir project
  prepareProject root project "rule_examples" "kernel-only" "The fixture's exact mathematical claim and scope."
  IO.FS.writeFile (project / "Example.lean") "/-! The true proposition. -/\ntheorem baseline : True := True.intro\n"
  let folder := root / "examples/rules" / rule
  let sourceName := (← optionalText spec "source" "{case}.lean").replace "{case}" case
  let sourceFile := folder / sourceName
  let displayed ← match sourceText with
    | some text => pure text
    | none => IO.FS.readFile sourceFile
  let mut paths := #[project / "Example.lean"]
  let mut sourcePath := project / "Example.lean"
  let output := ctx.scratch / s!"{rule}-{phase}.json"
  requireChecks [⟨"fresh corpus output", !(← output.pathExists)⟩]
  let kind ← if case == "Fixed" then pure "positive" else string spec "kind"
  let mode ← string spec "invocation"
  if mode == "file" && rule != "SL2001" then
    sourcePath := project / "Fixture.lean"
    paths := paths.push sourcePath
  let mut binary := root / ".lake/build/bin/axiomGate"
  let mut command := #["--project", project.toString]
  if mode == "documentation" then
    IO.FS.createDir (project / "docs")
    sourcePath := project / "docs/Example.md"
    IO.FS.writeFile sourcePath displayed
    paths := paths.push sourcePath
    binary := root / ".lake/build/bin/ruleExamples"
    command := #["--documentation", project.toString, (project / "docs").toString, output.toString]
  else
    IO.FS.writeFile sourcePath displayed
    if rule == "SL2001" then
      let request ← readJson (folder / s!"{case}.json")
      if (request.getObjValAs? Bool "unavailableWorkspace").toOption == some true then
        let config := project / "lakefile.lean"
        IO.FS.writeFile config ((← IO.FS.readFile config) ++ "\nrequire unavailable from \"./missing\"\n")
        addPackage project "unavailable" "./missing" "lakefile.lean"
      command := command ++ #["--file", (project / (← string request "source")).toString, "--claim", "kernel-only", "--execution", "checked"]
    else if rule == "SL2002" then
      IO.FS.writeBinFile (project / "foundation_manifest.json") (← IO.FS.readBinFile (folder / s!"{case}.json"))
    else if rule == "SL1003" then
      let vendor := project / "vendor"
      IO.FS.createDir vendor
      IO.FS.writeBinFile (vendor / "Dependency.lean") (← IO.FS.readBinFile (folder / s!"{case}.lean"))
      IO.FS.writeBinFile (vendor / "lean-toolchain") (← IO.FS.readBinFile (root / "lean-toolchain"))
      IO.FS.writeFile (vendor / "lakefile.toml") "name = \"example_dependency\"\n[[lean_lib]]\nname = \"Dependency\"\n"
      let config := project / "lakefile.lean"
      IO.FS.writeFile config ((← IO.FS.readFile config) ++ s!"\nrequire example_dependency from {toJson vendor.toString |>.compress}\n")
      addPackage project "example_dependency" vendor "lakefile.toml"
      paths := paths ++ #[vendor / "Dependency.lean", vendor / "lakefile.toml", vendor / "lean-toolchain"]
    else if mode == "file" then
      let claim ← match producerClaim with
        | some claim => pure claim
        | none => optionalText spec "claim" "kernel-only"
      command := command ++ #["--file", sourcePath.toString, "--claim", claim, "--execution", "checked"]
    if rule == "SL1002" && case == "Violation" then
      binary := root / ".lake/build/bin/ruleExamples"
      command := #["--policy-negative", project.toString, sourcePath.toString, output.toString]
    else command := command ++ #["--json-out", output.toString]
  let configPaths := #["foundation_manifest.json", "lakefile.lean", "lakefile.toml", "lean-toolchain", "lake-manifest.json", ".lake/package-overrides.json"].map (fun (name : String) => project / name)
  let configurationBefore ← configuration configPaths
  let frozen := Json.mkObj [("uri", .str project.toString), ("source", .str configurationBefore.compress)]
  let mut before := Json.mkObj [("sources", ← snapshot paths), ("configuration", frozen)]
  let requestKind := if rule == "SL1002" && case == "Violation" then "policyNegative"
    else if mode == "documentation" then "documentation" else if mode == "file" then "file" else "project"
  let requestedClaim ← optionalText spec "claim" "kernel-only"
  let request := Json.mkObj [
    ("kind", .str requestKind), ("project", .str project.toString),
    ("subject", .str (if #["file", "policyNegative"].contains requestKind then sourcePath.toString
      else if requestKind == "documentation" then (project / "docs").toString else project.toString)),
    ("claim", if requestKind == "file" then .str requestedClaim else .null),
    ("execution", if requestKind == "file" then .str "checked" else .null), ("configuration", configurationBefore)]
  let started ← IO.monoMsNow
  let execution ← run project binary.toString command cleanEnv
  let elapsed := (← IO.monoMsNow) - started
  requireChecks [⟨s!"{rule}/{phase}: missing terminal result\n{execution.stdout}{execution.stderr}", ← output.pathExists⟩]
  let observed ← readJson output
  let mut after := Json.mkObj [("sources", ← snapshot paths), ("configuration", Json.mkObj [
    ("uri", .str project.toString), ("source", .str (← configuration configPaths).compress)])]
  let mut replacements := [("$PROJECT", project.toString), ("$SOURCE", sourcePath.toString),
    ("$MISSING", (project / "Missing.lean").toString), ("$SOURCE_TEXT", ← IO.FS.readFile sourcePath),
    ("$DOCS", (project / "docs").toString)]
  if mode == "project" then
    let captured ← match field observed "sourceAccount" with
      | .ok value => IO.ofExcept value.getArr?
      | .error _ => pure #[]
    let account ← if captured.isEmpty then entries (← get observed "scope") "sources" else
      captured.mapM fun s => return Json.mkObj [("module", ← get s "moduleName"), ("path", ← get s "path"), ("source", ← get s "content")]
    let candidates ← account.filterM fun s => return (← get s "module") == nameJson "Example"
    let #[item] := candidates | throw <| IO.userError "project example source account mismatch"
    let originalSources ← entries before "sources"
    let some original := originalSources[0]? | throw <| IO.userError "missing frozen source"
    let actualSource ← string item "source"
    let actualPath ← string item "path"
    requireChecks [⟨"project source binding", actualSource == (← string original "source")⟩,
      ⟨"fresh project source belongs to owned copy", actualPath.startsWith ((project / "tmp").toString ++ "/")⟩]
    replacements := ("$SOURCE", actualPath) :: replacements.filter (·.1 != "$SOURCE")
    let sourceAlias := Json.mkObj [("uri", .str actualPath), ("source", .str actualSource)]
    before := before.setObjVal! "sources" (toJson (originalSources.push sourceAlias))
    after := after.setObjVal! "sources" (toJson ((← entries after "sources").push sourceAlias))
  if mode == "documentation" && case == "Violation" then
    if let .ok raw := field spec "snippet" then
      let values ← IO.ofExcept raw.getArr?
      let #[start, stop, origin] := values | throw <| IO.userError "invalid snippet range"
      let start ← IO.ofExcept start.getNat?
      let stop ← IO.ofExcept stop.getNat?
      let bytes ← IO.FS.readBinFile sourcePath
      requireChecks [⟨"snippet byte bounds", start ≤ stop && stop ≤ bytes.size⟩]
      let some snippet := String.fromUTF8? (bytes.extract start stop) | throw <| IO.userError "invalid UTF-8 snippet"
      let uri := (project / "docs").toString ++ "/" ++ (← IO.ofExcept origin.getStr?) ++ "#lean-snippet"
      replacements := [("$SNIPPET_URI", uri), ("$SNIPPET_TEXT", snippet)] ++ replacements
      let sourceAlias := Json.mkObj [("uri", .str uri), ("source", .str snippet)]
      before := before.setObjVal! "sources" (toJson ((← entries before "sources").push sourceAlias))
      after := after.setObjVal! "sources" (toJson ((← entries after "sources").push sourceAlias))
  let expected ← if case == "Fixed" then pure (toJson (#[] : Array Json)) else do
    let template ← get spec "diagnostics"
    pure (← IO.ofExcept (StrictLeanQualification.Template.instantiate
      (StrictLeanQualification.Template.replace replacements) 64 template)).val
  return Json.mkObj [
    ("rule", .str rule), ("phase", .str phase), ("kind", .str kind), ("mode", ← get spec "mode"),
    ("sourcePath", .str s!"examples/rules/{rule}/{sourceName}"), ("source", .str displayed),
    ("command", toJson (#[binary.toString] ++ command)), ("exitCode", toJson execution.exitCode.toNat),
    ("before", before), ("after", after), ("request", request), ("expected", expected), ("result", observed),
    ("unresolvedPatterns", if case == "Fixed" then toJson (#[] : Array Json) else (field spec "unresolvedPatterns").toOption.getD (toJson (#[] : Array Json))),
    ("stdout", .str execution.stdout), ("stderr", .str execution.stderr), ("detectorMillis", toJson elapsed)]

private def admitRecord (ctx : Context) (record : Json) (refusal : Option String := none) : IO Unit := do
  let current := ctx.scratch / "current.json"
  writeJson current (Json.mkObj [("checkerBefore", ctx.checkerBefore), ("checkerAfter", ← snapshot ctx.checkerPaths), ("records", toJson #[record])])
  let checked ← run ctx.root (ctx.root / ".lake/build/bin/ruleExampleQualification").toString #["--record", current.toString] cleanEnv
  requireChecks [⟨s!"corpus record admission: {checked.stdout}{checked.stderr}", match refusal with
    | none => checked.exitCode == 0
    | some reason => checked.exitCode != 0 && (checked.stdout ++ checked.stderr).contains reason⟩]

/-- Full corpus or explicit scoped selection; all records and admission controls are
exported. No partial export is labelled a successfully qualified corpus. -/
def check (evidence : FilePath) (selection : Option (Array String)) : IO Unit := do
  let root ← rootDirectory
  let specs ← readJson (root / "examples/rules/corpus.json")
  let keys := (← IO.ofExcept specs.getObj?).toList.map Prod.fst |>.toArray
  let selected := selection.getD keys
  requireChecks [⟨"nonempty known unique selected rules", !selected.isEmpty && selected.all keys.contains && selected.toList.eraseDups.length == selected.size⟩]
  let inventory ← StrictLean.Checker.Lake.surfaceInventory root
  let modulePaths := inventory.moduleSources.map Prod.snd
  let corpusPaths ← (← (root / "examples/rules").walkDir).filterM fun path => return !(← path.isDir)
  let checkerPaths := (modulePaths ++ #[root / "lean-toolchain", root / "lakefile.lean", root / "lake-manifest.json"] ++ corpusPaths).toList.eraseDups.toArray
  let checkerBefore ← snapshot checkerPaths
  if let some parent := evidence.parent then IO.FS.createDirAll parent
  if ← evidence.pathExists then IO.FS.removeFile evidence
  withScratch root "rule-examples" fun scratch => do
    let ctx : Context := ⟨root, scratch, specs, checkerPaths, checkerBefore⟩
    let mut records : Array Json := #[]
    let jobs := selected.flatMap fun rule => #["Fixed", "Violation", "Restored"].map (rule, ·)
    -- Two disjoint producers, consumed/refilled in fixed order as upstream. Drain
    -- every launched task before scratch cleanup, including on admission failure.
    let pending ← IO.mkRef (#[] : Array (Task (Except IO.Error Json)))
    for (rule, phase) in jobs.extract 0 2 do
      let task ← IO.asTask (produce ctx rule phase)
      pending.modify (·.push task)
    try
      for index in [:jobs.size] do
        let task := (← pending.get)[index]!
        let record ← match (← IO.wait task) with
          | .ok value => pure value
          | .error error => throw error
        records := records.push record
        writeJson evidence (Json.mkObj [("schemaVersion", toJson (1 : Nat)), ("completeCorpus", .bool selection.isNone),
          ("outcome", .str "INCOMPLETE"), ("selected", toJson selected), ("checkerBefore", checkerBefore),
          ("checkerAfter", ← snapshot checkerPaths), ("records", toJson records)])
        admitRecord ctx record
        IO.println s!"{← string record "rule"}/{← string record "phase"}: qualified {← string record "kind"}"
        (← IO.getStdout).flush
        if let some (rule, phase) := jobs[index + 2]? then
          let task ← IO.asTask (produce ctx rule phase)
          pending.modify (·.push task)
    finally
      for task in ← pending.get do
        let _ ← IO.wait task
        pure ()
    let mut controls := #[]
    if selected.contains "SL1005" then
      let wrong ← produce ctx "SL1005" "WrongClaim" (some (← IO.FS.readFile (root / "examples/rules/SL1005/Violation.lean"))) (some "standard-logical")
      requireChecks [⟨"Standard-Logical producer control completes", (← get wrong "exitCode") == toJson (0 : Nat) && (← string (← get wrong "result") "status") == "completed"⟩]
      admitRecord ctx wrong (some "producer request differs from frozen example request")
      let restored ← produce ctx "SL1005" "ClaimRestored"
      admitRecord ctx restored
      controls := controls ++ #[wrong, restored]
    if selected.contains "SL4004" then
      let teaching := "<!-- lean-trusted-compiler -->\n```lean\n" ++ (← IO.FS.readFile (root / "examples/rules/SL1004/Violation.lean")) ++ "```\n"
      let negative := "<!-- lean-fail: Unknown identifier -->\n```lean\n#check missingExample\n```\n"
      for (phase, source) in #[("TrustedControl", teaching), ("NegativeControl", negative)] do
        let record ← produce ctx "SL4004" phase (some source)
        requireChecks [⟨"nonpositive documentation classifies", (← get record "exitCode") == toJson (0 : Nat) && (← string (← get record "result") "status") == "classified"⟩]
        admitRecord ctx record (some "documentation correction requires completed positive fences")
        controls := controls.push record
      let restored ← produce ctx "SL4004" "ClassificationRestored"
      admitRecord ctx restored
      controls := controls.push restored
    for record in records do
      if (← string record "kind") == "diagnosticDemonstration" then
        let relabelled := record.setObjVal! "rule" (.str "SL1001")
        admitRecord ctx relabelled (some "diagnostic demonstration mismatch")
        admitRecord ctx record
        controls := controls.push relabelled
      if (← string record "phase") == "Violation" && #["SL2003", "SL2005"].contains (← string record "rule") then
        let fixed ← IO.FS.readFile (root / "examples/rules" / (← string record "rule") / "Fixed.lean")
        let original ← string record "source"
        let mut stale := record.setObjVal! "source" (.str fixed)
        for side in #["before", "after"] do
          let bound ← get stale side
          let sources ← (← entries bound "sources").mapM fun s => do
            return if (← string s "source") == original then s.setObjVal! "source" (.str fixed) else s
          stale := stale.setObjVal! side (bound.setObjVal! "sources" (toJson sources))
        admitRecord ctx stale (some "missing or mismatched producer source account")
        admitRecord ctx record
        controls := controls.push stale
        let result ← get record "result"
        let result := Json.mkObj ((← IO.ofExcept result.getObj?).toList.filter (·.1 != "sourceAccount"))
        let missing := record.setObjVal! "result" result
        admitRecord ctx missing (some "missing result source account")
        admitRecord ctx record
        controls := controls.push missing
    let exported ← readJson evidence
    writeJson evidence ((exported.setObjVal! "admissionControls" (toJson controls)).setObjVal! "checkerAfter" (← snapshot checkerPaths))
  let checked ← run root (root / ".lake/build/bin/ruleExampleQualification").toString #[(← IO.FS.realPath evidence).toString] cleanEnv
  requireChecks [⟨s!"corpus admission: {checked.stdout}{checked.stderr}", checked.exitCode == 0⟩]
  writeJson evidence ((← readJson evidence).setObjVal! "outcome" (.str "PASS"))
  IO.println s!"rule example campaign: PASS ({selected.size} selected rules; diagnostic evidence only)"
end StrictLean.Qualification.RuleExamples
