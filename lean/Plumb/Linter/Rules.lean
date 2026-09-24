module

public import Plumb.Collect
public import Plumb.Findings
public import PlumbPolicy.Decision

public section

/-! Local declaration decisions reuse the executed pure policy. Deferred role
observations are explicit; a snapshot result is never whole-project acceptance. -/
namespace Plumb.Linter.Rules
open Lean
open PlumbPolicy

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
def needsRoleEvidence (d : PlumbPolicy.Declaration) : DeclarationFailure → Bool
  | .projectAxiom => (nativeParent? d.name).isSome
  | .unknownAxiom => d.axioms.any fun name => (nativeParent? name).isSome
  | .escapeHatch => d.unsafeRecBase.isSome
  | _ => false

/-- Assess the selected records, retaining original structural identities/ranges.
This runs no native replay, external process, project build or global role scan. -/
def declarations (ds : Array PlumbPolicy.Declaration) (source : SourceSnapshot)
    (inspection : InspectionRequest) : Except String SnapshotResult := do
  let inventory ← admitInventory ds #[]
  let roles := authorize inventory
  let claim := match inspection with
    | .conforming p => some p.spelling
    | .classification => none
    | .teaching => some "compiler-trusting"
  let mut result : SnapshotResult := {}
  -- `admitInventory_exact` retains `ds`; iterating the inventory supplies membership.
  for h : d in inventory.declarations do
    if let some failure := checkedMemberFailure.run inventory roles d h inspection then
      if needsRoleEvidence d failure then
        result := { result with pending := result.pending.push d.name }
      else
        let id := ruleForFailure failure
        let location ← Findings.declarationLocation d (some source)
        let finding ← Findings.declarationFinding id d.name
          (descriptor id).applicability location .editorSnapshot claim
        result := { result with findings := result.findings.push finding }
  return result

end Plumb.Linter.Rules
