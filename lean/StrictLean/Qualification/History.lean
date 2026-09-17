import StrictLean.Qualification.Project
import StrictLeanQualification.History

/-! Actual project/file history qualification. Sources and output paths are isolated;
positive/unsupported/restored controls all discard generated build artifacts. -/
namespace StrictLean.Qualification.History
open Lean

private def source := "import Lean\n/-! Two callers preserve an earlier implementation overwritten after compilation. -/\ndef earlier (n : Nat) : Nat := n + 0\ndef target (n : Nat) : Nat := n\n@[implemented_by earlier] def reference (n : Nat) : Nat := n\ndef first (n : Nat) : Nat := reference n\nattribute [implemented_by target] reference\ndef second (n : Nat) : Nat := reference n\n-- evaluator control\n"

/-- Nine real public invocations retain exact requests, source binding, outcomes and
both replacement targets. The transport mutation campaign consumes a real restored report. -/
def check : IO Unit := do
  let root ← rootDirectory
  withScratch root "history-controls" fun project => do
    prepareProject root project "history_adopter" "standard-logical"
      "All three implementations compute the identity."
    for (invocation, flags, mode) in #[
        ("project", #[], "freshProject"), ("incremental", #["--incremental"], "incrementalProject"),
        ("file", #["--file", "Example.lean", "--claim", "standard-logical", "--execution", "checked"], "freshFile")] do
      for phase in #["positive", "unsupported", "restored"] do
        let source := if phase == "unsupported" then source.replace "-- evaluator control" "run_cmd pure ()" else source
        IO.FS.writeFile (project / "Example.lean") source
        clearBuild project
        let output := project / s!"{invocation}-{phase}.json"
        let (result, report) ← observeProject root project output flags
        IO.ofExcept (StrictLeanQualification.History.checkedValidation.run report result.exitCode.toNat
          mode source (invocation == "file") (phase == "unsupported"))
        if phase == "unsupported" then
          let scope ← IO.ofExcept (report.getObjVal? "scope")
          let account ← IO.ofExcept (if invocation == "file" then scope.getObjVal? "report" else do
            let surfaces ← scope.getObjValAs? (Array Json) "surfaces"
            let some surface := surfaces[0]? | throw "missing surface"
            surface.getObjVal? "report")
          let execution ← IO.ofExcept (account.getObjValAs? (Array Json) "execution")
          let missingOne := execution.filter (fun entry =>
            (entry.getObjVal? "name").toOption != some (nameJson "reference"))
          requireChecks [⟨"missing-one mutation removes reference", missingOne.size < execution.size⟩]
          for (label, entries) in #[("missing-one-execution", missingOne), ("empty-execution", #[])] do
            let changed := account.setObjVal! "execution" (toJson entries)
            let changedScope ← IO.ofExcept (if invocation == "file" then pure (scope.setObjVal! "report" changed) else do
              let surfaces ← scope.getObjValAs? (Array Json) "surfaces"
              let some surface := surfaces[0]? | throw "missing surface"
              pure (scope.setObjVal! "surfaces" (toJson (surfaces.set! 0 (surface.setObjVal! "report" changed)))))
            let mutated := report.setObjVal! "scope" changedScope
            match StrictLeanQualification.History.checkedValidation.run mutated result.exitCode.toNat
                mode source (invocation == "file") true with
            | .ok () => throw <| IO.userError s!"{label}: missing evidence accepted"
            | .error reason => requireChecks [⟨"intended missing-execution refusal",
                reason == "every requested root has unresolved execution evidence"⟩]
            IO.ofExcept (StrictLeanQualification.History.checkedValidation.run report result.exitCode.toNat
              mode source (invocation == "file") true)
            IO.println s!"history oracle {invocation}/{label}: intended refusal + restored control PASS"
        requireChecks [⟨"history source unchanged", (← IO.FS.readFile (project / "Example.lean")) == source⟩]
        if invocation == "project" && phase == "restored" then
          transportControl root "lean/StrictLean/Checker/HistoryQualification.lean" output
        IO.println s!"history {invocation}/{phase}: exact requests/source/outcome PASS"

end StrictLean.Qualification.History
