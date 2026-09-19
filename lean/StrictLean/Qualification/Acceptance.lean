import StrictLean.Qualification.InputInventory

/-! Native retention of raw-worker acceptance and documentation-dependency controls.
The coordinator is the actual checker; only a copied native child proxy mutates
requests or completed packets. IO/process observations remain trusted boundaries. -/
namespace StrictLean.Qualification.Acceptance
open Lean System DependencySnapshot InputInventory

private def get (j : Json) (key : String) : IO Json := IO.ofExcept (j.getObjVal? key)
private def array (j : Json) (key : String) : IO (Array Json) := IO.ofExcept (j.getObjValAs? (Array Json) key)
private def string (j : Json) (key : String) : IO String := IO.ofExcept (j.getObjValAs? String key)
private def first (xs : Array Json) : IO Json := do
  let some x := xs[0]? | throw <| IO.userError "mutation requires a nonempty array"
  return x

/-- Test-only native proxy; invoked before the dispatcher's outer deadline wrapper. -/
def worker (args : List String) : IO UInt32 := do
  -- The foreground timer below owns this single child, which cannot spawn a
  -- descendant. Both inherit the public qualification's outer process group.
  if args == ["--timeout-sleeper"] then
    IO.println "qualification: surface worker waiting"
    (← IO.getStdout).flush
    IO.sleep 60000
    return 0
  let mode := (← IO.getEnv "STRICT_LEAN_PACKET_FAULT").getD ""
  let surface := args.head? == some "--surface-worker"
  let compilation := args.head? == some "--compile-batch-worker"
  let trace ← IO.getEnv "STRICT_LEAN_SOURCE_TRACE"
  let mut original := Json.null
  let mut request := Json.null
  if surface && trace.isSome then
    let some path := args[1]? | throw <| IO.userError "missing surface request"
    request ← readJson ⟨path⟩
    original := request
    let bindings ← array request "sourceBindings"
    let bindings ← if mode == "source-shortened" then pure bindings.pop
      else if mode == "source-reordered" then pure bindings.reverse
      else if mode == "source-extra" then do
        let some last := bindings.back? | throw <| IO.userError "mutation requires source bindings"
        pure (bindings.push last)
      else pure bindings
    request := request.setObjVal! "sourceBindings" (toJson bindings)
    writeJson ⟨path⟩ request
  if surface && mode == "process" then return 17
  if surface && mode == "timeout" then
    let timer ← timeoutCommand
    let result ← IO.Process.output {
      cmd := timer, args := #["--foreground", "--signal=KILL", "8s", (← IO.appPath).toString, "--timeout-sleeper"] }
    IO.print result.stdout
    (← IO.getStderr).putStr result.stderr
    let path : FilePath := ← requiredEnv "STRICT_LEAN_TIMEOUT_RECORD"
    writeJson path (Json.mkObj [("workerExitCode", toJson result.exitCode.toNat),
      ("marker", toJson (result.stdout.contains "qualification: surface worker waiting"))])
    return result.exitCode
  let some parent := (← IO.appPath).parent | throw <| IO.userError "missing proxy directory"
  let child ← IO.Process.spawn {
    cmd := (parent / "axiomGate-real").toString, args := args.toArray,
    stdin := .inherit, stdout := .inherit, stderr := .inherit }
  let code ← child.wait
  if surface then
    if let some trace := trace then
      let result : FilePath := ← string request "resultOut"
      let childResult ← if ← result.pathExists then readJson result else pure Json.null
      writeJson ⟨trace⟩ (Json.mkObj [("original", original), ("sent", request),
        ("childResult", childResult)])
  if code != 0 then return code
  if surface && #["missing", "duplicate", "misindexed", "stale", "unknown", "conflict", "build"].contains mode then
    let some requestPath := args[1]? | throw <| IO.userError "missing request"
    let surfaceRequest ← readJson ⟨requestPath⟩
    let output : FilePath := ← string surfaceRequest "output"
    if mode == "missing" then IO.FS.removeFile output; return 0
    let mut packet ← readJson output
    let mut payload ← get packet "payload"
    if mode == "stale" then
      let bound ← get packet "request"
      packet := packet.setObjVal! "request" (bound.setObjVal! "reportRoot" (toJson ((← string bound "reportRoot") ++ "-stale")))
    else if mode == "build" then
      payload := payload.setObjVal! "build" ((← get payload "build").setObjVal! "exitCode" (toJson (17 : Nat)))
    else
      let mut inspections ← array payload "inspections"
      let mut inspection ← first inspections
      if mode == "duplicate" then inspections := inspections.push inspection
      else
        if mode == "misindexed" then inspection := inspection.setObjVal! "expectedModules" (toJson (#[] : Array Json))
        else
          let mut report ← get inspection "report"
          if mode == "unknown" then
            let declarations ← array report "declarations"
            report := report.setObjVal! "declarations" (toJson (declarations.set! 0
              ((← first declarations).setObjVal! "kind" (toJson "unknown-kind"))))
          else
            let bindings ← array report "sourceBindings"
            let binding ← first bindings
            report := report.setObjVal! "sourceBindings" (toJson (bindings.set! 0
              (binding.setObjVal! "content" (toJson ((← string binding "content") ++ "\n-- conflicting observation\n")))))
          inspection := inspection.setObjVal! "report" report
        inspections := inspections.set! 0 inspection
      payload := payload.setObjVal! "inspections" (toJson inspections)
    writeJson output (packet.setObjVal! "payload" payload)
  if compilation && #["fence-missing", "fence-duplicate", "fence-misindexed"].contains mode then
    let some path := args[2]? | throw <| IO.userError "missing compilation output"
    let packet ← readJson ⟨path⟩
    let mut payload ← array packet "payload"
    if mode == "fence-missing" then payload := payload.pop
    else if mode == "fence-duplicate" then payload := payload.push (← first payload)
    else
      let entry ← IO.ofExcept ((← first payload).getArr?)
      payload := payload.set! 0 (toJson (entry.set! 0 (toJson (999999 : Nat))))
    writeJson ⟨path⟩ (packet.setObjVal! "payload" (toJson payload))
  return 0

private def faults : String → Array (String × String)
  | "surface" => #[("missing", "No such file"), ("duplicate", "omitted or added"),
      ("misindexed", "indexed to another request"), ("stale", "request binding mismatch")]
  | "evidence" => #[("unknown", "unknown DeclarationKind"), ("conflict", "producer-source"), ("build", "acceptance refused")]
  | "fences" => #[("fence-missing", "missing required key"), ("fence-duplicate", "duplicateResult"), ("fence-misindexed", "unknownKey")]
  | "process" => #[("process", ""), ("timeout", "qualification: surface worker waiting")]
  | "sources" => #[("source-shortened", "surface worker source inventory mismatch"),
      ("source-reordered", "surface worker source inventory mismatch"), ("source-extra", "surface worker source inventory mismatch")]
  | _ => #[]

private def save (path : FilePath) (receipt : Json) : IO Unit := do
  let suffix ← IO.getRandomBytes 12
  let temporary := FilePath.mk (path.toString ++ "." ++ suffix.foldl (fun s b => s ++ s!"{b.toNat}-") "")
  try
    writeJson temporary receipt
    IO.FS.rename temporary path
  finally
    removeFile temporary

private def qualify (group : String) (evidence : FilePath) (receipt : IO.Ref Json) : IO Unit := do
  let root ← rootDirectory
  let update (key : String) (value : Json) := do
    receipt.modify (·.setObjVal! key value)
    save evidence (← receipt.get)
  let executable := root / ".lake/build/bin/axiomGate"
  let head ← run root "git" #["rev-parse", "HEAD"]
  success head
  update "inputs" (Json.mkObj [("head", toJson head.stdout.trimAscii.toString)])
  let digest ← run root "shasum" #["-a", "256", executable.toString]
  success digest
  update "inputs" (Json.mkObj [("head", toJson head.stdout.trimAscii.toString),
    ("binarySha256", toJson (digest.stdout.splitOn " ").head!)])
  withScratch root "acceptance-controls" fun scratch => do
    let project := scratch / "project"
    IO.FS.createDirAll (project / "docs")
    prepareProject root project "acceptance_control" "standard-logical" "Exact accepted-result transport controls."
    manifest project "standard-logical"
    IO.FS.writeFile (project / "Example.lean") "import StrictLean.Contract\n/-! Public acceptance transport control. -/\ndef value : Nat := 7\n"
    IO.FS.writeFile (project / "docs/control.md")
      "```lean\ntheorem documented : True := True.intro\n```\n\n<!-- lean-fail: Type mismatch -->\n```lean\nexample : False := True.intro\n```\n"
    if group == "sources" then
      let lakefile := project / "lakefile.lean"
      IO.FS.writeFile lakefile ((← IO.FS.readFile lakefile).replace "lean_lib Example\n"
        "lean_lib Example where\n  globs := #[.one `Example, .one `Extra]\n")
      IO.FS.writeFile (project / "Extra.lean") "import StrictLean.Contract\n/-! Second independently discovered source. -/\ndef extraValue : Nat := 11\n"
    let bin := scratch / "tool/bin"
    IO.FS.createDirAll bin
    IO.FS.createDirAll (scratch / "tool/lib")
    success (← run root "ln" #["-s", (root / ".lake/build/lib/lean").toString, (scratch / "tool/lib/lean").toString])
    copyExecutable executable (bin / "axiomGate-real")
    copyExecutable (← IO.appPath) (bin / "axiomGate")
    let mut sources : List (String × Json) := []
    for name in #["lean-toolchain", "lakefile.lean", "lake-manifest.json", "foundation_manifest.json", "Example.lean", "Extra.lean", "docs/control.md"] do
      if ← (project / name).pathExists then sources := sources ++ [(name, toJson (← IO.FS.readFile (project / name)))]
    update "sources" (Json.mkObj sources)
    let mut records : Array Json := #[]
    let mut cases := #[("positive", "", "")]
    for (fault, reason) in faults group do
      cases := cases.push ("mutation", fault, reason) |>.push ("restored", "", "")
    for (phase, fault, reason) in cases do
      let output := scratch / s!"result-{records.size}.json"
      let trace := scratch / s!"source-trace-{records.size}.json"
      let timeoutRecord := scratch / s!"timeout-{records.size}.json"
      let args := #["--project", project.toString, "--with-docs", "--json-out", output.toString]
      update "activeCase" (Json.mkObj [("phase", toJson phase), ("fault", toJson fault),
        ("command", toJson (#[ (bin / "axiomGate").toString ] ++ args))])
      let env := cleanEnv ++ #[("STRICT_LEAN_QUALIFICATION_WRAPPER", some "acceptance"),
        ("STRICT_LEAN_PACKET_FAULT", some fault),
        ("STRICT_LEAN_TIMEOUT_RECORD", some timeoutRecord.toString),
        ("STRICT_LEAN_SOURCE_TRACE", if group == "sources" then some trace.toString else none)]
      let start ← IO.monoMsNow
      -- Normal cases inherit only the public 420-second deadline. The timeout
      -- mutation is a worker timeout, not cancellation of the whole coordinator.
      let result ← IO.Process.output {
        cmd := (bin / "axiomGate").toString, args,
        cwd := some project, env }
      let elapsed := (← IO.monoMsNow) - start
      let value ← if ← output.pathExists then readJson output else pure Json.null
      let sourceTrace ← if ← trace.pathExists then readJson trace else pure Json.null
      let log := result.stdout ++ result.stderr
      let timeoutObservation ← if ← timeoutRecord.pathExists then readJson timeoutRecord else pure Json.null
      let timedOut := (timeoutObservation.getObjValAs? Nat "workerExitCode").toOption == some 137 &&
        (timeoutObservation.getObjValAs? Bool "marker").toOption == some true
      let status := (value.getObjValAs? String "status").toOption
      let hasAcceptance := (value.getObjVal? "acceptance").toOption.isSome
      let hasDocs := (value.getObjVal? "documentationAcceptance").toOption.isSome
      let mut passed := if fault.isEmpty then !timedOut && result.exitCode == 0 && status == some "completed" && hasAcceptance && hasDocs
        else result.exitCode != 0 && status == some "incomplete" && !hasAcceptance && !hasDocs &&
          (fault != "timeout" || timedOut) && (reason.isEmpty || log.toLower.contains reason.toLower)
      if group == "sources" then
        let retained ← get sourceTrace "original"
        let expected ← array retained "sourceBindings"
        let child ← get sourceTrace "childResult"
        passed := passed && expected.size == 2 && (← get child "sourceAccount") == toJson expected
      -- Retain the original emitted bytes once. Rewriting all previous raw packets
      -- in each receipt update adds no evidence and scales quadratically.
      let resultEvidence := evidence.addExtension s!"result-{records.size}.json"
      let traceEvidence := evidence.addExtension s!"source-trace-{records.size}.json"
      let resultFile ← if ← output.pathExists then do
        IO.FS.rename output resultEvidence
        pure (toJson resultEvidence.toString)
        else pure Json.null
      let traceFile ← if ← trace.pathExists then do
        IO.FS.rename trace traceEvidence
        pure (toJson traceEvidence.toString)
        else pure Json.null
      let record := Json.mkObj [("phase", toJson phase), ("fault", toJson fault), ("command", toJson args),
        ("milliseconds", toJson elapsed), ("exitCode", toJson result.exitCode.toNat), ("timeout", toJson timedOut),
        ("expectedReason", toJson reason), ("status", toJson status), ("pass", toJson passed),
        ("log", toJson log), ("resultFile", resultFile), ("sourceTraceFile", traceFile),
        ("timeoutObservation", timeoutObservation)]
      records := records.push record
      update "records" (toJson records)
      update "activeCase" Json.null
      requireChecks [⟨s!"acceptance {phase}/{fault}: {log}", passed⟩]
      IO.println s!"acceptance transport {phase}/{fault}: PASS"

/-- Invalidate old evidence before setup. SIGKILL leaves a current incomplete receipt;
ordinary exceptions retain failure and the active case. Filesystem atomicity is trusted. -/
def check (group : String) (evidence : FilePath) : IO Unit := do
  if let some parent := evidence.parent then IO.FS.createDirAll parent
  let attempt ← IO.getRandomBytes 16
  let receipt ← IO.mkRef (Json.mkObj [("attemptId", toJson (attempt.toList.map UInt8.toNat)),
    ("status", toJson "incomplete"), ("group", toJson group), ("inputs", Json.mkObj []),
    ("records", toJson (#[] : Array Json))])
  save evidence (← receipt.get)
  try
    requireChecks [⟨"known transport group", !(faults group).isEmpty⟩]
    qualify group evidence receipt
  catch error =>
    receipt.modify (fun r => (r.setObjVal! "status" (toJson "failed")).setObjVal! "error" (toJson error.toString))
    save evidence (← receipt.get)
    throw error
  receipt.modify (·.setObjVal! "status" (toJson "completed"))
  save evidence (← receipt.get)

def documentationDependencies : IO Unit := do
  let root ← rootDirectory
  withScratch root "documentation-dependency" fun scratch => do
    let dependency := scratch / "dependency"
    IO.FS.createDirAll dependency
    IO.FS.writeFile (dependency / "lakefile.toml") "name = \"dep\"\n[[lean_lib]]\nname = \"Dep\"\n"
    toolchain root dependency
    let original := "namespace Dep\ndef n : Nat := 1\nend Dep\n"
    let changed := "namespace Dep\ndef n : Nat := 2\nend Dep\n"
    let dependencySource := dependency / "Dep.lean"
    IO.FS.writeFile dependencySource original
    let project := scratch / "project"
    IO.FS.createDirAll (project / "docs")
    toolchain root project
    IO.FS.writeFile (project / "lakefile.toml")
      "name = \"documentation_dependency\"\n[[require]]\nname = \"dep\"\npath = \"../dependency\"\n[[lean_lib]]\nname = \"Example\"\n"
    manifest project "kernel-only"
    let source := "import Lean\nimport Dep\n/-! Documentation prerequisite. -/\ntheorem value : Dep.n = 1 := rfl\n"
    IO.FS.writeFile (project / "Example.lean") source
    IO.FS.writeFile (project / "docs/control.md") "```lean\nimport Dep\nexample : Dep.n = 1 := rfl\n```\n"
    success (← run project "lake" #["update"] cleanEnv)
    for route in #["docFenceAudit", "ruleExamples"] do
      for phase in #["positive", "changed-during-build", "restored"] do
        if phase != "changed-during-build" then
          clearBuild project
          clearBuild dependency
        IO.FS.writeFile dependencySource original
        let bad := phase == "changed-during-build"
        let mutation := if bad then s!"run_cmd do\n  IO.FS.writeFile {toJson dependencySource.toString |>.compress} {toJson changed |>.compress}\n" else ""
        IO.FS.writeFile (project / "Example.lean") (source ++ mutation)
        let output := scratch / s!"{route}-{phase}.json"
        let args := if route == "docFenceAudit" then #["--project", project.toString, "--jobs", "1"]
          else #["--documentation", project.toString, (project / "docs").toString, output.toString]
        let result ← run project (root / ".lake/build/bin" / route).toString args cleanEnv
        if bad then
          requireChecks [⟨"dependency mutation occurred", (← IO.FS.readFile dependencySource) == changed⟩,
            ⟨"frozen dependency refused", result.exitCode != 0 && result.stdout.contains "dependency snapshot changed:" &&
              !result.stdout.contains "accepted "⟩]
          if ← output.pathExists then
            requireChecks [⟨"no acceptance", ((← readJson output).getObjVal? "acceptance").toOption.isNone⟩]
        else
          success result
          requireChecks [⟨"checked positive fence", result.stdout.contains "conforming-positive-pass=1/1"⟩]
          if route == "ruleExamples" then requireChecks [⟨"documentation accepted", accepted (← readJson output)⟩]
        IO.println s!"documentation dependency {route}/{phase}: PASS"
    let (result, packet) ← observeProject root project (scratch / "combined.json") #["--with-docs"]
    success result
    requireChecks [⟨"same-snapshot combined acceptance", accepted packet &&
      (packet.getObjVal? "documentationAcceptance").toOption.isSome⟩]
end StrictLean.Qualification.Acceptance
