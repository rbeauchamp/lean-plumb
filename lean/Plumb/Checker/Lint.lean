import Plumb.Checker.AxiomGate

/-!
`lint`: the Lake lint driver (`lintDriver = "plumb/lint"`).

It runs the same project audit body as `axiomGate` (incremental by default, fresh with
`--fresh`) and maps that audit's own recorded terminal status to four exit classes through the
claimed `PlumbCore.Lint.classify`. It adds no detector, policy or acceptance path: its
success line is `Account.pass` of the accepted account the audit recorded. `--explain-config` is a read-only
account of the configuration an audit would use; it runs no audit.
-/

namespace Plumb.Checker.Lint

open Lean System

def stageName : PlumbPolicy.Stage → String
  | .configuration => "configuration" | .discovery => "discovery" | .build => "build"
  | .admission => "admission" | .declarationPolicy => "declarationPolicy"
  | .execution => "execution" | .transcript => "transcript" | .history => "history"
  | .origin => "origin" | .documentationPresence => "documentationPresence"
  | .documentScan => "documentScan" | .example => "example" | .graph => "graph"

structure Options where
  project : Option String := none
  manifest : Option String := none
  jsonOut : Option String := none
  fresh : Bool := false
  verbose : Bool := false
  explain : Bool := false
  help : Bool := false

def usage : String :=
  "usage: lake lint [-- [--fresh] [--project DIR] [--manifest PATH] [--json-out PATH] [--verbose]]\n" ++
  "       lake lint -- --explain-config [--fresh] [--project DIR] [--manifest PATH]\n" ++
  "Checks every manifested Lake surface: incremental elaboration with current policy\n" ++
  "inspection by default, or an isolated fresh build with --fresh.\n" ++
  "exit codes: 0 accepted, 1 violation, 2 invalid configuration or invocation, 3 incomplete\n" ++
  "--explain-config and --help run no audit and establish no result."

private def setOnce (flag : String) (current : Option String) (value : String) :
    Except String (Option String) :=
  if current.isSome then .error s!"duplicate {flag} option" else .ok (some value)

private def setFlag (flag : String) (current : Bool) : Except String Bool :=
  if current then .error s!"duplicate {flag} option" else .ok true

/-- Unknown, duplicate and incomplete arguments are refused; none narrows the claim. -/
def parseArgs : List String → Options → Except String Options
  | [], options => .ok options
  | "--" :: rest, options => parseArgs rest options
  | "--project" :: value :: rest, options => do
      parseArgs rest { options with project := ← setOnce "--project" options.project value }
  | "--manifest" :: value :: rest, options => do
      parseArgs rest { options with manifest := ← setOnce "--manifest" options.manifest value }
  | "--json-out" :: value :: rest, options => do
      parseArgs rest { options with jsonOut := ← setOnce "--json-out" options.jsonOut value }
  | "--fresh" :: rest, options => do
      parseArgs rest { options with fresh := ← setFlag "--fresh" options.fresh }
  | "--verbose" :: rest, options => do
      parseArgs rest { options with verbose := ← setFlag "--verbose" options.verbose }
  | "--explain-config" :: rest, options => do
      parseArgs rest { options with explain := ← setFlag "--explain-config" options.explain }
  | "--help" :: rest, options | "-h" :: rest, options =>
      parseArgs rest { options with help := true }
  | flag :: _, _ => .error s!"unknown or incomplete argument: {flag}"

/-- The audit invocation: the same `axiomGate` project body and options. -/
def gateArgs (options : Options) : List String :=
  (if options.fresh then [] else ["--incremental"]) ++
  (options.project.map (["--project", ·])).getD [] ++
  (options.manifest.map (["--manifest", ·])).getD [] ++
  (options.jsonOut.map (["--json-out", ·])).getD [] ++
  (if options.verbose then ["--verbose"] else [])

/-- The evidence mode an audit of this invocation must report. -/
def requestedMode (fresh : Bool) : EvidenceMode :=
  if fresh then .freshProject else .incrementalProject

private def modeText (fresh : Bool) : String :=
  if fresh then "freshProject (isolated copy built from empty output)"
  else "incrementalProject (incremental elaboration; current policy on cached modules)"

/-- Read-only: validates the manifest and Lake scope with the audit's own functions and
prints what an audit would check. It never constructs or reports a result. -/
private def explain (options : Options) : IO UInt32 := do
  Plumb.Checker.initializeLeanSearchPath
  let repo ← match options.project with
    | some dir => findRepoRoot dir
    | none => repoRoot
  let manifestPath := match options.manifest with
    | some path => if (FilePath.mk path).isAbsolute then FilePath.mk path else repo / path
    | none => Manifest.defaultPath repo
  IO.println "plumb lint configuration (read-only; no audit was run)"
  IO.println s!"project: {repo}"
  IO.println s!"manifest: {manifestPath} ({if options.manifest.isSome then "--manifest" else "project-root default"})"
  try
    let manifest ← Manifest.load manifestPath
    let inventory ← Lake.surfaceInventory repo
    AxiomGate.checkClassification manifest inventory
    discard <| IO.ofExcept <| Acceptance.surfaceAssignments manifest inventory
    IO.println s!"mode: {modeText options.fresh}"
    IO.println s!"required stages: {", ".intercalate (projectStages.map stageName)}"
    for surface in manifest.surfaces do
      let modules := ((inventory.libraries.find? (·.library == surface.library)).map (·.modules)).getD #[]
      IO.println s!"surface {surface.library}: claim {surface.claim}, execution {surface.execution}"
      IO.println s!"  modules: {", ".intercalate (modules.map toString).toList}"
      unless surface.executables.isEmpty do
        IO.println s!"  executables: {", ".intercalate surface.executables.toList}"
    for excluded in manifest.excludedLibraries do
      IO.println s!"excluded library {excluded.library}: {excluded.rationale}"
    for excluded in manifest.excludedExecutables do
      IO.println s!"excluded executable {excluded.executable}: {excluded.rationale}"
    IO.println ("not run by this command: documentation fences (`lake exe axiomGate --with-docs`); " ++
      "editor options such as linter.plumb affect only local feedback")
    return 0
  catch error =>
    let configuration := error.toString.startsWith "manifest-"
    IO.eprintln s!"configuration {if configuration then "invalid" else "unavailable"}: {error}"
    return (if configuration then Outcome.configuration else Outcome.incomplete).exitCode

/-- Driver body. Only a zero audit exit with a recorded completed status succeeds. -/
unsafe def run (args : List String) : IO UInt32 := do
  match parseArgs args {} with
  | .error message =>
      IO.eprintln usage
      IO.eprintln s!"plumb lint: {Outcome.configuration.label}: {message}"
      return Outcome.configuration.exitCode
  | .ok options =>
    if options.help then
      IO.println usage
      return 0
    if options.explain then return ← explain options
    IO.println s!"plumb lint: enforcing all manifested Lake surfaces; mode {modeText options.fresh}"
    (← IO.getStdout).flush
    let code ← AxiomGate.entry (gateArgs options)
    let observed ← AxiomGate.terminalObservation.get
    let outcome := classify (requestedMode options.fresh) code observed
    -- The only success line projects the accepted account the audit recorded.
    match outcome, observed with
    | .accepted, some ⟨.completed account, _⟩ => IO.println (account.pass "plumb lint")
    | _, _ => IO.println s!"plumb lint: {outcome.label} (exit {outcome.exitCode})"
    return outcome.exitCode

end Plumb.Checker.Lint
