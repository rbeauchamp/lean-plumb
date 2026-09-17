import StrictLean.Checker.ProducerReport

/-! Mutations of a real history-bearing report at its actual transport boundary.
These controls qualify refusal behavior; they do not authenticate serialized source bytes. -/
open Lean

def main (args : List String) : IO UInt32 := do
  let [path] := args | throw <| IO.userError "expected one actual project report"
  let envelope ← IO.ofExcept <| Json.parse (← IO.FS.readFile path)
  let scope ← IO.ofExcept <| envelope.getObjVal? "scope"
  let surfaces ← IO.ofExcept <| scope.getObjValAs? (Array Json) "surfaces"
  let some surface := surfaces[0]? | throw <| IO.userError "missing actual surface"
  let original ← IO.ofExcept <| surface.getObjVal? "report"
  let decode (j : Json) := (fromJson? j : Except String StrictLean.Checker.ProducerReport.Environment)
  let _ ← IO.ofExcept (decode original)
  let census ← IO.ofExcept <| original.getObjVal? "census"
  let requests ← IO.ofExcept <| census.getObjValAs? (Array Json) "historyRequests"
  let histories ← IO.ofExcept <| original.getObjValAs? (Array Json) "histories"
  let some first := histories[0]? | throw <| IO.userError "control has no histories"
  let pair ← IO.ofExcept <| first.getArr?
  let some mod := pair[0]? | throw <| IO.userError "missing module"
  let some outcome := pair[1]? | throw <| IO.userError "missing outcome"
  let history (outcome : Json) := original.setObjVal! "histories"
    (toJson (histories.set! 0 (toJson #[mod, outcome])))
  let empty := toJson (#[] : Array Json)
  let mutations := #[
    ("dropped-history", "producer-history: request coverage mismatch", original.setObjVal! "histories" empty),
    ("dropped-requests", "producer-history: request coverage mismatch", original.setObjVal! "census" (census.setObjVal! "historyRequests" empty)),
    ("duplicate-requests", "producer-history: request coverage mismatch", original.setObjVal! "census"
      (census.setObjVal! "historyRequests" (toJson (requests ++ requests)))),
    ("changed-source", "producer-history: invalid completed source observation", history (outcome.setObjVal! "after" (toJson "changed"))),
    ("missing-path", "producer-history: invalid completed source observation", history (outcome.setObjVal! "path" (toJson ""))),
    ("missing-edges", "producer-history: completed execution omits replacement history edge", history (outcome.setObjVal! "replacements" empty)),
    ("unavailable-completed", "producer-history: unavailable history without unresolved execution", history (Json.mkObj [("kind", toJson "unavailable"), ("detail", toJson "unavailable")])),
    ("hidden-requests-and-history", "producer-history: unrequested runtime replacement", (original.setObjVal! "histories" empty).setObjVal! "census"
      (census.setObjVal! "historyRequests" empty))]
  for (label, expected, mutated) in mutations do
    match decode mutated with
    | .ok _ => throw <| IO.userError s!"{label}: mutation admitted"
    | .error error => unless error == expected do
        throw <| IO.userError s!"{label}: unrelated rejection: {error}"
    let _ ← IO.ofExcept (decode original)
    IO.println s!"history transport {label}: intended refusal + restored control PASS"
  let observed ← IO.ofExcept (decode original)
  let some index := observed.execution.findIdx? (fun root =>
      !root.closure.currentReplacementEdges.isEmpty && !root.closure.historyEdges.isEmpty)
    | throw <| IO.userError "control has no replacement-bearing closure"
  let some root := observed.execution[index]?
    | throw <| IO.userError "selected closure index unavailable"
  let mutate (changed : StrictLean.Report.ExecutionRoot) := toJson
    { observed with execution := observed.execution.set! index changed }
  let invalid := "producer-closure: invalid reached-node, edge, or boundary account"
  let closureMutations := #[
    ("omitted-root", invalid, mutate {root with closure := {root.closure with nodes := root.closure.nodes.filter (· != root.name)}}),
    ("omitted-visit", invalid, mutate {root with closure := {root.closure with visits := root.closure.visits.pop}}),
    ("cyclic-discovery", invalid, mutate {root with closure := {root.closure with visits := root.closure.visits.modify 0 (fun v => {v with parent := some 0})}}),
    ("misclassified-history-channel", "producer-closure: replacement boundary coverage mismatch",
      mutate {root with closure := {root.closure with
        historyEdges := #[]
        logicalEdges := StrictLeanPolicy.canonicalEdges (root.closure.logicalEdges ++ root.closure.historyEdges)}}),
    ("omitted-boundary", "producer-closure: replacement boundary coverage mismatch",
      mutate {root with boundaries := root.boundaries.filter (·.boundary != .runtimeReplacement)}),
    ("wrong-module", "producer-closure: reached module attribution mismatch",
      mutate {root with closure := {root.closure with visits := root.closure.visits.modify 0 (fun v => {v with moduleName := none})}}),
    ("missing-code-account", invalid,
      mutate {root with closure := {root.closure with requiredCode := #[]}})]
  for (label, expected, mutated) in closureMutations do
    match decode mutated with
    | .ok _ => throw <| IO.userError s!"{label}: mutation admitted"
    | .error error => unless error == expected do
        throw <| IO.userError s!"{label}: unrelated rejection: {error}"
    let _ ← IO.ofExcept (decode original)
    IO.println s!"closure transport {label}: intended refusal + restored control PASS"
  let bindings ← IO.ofExcept <| original.getObjValAs? (Array Json) "sourceBindings"
  let some source := bindings[0]? | throw <| IO.userError "control has no owned source snapshot"
  let sourceMutations := #[
    ("missing-source", "producer-source: source coverage or coordinates mismatch",
      original.setObjVal! "sourceBindings" empty),
    ("changed-history-source", "producer-source: history differs from owned source snapshot",
      original.setObjVal! "sourceBindings" (toJson (bindings.set! 0 (source.setObjVal! "content"
        (toJson ((← IO.ofExcept <| source.getObjValAs? String "content") ++ "\n"))))))]
  for (label, expected, mutated) in sourceMutations do
    match decode mutated with
    | .ok _ => throw <| IO.userError s!"{label}: mutation admitted"
    | .error error => unless error == expected do
        throw <| IO.userError s!"{label}: unrelated rejection: {error}"
    let _ ← IO.ofExcept (decode original)
    IO.println s!"source transport {label}: intended refusal + restored control PASS"
  return 0
