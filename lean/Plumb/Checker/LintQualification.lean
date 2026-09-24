import Plumb.Checker.BuildLintQualification

/-!
Qualification of the `lake lint` driver path. Each control copies a shipped adopter
(`examples/build-lint` in `lakefile.lean` format, `examples/lake-lint-toml` in
`lakefile.toml` format), establishes a green `lake lint`, applies one intended
mutation, and re-establishes the green control after removing all build output.
The driver reuses the build-policy audit body, whose detectors the build-policy
partition qualifies; these controls establish Lake's dispatch, the exit classes,
and the editor/builtin boundaries of this invocation path. They are diagnostics,
not proofs of the driver or of Lake.
-/

namespace Plumb.Checker.LintQualification

open Lean System

private def lint (adopter : FilePath) (args : Array String := #[]) : IO ProcessResult :=
  runProcess adopter "lake" (#["lint"] ++ args) scrubbedLeanPathEnv

/-- One invocation's required exit code and required/forbidden output fragments. -/
private structure Expectation where
  label : String
  exitCode : UInt32
  contains : Array String := #[]
  excludes : Array String := #[]

private def expect (adopter : FilePath) (e : Expectation) (args : Array String := #[]) :
    IO (Array String) := do
  let result ← lint adopter args
  let mut failures := #[]
  if result.exitCode != e.exitCode then
    failures := failures.push s!"lake-lint/{e.label}: exit {result.exitCode}, expected {e.exitCode}"
  if let some missing := e.contains.find? (!result.output.contains ·) then
    failures := failures.push s!"lake-lint/{e.label}: missing {missing}"
  if let some present := e.excludes.find? (result.output.contains ·) then
    failures := failures.push s!"lake-lint/{e.label}: unexpected {present}"
  if !failures.isEmpty then failures := failures.push result.output
  IO.println s!"lake-lint control {e.label}: {if failures.isEmpty then "completed" else "FAILED"}"
  (← IO.getStdout).flush
  return failures

/-- An accepted run prints its account's `Account.pass` line, which names the coverage. -/
private def accepted (label : String) (fresh : Bool := false) : Expectation :=
  { label, exitCode := 0, contains := #[if fresh then
      "plumb lint: PASS — fresh whole-project acceptance"
    else "plumb lint: PASS — incremental project acceptance"] }

/-- Replace one exact anchor; a missing or repeated anchor is a harness failure. -/
private def mutate (path : FilePath) (before after : String) : IO Unit := do
  let original ← IO.FS.readFile path
  if (original.splitOn before).length != 2 then
    throw <| IO.userError s!"lake-lint: expected exactly one anchor {before} in {path}"
  IO.FS.writeFile path (original.replace before after)

private def restore (adopter : FilePath) (files : Array (FilePath × String)) : IO Unit := do
  for (path, text) in files do IO.FS.writeFile path text
  if ← (adopter / ".lake" / "build").pathExists then
    IO.FS.removeDirAll (adopter / ".lake" / "build")

/-- `lakefile.lean` adopter: every exit class, a repeated cached failure, Lake's
builtin-only and combined dispatch, and the read-only configuration explanation. -/
private def leanAdopter (repo adopter : FilePath) : IO (Array String) := do
  BuildLintQualification.setup repo adopter
  let mut failures ← expect adopter (accepted "lean/positive")
  if !failures.isEmpty then return failures
  failures := failures ++ (← expect adopter {
      label := "lean/explain-config", exitCode := 0,
      contains := #["no audit was run", "Widget.Additional", "kernel-only"],
      excludes := #["plumb lint: PASS"] } #["--", "--explain-config"])
  let additional := adopter / "Widget" / "Additional.lean"
  let manifest := adopter / "foundation_manifest.json"
  let widget := adopter / "Widget.lean"
  let originals := #[(additional, ← IO.FS.readFile additional),
    (manifest, ← IO.FS.readFile manifest), (widget, ← IO.FS.readFile widget)]
  -- An unimported glob module; the second run has every module cached.
  mutate additional "namespace Widget.Additional" "axiom lintAssumption : True\nnamespace Widget.Additional"
  let violation : Expectation := {
    label := "lean/violation", exitCode := 1,
    contains := #["PL1001", "lintAssumption", "plumb lint: VIOLATION (exit 1)"] }
  failures := failures ++ (← expect adopter violation)
  failures := failures ++ (← expect adopter { violation with label := "lean/cached-violation" })
  -- Builtin linting needs explicit modules here (the default target is `policy`).
  -- Lake skips the driver: exit 0 despite the violation is not Plumb enforcement.
  failures := failures ++ (← expect adopter {
      label := "lean/builtin-only", exitCode := 0,
      excludes := #["plumb lint:"] } #["--builtin-only", "Widget"])
  failures := failures ++ (← expect adopter { violation with label := "lean/builtin-and-driver" }
    #["--builtin-lint", "Widget"])
  restore adopter originals
  mutate manifest "\"kernel-only\"" "\"unknown\""
  failures := failures ++ (← expect adopter {
      label := "lean/configuration", exitCode := 2,
      contains := #["manifest-schema", "plumb lint: INVALID CONFIGURATION (exit 2)"] })
  failures := failures ++ (← expect adopter {
      label := "lean/invocation", exitCode := 2,
      contains := #["unknown or incomplete argument: --bogus"] } #["--", "--bogus"])
  restore adopter originals
  mutate widget "namespace Widget" "def lintBroken : Nat := \"text\"\nnamespace Widget"
  failures := failures ++ (← expect adopter {
      label := "lean/incomplete", exitCode := 3,
      contains := #["build-failed", "plumb lint: INCOMPLETE (exit 3)"] })
  restore adopter originals
  failures := failures ++ (← expect adopter (accepted "lean/fresh-restored"))
  return failures

/-- `lakefile.toml` adopter importing `Plumb.Linter`: disabling live feedback
cannot waive the project predicate, and a live finding fails the claimed build. -/
private def tomlAdopter (repo adopter : FilePath) : IO (Array String) := do
  BuildLintQualification.setup repo adopter "lake-lint-toml" #["Gadget.lean", "Gadget/Double.lean"]
    "lakefile.toml"
  let mut failures ← expect adopter (accepted "toml/positive")
  if !failures.isEmpty then return failures
  let double := adopter / "Gadget" / "Double.lean"
  let originals := #[(double, ← IO.FS.readFile double)]
  mutate double "end Gadget" "set_option linter.plumb false in\naxiom optedOut : True\nend Gadget"
  failures := failures ++ (← expect adopter {
      label := "toml/editor-opt-out", exitCode := 1,
      contains := #["PL1001", "optedOut", "plumb lint: VIOLATION (exit 1)"] })
  restore adopter originals
  mutate double "end Gadget" "axiom liveFinding : True\nend Gadget"
  failures := failures ++ (← expect adopter {
      label := "toml/live-finding", exitCode := 3,
      contains := #["build-failed", "PL1001 [violation; editorSnapshot", "liveFinding", "plumb lint: INCOMPLETE (exit 3)"] })
  restore adopter originals
  failures := failures ++ (← expect adopter (accepted "toml/fresh-restored" (fresh := true)) #["--", "--fresh"])
  return failures

/-- Both independent adopters, each in its own disposable workspace. -/
def qualify (repo scratch : FilePath) (jobs : Nat) : IO (Array String) := do
  let results ← mapConcurrent jobs #[("lean", leanAdopter), ("toml", tomlAdopter)]
    fun (name, control) => withScratch scratch s!"lake-lint-{name}" fun adopter => control repo adopter
  return results.foldl (· ++ ·) #[]

end Plumb.Checker.LintQualification
