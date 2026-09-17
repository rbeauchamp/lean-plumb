import StrictLean.Qualification.RegistryCli
import StrictLean.Qualification.NativeLinter
import StrictLean.Qualification.Producer
import StrictLean.Qualification.History

/-! One Lake executable for operational qualification, with independently selectable
campaigns. Each oracle is proved on the positive `StrictLeanQualification` surface;
this process dispatcher and its IO adapters remain operational tooling. -/

/-- Explicit commands; unknown or extra arguments refuse instead of silently skipping
work. The acceptance shell owns the overall deadline, not this dispatcher. -/
private def dispatch (args : List String) : IO Unit := do
  match args with
  | ["registry"] => StrictLean.Qualification.RegistryCli.check
  | ["native"] => StrictLean.Qualification.NativeLinter.checkAll
  | ["producers"] => StrictLean.Qualification.Producer.check none
  | ["producers", "--evidence", path] => StrictLean.Qualification.Producer.check (some ⟨path⟩)
  | ["history"] => StrictLean.Qualification.History.check
  | _ => throw <| IO.userError "usage: lake exe qualify registry|native|producers [--evidence PATH]|history"

/-- Standalone commands get one group-wide 420-second bound. The private protocol flag
is supplied by this wrapper or the already timed acceptance driver, never documented
as a bounded standalone command. Nested commands do not create escaping groups. -/
def main (args : List String) : IO UInt32 := do
  match args with
  | "--under-deadline" :: rest => dispatch rest; return 0
  | _ => StrictLean.Qualification.runBounded (← IO.currentDir) 420 (← IO.appPath).toString (#["--under-deadline"] ++ args.toArray)
