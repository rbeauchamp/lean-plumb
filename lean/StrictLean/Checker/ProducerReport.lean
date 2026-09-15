import StrictLean.Report

/-! Operational producer transport and key reconciliation. Kept outside the force-loaded
report module so ordinary admission does not replay JSON-validator implementation. -/
namespace StrictLean.Checker.ProducerReport
open Lean StrictLeanPolicy
open StrictLean.Checker.PolicyCodec (exactFields)
open scoped StrictLean.Report

abbrev Census := StrictLean.Report.Census
deriving instance ToJson for StrictLean.Report.Census

instance : FromJson Census := ⟨fun j => do
  exactFields j ["modules", "declarations", "executionRoots"]
  return { modules := ← j.getObjValAs? _ "modules"
           declarations := ← j.getObjValAs? _ "declarations"
           executionRoots := ← j.getObjValAs? _ "executionRoots" }⟩

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

/-- Operational producer account extends the unchanged pure policy observations.
The interactive probe alone has no admission/documentation receipt. Trusted loaders supply
both; a consumer must validate the account before using its results. -/
structure Environment extends StrictLean.Report.Collected where
  admission : Option AdmissionReceipt := none
  documentation : Option DocumentationObservation := none
  deriving Repr

instance : ToJson Environment := ⟨fun r => Json.mkObj [
  ("toolchain", toJson r.toolchain), ("modules", toJson r.modules),
  ("moduleOrigins", toJson r.moduleOrigins), ("declarations", toJson r.declarations),
  ("execution", toJson r.execution), ("census", toJson r.census),
  ("admission", toJson r.admission), ("documentation", toJson r.documentation)]⟩

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

instance : FromJson Environment := ⟨fun j => do
  exactFields j ["toolchain", "modules", "moduleOrigins", "declarations", "execution",
    "census", "admission", "documentation"]
  let r : Environment := {
    toolchain := ← j.getObjValAs? _ "toolchain"
    modules := ← j.getObjValAs? _ "modules"
    moduleOrigins := ← j.getObjValAs? _ "moduleOrigins"
    declarations := ← j.getObjValAs? _ "declarations"
    execution := ← j.getObjValAs? _ "execution"
    census := ← j.getObjValAs? _ "census"
    admission := ← j.getObjValAs? _ "admission"
    documentation := ← j.getObjValAs? _ "documentation"
  }
  r.validate
  return r⟩

end StrictLean.Checker.ProducerReport
