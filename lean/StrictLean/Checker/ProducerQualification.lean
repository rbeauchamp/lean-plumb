import StrictLean.Checker.ProducerReport
import StrictLean.Report

/-! Qualification of actual producer transport admission, using a real project report.
Mutations diagnose missing boundary checks; they are not universal collection proofs. -/
open Lean StrictLean.Report

def main (args : List String) : IO UInt32 := do
  let [path] := args | throw <| IO.userError "expected one actual report file"
  let envelope ← IO.ofExcept <| Json.parse (← IO.FS.readFile path)
  let scope ← IO.ofExcept <| envelope.getObjVal? "scope"
  let surfaces ← IO.ofExcept <| scope.getObjValAs? (Array Json) "surfaces"
  let some surface := surfaces[0]? | throw <| IO.userError "missing actual surface"
  let original ← IO.ofExcept <| surface.getObjVal? "report"
  let decode (j : Json) := (fromJson? j : Except String StrictLean.Checker.ProducerReport.Environment)
  let _ ← IO.ofExcept (decode original)
  let census ← IO.ofExcept <| original.getObjVal? "census"
  let receipt ← IO.ofExcept <| original.getObjVal? "admission"
  let docs ← IO.ofExcept <| original.getObjVal? "documentation"
  let keys ← IO.ofExcept <| census.getObjValAs? (Array Json) "declarations"
  unless !keys.isEmpty do throw <| IO.userError "control has no declaration census"
  let mutations := #[
    ("dropped-declarations", "producer-census", original.setObjVal! "declarations" (toJson (#[] : Array Json))),
    ("dropped-census", "producer-census", original.setObjVal! "census"
      (census.setObjVal! "declarations" (toJson (#[] : Array Json)))),
    ("duplicate-census", "producer-census", original.setObjVal! "census"
      (census.setObjVal! "declarations" (toJson (keys ++ keys)))),
    ("missing-admission", "producer-admission", original.setObjVal! "admission" .null),
    ("missing-replay", "producer-admission", original.setObjVal! "admission"
      (receipt.setObjVal! "admitted" (toJson (#[] : Array Json)))),
    ("missing-documentation", "producer-documentation", original.setObjVal! "documentation" .null),
    ("missing-module-doc-observation", "producer-documentation", original.setObjVal! "documentation"
      (docs.setObjVal! "modules" (toJson (#[] : Array Json)))),
    ("missing-material-observation", "producer-documentation", original.setObjVal! "documentation"
      (docs.setObjVal! "declarations" (toJson (#[] : Array Json))))]
  for (label, reason, mutated) in mutations do
    match decode mutated with
    | .ok _ => throw <| IO.userError s!"{label}: mutation was admitted"
    | .error error => unless error.contains reason do
        throw <| IO.userError s!"{label}: unrelated rejection: {error}"
    let _ ← IO.ofExcept (decode original)
    IO.println s!"producer transport {label}: intended refusal + restored control PASS"
  return 0
