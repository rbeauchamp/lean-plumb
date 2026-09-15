import StrictLeanPolicy.Domain

/-! Admission of observations before policy. These proofs establish data validity,
not the truth of compiler extraction. Generated roles remain bound to this entire
inventory; all policy decisions consume a member of that same admitted inventory. -/
namespace StrictLeanPolicy

/-- Structural key validity. Anonymous prefixes are legal; complete keys are not. -/
def named (n : Lean.Name) : Prop := n ≠ .anonymous
instance (n : Lean.Name) : Decidable (named n) := inferInstanceAs (Decidable (n ≠ .anonymous))

/-- Repeated observations are refused even when their payloads agree. -/
def uniqueNames (names : Array Lean.Name) : Prop := names.toList.Pairwise (· ≠ ·)
instance (names : Array Lean.Name) : Decidable (uniqueNames names) :=
  inferInstanceAs (Decidable (names.toList.Pairwise (· ≠ ·)))

/-- Every policy-relevant declaration reference is structural and nonanonymous.
A failed executable-contract observation may lack a root; it remains a refusal. -/
def Declaration.Valid (d : Declaration) : Prop :=
  named d.name ∧ named d.module ∧
  d.safety = (if d.isPartial then some .partial else if d.isUnsafe then some .unsafe else none) ∧
  canonicalNames d.axioms = d.axioms ∧ canonicalNames d.valueConstants = d.valueConstants ∧
  (∀ ns ∈ d.unsafeRecEquationAxioms, canonicalNames ns = ns ∧ ∀ n ∈ ns, named n) ∧
  (∀ n ∈ d.axioms, named n) ∧ (∀ n ∈ d.valueConstants, named n) ∧
  (∀ n ∈ d.all, named n) ∧ (∀ n ∈ d.nativeUseParents, named n) ∧
  (∀ n ∈ d.implementedBy, named n) ∧ (∀ n ∈ d.unsafeRecBase, named n) ∧
  (∀ c ∈ d.executableContract, c.failure.isSome = true ∨ named c.root)
instance instDecidableDeclarationValid (d : Declaration) : Decidable d.Valid := by
  unfold Declaration.Valid
  infer_instance

/-- Codepoint coordinates select an existing line and a boundary on that line.
The operational bridge separately checks correspondence with Lean's FileMap. -/
def Position.validFor (p : Position) (source : String) : Bool :=
  p.line > 0 && ((source.splitOn "\n")[p.line - 1]?).any (fun line => p.column ≤ line.length)

private def positionLE (a b : Position) : Bool :=
  a.line < b.line || (a.line == b.line && a.column ≤ b.column)

private def utf16Column (p : Position) (source : String) : Nat :=
  ((((source.splitOn "\n")[p.line - 1]?).getD "").toList.take p.column).foldl
    (fun n c => n + if c.toNat > 65535 then 2 else 1) 0

def Range.validFor (r : Range) (source : String) : Bool :=
  r.start.validFor source && r.end.validFor source && positionLE r.start r.end &&
  r.startUtf16 == utf16Column r.start source && r.endUtf16 == utf16Column r.end source

def Ranges.validFor (r : Ranges) (source : String) : Bool :=
  r.range.validFor source && r.selectionRange.validFor source &&
  positionLE r.range.start r.selectionRange.start && positionLE r.selectionRange.end r.range.end

def Frontend.SyntaxRange.validFor (r : Frontend.SyntaxRange) (source : String) : Bool :=
  r.start.validFor source && r.end.validFor source && positionLE r.start r.end

def Frontend.Transcript.validCoordinates (t : Frontend.Transcript) : Bool :=
  t.commands.all fun command =>
    command.commandRange.all (·.validFor t.sourceContent) &&
    command.evaluators.all (fun e => e.range.all (·.validFor t.sourceContent)) &&
    command.bindings.all (fun b => b.range.all (·.validFor t.sourceContent)) &&
    command.added == command.addedDeclarations.map (·.name) &&
    command.added.all (· != .anonymous)

/-- Admitted inventories have one declaration per name and one transcript per module.
Ordered evaluator and mutual-group sequences are intentionally not normalized. -/
def InventoryValid (decls : Array Declaration) (transcripts : Array Frontend.Transcript) : Prop :=
  uniqueNames (decls.map (·.name)) ∧
  (∀ d ∈ decls, d.Valid) ∧
  uniqueNames (transcripts.map (·.module)) ∧
  (∀ t ∈ transcripts, named t.module ∧ t.source ≠ "" ∧
    t.sourceBytes = t.sourceContent.utf8ByteSize ∧
    t.leanVersion = "4.33.1" ∧ t.leanGitHash = "819816b2e0a3bf405af45ae5c7af2491d8f5bee6" ∧
    t.validCoordinates = true ∧
    ∀ d ∈ decls, d.module = t.module → d.ranges.all (·.validFor t.sourceContent) = true)
instance instDecidableInventoryValid (decls : Array Declaration) (transcripts : Array Frontend.Transcript) :
    Decidable (InventoryValid decls transcripts) := by
  unfold InventoryValid
  infer_instance

/-- No raw constructor or decoder can omit the inventory-validity proof. -/
structure Inventory where
  declarations : Array Declaration
  transcripts : Array Frontend.Transcript
  valid : InventoryValid declarations transcripts

/-- Validate without dropping, substituting, or deduplicating result observations. -/
def admitInventory (decls : Array Declaration) (transcripts : Array Frontend.Transcript) :
    Except String Inventory :=
  if h : InventoryValid decls transcripts then .ok ⟨decls, transcripts, h⟩
  else .error "invalid policy inventory: anonymous, duplicate, or malformed identity"

/-- Every valid inventory is admitted with exactly its input fields. -/
theorem admitInventory_exact (ds : Array Declaration) (ts : Array Frontend.Transcript)
    (h : InventoryValid ds ts) : admitInventory ds ts = .ok ⟨ds, ts, h⟩ := by
  simp [admitInventory, h]
/-- Boundary origin receipts must refer to this observation's module. -/
def ExecutionBoundary.Valid (b : ExecutionBoundary) : Prop :=
  named b.name ∧ named b.module ∧
  (∀ n ∈ b.replacement, named n) ∧ (∀ n ∈ b.compilerCallers, named n) ∧
  (∀ o ∈ b.account.nativeOrigin?, o.moduleName = b.module)
instance instDecidableExecutionBoundaryValid (b : ExecutionBoundary) : Decidable b.Valid := by
  unfold ExecutionBoundary.Valid
  infer_instance

/-- Occurrence numbers distinguish repeated evidence, while roots have unique keys. -/
def ExecutionRoot.Valid (r : ExecutionRoot) : Prop :=
  named r.name ∧ named r.module ∧
  canonicalEdges r.compilerEdges = r.compilerEdges ∧
  (∀ b ∈ r.boundaries, b.Valid) ∧
  (r.boundaries.map (·.occurrence)).toList.Pairwise (· ≠ ·) ∧
  (∀ e ∈ r.compilerEdges, named e.1 ∧ named e.2)
instance instDecidableExecutionRootValid (r : ExecutionRoot) : Decidable r.Valid := by
  unfold ExecutionRoot.Valid
  infer_instance

def ExecutionValid (roots : Array ExecutionRoot) : Prop :=
  uniqueNames (roots.map (·.name)) ∧ ∀ r ∈ roots, r.Valid
instance instDecidableExecutionValid (roots : Array ExecutionRoot) : Decidable (ExecutionValid roots) := by
  unfold ExecutionValid
  infer_instance

structure ExecutionInventory where
  roots : Array ExecutionRoot
  valid : ExecutionValid roots

def admitExecution (roots : Array ExecutionRoot) : Except String ExecutionInventory :=
  if h : ExecutionValid roots then .ok ⟨roots, h⟩
  else .error "invalid execution inventory: identity, occurrence, or origin binding"

theorem admitExecution_exact (roots : Array ExecutionRoot) (h : ExecutionValid roots) :
    admitExecution roots = .ok ⟨roots, h⟩ := by simp [admitExecution, h]
end StrictLeanPolicy
