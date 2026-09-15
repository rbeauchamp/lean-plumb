import StrictLean.DiagnosticCodec

/-! Shared website metadata and checked-example interfaces. Canonical metadata and
validation credit con-leche (RuleId); presentation credits Verso and Microsoft CA1416,
not their rule semantics. Collector completion remains an explicit trusted boundary. -/
namespace StrictLean.Website
open Lean RegistryCodec

/-- Policy rejection may follow successful elaboration; it is not a compiler failure. -/
inductive ExampleExpectation where
  | positive
  | compilerRejection (expectedMessage : String)
  | policyRejection (rule : RuleId) (subreason : String)
  | trustedTeaching

/-- Only a completed collector may supply a classified outcome. -/
inductive ExampleOutcome where
  | incomplete (detail : String)
  | compilerRejected (messages : Array String)
  | checked (findings : Array Finding) (compilerTeaching : Bool)

def validateExample (expected : ExampleExpectation) (outcome : ExampleOutcome) : Except String Unit := do
  match expected, outcome with
  | .positive, .checked findings false =>
      unless findings.isEmpty do throw "unexpected diagnostics in positive example"
  | .trustedTeaching, .checked findings true =>
      unless findings.isEmpty do throw "unexpected diagnostics in trusted teaching example"
  | .compilerRejection text, .compilerRejected messages =>
      unless !text.isEmpty && messages.any (·.contains text) do throw "wrong compiler rejection"
  | .policyRejection rule subreason, .checked findings false =>
      unless !subreason.isEmpty && subreason == (descriptor rule).applicability && findings.size == 1 do
        throw "wrong policy diagnostic expectation"
      let some finding := findings[0]? | throw "missing policy diagnostic"
      unless finding.1 == rule && finding.2.impact == .violation do throw "wrong policy rejection"
      match finding.2.location with
      | .source _ => pure ()
      | _ => throw "policy example requires its real primary source range"
  | _, .incomplete detail => throw s!"example collection incomplete: {detail}"
  | _, _ => throw "example outcome does not match its classification"

/-- This artifact list is supplied by the builder after inspecting its actual output tree. -/
def parsePage (j : Json) : Except String Page := do
  let rule ← parseRule (← j.getObjVal? "id")
  let route ← (← j.getObjVal? "route").getStr?
  let checkedExample ← (← j.getObjVal? "checkedExample").getBool?
  let advertisedEnforced ← (← j.getObjVal? "advertisedEnforced").getBool?
  unless j == Json.mkObj [("id", ruleJson rule), ("route", toJson route),
    ("checkedExample", toJson checkedExample), ("advertisedEnforced", toJson advertisedEnforced)] do
    throw "unknown page fields"
  return ⟨rule, route, checkedExample, advertisedEnforced⟩

/-- Required IDs come from the selected site scope plus every emitted example diagnostic.
Production #15 uses its full scope; the bounded prototype explicitly selects one rule. -/
def validateArtifact (p : ProducerIdentity) (manifest artifact : Json) : Except String Unit := do
  let required ← (← (← artifact.getObjVal? "required").getArr?).toList.mapM parseRule
  let emitted ← (← (← artifact.getObjVal? "emitted").getArr?).toList.mapM parseRule
  let rawPages ← (← artifact.getObjVal? "pages").getArr?
  let pages ← rawPages.toList.mapM parsePage
  unless artifact == Json.mkObj [("required", toJson (required.map ruleJson)),
    ("emitted", toJson (emitted.map ruleJson)), ("pages", toJson rawPages)] do
    throw "unknown artifact fields"
  unless emitted.all (fun id => required.contains id) do throw "emitted diagnostic has no required page"
  validatePages p manifest required pages
end StrictLean.Website
