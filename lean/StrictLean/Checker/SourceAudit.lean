import StrictLean.Checker.PolicyCodec
import StrictLean.Checker.Environment
import StrictLean.Checker.Frontend
import StrictLean.Checker.Policy

/-! Verbatim source compilation followed by separate typed environment inspection. -/

namespace StrictLean.Checker.SourceAudit

open Lean System
open scoped StrictLean.Report
open StrictLean.Checker

structure SourceSpec where
  «module» : String
  source : String
  warningAsError : Bool := false
  rejectWarnings : Bool := false
  captureRejection : Bool := false
  deriving Repr, ToJson

instance : FromJson SourceSpec := ⟨fun j => do
  StrictLean.Checker.PolicyCodec.exactFields j ["module", "source", "warningAsError", "rejectWarnings", "captureRejection"]
  return {
    «module» := ← j.getObjValAs? _ "module"
    source := ← j.getObjValAs? _ "source"
    warningAsError := ← j.getObjValAs? _ "warningAsError"
    rejectWarnings := ← j.getObjValAs? _ "rejectWarnings"
    captureRejection := ← j.getObjValAs? _ "captureRejection"
  }⟩

private instance : ToJson ProcessResult where
  toJson value := Json.mkObj [
    ("exitCode", toJson value.exitCode.toNat),
    ("stdout", toJson value.stdout), ("stderr", toJson value.stderr)]

private instance : FromJson ProcessResult where
  fromJson? value := do
    StrictLean.Checker.PolicyCodec.exactFields value ["exitCode", "stdout", "stderr"]
    let code : Nat ← value.getObjValAs? Nat "exitCode"
    if code >= 2^32 then throw "invalid process exit code"
    let stdout ← value.getObjValAs? String "stdout"
    let stderr ← value.getObjValAs? String "stderr"
    return { exitCode := UInt32.ofNat code, stdout, stderr }

structure Compilation where
  spec : SourceSpec
  sourcePath : FilePath
  oleanPath : FilePath
  ileanPath : FilePath
  process : ProcessResult
  errors : Option (Array String) := none
  deriving Repr, ToJson

instance : FromJson Compilation := ⟨fun j => do
  StrictLean.Checker.PolicyCodec.exactFields j ["spec", "sourcePath", "oleanPath", "ileanPath", "process", "errors"]
  return {
    spec := ← j.getObjValAs? _ "spec"
    sourcePath := ← j.getObjValAs? _ "sourcePath"
    oleanPath := ← j.getObjValAs? _ "oleanPath"
    ileanPath := ← j.getObjValAs? _ "ileanPath"
    process := ← j.getObjValAs? _ "process"
    errors := ← j.getObjValAs? _ "errors"
  }⟩

structure Inspected where
  compilation : Compilation
  report : StrictLean.Checker.ProducerReport.Environment
  transcripts : Array Frontend.Transcript
  deriving Repr

/-- A worker owns every imported region for one compatible inspection group.
Only JSON data crosses the process boundary; extension-held references die
with the worker instead of accumulating across groups in the coordinator. -/
structure GroupRequest where
  modules : Array Name
  moduleSources : Array (Name × String) := #[]
  ownedOutput : Option String := none
  includeExecution : Bool := true
  includeModuleOrigins : Bool := true
  deriving ToJson

instance : FromJson GroupRequest := ⟨fun j => do
  StrictLean.Checker.PolicyCodec.exactFields j ["modules", "moduleSources", "ownedOutput", "includeExecution", "includeModuleOrigins"]
  return {
    modules := ← j.getObjValAs? _ "modules"
    moduleSources := ← j.getObjValAs? _ "moduleSources"
    ownedOutput := ← j.getObjValAs? _ "ownedOutput"
    includeExecution := ← j.getObjValAs? _ "includeExecution"
    includeModuleOrigins := ← j.getObjValAs? _ "includeModuleOrigins"
  }⟩

structure GroupReport where
  report : StrictLean.Checker.ProducerReport.Environment
  transcripts : Array Frontend.Transcript
  deriving ToJson

instance : FromJson GroupReport := ⟨fun j => do
  StrictLean.Checker.PolicyCodec.exactFields j ["report", "transcripts"]
  return {
    report := ← j.getObjValAs? _ "report"
    transcripts := ← j.getObjValAs? _ "transcripts"
  }⟩

unsafe def inspectGroupWorker (request : GroupRequest) : IO GroupReport := do
  let moduleSources := request.moduleSources.map fun (name, path) =>
    (name, FilePath.mk path)
  let report ← Environment.loadReportCurrentSearchPath request.modules moduleSources
    (request.ownedOutput.map FilePath.mk) request.includeExecution request.includeModuleOrigins
  return { report, transcripts := #[] }

def inspectGroupCurrentSearchPath (modules : Array Name)
    (transcriptSources : Array (Name × FilePath) := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none)
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    IO GroupReport := do
  let some selfLib ← checkerPackageLibDir
    | throw <| IO.userError "checker library directory unavailable"
  let binary := selfLib.parent.getD selfLib / ".." / "bin" / "axiomGate"
  withScratch (← IO.currentDir) "inspection-group" fun scratch => do
    let input := scratch / "request.json"
    let output := scratch / "report.json"
    let request : GroupRequest := {
      modules
      moduleSources := moduleSources.map fun (name, path) => (name, path.toString)
      ownedOutput := ownedOutput.map (·.toString)
      includeExecution
      includeModuleOrigins
    }
    writeJson input (toJson request)
    let result ← runProcess (← IO.currentDir) binary.toString
      #["--inspection-group-worker", input.toString, output.toString]
      #[("LEAN_PATH", some (SearchPath.toString (← Lean.searchPathRef.get)))]
    -- Put the actual failure before timing stdout: documentation displays a
    -- bounded diagnostic excerpt, so progress must not hide the rejection.
    if !result.succeeded then throw <| IO.userError (result.stderr ++ result.stdout)
    let json ← IO.ofExcept <| StrictLean.Checker.PolicyCodec.parse (← IO.FS.readFile output)
    let payload ← IO.ofExcept <| readWorkerPacket (toJson request) json
    let inspected : GroupReport ← IO.ofExcept (fromJson? payload)
    unless inspected.report.census.modules == modules &&
        inspected.report.census.executionRoots.isSome == includeExecution do
      throw <| IO.userError "producer-census: inspection response scope mismatch"
    -- The report worker has exited before any frontend imports are loaded.
    -- Each transcript likewise releases its imports before the next one.
    let mut transcripts := #[]
    for (name, path) in transcriptSources do
      let declarations := inspected.report.declarations.filter (·.«module» == name)
      if Policy.needsFrontendTranscript declarations then
        transcripts := transcripts.push (← Frontend.buildIsolated name path)
    return { inspected with transcripts }

private def compileIn (repo scratch : FilePath) (spec : SourceSpec)
    (insideLakeEnv : Bool) : IO Compilation := do
  let spawn := fun cmd args =>
    if insideLakeEnv then runProcess repo cmd args
    else runProcess repo "lake" (#["env", cmd] ++ args) scrubbedLeanPathEnv
  let sourcePath := scratch / s!"{spec.«module»}.lean"
  let oleanPath := scratch / s!"{spec.«module»}.olean"
  let ileanPath := scratch / s!"{spec.«module»}.ilean"
  IO.FS.writeFile sourcePath spec.source
  if spec.captureRejection then
    let some selfLib ← checkerPackageLibDir
      | throw <| IO.userError "checker library directory unavailable"
    let binary := selfLib.parent.getD selfLib / ".." / "bin" / "axiomGate"
    let output := scratch / s!"{spec.«module»}.diagnostics.json"
    let process ← spawn binary.toString
      #["--diagnostic-worker", (StrictLean.RegistryCodec.nameJson spec.module.toName).compress, sourcePath.toString, output.toString]
    let errors ← if process.succeeded then
        try
          let json ← IO.ofExcept <| StrictLean.Checker.PolicyCodec.parse (← IO.FS.readFile output)
          let payload ← IO.ofExcept <| readWorkerPacket
            (sourceWorkerRequest "diagnostic" spec.module.toName sourcePath spec.source) json
          unless (← IO.FS.readFile sourcePath) == spec.source do throw <| IO.userError "diagnostic snapshot changed"
          pure <| some (← IO.ofExcept <| fromJson? payload)
        catch _ => pure none
      else pure none
    return { spec, sourcePath, oleanPath, ileanPath, process, errors }
  let warningArgs := if spec.warningAsError then #["-DwarningAsError=true"] else #[]
  let args := warningArgs ++
    #["-o", oleanPath.toString, "-i", ileanPath.toString, sourcePath.toString]
  -- The worker sees only the workspace's own search path: an import that the
  -- fresh claimed-surface build did not produce fails here instead of
  -- resolving from the invoking checkout's inherited `LEAN_PATH`.
  let compiler ← if insideLakeEnv then do
      let some path ← IO.getEnv "LEAN"
        | throw <| IO.userError "Lake batch environment has no LEAN executable"
      if path.isEmpty || !(FilePath.mk path).isAbsolute then
        throw <| IO.userError "Lake batch LEAN executable must be absolute"
      pure path
    else pure "lean"
  let process ← spawn compiler args
  return { spec, sourcePath, oleanPath, ileanPath, process }

/-- Standalone compilation still obtains its environment through Lake. -/
def compile (repo scratch : FilePath) (spec : SourceSpec) : IO Compilation :=
  compileIn repo scratch spec false

structure CompileBatch where
  scratch : FilePath
  jobs : Nat
  specs : Array SourceSpec
  deriving ToJson

instance : FromJson CompileBatch := ⟨fun j => do
  StrictLean.Checker.PolicyCodec.exactFields j ["scratch", "jobs", "specs"]
  return {
    scratch := ← j.getObjValAs? _ "scratch"
    jobs := ← j.getObjValAs? _ "jobs"
    specs := ← j.getObjValAs? _ "specs"
  }⟩

/-- Entered only through a scrubbed `lake env` invocation. Each example still
has its own compiler/diagnostic process; only Lake environment setup is shared. -/
def compileBatchWorker (request : CompileBatch) : IO (Array Compilation) := do
  if request.jobs == 0 then throw <| IO.userError "compile batch requires positive jobs"
  let repo ← IO.currentDir
  mapWorkQueue request.jobs request.specs fun spec =>
    compileIn repo request.scratch spec true

/-- Resolve the complete subprocess environment with Lake once, preserving
PATH, Lean paths, dynamic-loader paths, and all other Lake environment entries. -/
def compileBatch (repo scratch : FilePath) (jobs : Nat) (specs : Array SourceSpec) :
    IO (Array Compilation) := do
  let some selfLib ← checkerPackageLibDir
    | throw <| IO.userError "checker library directory unavailable"
  let binary := selfLib.parent.getD selfLib / ".." / "bin" / "axiomGate"
  withScratch repo "compile-batch" fun work => do
    let input := work / "request.json"
    let output := work / "result.json"
    writeJson input (toJson ({ scratch, jobs, specs } : CompileBatch))
    let result ← runProcess repo "lake"
      #["env", binary.toString, "--compile-batch-worker", input.toString, output.toString]
      scrubbedLeanPathEnv
    if !result.succeeded then throw <| IO.userError result.output
    let json ← IO.ofExcept <| StrictLean.Checker.PolicyCodec.parse (← IO.FS.readFile output)
    let payload ← IO.ofExcept <| readWorkerPacket (toJson ({ scratch, jobs, specs } : CompileBatch)) json
    let binding (i : Nat) (actual : Compilation) : Bool :=
      match specs[i]? with
      | none => false
      | some expected => toJson actual.spec == toJson expected &&
          actual.sourcePath == scratch / s!"{expected.module}.lean" &&
          actual.oleanPath == scratch / s!"{expected.module}.olean" &&
          actual.ileanPath == scratch / s!"{expected.module}.ilean"
    let compilations ← IO.ofExcept <| admitIndexedWorkerResults specs.size binding payload
    if compilations.size != specs.size then
      throw <| IO.userError "compile batch returned incomplete results"
    for i in [:specs.size] do
      let some expected := specs[i]? | throw <| IO.userError "missing compile request"
      let some actual := compilations[i]? | throw <| IO.userError "missing compile result"
      unless toJson actual.spec == toJson expected &&
          actual.sourcePath == scratch / s!"{expected.module}.lean" &&
          actual.oleanPath == scratch / s!"{expected.module}.olean" &&
          actual.ileanPath == scratch / s!"{expected.module}.ilean" do
        throw <| IO.userError "compile batch result binding mismatch"
      unless (← IO.FS.readFile actual.sourcePath) == expected.source do
        throw <| IO.userError "compile batch source snapshot changed"
    return compilations

def compilationPassed (value : Compilation) : Bool :=
  value.process.succeeded
    && (!value.spec.rejectWarnings || (warningLines value.process.output).isEmpty)

/-- A normal compiler exit with a source-located error/warning establishes an emitted
source diagnostic. Crashes, termination and unrelated tool messages remain incomplete.
The pinned compiler's exit and textual diagnostic protocol is a trusted boundary. -/
def sourceDiagnosticFailure (value : Compilation) : Bool :=
  value.process.exitCode ≤ 1 && (outputLines value.process.output).any (fun line =>
    line.startsWith (value.sourcePath.toString ++ ":") && (isErrorLine line || isWarningLine line))

unsafe def inspect (value : Compilation) (extraSearchRoots : Array FilePath := #[])
    (sourceRoots : Array FilePath := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none) :
    IO Inspected := do
  if !compilationPassed value then
    throw <| IO.userError s!"source did not elaborate: {value.spec.«module»}"
  let some scratch := value.sourcePath.parent
    | throw <| IO.userError "compiled source has no parent directory"
  let report ← Environment.loadReport #[value.spec.«module».toName] (#[scratch] ++ extraSearchRoots) sourceRoots moduleSources ownedOutput
  let declarations := report.declarations
  let transcripts : Array Frontend.Transcript ←
    if Policy.needsFrontendTranscript declarations then
      pure #[← Frontend.build value.spec.«module».toName value.sourcePath extraSearchRoots]
    else pure #[]
  return { compilation := value, report, transcripts }

/-- Inspect with a caller-owned, already configured Lean search path. -/
unsafe def inspectCurrentSearchPath (value : Compilation)
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none) : IO Inspected := do
  if !compilationPassed value then
    throw <| IO.userError s!"source did not elaborate: {value.spec.«module»}"
  let report ← Environment.loadReportCurrentSearchPath #[value.spec.«module».toName] moduleSources ownedOutput
  let declarations := report.declarations
  let transcripts : Array Frontend.Transcript ←
    if Policy.needsFrontendTranscript declarations then
      pure #[← Frontend.buildCurrentSearchPath value.spec.«module».toName value.sourcePath]
    else pure #[]
  return { compilation := value, report, transcripts }

unsafe def compileAndInspect (repo scratch : FilePath) (spec : SourceSpec)
    (extraSearchRoots : Array FilePath := #[]) (sourceRoots : Array FilePath := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none) :
    IO (Except String Inspected) := do
  let compilation ← compile repo scratch spec
  if !compilationPassed compilation then
    return .error compilation.process.output
  try
    return .ok (← inspect compilation extraSearchRoots sourceRoots moduleSources ownedOutput)
  catch error =>
    return .error s!"{error}\n{compilation.process.output}"

end StrictLean.Checker.SourceAudit
