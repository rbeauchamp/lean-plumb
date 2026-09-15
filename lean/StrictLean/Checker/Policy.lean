import StrictLean.Checker.Frontend
import StrictLeanPolicy.Decision
import StrictLeanPolicy.Execution
import StrictLean.Rule

/-! Exact foundation, generated-role, and computation policy over typed reports. -/

namespace StrictLean.Checker.Policy

open Lean (Name)
open StrictLean.Report
open StrictLeanPolicy (DeclarationKind BoundaryKind Correspondence FoundationClass)
open StrictLean.Checker.Frontend

abbrev ExecutionClaim := StrictLeanPolicy.ExecutionClaim
abbrev ExecutionClaim.parse? (s : String) : Option ExecutionClaim := StrictLeanPolicy.ExecutionClaim.parse? s
abbrev ExecutionClaim.toString (x : ExecutionClaim) : String := StrictLeanPolicy.ExecutionClaim.spelling x

inductive Profile where
  | kernelOnly
  | choiceFree
  | standardLogical
  | compilerTrusting
  deriving Repr, BEq, DecidableEq, Inhabited

namespace Profile

def parse? : String → Option Profile
  | "kernel-only" => some .kernelOnly
  | "choice-free" => some .choiceFree
  | "standard-logical" => some .standardLogical
  | "compiler-trusting" => some .compilerTrusting
  | _ => none

def toString : Profile → String
  | .kernelOnly => "kernel-only"
  | .choiceFree => "choice-free"
  | .standardLogical => "standard-logical"
  | .compilerTrusting => "compiler-trusting"

instance : ToString Profile := ⟨toString⟩


end Profile

/-- Adapter groups one admitted inventory with its recomputed role evidence. -/
structure PolicyScope where
  inventory : StrictLeanPolicy.Inventory
  roles : StrictLeanPolicy.Roles inventory

def admitScope (ds : Array Declaration) (ts : Array Transcript := #[]) : Except String PolicyScope := do
  for transcript in ts do Frontend.validateCoordinates ds transcript
  let inventory ← StrictLeanPolicy.admitInventory ds ts
  return ⟨inventory, StrictLeanPolicy.authorize inventory⟩

def PolicyScope.native (s : PolicyScope) : Array Name := s.roles.native
def PolicyScope.helpers (s : PolicyScope) : Array Name := s.roles.helpers

private def inspection : Option Profile → StrictLeanPolicy.InspectionRequest
  | none => .classification
  | some .compilerTrusting => .teaching
  | some .kernelOnly => .conforming .kernelOnly
  | some .choiceFree => .conforming .choiceFree
  | some .standardLogical => .conforming .standardLogical

abbrev declarationNeedsTranscript := StrictLeanPolicy.declarationNeedsTranscript
abbrev needsFrontendTranscript := StrictLeanPolicy.needsFrontendTranscript

def ruleFor (decl : Declaration) (claim : Option Profile) (scope : PolicyScope) : Option RuleId :=
  (StrictLeanPolicy.policyFor scope.inventory scope.roles decl (inspection claim)).map StrictLean.ruleForFailure

def reasonFor (decl : Declaration) (claim : Option Profile) (scope : PolicyScope) : Option String :=
  (ruleFor decl claim scope).map (fun id => (descriptor id).applicability)

def labelOf (decl : Declaration) (scope : PolicyScope) : Except String FoundationClass :=
  StrictLeanPolicy.foundationFor scope.inventory scope.roles decl

abbrev ExecutionInventory := StrictLeanPolicy.ExecutionInventory
abbrev admitExecution := StrictLeanPolicy.admitExecution

structure ExecutionFailure where
  id : RuleId
  root : StrictLean.Report.ExecutionRoot
  detail : String

def executionFailureRecords (inventory : ExecutionInventory)
    (claim : ExecutionClaim) : Array ExecutionFailure :=
  (StrictLeanPolicy.executionFailureRecords inventory claim).map fun f =>
    { id := match f.id with
        | .executionUnresolved => .executionUnresolved
        | .executionBoundary => .executionBoundary
      root := f.root, detail := f.detail }

/-- Existing text subreasons derive from the registry and the same decision records. -/
def executionFailures (inventory : ExecutionInventory)
    (claim : ExecutionClaim) : Array String :=
  (executionFailureRecords inventory claim).map fun failure =>
    s!"{(descriptor failure.id).applicability}: {failure.detail}"

/-- One-line rendering of a single execution boundary. -/
def describeBoundary (boundary : StrictLean.Report.ExecutionBoundary) : String :=
  let replacement := boundary.replacement.map (fun value => s!" replacement={value}") |>.getD ""
  let evidence := boundary.evidence.map (fun value => s!" evidence={value}") |>.getD ""
  let owned := if boundary.owned then " owned" else ""
  let callers := if boundary.compilerCallers.isEmpty then "" else
    s!" compiler-callers={boundary.compilerCallers}"
  s!"boundary {boundary.name} [{boundary.boundary}] " ++
    s!"correspondence={boundary.correspondence}{replacement}{evidence}{owned}{callers} " ++
    s!"(module {boundary.«module»})"

abbrev executionSummary := StrictLeanPolicy.executionSummary

def classify (decl : Declaration) (scope : PolicyScope) : String :=
  let flags := Id.run do
    let mut values : Array String := #[]
    if decl.kind == .«axiom» then values := values.push "AXIOM"
    if decl.isProp then values := values.push "Prop"
    if decl.«instance» then values := values.push "instance"
    if decl.«noncomputable» then values := values.push "noncomputable"
    if decl.isUnsafe then values := values.push "unsafe"
    if decl.isPartial then values := values.push "partial"
    if let some implementation := decl.implementedBy then
      values := values.push s!"implemented_by={implementation}"
    if decl.«extern» then values := values.push "extern"
    values
  let roles := Id.run do
    let mut values : Array String := #[]
    if decl.internal then values := values.push "internal"
    if decl.«private» then values := values.push "private"
    if decl.projection then values := values.push "projection"
    if decl.matcher then values := values.push "matcher"
    if let some base := decl.unsafeRecBase then values := values.push s!"unsafe-rec-for={base}"
    values
  let flagText := if flags.isEmpty then "" else s!" [{", ".intercalate flags.toList}]"
  let roleText := if roles.isEmpty then "" else s!" roles={repr roles.toList}"
  let contractText := decl.executableContract.map (fun contract =>
    s!" executable-contract={contract.root} requires={contract.requirement}" ++
      (contract.failure.map (s!" failure={·}")).getD "") |>.getD ""
  s!"{decl.name} ({decl.kind}){flagText}{roleText} type={decl.prettyType} " ++
    s!"axioms={repr (decl.axioms.toList.map (·.toString))} -> {(StrictLeanPolicy.foundationFor scope.inventory scope.roles decl).toOption.map (·.spelling) |>.getD "invalid-inventory"}{contractText}"

end StrictLean.Checker.Policy
