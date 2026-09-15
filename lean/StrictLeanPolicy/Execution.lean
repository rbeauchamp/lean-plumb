import StrictLeanPolicy.Admission

/-! Executable execution decisions over an admitted inventory. Semantic equivalence
and acceptance soundness belong to the subsequent proof issue. -/
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

def executionFailureRecords (inventory : ExecutionInventory)
    (claim : ExecutionClaim) : Array ExecutionFailure := Id.run do
  let mut failures := #[]
  for root in inventory.roots do
    for item in root.unresolved do
      failures := failures.push ⟨.executionUnresolved, root, s!"{root.name}: {item}"⟩
    for boundary in root.boundaries do
      if boundary.correspondence == .unresolved then
        failures := failures.push ⟨.executionUnresolved, root,
          s!"{root.name} reaches {boundary.name} ({boundary.boundary}): {boundary.evidence.getD "unclassified"}"⟩
      else if claim == .checked && boundary.correspondence != .checked
          && boundary.boundary != .nativeRuntime then
        failures := failures.push ⟨.executionBoundary, root,
          s!"{root.name} reaches {boundary.name} ({boundary.boundary})"⟩
  failures

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
