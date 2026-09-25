import Plumb.Qualification.RegistryCli
import Plumb.Qualification.NativeLinter
import Plumb.Qualification.Producer
import Plumb.Qualification.History
import Plumb.Qualification.DocumentationSource
import Plumb.Qualification.FrozenExit
import Plumb.Qualification.RuleExamples
import Plumb.Qualification.EnvironmentCensus
import Plumb.Qualification.Acceptance
import Plumb.Qualification.ReceiptBoundary
import Plumb.Qualification.Preparation
import Plumb.Qualification.SelfAudit

/-! One Lake executable for operational qualification, with independently selectable
campaigns. Each oracle is proved on the positive `PlumbQualification` surface;
this process dispatcher and its IO adapters remain operational tooling. -/

/-- Explicit commands; unknown or extra arguments refuse instead of silently skipping
work. The acceptance shell owns the overall deadline, not this dispatcher. -/
private unsafe def dispatch (args : List String) (attempt : Option String := none) : IO Unit := do
  match args with
  | ["registry"] => Plumb.Qualification.RegistryCli.check
  | ["native"] => Plumb.Qualification.NativeLinter.checkAll
  | ["combined"] => do
      Plumb.Qualification.RegistryCli.check
      Plumb.Qualification.NativeLinter.checkAll
  | ["native-launcher"] => Plumb.Qualification.NativeLinter.paired
  | ["rule-examples", "--evidence", path] => Plumb.Qualification.RuleExamples.check ⟨path⟩ none attempt
  | "rule-examples" :: "--evidence" :: path :: "--rules" :: rules =>
      Plumb.Qualification.RuleExamples.check ⟨path⟩ (some rules.toArray) attempt
  | ["rule-examples", "--evidence", path, "--shard", spec] => do
      let shard ← match (spec.splitOn "/").map String.toNat? with
        | [some index, some count] =>
          if 1 ≤ index && index ≤ count then pure (index, count)
          else throw <| IO.userError s!"invalid rule-example shard: {spec}"
        | _ => throw <| IO.userError s!"invalid rule-example shard: {spec}"
      Plumb.Qualification.RuleExamples.check ⟨path⟩ none attempt (some shard)
  | ["producers"] => Plumb.Qualification.Producer.check none
  | ["producers", "--evidence", path] => Plumb.Qualification.Producer.check (some ⟨path⟩)
  | ["producers-combined"] => do
      Plumb.Qualification.Producer.check none
      Plumb.Qualification.History.check
  | ["history"] => Plumb.Qualification.History.check
  | ["self-audit"] => Plumb.Qualification.SelfAudit.check
  | ["self-audit-module", m] => Plumb.Qualification.SelfAudit.worker m
  | ["environments", "--evidence", path] => Plumb.Qualification.EnvironmentCensus.check ⟨path⟩ attempt
  | ["acceptance", group, "--evidence", path] => Plumb.Qualification.Acceptance.check group ⟨path⟩ attempt
  | ["acceptance-snapshots", group] => Plumb.Qualification.DependencySnapshot.check group
  | ["prep-measure"] => Plumb.Qualification.Preparation.check
  | ["documentation-dependencies"] => Plumb.Qualification.Acceptance.documentationDependencies
  | ["input-inventory"] => Plumb.Qualification.InputInventory.check
  | ["receipt-boundaries"] => Plumb.Qualification.ReceiptBoundary.check
  | ["closure-evidence"] => Plumb.Qualification.SourceEvidence.closure
  | ["configuration-capture"] => Plumb.Qualification.SourceEvidence.configuration
  | ["fence-evidence"] => Plumb.Qualification.SourceEvidence.fences
  | ["frozen-exits"] => Plumb.Qualification.FrozenExit.check
  | ["documentation-source"] => Plumb.Qualification.DocumentationSource.check false
  | ["documentation-source", "--source-read-only"] => Plumb.Qualification.DocumentationSource.check true
  | _ => throw <| IO.userError "usage: lake exe qualify registry|native|combined|native-launcher|producers [--evidence PATH]|environments --evidence PATH|acceptance GROUP --evidence PATH|acceptance-snapshots dependencies|history|self-audit|git-status|all|documentation-dependencies|input-inventory|history|closure-evidence|configuration-capture|fence-evidence|frozen-exits|documentation-source [--source-read-only]|rule-examples --evidence PATH [--rules RULE ... | --shard K/N]"

/-- Standalone commands get one group-wide 420-second bound. The private protocol flag
is supplied by this wrapper or the already timed acceptance driver, never documented
as a bounded standalone command. Nested commands do not create escaping groups. -/
unsafe def main (args : List String) : IO UInt32 := do
  if (← IO.getEnv "PLUMB_RECEIPT_TIMER") == some "1" && args == ["--version"] then
    return ← Plumb.Qualification.ReceiptBoundary.worker args
  match ← IO.getEnv "PLUMB_QUALIFICATION_WRAPPER" with
  | some "acceptance" => return ← Plumb.Qualification.Acceptance.worker args
  | some "inventory" => return ← Plumb.Qualification.InputInventory.worker args
  | some _ => throw <| IO.userError "unknown qualification wrapper mode"
  | none => pure ()
  match args with
  | "--under-deadline" :: "--attempt" :: attempt :: rest => dispatch rest (some attempt); return 0
  | "--under-deadline" :: rest => dispatch rest; return 0
  | _ =>
    -- Recognize evidence destinations even when later argument validation refuses.
    -- This must precede timeout selection and spawning, both of which can fail.
    let attempt ← Plumb.Qualification.freshAttempt
    match args with
    | "acceptance" :: group :: "--evidence" :: path :: _ =>
      let _ ← Plumb.Qualification.Acceptance.beginAttempt group ⟨path⟩ attempt
    | "environments" :: "--evidence" :: path :: _ =>
      Plumb.Qualification.EnvironmentCensus.beginAttempt ⟨path⟩ attempt
    | "rule-examples" :: "--evidence" :: path :: _ =>
      Plumb.Qualification.RuleExamples.beginAttempt ⟨path⟩ attempt
    | _ => pure ()
    Plumb.Qualification.runBounded (← IO.currentDir) 420 (← IO.appPath).toString
      (#["--under-deadline", "--attempt", attempt] ++ args.toArray)
