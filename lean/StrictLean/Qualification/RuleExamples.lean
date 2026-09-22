import StrictLean.Qualification.Project
import StrictLean.Checker.Lake
import StrictLean.Checker.Snapshot
import StrictLean.Qualification.Slot
import StrictLeanQualification.Evidence
import StrictLeanQualification.Template
import StrictLean.Checker.RuleExampleCorpusProjection

/-! Source-owned corpus orchestration. Actual detector receipts are admitted by the
existing RuleExampleQualification executable and its proof-linked policy functions.
This adapter does not infer policy from source text. Filesystem/process authenticity
remains trusted. Independent phases use distinct root artifacts and at most five
producer jobs, each writing only its own writable slot. The consumer path —
admission, raw validation, terminal qualification — consumes captured data and the
real ROOT checkout and never dereferences a slot path. The consumer thread reuses
pure snapshot construction only at proved exact equality of fresh captures; no read
is ever skipped and producer tasks stay uncached. -/
namespace StrictLean.Qualification.RuleExamples
open Lean System StrictLeanQualification.Evidence

private def get (j : Json) (key : String) : IO Json := IO.ofExcept (field j key)
private def string (j : Json) (key : String) : IO String := IO.ofExcept (text j key)
private def entries (j : Json) (key : String) : IO (Array Json) := IO.ofExcept (array j key)
private def optionalText (j : Json) (key fallback : String) : IO String :=
  match field j key with
  | .error _ => pure fallback
  | .ok value => IO.ofExcept value.getStr?

/-- Producer-window environment: the scrub plus no-optional-write Git and a
disabled Lake artifact cache (fail-closed), so producer children take no shared
optional locks and restore no shared cache artifacts. -/
def corpusEnv : Array (String × Option String) :=
  cleanEnv ++ #[("GIT_OPTIONAL_LOCKS", some "0"), ("LAKE_CACHE_DIR", some "")]

/-- Derived slot nonoverlap at width five: any five consecutive job indices
map to pairwise distinct slots under `index % 5`, so concurrent producers never
share a slot (a slot is reassigned only after its prior task returned). -/
theorem slots_distinct (j : Nat) :
    ∀ (a b : Nat), 1 ≤ a → a < b → b ≤ 5 → (j + a) % 5 ≠ (j + b) % 5 := by
  intro a b ha hab hb
  omega

/-- Pure snapshot entry construction; the exact `Json.mkObj` request shape. -/
def snapshotEntry (uri source : String) : Json :=
  Json.mkObj [("uri", .str uri), ("source", .str source)]

/-- Pure request-snapshot construction from exact captured path/source pairs. -/
def snapshotOf (captured : Array (String × String)) : Json :=
  toJson (captured.map fun (uri, source) => snapshotEntry uri source)

/-- Fresh exact capture of every requested path. No read is ever skipped. -/
def capture (paths : Array FilePath) : IO (Array (String × String)) :=
  paths.mapM fun path => do pure (path.toString, ← IO.FS.readFile path)

/-- Constructed-value cache over exact captured sources. The `sound` field keeps
the invariant `value = snapshotOf captured` by type. -/
structure SnapshotCache where
  captured : Array (String × String)
  value : Json
  sound : value = snapshotOf captured

/-- The empty cache: the construction for no captured sources. -/
def SnapshotCache.empty : SnapshotCache := ⟨#[], snapshotOf #[], rfl⟩

/-- Pure reuse decision. At proved exact equality of the fresh captures it
returns the cached construction; otherwise it constructs from the fresh
captures. In both cases the first component is exactly `snapshotOf fresh`. -/
def decideSnapshot (cache : SnapshotCache) (fresh : Array (String × String)) :
    Json × SnapshotCache :=
  dite (fresh = cache.captured) (fun _ => (cache.value, cache))
    (fun _ => (snapshotOf fresh, ⟨fresh, snapshotOf fresh, rfl⟩))

/-- Execution-linked equivalence: the value returned by the executed
`decideSnapshot` is exactly the uncached construction `snapshotOf fresh` over the
same fresh captures, so reuse at equal bytes changes no result. -/
theorem decideSnapshot_value (cache : SnapshotCache) (fresh : Array (String × String)) :
    (decideSnapshot cache fresh).1 = snapshotOf fresh :=
  if hc : fresh = cache.captured then by
    unfold decideSnapshot
    rw [dite_eq_left hc, hc]
    exact cache.sound
  else by
    unfold decideSnapshot
    rw [dite_eq_right hc]

/-- Exact request-snapshot value from fresh reads of every path. -/
def snapshot (paths : Array FilePath) : IO Json :=
  return snapshotOf (← capture paths)

/-- Fresh reads every path (mandatory), then constructs through the proved
`decideSnapshot`. Only the pure construction of an equal value is reused, and
only at proved exact equality of the fresh captures. Consumer-thread only:
concurrent producers use uncached `snapshot`. -/
def snapshotCached (cache : IO.Ref SnapshotCache) (paths : Array FilePath) : IO Json := do
  let fresh ← capture paths
  let (value, next) := decideSnapshot (← cache.get) fresh
  cache.set next
  return value

private def configuration (paths : Array FilePath) : IO Json := do
  return toJson (← paths.mapM fun path => do
    let value ← if (← path.pathExists) && !(← path.isDir) then pure (some (← IO.FS.readFile path)) else pure none
    pure (path.toString, value))

private def save (path : FilePath) (value : Json) : IO Unit := do
  let temporary := FilePath.mk (path.toString ++ ".pending")
  IO.FS.writeFile temporary (value.compress ++ "\n")
  IO.FS.rename temporary path

/-- Invalidate the previous verdict before any campaign setup or timer acquisition. -/
def beginAttempt (evidence : FilePath) (attempt : String) : IO Unit := do
  if let some parent := evidence.parent then IO.FS.createDirAll parent
  save evidence (Json.mkObj [("outcome", .str "INCOMPLETE"), ("attempt", .str attempt),
    ("rawDirectory", .str (evidence.toString ++ ".raw/" ++ attempt))])

private def digest (root path : FilePath) : IO Json := do
  let result ← run root "shasum" #["-a", "256", path.toString]
  let value := (result.stdout.splitOn " ").head!
  requireChecks [⟨"raw observation digest", result.exitCode == 0 && value.length == 64 &&
    value.toList.all (fun c => c.isDigit || ('a' ≤ c && c ≤ 'f'))⟩]
  return Json.mkObj [("sha256", .str value), ("bytes", toJson (← path.metadata).byteSize)]

/-- Drain textual process streams one line at a time, retaining line terminators and
the final EOF-terminated line. A kill preserves completed lines already read; a pending
unterminated line can remain buffered. Only terminal observations claim complete streams. -/
private partial def drain (source target : IO.FS.Handle) : IO Unit := do
  let line ← source.getLine
  unless line.isEmpty do
    target.putStr line
    target.flush
    drain source target

/-- Observe one detector run. The returned observation is taken only after the
direct child is waited and both stream drains reach EOF: direct-child reaping
and stream-holder closure at producer return. Universal detached-grandchild
termination is not claimed; the joined-worker discipline is the stated basis
(`Common.runProcess`, `runTypedWorker`, `observe` and `run` all wait their
children). -/
private def observe (project binary stdout stderr : FilePath) (command : Array String)
    (env : Array (String × Option String) := corpusEnv) : IO IO.Process.Output := do
  let out ← IO.FS.Handle.mk stdout .write
  let err ← IO.FS.Handle.mk stderr .write
  let child ← IO.Process.spawn {
    cmd := binary.toString, args := command, cwd := some project,
    env, stdin := .null, stdout := .piped, stderr := .piped }
  let outTask ← IO.asTask (drain child.stdout out) Task.Priority.dedicated
  let errTask ← IO.asTask (drain child.stderr err) Task.Priority.dedicated
  -- Hold every managed outcome until both launched drains have joined. A failed
  -- wait is not successful reaping; it still owes the stream joins before
  -- unwinding. Preserve the original error order and exact error values.
  let waited : Except IO.Error UInt32 ← try
    pure (.ok (← child.wait))
  catch error => pure (.error error)
  let drainedOut ← IO.wait outTask
  let drainedErr ← IO.wait errTask
  let code ← IO.ofExcept waited
  IO.ofExcept drainedOut
  IO.ofExcept drainedErr
  return ⟨code, ← IO.FS.readFile stdout, ← IO.FS.readFile stderr⟩

private def addPackage (project : FilePath) (name : String) (dir : FilePath) (config : String) : IO Unit := do
  let path := project / "lake-manifest.json"
  let lock ← readJson path
  let packages ← entries lock "packages"
  writeJson path (lock.setObjVal! "packages" (toJson (packages.push (Json.mkObj [
    ("type", .str "path"), ("name", .str name), ("dir", .str dir.toString),
    ("manifestFile", .str "lake-manifest.json"), ("inherited", .bool false), ("configFile", .str config)]))))

/-- Consumer context: carries no slot paths. Admission, raw validation and
terminal qualification consume captured data and the real ROOT checkout only. -/
private structure Context where
  root : FilePath
  scratch : FilePath
  specs : Json
  checkerPaths : Array FilePath
  checkerBefore : Json
  attempt : String
  rawDirectory : FilePath
  cache : IO.Ref SnapshotCache

/-- Produce one record in the producer's own writable slot. Producer-only slot
writes; direct children are waited and stream holders closed before return
(`observe`/`run`; joined-worker discipline, no universal grandchild claim). -/
private def produce (ctx : Context) (slot : Slot.ProducerSlot) (rule phase : String)
    (sourceText : Option String := none) (producerClaim : Option String := none) : IO Json := do
  let root := ctx.root
  let spec ← get ctx.specs rule
  let case := if phase == "Violation" then "Violation" else "Fixed"
  let project := ctx.scratch / s!"{rule}-{phase}"
  IO.FS.createDir project
  Slot.prepareSlotProject slot project "rule_examples" "kernel-only" "The fixture's exact mathematical claim and scope."
  IO.FS.writeFile (project / "Example.lean") "/-! The true proposition. -/\ntheorem baseline : True := True.intro\n"
  let folder := root / "examples/rules" / rule
  let sourceName := (← optionalText spec "source" "{case}.lean").replace "{case}" case
  let sourceFile := folder / sourceName
  let displayed ← match sourceText with
    | some text => pure text
    | none => IO.FS.readFile sourceFile
  let mut paths := #[project / "Example.lean"]
  let mut sourcePath := project / "Example.lean"
  let raw := ctx.rawDirectory / rule / phase
  IO.FS.createDirAll raw
  let output := raw / "result.json"
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
  let registration := Json.mkObj [
    ("attempt", .str ctx.attempt), ("rule", .str rule), ("phase", .str phase),
    ("resultPath", .str output.toString), ("stdoutPath", .str (raw / "stdout").toString),
    ("stderrPath", .str (raw / "stderr").toString),
    ("command", toJson (#[binary.toString] ++ command)), ("cwd", .str project.toString),
    ("environment", toJson corpusEnv), ("request", request), ("before", before)]
  save (raw / "registered.json") registration
  let started ← IO.monoMsNow
  let execution ← observe project binary (raw / "stdout") (raw / "stderr") command
  let elapsed := (← IO.monoMsNow) - started
  IO.println s!"driver span: process wait: {elapsed}ms"
  let loggedMs := (execution.stdout.splitOn "\n").foldl (fun acc line =>
    if line.endsWith "ms (finished)" then
      acc + ((((line.splitOn ": ").getLast!).splitOn "ms").head!).toNat?.getD 0
    else acc) 0
  IO.println s!"driver span: detector logged-phase total: {loggedMs}ms (child elapsed {elapsed}ms)"
  let terminal := Json.mkObj [("registration", registration), ("exitCode", toJson execution.exitCode.toNat),
    ("stdout", .str execution.stdout), ("stderr", .str execution.stderr), ("detectorMillis", toJson elapsed)]
  save (raw / "terminal.json") terminal
  let mut after := Json.mkObj [("sources", ← snapshot paths), ("configuration", Json.mkObj [
    ("uri", .str project.toString), ("source", .str (← configuration configPaths).compress)])]
  let terminal := terminal.setObjVal! "after" after
  save (raw / "terminal.json") terminal
  requireChecks [⟨s!"{rule}/{phase}: missing terminal result\n{execution.stdout}{execution.stderr}", ← output.pathExists⟩,
    ⟨s!"{rule}/{phase}: process failed/timed out", !#[124, 125, 126, 127, 137].contains execution.exitCode⟩]
  let evidenceStart ← IO.monoMsNow
  let rawObservation := terminal.setObjVal! "resultIdentity" (← digest root output)
  save (raw / "terminal.json") rawObservation
  let observed ← readJson output
  IO.println s!"driver span: raw digest/read/parse/projection: {(← IO.monoMsNow) - evidenceStart}ms"
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
  let record := StrictLean.Checker.RuleExampleProjection.record [
    ("rule", .str rule), ("phase", .str phase), ("kind", .str kind), ("mode", ← get spec "mode"),
    ("sourcePath", .str s!"examples/rules/{rule}/{sourceName}"), ("source", .str displayed),
    ("command", toJson (#[binary.toString] ++ command)), ("exitCode", toJson execution.exitCode.toNat),
    ("before", before), ("after", after), ("request", request), ("expected", expected),
    ("rawObservation", rawObservation),
    ("unresolvedPatterns", if case == "Fixed" then toJson (#[] : Array Json) else (field spec "unresolvedPatterns").toOption.getD (toJson (#[] : Array Json))),
    ("stdout", .str execution.stdout), ("stderr", .str execution.stderr), ("detectorMillis", toJson elapsed)]
    (StrictLean.Checker.RuleExampleProjection.resultView observed)
  let recordStart ← IO.monoMsNow
  save (raw / "record.json") record
  IO.println s!"driver span: save record transport: {(← IO.monoMsNow) - recordStart}ms"
  return record

private def admitRecord (ctx : Context) (record : Json) (refusal : Option String := none) : IO Unit := do
  if let .ok mutation := field record "mutation" then
    let registration ← get (← get record "rawObservation") "registration"
    let origin := ctx.rawDirectory / (← string registration "rule") / (← string registration "phase")
    let controls := origin / "controls"
    IO.FS.createDirAll controls
    let label ← IO.ofExcept mutation.getStr?
    save (controls / (label ++ ".json")) (Json.mkObj [
      ("origin", .str (origin / "record.json").toString), ("mutation", mutation), ("record", record)])
  let current := ctx.rawDirectory / "current.json"
  let currentStart ← IO.monoMsNow
  save current (Json.mkObj [("checkerBefore", ctx.checkerBefore), ("checkerAfter", ← snapshotCached ctx.cache ctx.checkerPaths), ("records", toJson #[record])])
  IO.println s!"driver span: save current transport: {(← IO.monoMsNow) - currentStart}ms"
  let admissionStart ← IO.monoMsNow
  let checked ← run ctx.root (ctx.root / ".lake/build/bin/ruleExampleQualification").toString #["--record", current.toString] cleanEnv
  IO.println s!"driver span: admission subprocess: {(← IO.monoMsNow) - admissionStart}ms"
  requireChecks [⟨s!"corpus record admission: {checked.stdout}{checked.stderr}", match refusal with
    | none => checked.exitCode == 0
    | some reason => checked.exitCode != 0 && (checked.stdout ++ checked.stderr).contains reason⟩]

private def validateRaw (ctx : Context) (record : Json) : IO Unit := do
  let observation ← get record "rawObservation"
  let registered ← get observation "registration"
  let rule ← string registered "rule"
  let phase ← string registered "phase"
  let mutation ← optionalText record "mutation" ""
  let raw := ctx.rawDirectory / rule / phase
  let output := raw / "result.json"
  let original ← readJson (raw / "record.json")
  requireChecks [⟨"raw observation attempt", (← string registered "attempt") == ctx.attempt⟩,
    ⟨"raw observation canonical record", mutation != "" || original == record⟩,
    ⟨"raw observation control origin", (← get original "rawObservation") == observation⟩,
    ⟨"raw observation original rule", (← string original "rule") == rule⟩,
    ⟨"raw observation original phase", (← string original "phase") == phase⟩,
    ⟨"raw observation original command", (← get original "command") == (← get registered "command")⟩,
    ⟨"raw observation original exit", (← get original "exitCode") == (← get observation "exitCode")⟩,
    ⟨"raw observation record rule", (← string record "rule") == rule ||
      (mutation == "demonstration relabel" && (← string record "rule") == "SL1001")⟩,
    ⟨"raw observation record phase", (← string record "phase") == phase⟩,
    ⟨"raw observation command", (← get record "command") == (← get registered "command")⟩,
    ⟨"raw observation request", (← get record "request") == (← get registered "request")⟩,
    ⟨"raw observation process exit", (← get record "exitCode") == (← get observation "exitCode")⟩,
    ⟨"raw observation process stdout", (← get record "stdout") == (← get observation "stdout")⟩,
    ⟨"raw observation process stderr", (← get record "stderr") == (← get observation "stderr")⟩,
    ⟨"raw observation rule", ((← IO.ofExcept ctx.specs.getObj?).toList.map Prod.fst).contains rule⟩,
    ⟨"raw observation phase", #["Fixed", "Violation", "Restored", "WrongClaim", "ClaimRestored",
      "TrustedControl", "NegativeControl", "ClassificationRestored"].contains phase⟩,
    ⟨"raw observation result path", (← string registered "resultPath") == output.toString⟩,
    ⟨"raw observation stdout path", (← string registered "stdoutPath") == (raw / "stdout").toString⟩,
    ⟨"raw observation stderr path", (← string registered "stderrPath") == (raw / "stderr").toString⟩,
    ⟨"raw registration unchanged", (← readJson (raw / "registered.json")) == registered⟩,
    ⟨"raw terminal observation unchanged", (← readJson (raw / "terminal.json")) == observation⟩,
    ⟨"raw detector bytes unchanged", (← digest ctx.root output) == (← get observation "resultIdentity")⟩,
    ⟨"raw stdout unchanged", (← IO.FS.readFile (raw / "stdout")) == (← string observation "stdout")⟩,
    ⟨"raw stderr unchanged", (← IO.FS.readFile (raw / "stderr")) == (← string observation "stderr")⟩]

/-- Full corpus or explicit scoped selection; all records and admission controls are
exported. No partial export is labelled a successfully qualified corpus. -/
def check (evidence : FilePath) (selection : Option (Array String))
    (suppliedAttempt : Option String := none) : IO Unit := do
  let attempt ← match suppliedAttempt with
    | some attempt => pure attempt
    | none => freshAttempt
  beginAttempt evidence attempt
  let root ← rootDirectory
  let evidence ← IO.FS.realPath evidence
  let rawDirectory := FilePath.mk (evidence.toString ++ ".raw/" ++ attempt)
  requireChecks [⟨"fresh raw observation attempt", !(← rawDirectory.pathExists)⟩]
  IO.FS.createDirAll rawDirectory
  -- Attempt-scoped flushed phase diagnostics (msg 174): one serialized writer
  -- (the consumer path) with per-mark open/append/flush/close; a diagnostic
  -- failure never masks a primary error or breaks a join; marks are
  -- diagnostics only — no acceptance interpretation from marks alone.
  -- Qualifier-end is marked at its join (consumer-observed), erring toward
  -- UNKNOWN at an abrupt kill.
  let mark (name edge : String) : IO Unit := do
    try
      let handle ← IO.FS.Handle.mk (rawDirectory / "phase-marks.txt") .append
      handle.putStrLn s!"phase mark: {name} {edge} {(← IO.monoMsNow)}"
      handle.flush
    catch _ => pure ()
  mark "run" "start"
  let specs ← readJson (root / "examples/rules/corpus.json")
  let keys := (← IO.ofExcept specs.getObj?).toList.map Prod.fst |>.toArray
  let selected := selection.getD keys
  requireChecks [⟨"nonempty known unique selected rules", !selected.isEmpty && selected.all keys.contains && selected.toList.eraseDups.length == selected.size⟩]
  let inventory ← StrictLean.Checker.Lake.surfaceInventory root
  let modulePaths := inventory.moduleSources.map Prod.snd
  let corpusPaths ← (← (root / "examples/rules").walkDir).filterM fun path => return !(← path.isDir)
  let checkerPaths := (modulePaths ++ #[root / "lean-toolchain", root / "lakefile.lean", root / "lake-manifest.json"] ++ corpusPaths).toList.eraseDups.toArray
  let cache ← IO.mkRef SnapshotCache.empty
  let checkerBefore ← snapshotCached cache checkerPaths
  save evidence (Json.mkObj [("outcome", .str "INCOMPLETE"),
    ("schemaVersion", toJson (1 : Nat)), ("completeCorpus", .bool selection.isNone),
    ("attempt", .str attempt), ("rawDirectory", .str rawDirectory.toString),
    ("selected", toJson selected), ("checkerBefore", checkerBefore)])
  let completed ← withScratch root "rule-examples" fun scratch => do
    let ctx : Context := ⟨root, scratch, specs, checkerPaths, checkerBefore, attempt, rawDirectory, cache⟩
    -- Five producer slots with derived nonoverlap (`slots_distinct`). Slot roots
    -- are producer-write-only; the consumer path never dereferences them.
    let slots ← #[0, 1, 2, 3, 4].mapM fun k => do
      let slot : Slot.ProducerSlot := ⟨scratch / s!"slot-{k}"⟩
      IO.FS.createDirAll slot.root
      pure slot
    let configNames ← (#["lean-toolchain", "lakefile.lean", "lake-manifest.json",
      "foundation_manifest.json"] : Array String).filterM
        (fun (name : String) => (root / name).pathExists)
    let rootConfigs ← configNames.mapM (fun (name : String) => do
      pure (root / name, ← IO.FS.readBinFile (root / name)))
    let rootSources ← modulePaths.mapM fun path => do
      pure (path, ← IO.FS.readBinFile path)
    let depObservations ← StrictLean.Checker.Snapshot.dependencies inventory
    -- Atomic pool readiness (CONSTRAINT-1): all slot preparations complete or
    -- the run fails (smallest-slot-index failure verbatim) before any producer
    -- task starts; every prep task/child drains first.
    let _ ← Slot.prepareSlots 3 slots root rootSources rootConfigs depObservations
    let mut records : Array Json := #[]
    let mut controls : Array Json := #[]
    let jobs := selected.flatMap fun rule => #["Fixed", "Violation", "Restored"].map (rule, ·)
    -- Pooled productions: the 60 record jobs plus the five special productions
    -- (jobs 60-64 in their original order). The single consumer path executes
    -- each job's original ordered post-production actions in job order
    -- (CONSTRAINT-6: each special's requireChecks stays between its produce and
    -- its admitRecord; records/controls/pending mutation stays here).
    let specials : Array String :=
      (if selected.contains "SL1005" then #["SL1005/WrongClaim", "SL1005/ClaimRestored"] else #[]) ++
      (if selected.contains "SL4004" then #["SL4004/TrustedControl", "SL4004/NegativeControl",
        "SL4004/ClassificationRestored"] else #[])
    let total := jobs.size + specials.size
    -- Special source reads happen inside their own selected producer jobs
    -- (scoped selections never read unselected specials' sources); a captured
    -- IO error fails that job's task and is delivered at its original job order.
    let produceJob (index : Nat) (slot : Slot.ProducerSlot) : IO Json := do
      if index < jobs.size then
        let (rule, phase) := jobs[index]!
        produce ctx slot rule phase
      else match specials[index - jobs.size]! with
        | "SL1005/WrongClaim" =>
          produce ctx slot "SL1005" "WrongClaim"
            (some (← IO.FS.readFile (root / "examples/rules/SL1005/Violation.lean")))
            (some "standard-logical")
        | "SL1005/ClaimRestored" => produce ctx slot "SL1005" "ClaimRestored"
        | "SL4004/TrustedControl" =>
          produce ctx slot "SL4004" "TrustedControl" (some ("<!-- lean-trusted-compiler -->\n```lean\n" ++
            (← IO.FS.readFile (root / "examples/rules/SL1004/Violation.lean")) ++ "```\n"))
        | "SL4004/NegativeControl" =>
          produce ctx slot "SL4004" "NegativeControl"
            (some "<!-- lean-fail: Unknown identifier -->\n```lean\n#check missingExample\n```\n")
        | _ => produce ctx slot "SL4004" "ClassificationRestored"
    -- Five disjoint producer slots (width-5 conservative default), consumed in
    -- fixed order and refilled before each admission. Drain every launched task
    -- before scratch cleanup, including on admission failure.
    let pending ← IO.mkRef (#[] : Array (Task (Except IO.Error Json)))
    for k in [0:5] do
      if k < total then
        let task ← IO.asTask (produceJob k slots[k]!)
        pending.modify (·.push task)
    try
      for index in [:total] do
        let task := (← pending.get)[index]!
        let record ← match (← IO.wait task) with
          | .ok value => pure value
          | .error error => throw error
        if index < jobs.size then
          records := records.push record
        else
          controls := controls.push record
        -- Refill before admission so producers run during every admission and
        -- admission is off the production critical path. Admission stays in
        -- fixed order: an admission refusal throws before any later entry is
        -- admitted, every already-launched task is drained in `finally` (slot
        -- reassignment only after the prior task returned its record), and up
        -- to five extra completed producers may remain raw-retained but are
        -- never admitted while the initial INCOMPLETE receipt stands.
        if index + 5 < total then
          let task ← IO.asTask (produceJob (index + 5) slots[(index + 5) % 5]!)
          pending.modify (·.push task)
        if index < jobs.size then
          admitRecord ctx record
          IO.println s!"{← string record "rule"}/{← string record "phase"}: qualified {← string record "kind"}"
          (← IO.getStdout).flush
        else
          -- Original ordered special consumer actions (requireChecks between
          -- produce and admitRecord; original refusals and restorations).
          match specials[index - jobs.size]! with
          | "SL1005/WrongClaim" =>
            requireChecks [⟨"Standard-Logical producer control completes", (← get record "exitCode") == toJson (0 : Nat) && (← string (← get record "result") "status") == "completed"⟩]
            admitRecord ctx record (some "producer request differs from frozen example request")
          | "SL1005/ClaimRestored" => admitRecord ctx record
          | "SL4004/TrustedControl" | "SL4004/NegativeControl" =>
            requireChecks [⟨"nonpositive documentation classifies", (← get record "exitCode") == toJson (0 : Nat) && (← string (← get record "result") "status") == "classified"⟩]
            admitRecord ctx record (some "documentation correction requires completed positive fences")
          | _ => admitRecord ctx record
    finally
      for task in ← pending.get do
        let _ ← IO.wait task
        pure ()
    for record in records do
      if (← string record "kind") == "diagnosticDemonstration" then
        let relabelled := (record.setObjVal! "rule" (.str "SL1001")).setObjVal! "mutation" (.str "demonstration relabel")
        admitRecord ctx relabelled (some "diagnostic demonstration mismatch")
        admitRecord ctx record
        controls := controls.push relabelled
      if (← string record "phase") == "Violation" && #["SL2003", "SL2005"].contains (← string record "rule") then
        let fixed ← IO.FS.readFile (root / "examples/rules" / (← string record "rule") / "Fixed.lean")
        let original ← string record "source"
        let mut stale := (record.setObjVal! "source" (.str fixed)).setObjVal! "mutation" (.str "displayed source and binding")
        for side in #["before", "after"] do
          let bound ← get stale side
          let sources ← (← entries bound "sources").mapM fun s => do
            return if (← string s "source") == original then s.setObjVal! "source" (.str fixed) else s
          stale := stale.setObjVal! side (bound.setObjVal! "sources" (toJson sources))
        admitRecord ctx stale (some "missing or mismatched producer source account")
        admitRecord ctx record
        controls := controls.push stale
        let result ← get record "result"
        let result ← IO.ofExcept (StrictLean.Checker.RuleExampleProjection.withoutSourceAccount result)
        let missing := (record.setObjVal! "result" result).setObjVal! "mutation" (.str "missing sourceAccount")
        admitRecord ctx missing (some "missing result source account")
        admitRecord ctx record
        controls := controls.push missing
    let finalFields := [("schemaVersion", toJson (1 : Nat)), ("completeCorpus", .bool selection.isNone),
      ("attempt", .str attempt), ("rawDirectory", .str rawDirectory.toString),
      ("selected", toJson selected), ("checkerBefore", checkerBefore),
      ("checkerAfter", ← snapshotCached cache checkerPaths), ("admissionControls", toJson controls)]
    mark "aggregate-save" "start"
    save evidence (StrictLean.Checker.RuleExampleProjection.corpus (("outcome", .str "INCOMPLETE") :: finalFields) records)
    mark "aggregate-save" "end"
    -- Tail overlap (strict-tail-overlap-audit constraints 1-7): start barrier
    -- is the frozen aggregate's atomic save above (the last owned write; the
    -- aggregate, raw sidecars and checker sources are stable for the window —
    -- no owned writer; external mutation timing outside equivalence). The
    -- terminal qualifier (write-free, evidence-only, output captured
    -- in-memory by `run`) and the read-only raw-validation region run
    -- concurrently over disjoint inputs with no shared mutable cells (the
    -- cache ref is touched only by the serial phases outside this window).
    -- Both join completely before any error surfaces; failures are held
    -- outcomes surfaced in the original serial order: the qualifier's failure
    -- first (its timeout-class throw or the corpus-admission check error,
    -- verbatim), then the validator's minimum-index verbatim error, then the
    -- terminal checker-equality failure. Abandoned concurrent work after an
    -- error is known stays read-only and unobservable. PASS save stays last.
    mark "qualifier" "start"
    let qualifierTask ← IO.asTask (do
      let checked ← run root (root / ".lake/build/bin/ruleExampleQualification").toString
        #[evidence.toString] cleanEnv
      requireChecks [⟨s!"corpus admission: {checked.stdout}{checked.stderr}", checked.exitCode == 0⟩])
    mark "raw-validation" "start"
    -- Terminal raw validation: the complete original validateRaw over every
    -- entry (records ++ controls), bounded to six concurrent read-only calls.
    let entries := records ++ controls
    let mut outcomes : Array (Option IO.Error) := #[]
    let mut start := 0
    while start < entries.size do
      let stop := min (start + 6) entries.size
      let batch := entries.extract start stop
      let tasks ← batch.mapM fun record => IO.asTask (validateRaw ctx record)
      let mut results : Array (Except IO.Error Unit) := #[]
      for task in tasks do
        results := results.push (← IO.wait task)
      for result in results do
        match result with
        | Except.ok _ => outcomes := outcomes.push none
        | Except.error error => outcomes := outcomes.push (some error)
      start := stop
    mark "raw-validation" "end"
    let qualifierFailure ← IO.wait qualifierTask
    mark "qualifier" "end"
    -- Held-outcome priority join (constraint 5): qualifier first, then the
    -- minimum-index validation failure, both verbatim.
    match qualifierFailure with
    | Except.error error => throw error
    | Except.ok () =>
      match outcomes.findSome? (fun outcome => outcome) with
      | some error => throw error
      | none => pure ()
    mark "terminal-equality" "start"
    requireChecks [⟨"terminal checker sources changed", (← snapshotCached cache checkerPaths) == checkerBefore⟩]
    mark "terminal-equality" "end"
    -- All producers (including child/stream joins), admission subprocesses,
    -- terminal qualifier and raw readers have now finished. Only these five
    -- owned slot roots are removed concurrently; retained evidence lives outside
    -- scratch. Authenticate every immediate-child identity before any deletion.
    -- No owned writer remains; external path replacement during this interval
    -- is outside the stable-filesystem boundary, as for sequential cleanup.
    mark "slot-cleanup" "start"
    let scratchRoot ← IO.FS.realPath scratch
    requireChecks [⟨"five owned cleanup slots", slots.size == 5⟩]
    for index in [:slots.size] do
      let path := slots[index]!.root
      let expected := scratchRoot / s!"slot-{index}"
      requireChecks [⟨"contained disjoint cleanup slot", path == expected &&
        (← IO.FS.realPath path) == expected && (← path.symlinkMetadata).type == .dir⟩]
    -- Reuse pinned removeDirAll: it never follows symlinks and specifies no
    -- deletion order. Three independent roots at a time; capture and join all
    -- five outcomes before propagating the first slot-index error verbatim.
    -- The enclosing withScratch still removes the parent on success or failure;
    -- its cleanup error retains precedence over an action error. SIGKILL cannot
    -- promise user-space drainage or cleanup. Complete deletion still precedes PASS.
    let mut cleanupOutcomes : Array (Except IO.Error Unit) := #[]
    let mut cleanupStart := 0
    while cleanupStart < slots.size do
      let cleanupStop := min (cleanupStart + 3) slots.size
      let tasks ← (slots.extract cleanupStart cleanupStop).mapM fun slot =>
        IO.asTask (IO.FS.removeDirAll slot.root)
      for task in tasks do
        cleanupOutcomes := cleanupOutcomes.push (← IO.wait task)
      cleanupStart := cleanupStop
    for outcome in cleanupOutcomes do
      IO.ofExcept outcome
    mark "slot-cleanup" "end"
    mark "parent-cleanup" "start"
    return StrictLean.Checker.RuleExampleProjection.corpus (("outcome", .str "PASS") :: finalFields) records
  mark "parent-cleanup" "end"
  mark "pass-save" "start"
  save evidence completed
  mark "pass-save" "end"
  mark "run" "end"
  IO.println s!"rule example campaign: PASS ({selected.size} selected rules; diagnostic evidence only)"
end StrictLean.Qualification.RuleExamples
