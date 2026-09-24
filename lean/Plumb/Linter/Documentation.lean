module

public meta import Plumb.MaterialClaim
public meta import Plumb.Findings
public meta import Lean.DocString

public meta section

/-! Module-doc and explicitly selected declaration-doc presence, using both of
Lean's documentation formats. Presence is distinct from adequacy and registration
completeness, which remain semantic review obligations. -/
namespace Plumb.Linter.Documentation
open Lean

/-- Read current or imported metadata. Callers establish completed elaboration
and load imported server data before treating absence as a completed observation. -/
def modulePresent (env : Environment) (moduleName : Name) : Except String Bool := do
  if moduleName == env.mainModule then
    return !(Lean.getMainModuleDoc env).isEmpty ||
      !(Lean.getMainVersoModuleDocs env).snippets.isEmpty
  let some markdown := Lean.getModuleDoc? env moduleName
    | throw s!"module documentation ownership is unavailable: {moduleName}"
  let some verso := Lean.getVersoModuleDoc? env moduleName
    | throw s!"Verso module documentation ownership is unavailable: {moduleName}"
  return !markdown.isEmpty || !verso.isEmpty

/-- Selector uses actual persistent registration and Lean's private-name convention. -/
def selected (env : Environment) (name : Name) : Bool :=
  materialClaimAttribute.hasTag env name && !Lean.isPrivateName name

/-- An inherited or Verso docstring counts according to Lean's own lookup. -/
def declarationPresent (env : Environment) (name : Name) : IO Bool := do
  return (← Lean.findDocString? env name).isSome

/-- The source-free module condition carries honest module attribution. -/
def moduleFinding (env : Environment) (moduleName : Name) (mode : EvidenceMode) :
    Except String (Option Finding) := do
  if ← modulePresent env moduleName then return none
  return some ⟨.moduleDocumentation, ← makeDiagnostic .moduleDocumentation
    ⟨moduleName.toString, "module-documentation: add a module doc comment describing this module"⟩
    (.module moduleName) mode none .violation⟩

/-- Only explicitly registered public declarations receive this obligation. -/
def declarationFinding (env : Environment) (decl : PlumbPolicy.Declaration)
    (snapshot : Option SourceSnapshot) (mode : EvidenceMode) : IO (Option Finding) := do
  if !selected env decl.name || (← declarationPresent env decl.name) then return none
  let location ← IO.ofExcept <| Findings.declarationLocation decl snapshot
  return some (← IO.ofExcept <| Findings.declarationFinding .materialDocumentation decl.name
    "material-documentation: document the claim, assumptions and evidence at this declaration"
    location mode none)

end Plumb.Linter.Documentation
