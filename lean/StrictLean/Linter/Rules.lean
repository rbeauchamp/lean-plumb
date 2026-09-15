module

public import StrictLean.Collect
public import StrictLean.Findings
public import StrictLeanPolicy.Decision

public section

/-! Local declaration decisions reuse the executed pure policy. Deferred role
observations are explicit; a snapshot result is never whole-project acceptance. -/
namespace StrictLean.Linter.Rules
open Lean
open StrictLeanPolicy

/-- Feedback contains actual findings and names that still need fresh evidence.
No accepted/project-PASS constructor exists at this scope. -/
structure SnapshotResult where
  findings : Array Finding := #[]
  pending : Array Name := #[]

/-- The editor's optional foundation request never supplies Lake surface authority. -/
def request (value : String) : Except String InspectionRequest :=
  if value == "classification-only" then .ok .classification
  else match ConformingProfile.parse? value with
    | some p => .ok (.conforming p)
    | none => .error s!"unsupported local foundation request: {value}"

/-- A missing fresh transcript cannot turn a possible generated-role exception
into either authorization or a definitive role-related violation. Other failures
retain the pure policy's precedence. -/
def needsRoleEvidence (d : StrictLeanPolicy.Declaration) : DeclarationFailure → Bool
  | .projectAxiom => (nativeParent? d.name).isSome
  | .unknownAxiom => d.axioms.any fun name => (nativeParent? name).isSome
  | .escapeHatch => d.unsafeRecBase.isSome
  | _ => false

/-- Assess the selected records, retaining original structural identities/ranges.
This runs no native replay, external process, project build or global role scan. -/
def declarations (ds : Array StrictLeanPolicy.Declaration) (source : SourceSnapshot)
    (inspection : InspectionRequest) : Except String SnapshotResult := do
  let inventory ← admitInventory ds #[]
  let roles := authorize inventory
  let claim := match inspection with
    | .conforming p => some p.spelling
    | .classification => none
    | .teaching => some "compiler-trusting"
  let mut result : SnapshotResult := {}
  for d in ds do
    if let some failure := policyFor inventory roles d inspection then
      if needsRoleEvidence d failure then
        result := { result with pending := result.pending.push d.name }
      else
        let id := ruleForFailure failure
        let location ← Findings.declarationLocation d (some source)
        let finding ← Findings.declarationFinding id d.name
          (descriptor id).applicability location .editorSnapshot claim
        result := { result with findings := result.findings.push finding }
  return result

end StrictLean.Linter.Rules
