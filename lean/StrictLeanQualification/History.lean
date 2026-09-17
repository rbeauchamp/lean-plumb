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

/-- Source binding, registered private/imported roots, and reached-closure traversal
witnesses added upstream. Every parent index refers backward to an actually retained
edge; the exact node/visit account and recursive IR calls are retained. -/
def closureRequirements (account ownModule : Json) (source : String) (unsupported : Bool) : Except String (List Check) := do
  let bindings ← array account "sourceBindings"
  let snapshots ← bindings.toList.filterMapM fun entry => do
    if (← field entry "moduleName") == ownModule then return some (← text entry "content")
    return none
  let declarations ← array account "declarations"
  let some contract := declarations.find? (fun entry => (entry.getObjVal? "name").toOption == some (nameJson "privateContract"))
    | throw "missing private contract"
  let privateRoot ← field (← field contract "executableContract") "root"
  let census ← array (← field account "census") "declarations"
  let unregistered ← declarations.toList.filterMapM fun entry => do
    let names ← array entry "name"
    return if names[0]? == some (toJson #["str", "unregistered"]) then some entry else none
  let [unregistered] := unregistered | throw "missing or repeated private unregistered root"
  let hidden ← field unregistered "name"
  let execution ← array account "execution"
  let mut checks := [
    Check.mk "exact source snapshot" (snapshots == [source]),
    ⟨"registered private root executed", execution.any (fun entry => (entry.getObjVal? "name").toOption == some privateRoot)⟩,
    ⟨"registered private root inventoried", census.contains (toJson #[ownModule, privateRoot])⟩,
    ⟨"unregistered root private", (← unregistered.getObjValAs? Bool "private")⟩,
    ⟨"unregistered private root inventoried", census.contains (toJson #[ownModule, hidden])⟩,
    ⟨"unregistered private root not executed", execution.all (fun entry => (entry.getObjVal? "name").toOption != some hidden)⟩,
    ⟨"registered imported root executed", execution.any fun entry =>
      (entry.getObjVal? "name").toOption == some (toJson #[#["str", "add"], #["str", "Nat"]]) &&
      (entry.getObjVal? "module").toOption.any (fun moduleName => moduleName != ownModule)⟩]
  let mut recursive := false
  for root in execution do
    let closure ← field root "closure"
    let nodes ← array closure "nodes"
    let visits ← array closure "visits"
    let names ← visits.mapM (field · "name")
    let compiler ← array root "compilerEdges"
    let mut edges := compiler
    for key in #["logicalEdges", "candidateEdges", "historyEdges", "currentReplacementEdges", "helperEdges"] do
      edges := edges ++ (← array closure key)
    checks := checks ++ [⟨"exact unique closure visits", names.size == nodes.toList.eraseDups.length &&
      names.all nodes.contains && nodes.all names.contains⟩]
    for i in [:visits.size] do
      let visit := visits[i]!
      let parent ← field visit "parent"
      let name ← field visit "name"
      if parent == Json.null then
        checks := checks ++ [⟨"root visit has no parent", i == 0 && name == (← field root "name")⟩]
      else
        let index ← parent.getNat?
        let predecessor ← match visits[index]? with
          | some value => field value "name"
          | none => throw "parent outside traversal"
        checks := checks ++ [⟨"backward retained parent edge", index < i && edges.contains (toJson #[predecessor, name])⟩]
    for edge in edges do
      let pair ← edge.getArr?
      let [a, b] := pair.toList | throw "invalid closure edge"
      checks := checks ++ [⟨"edge endpoints covered", nodes.contains a && nodes.contains b⟩]
    recursive := recursive || compiler.any (fun edge => edge == toJson #[nameJson "recursiveSum", nameJson "recursiveSum"])
    if (← field root "name") == nameJson "reference" then
      let current ← array closure "currentReplacementEdges"
      let history ← array closure "historyEdges"
      checks := checks ++ [⟨"current replacement retained", current.contains (toJson #[nameJson "reference", nameJson "target"])⟩,
        ⟨"earlier replacement remains historical", unsupported || (history.contains (toJson #[nameJson "reference", nameJson "earlier"]) &&
          !current.contains (toJson #[nameJson "reference", nameJson "earlier"]))⟩]
  return checks ++ [⟨"recursive IR calls retained", recursive⟩]

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
  return checks ++ (← closureRequirements account ownModule source unsupported)

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
