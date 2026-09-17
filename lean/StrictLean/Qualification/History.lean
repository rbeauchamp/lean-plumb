import StrictLean.Qualification.SourceEvidence
import StrictLeanQualification.History

/-! Actual project/file history qualification. Sources and output paths are isolated;
positive/unsupported/restored controls all discard generated build artifacts. -/
namespace StrictLean.Qualification.History
open Lean

private def source := "import Lean\nimport StrictLean.Contract\n/-! Two callers preserve an earlier implementation overwritten after compilation. -/\ndef earlier (n : Nat) : Nat := n + 0\ndef target (n : Nat) : Nat := n\n@[implemented_by earlier] def reference (n : Nat) : Nat := n\ndef first (n : Nat) : Nat := reference n\nattribute [implemented_by target] reference\ndef second (n : Nat) : Nat := reference n\ndef recursiveSum : List Nat → Nat\n  | [] => 0\n  | x :: xs => x + recursiveSum xs\nprivate def unused (xs : List Nat) : Nat := recursiveSum xs\nprivate def unregistered (xs : List Nat) : Nat := recursiveSum xs\ntheorem privateContract : StrictLean.ExecutableContract unused\n    (fun f => ∀ xs, f xs = recursiveSum xs) := ⟨by intro xs; rfl⟩\ntheorem importedContract : StrictLean.ExecutableContract Nat.add\n    (fun f => ∀ n m, f n m = n + m) := ⟨by intros; rfl⟩\n-- evaluator control\n"

/-- Seventeen real public invocations retain exact requests, source binding, outcomes and
both replacement targets. The transport mutation campaign consumes a real restored report. -/
def check : IO Unit := do
  let root ← rootDirectory
  withScratch root "history-controls" fun project => do
    prepareProject root project "history_adopter" "standard-logical"
      "All three implementations compute the identity."
    for (invocation, flags, mode) in #[
        ("project", #[], "freshProject"), ("incremental", #["--incremental"], "incrementalProject"),
        ("file", #["--file", "Example.lean", "--claim", "standard-logical", "--execution", "checked"], "freshFile")] do
      let phases := #["positive", "unsupported", "restored"] ++
        (if invocation == "incremental" then #[] else #["admission", "restored", "source-change", "restored"])
      for index in [:phases.size] do
        let phase := phases[index]!
        let mutation := if phase == "unsupported" then "run_cmd pure ()"
          else if phase == "admission" then SourceEvidence.unchecked
          else if phase == "source-change" then "run_cmd do\n  let path ← Lean.getFileName\n  let content ← IO.FS.readFile path\n  IO.FS.writeFile path (content ++ \"\\n\")\n"
          else "-- evaluator control"
        let source := source.replace "-- evaluator control" mutation
        IO.FS.writeFile (project / "Example.lean") source
        clearBuild project
        let output := project / s!"{invocation}-{index}-{phase}.json"
        let (result, report) ← observeProject root project output flags
        if phase == "admission" || phase == "source-change" then
          let reason := if phase == "admission" then "kernel-admission" else "producer-source: source snapshot changed"
          IO.ofExcept (StrictLeanQualification.Evidence.checkedValidation.run {
            failure := true, mode := some mode, status := "incomplete", ids := ["SL2005"], reason,
            impact := some "incomplete", diagnosticMode := some mode }
            result.exitCode.toNat (result.stdout ++ result.stderr) (some report))
          requireChecks [⟨"exact history evidence exit", result.exitCode == 1⟩]
          if phase == "admission" then
            let ds ← IO.ofExcept (report.getObjValAs? (Array Json) "diagnostics")
            for d in ds do
              requireChecks [⟨"intended unchecked theorem", (← IO.ofExcept (StrictLeanQualification.Evidence.detail d)).contains "admissionFalse"⟩]
          IO.println s!"source {invocation}/{phase}: exact SL2005 incomplete PASS"
          continue
        IO.ofExcept (StrictLeanQualification.History.checkedValidation.run report result.exitCode.toNat
          mode source (invocation == "file") (phase == "unsupported"))
        if invocation == "file" && phase == "positive" then
          let scope ← IO.ofExcept (report.getObjVal? "scope")
          let account ← IO.ofExcept (scope.getObjVal? "report")
          let execution ← IO.ofExcept (account.getObjValAs? (Array Json) "execution")
          let importedName := toJson #[#["str", "add"], #["str", "Nat"]]
          let imported := execution.filter (fun entry => (entry.getObjVal? "name").toOption == some importedName)
          requireChecks [⟨"one imported control with existing ownership", imported.size == 1 && imported.all
            (fun entry => (entry.getObjVal? "module").toOption.isSome)⟩]
          let changed ← execution.mapM fun entry => do
            if (entry.getObjVal? "name").toOption != some importedName then return entry
            let fields ← IO.ofExcept entry.getObj?
            return Json.mkObj (fields.toList.filter (·.1 != "module"))
          let mutated := report.setObjVal! "scope" (scope.setObjVal! "report"
            (account.setObjVal! "execution" (toJson changed)))
          match StrictLeanQualification.History.checkedValidation.run mutated result.exitCode.toNat mode source true false with
          | .ok () => throw <| IO.userError "missing imported ownership accepted"
          | .error reason => requireChecks [⟨"intended imported-ownership refusal", reason == "registered imported root executed"⟩]
          IO.ofExcept (StrictLeanQualification.History.checkedValidation.run report result.exitCode.toNat mode source true false)
          IO.println "history oracle file/missing-imported-module: intended refusal + restored control PASS"
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
        if invocation == "project" && index == 2 then
          transportControl root "lean/StrictLean/Checker/HistoryQualification.lean" output
        IO.println s!"history {invocation}/{phase}: exact requests/source/outcome PASS"

end StrictLean.Qualification.History
