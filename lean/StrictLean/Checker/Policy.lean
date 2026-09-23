import StrictLean.Checker.Frontend
import StrictLeanPolicy.Decision
import StrictLeanPolicy.Execution
import StrictLean.Rule
import StrictLean.Contract

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

/-- Adapter groups one admitted inventory with its recomputed role evidence.
`StrictLeanPolicy.Roles.eq_authorize` determines `roles` from `inventory`. -/
structure PolicyScope where
  inventory : StrictLeanPolicy.Inventory
  roles : StrictLeanPolicy.Roles inventory

/-- Pure `Except` traversal succeeds exactly when every element succeeds. -/
private theorem forM_ok {α ε : Type} (f : α → Except ε Unit) :
    ∀ l : List α, l.forM f = .ok () ↔ ∀ x ∈ l, f x = .ok ()
  | [] => by simp [pure, Except.pure]
  | x :: l => by
    simp only [List.forM]
    cases hx : f x with
    | error e => simp [bind, Except.bind, hx]
    | ok u =>
      cases u
      simp only [bind, Except.bind, List.mem_cons, forall_eq_or_imp, hx, true_and]
      exact forM_ok f l

/-- The first failing element determines the refusal of a pure `Except` traversal. -/
private theorem forM_first {α ε : Type} (f : α → Except ε Unit) (x : α) (e : ε) (after : List α) :
    ∀ before : List α, (∀ b ∈ before, f b = .ok ()) → f x = .error e →
      (before ++ x :: after).forM f = .error e
  | [], _, hx => by simp [List.forM_cons, bind, Except.bind, hx]
  | b :: before, hb, hx => by
    simp only [List.cons_append, List.forM, hb b (by simp), bind, Except.bind]
    exact forM_first f x e after before (fun b' h => hb b' (by simp [h])) hx

/-- Required admission relation. Coordinate checks run first, over transcripts in order,
and the first refusal is returned. Afterwards admission is exactly inventory admission with
recomputed roles. Success retains the exact declaration and transcript arrays, and occurs
exactly when every coordinate check and the inventory predicate hold. -/
def ScopeContract (admit : Array Declaration → Array Transcript → Except String PolicyScope) :
    Prop :=
  (∀ ds ts before t after e, ts.toList = before ++ t :: after →
      (∀ b ∈ before, Frontend.validateCoordinates ds b = .ok ()) →
      Frontend.validateCoordinates ds t = .error e → admit ds ts = .error e) ∧
  (∀ ds ts, (∀ t ∈ ts, Frontend.validateCoordinates ds t = .ok ()) →
      admit ds ts = (StrictLeanPolicy.admitInventory ds ts).map
        fun inventory => ⟨inventory, StrictLeanPolicy.authorize inventory⟩) ∧
  (∀ ds ts, (∃ scope, admit ds ts = .ok scope) ↔
      (∀ t ∈ ts, Frontend.validateCoordinates ds t = .ok ()) ∧
        StrictLeanPolicy.InventoryValid ds ts) ∧
  (∀ ds ts scope, admit ds ts = .ok scope →
      scope.inventory.declarations = ds ∧ scope.inventory.transcripts = ts)

private def admitScopeImpl (ds : Array Declaration) (ts : Array Transcript) :
    Except String PolicyScope := do
  ts.toList.forM (Frontend.validateCoordinates ds)
  let inventory ← StrictLeanPolicy.admitInventory ds ts
  return ⟨inventory, StrictLeanPolicy.authorize inventory⟩

private theorem admitScopeImpl_checked (ds : Array Declaration) (ts : Array Transcript)
    (h : ∀ t ∈ ts, Frontend.validateCoordinates ds t = .ok ()) :
    admitScopeImpl ds ts = (StrictLeanPolicy.admitInventory ds ts).map
      fun inventory => ⟨inventory, StrictLeanPolicy.authorize inventory⟩ := by
  have hts : ts.toList.forM (Frontend.validateCoordinates ds) = .ok () :=
    (forM_ok _ _).mpr fun t ht => h t (by simpa using ht)
  simp only [admitScopeImpl, hts, bind, Except.bind]
  cases StrictLeanPolicy.admitInventory ds ts <;> rfl

/-- Registers `ScopeContract` about the executed admission; callers use `admitScope`. -/
theorem checkedScope : StrictLean.ExecutableContract admitScopeImpl ScopeContract := by
  refine ⟨⟨?first, admitScopeImpl_checked, ?success, ?fidelity⟩⟩
  case first =>
    intro ds ts before t after e hts hb ht
    simp only [admitScopeImpl, hts, forM_first _ t e after before hb ht, bind, Except.bind]
  case success =>
    intro ds ts
    by_cases hc : ∀ t ∈ ts, Frontend.validateCoordinates ds t = .ok ()
    · rw [admitScopeImpl_checked ds ts hc]
      by_cases hv : StrictLeanPolicy.InventoryValid ds ts
      · simpa [StrictLeanPolicy.admitInventory_exact ds ts hv, Except.map, hv] using hc
      · simp [StrictLeanPolicy.admitInventory, hv, Except.map]
    · have hts : ts.toList.forM (Frontend.validateCoordinates ds) ≠ .ok () :=
        fun h => hc fun t ht => (forM_ok _ _).mp h t (by simpa using ht)
      simp only [hc, false_and, iff_false, not_exists]
      intro scope h
      apply hts
      cases h' : ts.toList.forM (Frontend.validateCoordinates ds) with
      | error e => simp [admitScopeImpl, h', bind, Except.bind] at h
      | ok u => rfl
  case fidelity =>
    intro ds ts scope h
    cases hts : ts.toList.forM (Frontend.validateCoordinates ds) with
    | error e => simp [admitScopeImpl, hts, bind, Except.bind] at h
    | ok u =>
      by_cases hv : StrictLeanPolicy.InventoryValid ds ts
      · simp [admitScopeImpl, hts, bind, Except.bind, StrictLeanPolicy.admitInventory_exact ds ts hv,
          pure, Except.pure] at h
        subst h
        exact ⟨rfl, rfl⟩
      · simp [admitScopeImpl, hts, bind, Except.bind, StrictLeanPolicy.admitInventory, hv] at h

/-- Admit the scope through `checkedScope`; this executes exactly `admitScopeImpl`. -/
def admitScope (ds : Array Declaration) (ts : Array Transcript := #[]) :
    Except String PolicyScope :=
  checkedScope.run ds ts

def PolicyScope.native (s : PolicyScope) : Array Name := s.roles.native
def PolicyScope.helpers (s : PolicyScope) : Array Name := s.roles.helpers

/-- Required meaning of a claim: no claim selects classification, compiler-trusting selects
teaching inspection, and every other profile selects the conforming profile of its spelling. -/
def RequestContract (request : Option Profile → StrictLeanPolicy.InspectionRequest) : Prop :=
  request none = .classification ∧
  ∀ profile, (request (some profile) = .teaching ↔ profile = .compilerTrusting) ∧
    ∀ conforming, request (some profile) = .conforming conforming ↔
      profile.toString = conforming.spelling

private def requestImpl : Option Profile → StrictLeanPolicy.InspectionRequest
  | none => .classification
  | some .compilerTrusting => .teaching
  | some .kernelOnly => .conforming .kernelOnly
  | some .choiceFree => .conforming .choiceFree
  | some .standardLogical => .conforming .standardLogical

/-- Registers `RequestContract` about the executed projection; callers use `request`. -/
theorem checkedRequest : StrictLean.ExecutableContract requestImpl RequestContract :=
  ⟨⟨rfl, fun profile => by
    cases profile <;> refine ⟨by simp [requestImpl], fun conforming => ?_⟩ <;>
      cases conforming <;> simp [requestImpl, Profile.toString,
        StrictLeanPolicy.ConformingProfile.spelling]⟩⟩

/-- The policy request selected by a claim, through `checkedRequest`. -/
def request (claim : Option Profile) : StrictLeanPolicy.InspectionRequest :=
  checkedRequest.run claim

/-- Command-line and manifest spellings select exactly the profile rendered by `toString`. -/
theorem Profile.parse?_eq_some_iff (text : String) (profile : Profile) :
    Profile.parse? text = some profile ↔ profile.toString = text := by
  constructor
  · intro h
    unfold Profile.parse? at h
    split at h <;> cases h <;> rfl
  · rintro rfl
    cases profile <;> rfl

abbrev declarationNeedsTranscript := StrictLeanPolicy.declarationNeedsTranscript
abbrev needsFrontendTranscript := StrictLeanPolicy.needsFrontendTranscript

/-- Required declaration projection: no rule exactly when the inventory-bound policy decision
for the selected request succeeds, and otherwise the registry rule of that decision's failure.
With `ruleForFailure_injective`, the rule identifies the first failed requirement proved by
`StrictLeanPolicy.policyFor_ordered`. -/
def RuleContract (rule : Declaration → Option Profile → PolicyScope → Option RuleId) : Prop :=
  ∀ decl claim scope,
    (rule decl claim scope = none ↔
      StrictLeanPolicy.policyFor scope.inventory scope.roles decl (request claim) = none) ∧
    ∀ failure, rule decl claim scope = some (StrictLean.ruleForFailure failure) ↔
      StrictLeanPolicy.policyFor scope.inventory scope.roles decl (request claim) = some failure

private def ruleForImpl (decl : Declaration) (claim : Option Profile) (scope : PolicyScope) :
    Option RuleId :=
  (StrictLeanPolicy.policyFor scope.inventory scope.roles decl (request claim)).map
    StrictLean.ruleForFailure

/-- Registers `RuleContract` about the executed projection; callers use `ruleFor`. -/
theorem checkedRule : StrictLean.ExecutableContract ruleForImpl RuleContract :=
  ⟨fun decl claim scope => by
    unfold ruleForImpl
    cases StrictLeanPolicy.policyFor scope.inventory scope.roles decl (request claim) with
    | none => simp
    | some found =>
      refine ⟨by simp, fun failure => ?_⟩
      simp only [Option.map_some, Option.some.injEq]
      exact ⟨fun h => (StrictLean.ruleForFailure_injective h).symm ▸ rfl,
        fun h => h ▸ rfl⟩⟩

/-- The registry rule for a declaration's first policy failure, through `checkedRule`. -/
def ruleFor (decl : Declaration) (claim : Option Profile) (scope : PolicyScope) : Option RuleId :=
  checkedRule.run decl claim scope

def reasonFor (decl : Declaration) (claim : Option Profile) (scope : PolicyScope) : Option String :=
  (ruleFor decl claim scope).map (fun id => (descriptor id).applicability)

/-- Declaration-failure rules have pairwise distinct applicability text. -/
theorem applicability_ruleForFailure_injective (a b : StrictLeanPolicy.DeclarationFailure)
    (h : (descriptor (StrictLean.ruleForFailure a)).applicability =
      (descriptor (StrictLean.ruleForFailure b)).applicability) : a = b := by
  cases a <;> cases b <;> first | rfl | (simp [descriptor, StrictLean.ruleForFailure] at h)

/-- The rendered reason is the applicability of the decision's failure, and only of it. -/
theorem reasonFor_eq_some_iff (decl : Declaration) (claim : Option Profile) (scope : PolicyScope)
    (failure : StrictLeanPolicy.DeclarationFailure) :
    reasonFor decl claim scope =
        some (descriptor (StrictLean.ruleForFailure failure)).applicability ↔
      StrictLeanPolicy.policyFor scope.inventory scope.roles decl (request claim) =
        some failure := by
  have contract := checkedRule.evidence decl claim scope
  rw [← (contract.2 failure)]
  unfold reasonFor ruleFor
  rw [StrictLean.ExecutableContract.run_eq]
  cases hr : ruleForImpl decl claim scope with
  | none => simp
  | some id =>
    have found : ∃ found, id = StrictLean.ruleForFailure found := by
      cases hp : StrictLeanPolicy.policyFor scope.inventory scope.roles decl (request claim) with
      | none => rw [← contract.1, hr] at hp; cases hp
      | some found =>
        exact ⟨found, Option.some.inj (hr.symm.trans ((contract.2 found).mpr hp))⟩
    obtain ⟨found, rfl⟩ := found
    simp only [Option.map_some, Option.some.injEq]
    exact ⟨fun h => applicability_ruleForFailure_injective _ _ h ▸ rfl, fun h => h ▸ rfl⟩

def labelOf (decl : Declaration) (scope : PolicyScope) : Except String FoundationClass :=
  StrictLeanPolicy.foundationFor scope.inventory scope.roles decl

abbrev ExecutionInventory := StrictLeanPolicy.ExecutionInventory
abbrev admitExecution := StrictLeanPolicy.admitExecution
abbrev ExecutionFailure := StrictLeanPolicy.ExecutionFailure

/-- The decision's own records, unchanged: kind, root, detail and order are preserved by
identity rather than by a second record type. -/
abbrev executionFailureRecords := StrictLeanPolicy.executionFailureRecords

/-- Total bridge from execution failure kinds to the single rule registry. -/
def executionRule : StrictLeanPolicy.ExecutionFailureKind → RuleId
  | .executionUnresolved => .executionUnresolved
  | .executionBoundary => .executionBoundary

theorem executionRule_injective : Function.Injective executionRule := by
  intro a b h
  cases a <;> cases b <;> first | rfl | cases h

/-- Existing text subreasons derive from the registry and the same decision records. -/
def executionFailures (inventory : ExecutionInventory)
    (claim : ExecutionClaim) : Array String :=
  (executionFailureRecords inventory claim).map fun failure =>
    s!"{(descriptor (executionRule failure.id)).applicability}: {failure.detail}"

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

/-- Execution-coverage counts, through `StrictLeanPolicy.checkedSummary`. -/
def executionSummary (inventory : ExecutionInventory) : StrictLeanPolicy.ExecutionSummary :=
  StrictLeanPolicy.checkedSummary.run inventory

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
