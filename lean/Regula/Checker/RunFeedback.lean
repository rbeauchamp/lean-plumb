import Regula.Diagnostic

/-! # Run-level finding output

Every finding a checker process prints goes through `emit` or `emitAll`, which execute
`RegulaCore.Feedback.step`: the first finding of a rule in the run carries the rule's
requirement, rationale, rewrites and compliant example, and later findings of that rule carry
their own message and remedy with a back-reference (`Feedback.renderFrom_cons` relates the
steps to `Feedback.render`). `emitAll` prints a batch in run order (`sortFindings`, whose
entries are in `Feedback.sortEntries` order by `sortFindings_entries`).
The set of explained rules is process state, reset when a run starts (`reset`). -/

namespace Regula.Checker.RunFeedback

/-- Rules whose guidance this run already printed, most recent first. -/
initialize explained : IO.Ref (List RuleId) ← IO.mkRef []

/-- Start a run: no rule's guidance has been printed. -/
def reset : IO Unit := explained.set []

/-- Print one entry with `Feedback.step`. -/
def emitEntry (print : String → IO Unit) (entry : Feedback.Entry) : IO Unit := do
  let (line, seen) := Feedback.step (← explained.get) entry
  explained.set seen
  print line

/-- Print one finding in the run's text. -/
def emit (print : String → IO Unit) (finding : Finding) : IO Unit :=
  emitEntry print finding.entry

/-- Print a batch of findings in run order. -/
def emitAll (print : String → IO Unit) (findings : Array Finding) : IO Unit := do
  for finding in sortFindings findings.toList do
    emit print finding

end Regula.Checker.RunFeedback
