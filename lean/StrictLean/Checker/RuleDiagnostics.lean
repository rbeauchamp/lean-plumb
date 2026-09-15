import StrictLean.RegistryCodec
import StrictLean.Checker.Policy

/-! Shared adapters from existing checker observations. These do not change policy.
Canonical construction credits con-leche as documented in StrictLean.RuleId. -/
namespace StrictLean.Checker.RuleDiagnostics
open Lean

/-- New diagnostic identity is recovered from the original structural Name only. -/
def declarationName (decl : Report.Declaration) : Except String Name := do
  unless decl.name != .anonymous do throw "anonymous declaration identity"
  return decl.name

def declarationFinding (id : RuleId) (name : Name) (detail : String)
    (location : Location) (mode : EvidenceMode) (claim : Option String) : Except String Finding :=
  let a : DeclarationArguments := ⟨name, detail⟩
  match id with
  | .projectAxiom => (fun d => ⟨.projectAxiom, d⟩) <$> makeDiagnostic .projectAxiom a location mode claim .violation
  | .proofHole => (fun d => ⟨.proofHole, d⟩) <$> makeDiagnostic .proofHole a location mode claim .violation
  | .unknownAxiom => (fun d => ⟨.unknownAxiom, d⟩) <$> makeDiagnostic .unknownAxiom a location mode claim .violation
  | .compilerTrusting => (fun d => ⟨.compilerTrusting, d⟩) <$> makeDiagnostic .compilerTrusting a location mode claim .violation
  | .profileExceeded => (fun d => ⟨.profileExceeded, d⟩) <$> makeDiagnostic .profileExceeded a location mode claim .violation
  | .escapeHatch => (fun d => ⟨.escapeHatch, d⟩) <$> makeDiagnostic .escapeHatch a location mode claim .violation
  | .executableContract => (fun d => ⟨.executableContract, d⟩) <$> makeDiagnostic .executableContract a location mode claim .violation
  | _ => .error s!"rule {id} is not an existing declaration policy diagnostic"

/-- Known context conditions keep their ID; unknown conditions remain incomplete. -/
def contextFinding (id : RuleId) (subject detail : String) (mode : EvidenceMode)
    (impact : Impact) : Except String Finding :=
  let a : ContextArguments := ⟨subject, detail⟩
  let location := Location.project subject
  match id with
  | .environment => (fun d => ⟨.environment, d⟩) <$> makeDiagnostic .environment a location mode none impact
  | .configuration => (fun d => ⟨.configuration, d⟩) <$> makeDiagnostic .configuration a location mode none impact
  | .sourceBuild => (fun d => ⟨.sourceBuild, d⟩) <$> makeDiagnostic .sourceBuild a location mode none impact
  | .coverage => (fun d => ⟨.coverage, d⟩) <$> makeDiagnostic .coverage a location mode none impact
  | .admission => (fun d => ⟨.admission, d⟩) <$> makeDiagnostic .admission a location mode none impact
  | .fenceStructure => (fun d => ⟨.fenceStructure, d⟩) <$> makeDiagnostic .fenceStructure a location mode none impact
  | .positiveExample => (fun d => ⟨.positiveExample, d⟩) <$> makeDiagnostic .positiveExample a location mode none impact
  | .negativeExample => (fun d => ⟨.negativeExample, d⟩) <$> makeDiagnostic .negativeExample a location mode none impact
  | .trustedExample => (fun d => ⟨.trustedExample, d⟩) <$> makeDiagnostic .trustedExample a location mode none impact
  | _ => .error s!"rule {id} requires another argument domain"

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
  | _ => throw "invalid execution diagnostic rule"

/-- A missing range has honest module attribution. A bad supplied range is an error. -/
def declarationLocation (decl : Report.Declaration) (snapshot : Option SourceSnapshot) :
    Except String Location := do
  match decl.ranges, snapshot with
  | some ranges, some source => return .source (← sourceFromReport source ranges)
  | _, _ => return .module decl.module

end StrictLean.Checker.RuleDiagnostics
