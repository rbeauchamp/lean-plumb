import Plumb.Findings
import Plumb.Checker.Policy

/-! Checker compatibility adapters for the public diagnostic constructors. -/
namespace Plumb.Checker.RuleDiagnostics
open Lean
abbrev declarationName := Plumb.Findings.declarationName
abbrev declarationFinding := Plumb.Findings.declarationFinding
abbrev contextFinding := Plumb.Findings.contextFinding
abbrev declarationLocation := Plumb.Findings.declarationLocation

/-- The diagnostic of one execution failure kind, typed by `Policy.executionRule` of that
kind, so its rule is the registry bridge's by construction. -/
def executionDiagnostic : (kind : PlumbPolicy.ExecutionFailureKind) → ExecutionArguments →
    Location → EvidenceMode → Policy.ExecutionClaim → Except String (Diagnostic (Policy.executionRule kind))
  | .executionUnresolved, a, location, mode, claim =>
      makeDiagnostic .executionUnresolved a location mode (some claim.toString) .incomplete
  | .executionBoundary, a, location, mode, claim =>
      makeDiagnostic .executionBoundary a location mode (some claim.toString) .violation

def executionFinding (failure : Policy.ExecutionFailure) (location : Location)
    (mode : EvidenceMode) (claim : Policy.ExecutionClaim) : Except String Finding := do
  let name := failure.root.name
  unless name != .anonymous do throw "anonymous execution root identity"
  return ⟨Policy.executionRule failure.id,
    ← executionDiagnostic failure.id ⟨name, failure.detail⟩ location mode claim⟩

end Plumb.Checker.RuleDiagnostics
