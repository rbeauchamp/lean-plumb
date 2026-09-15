import StrictLeanPolicy.Admission

/-! Executable execution decisions and their exact finite-observation specification.
Neither policy equivalence nor admitted origin data proves extraction or native runtime correctness. -/
namespace StrictLeanPolicy
inductive ExecutionFailureKind where
  | executionUnresolved | executionBoundary
  deriving Repr, DecidableEq

/-- Execution-claim failures over the typed coverage account. Unresolved
paths and unclassified boundaries block in every mode; a trusted boundary
blocks a checked-correspondence claim unless it is a toolchain native-runtime
primitive. -/
structure ExecutionFailure where
  id : ExecutionFailureKind
  root : ExecutionRoot
  detail : String

/-- A resolved boundary in checked mode has checked evidence or the typed native-runtime
origin account. Report mode retains trusted boundaries; unresolved never passes. -/
def BoundaryOK (claim : ExecutionClaim) (b : ExecutionBoundary) : Prop :=
  b.correspondence ≠ .unresolved ∧
  (claim = .report ∨ b.correspondence = .checked ∨ b.boundary = .nativeRuntime)
instance (claim : ExecutionClaim) (b : ExecutionBoundary) : Decidable (BoundaryOK claim b) := by
  unfold BoundaryOK; infer_instance

/-- The finite closure account has no unresolved paths and every boundary meets its claim.
Completeness of actual execution-root/closure extraction is a separate operational obligation. -/
def ExecutionOK (inventory : ExecutionInventory) (claim : ExecutionClaim) : Prop :=
  ∀ r ∈ inventory.roots, r.unresolved = #[] ∧ ∀ b ∈ r.boundaries, BoundaryOK claim b
instance (inventory : ExecutionInventory) (claim : ExecutionClaim) : Decidable (ExecutionOK inventory claim) := by
  unfold ExecutionOK; infer_instance

/-- One boundary's deterministic diagnostic, retaining unresolved-before-trusted precedence. -/
def boundaryFailures (root : ExecutionRoot) (claim : ExecutionClaim)
    (b : ExecutionBoundary) : Array ExecutionFailure :=
  if b.correspondence == .unresolved then
    #[⟨.executionUnresolved, root,
      s!"{root.name} reaches {b.name} ({b.boundary}): {b.evidence.getD "unclassified"}"⟩]
  else if claim == .checked && b.correspondence != .checked && b.boundary != .nativeRuntime then
    #[⟨.executionBoundary, root, s!"{root.name} reaches {b.name} ({b.boundary})"⟩]
  else #[]

/-- Preserve root order, each unresolved path, and then every boundary's failure. -/
def rootFailures (root : ExecutionRoot) (claim : ExecutionClaim) : Array ExecutionFailure :=
  root.unresolved.map (fun item => ⟨.executionUnresolved, root, s!"{root.name}: {item}"⟩) ++
    root.boundaries.flatMap (boundaryFailures root claim)

def executionFailureRecords (inventory : ExecutionInventory)
    (claim : ExecutionClaim) : Array ExecutionFailure :=
  inventory.roots.flatMap (fun root => rootFailures root claim)

/-- All and only boundary-policy violations produce a failure. -/
theorem boundaryFailures_empty_iff (r : ExecutionRoot) (c : ExecutionClaim) (b : ExecutionBoundary) :
    boundaryFailures r c b = #[] ↔ BoundaryOK c b := by
  unfold boundaryFailures BoundaryOK
  cases c <;> cases hb : b.correspondence <;> simp

/-- Every unresolved path and boundary is included; an empty failure array is equivalent
to the independent execution predicate, for every admitted finite inventory and mode. -/
theorem executionFailureRecords_empty_iff (i : ExecutionInventory) (c : ExecutionClaim) :
    executionFailureRecords i c = #[] ↔ ExecutionOK i c := by
  simp [executionFailureRecords, rootFailures, ExecutionOK, Array.flatMap_eq_empty_iff,
    boundaryFailures_empty_iff]

/-- Execution-coverage summary counts for gate output: roots, boundaries,
checked, trusted, unresolved. -/
def executionSummary (inventory : ExecutionInventory) :
    Nat × Nat × Nat × Nat × Nat := Id.run do
  let mut boundaries := 0
  let mut checked := 0
  let mut trusted := 0
  let mut unresolved := 0
  for root in inventory.roots do
    unresolved := unresolved + root.unresolved.size
    for boundary in root.boundaries do
      boundaries := boundaries + 1
      if boundary.correspondence == .checked then checked := checked + 1
      else if boundary.correspondence == .trusted then trusted := trusted + 1
      else unresolved := unresolved + 1
  return (inventory.roots.size, boundaries, checked, trusted, unresolved)

end StrictLeanPolicy
