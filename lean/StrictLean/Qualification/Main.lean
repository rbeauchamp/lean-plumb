import StrictLean.Qualification.RegistryCli
import StrictLean.Qualification.NativeLinter
import StrictLean.Qualification.Producer
import StrictLean.Qualification.History
import StrictLean.Qualification.DocumentationSource
import StrictLean.Qualification.FrozenExit
import StrictLean.Qualification.RuleExamples
import StrictLean.Qualification.EnvironmentCensus
import StrictLean.Qualification.Acceptance
import StrictLean.Qualification.ReceiptBoundary
import StrictLean.Qualification.Preparation

/-! One Lake executable for operational qualification, with independently selectable
campaigns. Each oracle is proved on the positive `StrictLeanQualification` surface;
this process dispatcher and its IO adapters remain operational tooling. -/

/-- Explicit commands; unknown or extra arguments refuse instead of silently skipping
work. The acceptance shell owns the overall deadline, not this dispatcher. -/
private unsafe def dispatch (args : List String) (attempt : Option String := none) : IO Unit := do
  match args with
  | ["registry"] => StrictLean.Qualification.RegistryCli.check
  | ["native"] => StrictLean.Qualification.NativeLinter.checkAll
  | ["combined"] => do
      StrictLean.Qualification.RegistryCli.check
      StrictLean.Qualification.NativeLinter.checkAll
  | ["native-launcher"] => StrictLean.Qualification.NativeLinter.paired
  | ["rule-examples", "--evidence", path] => StrictLean.Qualification.RuleExamples.check ⟨path⟩ none attempt
  | "rule-examples" :: "--evidence" :: path :: "--rules" :: rules =>
      StrictLean.Qualification.RuleExamples.check ⟨path⟩ (some rules.toArray) attempt
  | ["rule-examples", "--evidence", path, "--shard", spec] => do
      let shard ← match (spec.splitOn "/").map String.toNat? with
        | [some index, some count] =>
          if 1 ≤ index && index ≤ count then pure (index, count)
          else throw <| IO.userError s!"invalid rule-example shard: {spec}"
        | _ => throw <| IO.userError s!"invalid rule-example shard: {spec}"
      StrictLean.Qualification.RuleExamples.check ⟨path⟩ none attempt (some shard)
  | ["producers"] => StrictLean.Qualification.Producer.check none
  | ["producers", "--evidence", path] => StrictLean.Qualification.Producer.check (some ⟨path⟩)
  | ["producers-combined"] => do
      StrictLean.Qualification.Producer.check none
      StrictLean.Qualification.History.check
  | ["history"] => StrictLean.Qualification.History.check
  | ["environments", "--evidence", path] => StrictLean.Qualification.EnvironmentCensus.check ⟨path⟩ attempt
  | ["acceptance", group, "--evidence", path] => StrictLean.Qualification.Acceptance.check group ⟨path⟩ attempt
  | ["acceptance-snapshots", group] => StrictLean.Qualification.DependencySnapshot.check group
  | ["prep-measure"] => StrictLean.Qualification.Preparation.check
  | ["documentation-dependencies"] => StrictLean.Qualification.Acceptance.documentationDependencies
  | ["input-inventory"] => StrictLean.Qualification.InputInventory.check
  | ["receipt-boundaries"] => StrictLean.Qualification.ReceiptBoundary.check
  | ["closure-evidence"] => StrictLean.Qualification.SourceEvidence.closure
  | ["configuration-capture"] => StrictLean.Qualification.SourceEvidence.configuration
  | ["fence-evidence"] => StrictLean.Qualification.SourceEvidence.fences
  | ["frozen-exits"] => StrictLean.Qualification.FrozenExit.check
  | ["documentation-source"] => StrictLean.Qualification.DocumentationSource.check false
  | ["documentation-source", "--source-read-only"] => StrictLean.Qualification.DocumentationSource.check true
  | _ => throw <| IO.userError "usage: lake exe qualify registry|native|combined|native-launcher|producers [--evidence PATH]|environments --evidence PATH|acceptance GROUP --evidence PATH|acceptance-snapshots dependencies|history|git-status|all|documentation-dependencies|input-inventory|history|closure-evidence|configuration-capture|fence-evidence|frozen-exits|documentation-source [--source-read-only]|rule-examples --evidence PATH [--rules RULE ... | --shard K/N]"

/-- Standalone commands get one group-wide 420-second bound. The private protocol flag
is supplied by this wrapper or the already timed acceptance driver, never documented
as a bounded standalone command. Nested commands do not create escaping groups. -/
unsafe def main (args : List String) : IO UInt32 := do
  if (← IO.getEnv "STRICT_LEAN_RECEIPT_TIMER") == some "1" && args == ["--version"] then
    return ← StrictLean.Qualification.ReceiptBoundary.worker args
  match ← IO.getEnv "STRICT_LEAN_QUALIFICATION_WRAPPER" with
  | some "acceptance" => return ← StrictLean.Qualification.Acceptance.worker args
  | some "inventory" => return ← StrictLean.Qualification.InputInventory.worker args
  | some _ => throw <| IO.userError "unknown qualification wrapper mode"
  | none => pure ()
  match args with
  | "--under-deadline" :: "--attempt" :: attempt :: rest => dispatch rest (some attempt); return 0
  | "--under-deadline" :: rest => dispatch rest; return 0
  | _ =>
    -- Recognize evidence destinations even when later argument validation refuses.
    -- This must precede timeout selection and spawning, both of which can fail.
    let attempt ← StrictLean.Qualification.freshAttempt
    match args with
    | "acceptance" :: group :: "--evidence" :: path :: _ =>
      let _ ← StrictLean.Qualification.Acceptance.beginAttempt group ⟨path⟩ attempt
    | "environments" :: "--evidence" :: path :: _ =>
      StrictLean.Qualification.EnvironmentCensus.beginAttempt ⟨path⟩ attempt
    | "rule-examples" :: "--evidence" :: path :: _ =>
      StrictLean.Qualification.RuleExamples.beginAttempt ⟨path⟩ attempt
    | _ => pure ()
    StrictLean.Qualification.runBounded (← IO.currentDir) 420 (← IO.appPath).toString
      (#["--under-deadline", "--attempt", attempt] ++ args.toArray)
