import StrictLeanQualification.Json

/-! Source-bound history observation requirements. Checks compare the supplied report
with exact source, invocation, requests, and both overwritten replacement targets.
`checkedDecoded` supplies sound/complete refusal semantics for the decoded requirement
list. These are predicates on observations, not proofs of source evaluator behavior. -/
namespace StrictLeanQualification.History
open Lean

private def field (value : Json) (name : String) : Except String Json := value.getObjVal? name
private def array (value : Json) (name : String) : Except String (Array Json) := value.getObjValAs? _ name
private def text (value : Json) (name : String) : Except String String := value.getObjValAs? _ name
private def nameJson (name : String) : Json := toJson (name.splitOn "." |>.map fun part => #["str", part])

/-- Mandatory decoding plus all preserved history assertions. `fileMode` selects the
actual public report shape; unsupported evaluators require explicit unavailability,
never a successful empty history. -/
def requirements (report : Json) (code : Nat) (mode source : String)
    (fileMode unsupported : Bool) : Except String (List Check) := do
  let scope ← field report "scope"
  let account ← if fileMode then field scope "report" else do
    let surfaces ← array scope "surfaces"
    let some surface := surfaces[0]? | throw "missing history surface"
    field surface "report"
  let census ← field account "census"
  let requests ← array census "historyRequests"
  let modules ← array census "modules"
  let some ownModule := modules[0]? | throw "missing history module"
  let histories ← array account "histories"
  let owned ← histories.toList.filterMapM fun entry => do
    let pair ← entry.getArr?
    let some moduleName := pair[0]? | throw "missing history owner"
    let some history := pair[1]? | throw "missing history payload"
    return if moduleName == ownModule then some history else none
  let [history] := owned | throw "expected exactly one own history"
  let diagnostics ← array report "diagnostics"
  let ids ← diagnostics.toList.mapM (fun d => text d "id")
  let mut checks : List Check := [
    ⟨"history exit", code == (if unsupported then 1 else 0)⟩,
    ⟨"history mode", (← text report "mode") == mode⟩,
    ⟨"history diagnostics", ids.eraseDups == (if unsupported then ["SL3001"] else [])⟩,
    ⟨"history status", (← text report "status") == (if unsupported then "incomplete" else "completed")⟩,
    ⟨"nonempty unique history requests", !requests.isEmpty && requests.toList.eraseDups.length == requests.size⟩,
    ⟨"all three requested roots", ["reference", "first", "second"].all
      (fun root => requests.contains (toJson #[nameJson root, ownModule]))⟩]
  if unsupported then
    let execution ← array account "execution"
    let ownRequests ← requests.toList.filterMapM fun request => do
      let pair ← request.getArr?
      let [root, moduleName] := pair.toList | throw "invalid history request pair"
      return if moduleName == ownModule then some root else none
    let coverage := ownRequests.all fun root => execution.any fun entry =>
      (entry.getObjVal? "name").toOption == some root &&
        (entry.getObjValAs? (Array Json) "unresolved").toOption.any (! ·.isEmpty)
    let requested ← execution.toList.filterMapM fun entry => do
      let name ← field entry "name"
      if requests.contains (toJson #[name, ownModule]) then return some (← array entry "unresolved")
      return none
    checks := checks ++ [
      ⟨"unsupported history explicitly unavailable", (← text history "kind") == "unavailable"⟩,
      ⟨"unsupported evaluator reason", (← text history "detail").contains "unsupported replacement-history evaluators"⟩,
      ⟨"every requested root has unresolved execution evidence", coverage⟩,
      ⟨"requested execution unresolved", requested.all (! ·.isEmpty)⟩]
  else
    let replacements ← array history "replacements"
    checks := checks ++ [
      ⟨"history completed", (← text history "kind") == "completed"⟩,
      ⟨"history before binds source", (← text history "before") == source⟩,
      ⟨"history after binds source", (← text history "after") == source⟩,
      ⟨"history has Lean source path", (← text history "path").endsWith ".lean"⟩,
      ⟨"earlier replacement retained", replacements.contains (toJson #[nameJson "reference", nameJson "earlier"])⟩,
      ⟨"current replacement retained", replacements.contains (toJson #[nameJson "reference", nameJson "target"])⟩]
  return checks

/-- Exact admission contract for the decoded history requirements. Missing fields
refuse before assertion evaluation; all predicates in `requirements` must hold. -/
def validate (report : Json) (code : Nat) (mode source : String)
    (fileMode unsupported : Bool) : Except String Unit :=
  checkedDecoded.run (requirements report code mode source fileMode unsupported)

/-- The application cannot replace the history oracle with an always-successful or
always-refusing implementation while retaining this required equivalence. -/
theorem checkedValidation : StrictLean.ExecutableContract validate
    (fun run => ∀ report code mode source fileMode unsupported,
      run report code mode source fileMode unsupported = .ok () ↔
        ∃ checks, requirements report code mode source fileMode unsupported = .ok checks ∧ Satisfied checks) :=
  ⟨fun _ _ _ _ _ _ => validateDecoded_exact _⟩

end StrictLeanQualification.History
