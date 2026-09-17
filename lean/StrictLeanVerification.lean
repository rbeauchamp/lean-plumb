import Lean

/-! Cold-start verification plan and operational interpreter. This module imports only
the pinned toolchain, so it can run before any root-package artifacts exist. Argument
selection has soundness and round-trip proofs; the interpreter consumes its proof-bearing
selection. Recipes name Lake targets, not a source-file census. Process effects remain
trusted IO under the shell's single 420-second process-group deadline. -/
namespace StrictLeanVerification

/-- Closed vocabulary of supported verification invocations. -/
inductive Mode where
  | ordinary | graph | diagnostics | fixtures | structural | cli | environments | buildPolicy | producers | history | ruleExamples
  deriving DecidableEq

/-- Exactly the documented arguments for each mode, with no ignored trailing arguments. -/
def arguments : Mode → List String
  | .ordinary => []
  | .graph => ["serialized-graph"]
  | .diagnostics => ["diagnostics"]
  | .fixtures => ["diagnostics", "fixtures"]
  | .structural => ["diagnostics", "structural"]
  | .cli => ["diagnostics", "cli"]
  | .environments => ["diagnostics", "environments"]
  | .buildPolicy => ["diagnostics", "build-policy"]
  | .producers => ["diagnostics", "producers"]
  | .history => ["diagnostics", "history"]
  | .ruleExamples => ["diagnostics", "rule-examples"]

/-- Every supported mode occurs once; the parser searches only this closed vocabulary. -/
def modes : List Mode := [.ordinary, .graph, .diagnostics, .fixtures, .structural,
  .cli, .environments, .buildPolicy, .producers, .history, .ruleExamples]

/-- Argument parsing never accepts a prefix of a supported invocation. -/
def parseMode (args : List String) : Option Mode :=
  modes.find? (fun mode => arguments mode == args)

/-- Successful parsing means exact argument equality, not a weakened prefix match. -/
theorem parseMode_sound (args : List String) (mode : Mode)
    (h : parseMode args = some mode) : args = arguments mode := by
  have exactArgs := List.find?_some h
  simpa using (eq_of_beq exactArgs).symm

/-- Every documented invocation is accepted; this excludes an always-refusing parser. -/
theorem parseMode_roundtrip (mode : Mode) : parseMode (arguments mode) = some mode := by
  cases mode <;> rfl

/-- Selection carries the argument-binding proof required by the operational caller. -/
def select (args : List String) : Option {mode : Mode // args = arguments mode} :=
  match h : parseMode args with
  | none => none
  | some mode => some ⟨mode, parseMode_sound args mode h⟩

/-- The selected mode is exactly the parser result, with no normalization or substitution. -/
theorem select_exact (args : List String) : (select args).map Subtype.val = parseMode args := by
  unfold select
  split <;> simp_all

/-- One argv invocation; there is no shell source in the recipe. -/
structure Command where
  program : String
  args : Array String

private def lake (args : Array String) : Command := ⟨"lake", args⟩

/-- Existing acceptance and diagnostic recipes, executed inside the outer deadline.
Qualification's private flag retains the already timed process group. -/
def commands : Mode → List Command
  | .ordinary => [
      lake #["build", "StrictLeanPolicy", "StrictLeanQualification", "axiomGate", "docFenceAudit", "qualify",
        "+StrictLean.Checker.CheckerSelftest:olean", "+StrictLean.Checker.FreshChecker:olean",
        "+StrictLean.RegistryChecks:olean", "+StrictLean.Linter:olean",
        "+StrictLean.Checker.ProducerQualification:olean", "+StrictLean.Checker.HistoryQualification:olean",
        "+StrictLean.Checker.RuleExamples:olean", "+StrictLean.Checker.RuleExampleQualification:olean"],
      lake #["env", "lean", "--run", "lean/StrictLean/RegistryChecks.lean"],
      lake #["exe", "qualify", "--under-deadline", "combined"],
      lake #["exe", "axiomGate", "--with-docs", "--legacy-json-out", "tmp/axiom-report.json"]]
  | .graph => [lake #["exe", "freshChecker", "--verbose"]]
  | .diagnostics => [lake #["exe", "checkerSelftest", "--build-bound", "--jobs", "4"]]
  | .producers => [
      lake #["build", "axiomGate", "qualify", "+StrictLean.Checker.ProducerQualification:olean"],
      lake #["exe", "qualify", "--under-deadline", "producers"]]
  | .history => [
      lake #["build", "axiomGate", "qualify", "+StrictLean.Checker.HistoryQualification:olean"],
      lake #["exe", "qualify", "--under-deadline", "history"]]
  | .ruleExamples => [
      lake #["build", "axiomGate", "ruleExamples", "ruleExampleQualification", "qualify"],
      lake #["exe", "qualify", "--under-deadline", "rule-examples", "--evidence", "tmp/rule-examples.json"]]
  | mode => [lake (#["exe", "checkerSelftest", "--build-bound", "--partition"] ++
      ((arguments mode).drop 1).toArray ++ #["--jobs", "4"])]

/-- Every mode schedules actual work rather than accepting an empty campaign. -/
theorem commands_nonempty (mode : Mode) : commands mode ≠ [] := by
  cases mode <;> simp [commands]

/-- Interpret sequentially; a nonzero process exit raises before any success report.
No theorem here purports to prove the OS's process execution or signal delivery. -/
def execute (command : Command) : IO Unit := do
  let child ← IO.Process.spawn {
    cmd := command.program, args := command.args,
    stdin := .null, stdout := .inherit, stderr := .inherit }
  let exit ← child.wait
  if exit != 0 then throw <| IO.userError s!"{command.program} {command.args} failed ({exit})"

/-- Cold-start driver; all builds and checks stay within the inherited outer deadline. -/
def run (args : List String) : IO Unit := do
  let some selection := select args
    | throw <| IO.userError "usage: scripts/verify.sh [serialized-graph | diagnostics [fixtures|structural|cli|environments|build-policy|producers|history|rule-examples]]"
  for command in [Command.mk "git" #["diff", "--check"],
      Command.mk "git" #["diff", "--cached", "--check"],
      Command.mk "shellcheck" #["scripts/verify.sh"]] ++ commands selection.val do
    execute command
  IO.println (match selection.val with
    | .ordinary => "local verification: PASS (complete ordinary conformance commands)"
    | .graph => "serialized-graph diagnostic: PASS (not ordinary verification)"
    | _ => "diagnostic qualification: PASS (selected scope only; not ordinary verification)")

end StrictLeanVerification

/-- Standalone cold-start entrypoint; invoke through the timed `scripts/verify.sh`. -/
def main (args : List String) : IO Unit := StrictLeanVerification.run args
