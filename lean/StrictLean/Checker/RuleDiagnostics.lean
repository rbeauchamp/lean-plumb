import StrictLean.Findings
import StrictLean.Checker.Policy

/-! Checker compatibility adapters for the public diagnostic constructors. -/
namespace StrictLean.Checker.RuleDiagnostics
open Lean
abbrev declarationName := StrictLean.Findings.declarationName
abbrev declarationFinding := StrictLean.Findings.declarationFinding
abbrev contextFinding := StrictLean.Findings.contextFinding
abbrev declarationLocation := StrictLean.Findings.declarationLocation

def executionFinding (failure : Policy.ExecutionFailure) (location : Location)
    (mode : EvidenceMode) (claim : Policy.ExecutionClaim) : Except String Finding := do
  let name := failure.root.name
  unless name != .anonymous do throw "anonymous execution root identity"
  let a : ExecutionArguments := ⟨name, failure.detail⟩
  match failure.id with
  | .executionUnresolved =>
      return ⟨.executionUnresolved, ← makeDiagnostic .executionUnresolved a location mode
        (some claim.toString) .incomplete⟩
  | .executionBoundary =>
      return ⟨.executionBoundary, ← makeDiagnostic .executionBoundary a location mode
        (some claim.toString) .violation⟩

end StrictLean.Checker.RuleDiagnostics
