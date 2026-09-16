import StrictLean.Report
import StrictLeanPolicy.Admission

/-! Operational producer transport and key reconciliation. Kept outside the force-loaded
report module so ordinary admission does not replay JSON-validator implementation. -/
namespace StrictLean.Checker.ProducerReport
open Lean StrictLeanPolicy
open StrictLean.Checker.PolicyCodec (exactFields)
open scoped StrictLean.Report

/-- A completed owned-admission attempt failed. The trusted operational path supplies
this outcome from the admission stage; raw data construction does not authenticate it.
Generic worker/import failures retain their own path. -/
structure AdmissionFailure where
  detail : String
  deriving Repr, ToJson

instance : FromJson AdmissionFailure := ⟨fun j => do
  exactFields j ["detail"]
  let detail ← j.getObjValAs? String "detail"
  if detail.isEmpty then throw "empty owned-admission failure"
  return ⟨detail⟩⟩

abbrev Census := StrictLean.Report.Census
deriving instance ToJson for StrictLean.Report.Census

instance : FromJson Census := ⟨fun j => do
  exactFields j ["modules", "declarations", "executionRoots", "historyRequests"]
  return { modules := ← j.getObjValAs? _ "modules"
           declarations := ← j.getObjValAs? _ "declarations"
           executionRoots := ← j.getObjValAs? _ "executionRoots"
           historyRequests := ← j.getObjValAs? _ "historyRequests" }⟩

/-- Replay scope can exceed report scope. Required keys come from the original environment;
admitted keys are observed in the separately replayed kernel after `Environment.replay`. -/
structure AdmissionReceipt where
  modules : Array Name
  required : Array (Name × Name)
  admitted : Array (Name × Name)
  deriving Repr, ToJson

instance : FromJson AdmissionReceipt := ⟨fun j => do
  exactFields j ["modules", "required", "admitted"]
  return { modules := ← j.getObjValAs? _ "modules"
           required := ← j.getObjValAs? _ "required"
           admitted := ← j.getObjValAs? _ "admitted" }⟩

/-- Metadata presence is deliberately separate from prose adequacy. The material selector
is frozen before docstring lookup and retains exact owning modules, including empty modules. -/
structure DocumentationObservation where
  modules : Array (Name × Bool)
  materialDeclarations : Array (Name × Name)
  declarations : Array ((Name × Name) × Option String)
  deriving Repr, ToJson

instance : FromJson DocumentationObservation := ⟨fun j => do
  exactFields j ["modules", "materialDeclarations", "declarations"]
  return { modules := ← j.getObjValAs? _ "modules"
           materialDeclarations := ← j.getObjValAs? _ "materialDeclarations"
           declarations := ← j.getObjValAs? _ "declarations" }⟩

/-- Completed history preserves the exact Lean-resolved source before/after the worker.
Unavailable history has no successful source receipt or usable edge payload. -/
inductive HistoryOutcome where
  | completed (path before after : String) (replacements : Array (Name × Name))
  | unavailable (detail : String)
  deriving Repr

instance : ToJson HistoryOutcome := ⟨fun
  | .completed path before after edges => Json.mkObj [
      ("kind", toJson "completed"), ("path", toJson path), ("before", toJson before),
      ("after", toJson after), ("replacements", toJson edges)]
  | .unavailable detail => Json.mkObj [("kind", toJson "unavailable"), ("detail", toJson detail)]⟩

instance : FromJson HistoryOutcome := ⟨fun j => do
  match ← j.getObjValAs? String "kind" with
  | "completed" =>
    exactFields j ["kind", "path", "before", "after", "replacements"]
    return .completed (← j.getObjValAs? _ "path") (← j.getObjValAs? _ "before")
      (← j.getObjValAs? _ "after") (← j.getObjValAs? _ "replacements")
  | "unavailable" =>
    exactFields j ["kind", "detail"]
    return .unavailable (← j.getObjValAs? _ "detail")
  | _ => throw "producer-history: unknown outcome"⟩

/-- Only a completed receipt supplies execution edges; failure remains explicit. -/
def HistoryOutcome.edges : HistoryOutcome → Except String (Array (Name × Name))
  | .completed _ _ _ edges => .ok edges
  | .unavailable detail => .error detail

/-- Exact source observed for one owned module; the caller binds it to the build
request. Paths identify files, while content equality binds their actual text. -/
structure SourceBinding where
  moduleName : Name
  path : String
  content : String
  deriving Repr, DecidableEq, ToJson

instance : FromJson SourceBinding := ⟨fun j => do
  exactFields j ["moduleName", "path", "content"]
  return { moduleName := ← j.getObjValAs? _ "moduleName"
           path := ← j.getObjValAs? _ "path"
           content := ← j.getObjValAs? _ "content" }⟩

/-- Operational producer account extends the unchanged pure policy observations.
The interactive probe alone has no admission/documentation receipt. Trusted loaders supply
both; a consumer must validate the account before using its results. -/
structure Environment extends StrictLean.Report.Collected where
  admission : Option AdmissionReceipt := none
  documentation : Option DocumentationObservation := none
  histories : Array (Name × HistoryOutcome) := #[]
  sourceBindings : Array SourceBinding := #[]
  deriving Repr

instance : ToJson Environment := ⟨fun r => Json.mkObj [
  ("toolchain", toJson r.toolchain), ("modules", toJson r.modules),
  ("moduleOrigins", toJson r.moduleOrigins), ("declarations", toJson r.declarations),
  ("execution", toJson r.execution), ("census", toJson r.census),
  ("admission", toJson r.admission), ("documentation", toJson r.documentation),
  ("histories", toJson r.histories), ("sourceBindings", toJson r.sourceBindings)]⟩

/-- Exact key reconciliation at the producer and transport admission boundaries. This
checks supplied observations; truthful Lean/Lake extraction remains the trusted boundary. -/
def Environment.validate (r : Environment) : Except String Unit := do
  unless !r.census.modules.isEmpty &&
      (canonicalNames r.census.modules).size == r.census.modules.size &&
      r.census.modules.all r.modules.contains do
    throw "producer-census: missing or duplicate claimed modules"
  unless (canonicalEdges r.census.declarations).size == r.census.declarations.size &&
      r.census.declarations == r.declarations.map (fun d => (d.module, d.name)) &&
      r.census.declarations.all (fun k => r.census.modules.contains k.1) do
    throw "producer-census: declaration coverage mismatch"
  match r.census.executionRoots with
  | none => unless r.execution.isEmpty do throw "producer-census: unrequested execution results"
  | some roots =>
    unless (canonicalEdges roots).size == roots.size &&
        roots == r.execution.map (fun root => (root.module, root.name)) &&
        roots.all (fun key => r.modules.contains key.1) do
      throw "producer-census: execution root coverage mismatch"
  match admitExecution r.execution with
  | .error _ => throw "producer-closure: invalid reached-node, edge, or boundary account"
  | .ok _ => pure ()
  unless (canonicalNames (r.sourceBindings.map (·.moduleName))).size == r.sourceBindings.size &&
      r.sourceBindings.all (fun s => !s.path.isEmpty && r.modules.contains s.moduleName) &&
      r.census.modules.all (fun m => r.sourceBindings.any (·.moduleName == m)) &&
      r.declarations.all (fun d => r.sourceBindings.any (fun s => s.moduleName == d.module &&
        d.ranges.all (·.validFor s.content))) do
    throw "producer-source: source coverage or coordinates mismatch"
  let some receipt := r.admission | throw "producer-admission: missing replay receipt"
  let requiredSet := receipt.required.foldl (fun s k => s.insert k)
    ({} : Std.HashSet (Name × Name))
  unless (canonicalNames receipt.modules).size == receipt.modules.size &&
      (canonicalEdges receipt.required).size == receipt.required.size &&
      receipt.admitted == receipt.required &&
      receipt.required.all (fun k => receipt.modules.contains k.1) &&
      r.census.modules.all receipt.modules.contains &&
      r.declarations.all (fun d => d.isUnsafe || d.isPartial ||
        requiredSet.contains (d.module, d.name)) do
    throw "producer-admission: replay coverage mismatch"
  let some docs := r.documentation | throw "producer-documentation: missing observations"
  unless docs.modules.map (·.1) == r.census.modules &&
      (canonicalEdges docs.materialDeclarations).size == docs.materialDeclarations.size &&
      docs.materialDeclarations.all r.census.declarations.contains &&
      docs.declarations.map (·.1) == docs.materialDeclarations do
    throw "producer-documentation: selector coverage mismatch"

  let requests := r.census.historyRequests
  unless (canonicalEdges requests).size == requests.size &&
      requests.all (fun (root, mod) => r.execution.any (·.name == root) && r.modules.contains mod) &&
      r.histories.map (·.1) == canonicalNames (requests.map (·.2)) do
    throw "producer-history: request coverage mismatch"
  for (mod, outcome) in r.histories do
    match outcome with
    | .completed path before after edges =>
      unless !path.isEmpty && before == after &&
          edges.all (fun (a, b) => !a.isAnonymous && !b.isAnonymous) do
        throw "producer-history: invalid completed source observation"
      if let some source := r.sourceBindings.find? (·.moduleName == mod) then
        unless path == source.path && before == source.content do
          throw "producer-source: history differs from owned source snapshot"
    | .unavailable detail =>
      unless !detail.isEmpty && requests.all (fun (root, requested) => requested != mod ||
          r.execution.any (fun r => r.name == root && !r.unresolved.isEmpty)) do
        throw "producer-history: unavailable history without unresolved execution"
  for root in r.execution do
    for boundary in root.boundaries do
      if boundary.boundary == .runtimeReplacement then
        unless requests.contains (root.name, boundary.module) do
          throw "producer-history: unrequested runtime replacement"
        if root.unresolved.isEmpty then
          let some (_, .completed _ _ _ edges) := r.histories.find? (·.1 == boundary.module)
            | throw "producer-history: completed execution lacks history"
          let some replacement := boundary.replacement
            | throw "producer-history: runtime replacement target missing"
          unless edges.contains (boundary.name, replacement) do
            throw "producer-history: completed execution omits replacement history edge"
    let visits := root.closure.visits
    unless (visits.find? (·.name == root.name)).any (·.moduleName == some root.module) &&
        visits.all (fun v => v.moduleName.all r.modules.contains) &&
        root.boundaries.all (fun b =>
          (visits.find? (·.name == b.name)).any (·.moduleName == some b.module)) do
      throw "producer-closure: reached module attribution mismatch"
    let boundaryEdges (kind : BoundaryKind) := canonicalEdges <| root.boundaries.filterMap fun b =>
      if b.boundary == kind then b.replacement.map (b.name, ·) else none
    unless boundaryEdges .compilerSimplification == root.closure.candidateEdges &&
        boundaryEdges .runtimeReplacement == canonicalEdges
          (root.closure.historyEdges ++ root.closure.currentReplacementEdges) do
      throw "producer-closure: replacement boundary coverage mismatch"
    let mut expectedHistory := #[]
    for edge in root.closure.currentReplacementEdges do
      let some visit := visits.find? (·.name == edge.1)
        | throw "producer-closure: replacement reference is not reached"
      let some mod := visit.moduleName
        | throw "producer-closure: replacement module is unavailable"
      unless requests.contains (root.name, mod) do
        throw "producer-closure: replacement history request is missing"
      let some (_, outcome) := r.histories.find? (·.1 == mod)
        | throw "producer-closure: replacement history outcome is missing"
      if let .completed _ _ _ edges := outcome then
        expectedHistory := expectedHistory ++ edges.filter (·.1 == edge.1)
    unless canonicalEdges expectedHistory == root.closure.historyEdges do
      throw "producer-closure: historical edges differ from their source receipts"

instance : FromJson Environment := ⟨fun j => do
  exactFields j ["toolchain", "modules", "moduleOrigins", "declarations", "execution",
    "census", "admission", "documentation", "histories", "sourceBindings"]
  let r : Environment := {
    toolchain := ← j.getObjValAs? _ "toolchain"
    modules := ← j.getObjValAs? _ "modules"
    moduleOrigins := ← j.getObjValAs? _ "moduleOrigins"
    declarations := ← j.getObjValAs? _ "declarations"
    execution := ← j.getObjValAs? _ "execution"
    census := ← j.getObjValAs? _ "census"
    admission := ← j.getObjValAs? _ "admission"
    documentation := ← j.getObjValAs? _ "documentation"
    histories := ← j.getObjValAs? _ "histories"
    sourceBindings := ← j.getObjValAs? _ "sourceBindings"
  }
  r.validate
  return r⟩

/-- Successful transport completion is distinct from successful logical admission. -/
inductive Outcome where
  | reported (report : Environment)
  | admissionFailed (failure : AdmissionFailure)

def Outcome.ofExcept : Except AdmissionFailure Environment → Outcome
  | .ok report => .reported report
  | .error failure => .admissionFailed failure

instance : ToJson Outcome := ⟨fun
  | .reported report => Json.mkObj [("kind", toJson "reported"), ("report", toJson report)]
  | .admissionFailed failure => Json.mkObj [("kind", toJson "admissionFailed"), ("failure", toJson failure)]⟩

instance : FromJson Outcome := ⟨fun j => do
  match ← j.getObjValAs? String "kind" with
  | "reported" =>
    exactFields j ["kind", "report"]
    return .reported (← j.getObjValAs? _ "report")
  | "admissionFailed" =>
    exactFields j ["kind", "failure"]
    return .admissionFailed (← j.getObjValAs? _ "failure")
  | _ => throw "unknown environment producer outcome"⟩

end StrictLean.Checker.ProducerReport
