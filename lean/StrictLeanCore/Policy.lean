import StrictLeanCore.Rule
import StrictLeanPolicy.Decision
import StrictLeanPolicy.Execution
import StrictLeanPolicy.Traversal
import StrictLean.Contract

/-! Pure checker projections of the policy decisions: claim spelling and request,
scope admission, declaration rules and execution rules. Each requirement is a named
`Prop`; a closed `ExecutableContract` proves it about the executed definition, and the
operational adapter `StrictLean.Checker.Policy` runs these registrations. Transcript
coordinate checking is a parameter supplied by that adapter: these contracts hold for
every check and do not authenticate transcripts, sources or environment observations. -/

namespace StrictLean.Checker.Policy

open StrictLeanPolicy (Declaration FoundationClass)

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

/-- Command-line and manifest spellings select exactly the profile rendered by `toString`. -/
theorem Profile.parse?_eq_some_iff (text : String) (profile : Profile) :
    Profile.parse? text = some profile ↔ profile.toString = text := by
  constructor
  · intro h
    unfold Profile.parse? at h
    split at h <;> cases h <;> rfl
  · rintro rfl
    cases profile <;> rfl

/-- Adapter groups one admitted inventory with its recomputed role evidence.
`StrictLeanPolicy.Roles.eq_authorize` determines `roles` from `inventory`. -/
structure PolicyScope where
  inventory : StrictLeanPolicy.Inventory
  roles : StrictLeanPolicy.Roles inventory

def PolicyScope.native (s : PolicyScope) : Array Lean.Name := s.roles.native
def PolicyScope.helpers (s : PolicyScope) : Array Lean.Name := s.roles.helpers

/-- A transcript-coordinate check over the declaration inventory. The operational
adapter supplies `Frontend.validateCoordinates`; its source reading is outside this module. -/
abbrev CoordinateCheck :=
  Array Declaration → StrictLeanPolicy.Frontend.Transcript → Except String Unit

/-- Required admission relation, for every coordinate check. The check runs first, over
transcripts in order, and the first refusal is returned. Afterwards admission is exactly
inventory admission with recomputed roles. Success retains the exact declaration and
transcript arrays, and occurs exactly when every check and the inventory predicate hold. -/
def ScopeContract
    (admit : CoordinateCheck → Array Declaration → Array StrictLeanPolicy.Frontend.Transcript →
      Except String PolicyScope) : Prop :=
  ∀ check : CoordinateCheck,
    (∀ ds ts before t after e, ts.toList = before ++ t :: after →
        (∀ b ∈ before, check ds b = .ok ()) →
        check ds t = .error e → admit check ds ts = .error e) ∧
    (∀ ds ts, (∀ t ∈ ts, check ds t = .ok ()) →
        admit check ds ts = (StrictLeanPolicy.admitInventory ds ts).map
          fun inventory => ⟨inventory, StrictLeanPolicy.authorize inventory⟩) ∧
    (∀ ds ts, (∃ scope, admit check ds ts = .ok scope) ↔
        (∀ t ∈ ts, check ds t = .ok ()) ∧ StrictLeanPolicy.InventoryValid ds ts) ∧
    (∀ ds ts scope, admit check ds ts = .ok scope →
        scope.inventory.declarations = ds ∧ scope.inventory.transcripts = ts)

private def admitScopeImpl (check : CoordinateCheck) (ds : Array Declaration)
    (ts : Array StrictLeanPolicy.Frontend.Transcript) : Except String PolicyScope := do
  ts.toList.forM (check ds)
  let inventory ← StrictLeanPolicy.admitInventory ds ts
  return ⟨inventory, StrictLeanPolicy.authorize inventory⟩

private theorem admitScopeImpl_checked (check : CoordinateCheck) (ds : Array Declaration)
    (ts : Array StrictLeanPolicy.Frontend.Transcript) (h : ∀ t ∈ ts, check ds t = .ok ()) :
    admitScopeImpl check ds ts = (StrictLeanPolicy.admitInventory ds ts).map
      fun inventory => ⟨inventory, StrictLeanPolicy.authorize inventory⟩ := by
  have hts : ts.toList.forM (check ds) = .ok () :=
    (StrictLeanPolicy.forM_eq_ok _ _).mpr fun t ht => h t (by simpa using ht)
  simp only [admitScopeImpl, hts, bind, Except.bind]
  cases StrictLeanPolicy.admitInventory ds ts <;> rfl

/-- Registers `ScopeContract` about the executed admission; the adapter's `admitScope`
runs it with the frontend coordinate check. -/
theorem checkedScope : StrictLean.ExecutableContract admitScopeImpl ScopeContract := by
  refine ⟨fun check => ⟨?first, admitScopeImpl_checked check, ?success, ?fidelity⟩⟩
  case first =>
    intro ds ts before t after e hts hb ht
    have refused := (StrictLeanPolicy.forM_eq_error _ _ e).mpr ⟨before, t, after, hts, hb, ht⟩
    simp only [admitScopeImpl, refused, bind, Except.bind]
  case success =>
    intro ds ts
    by_cases hc : ∀ t ∈ ts, check ds t = .ok ()
    · rw [admitScopeImpl_checked check ds ts hc]
      by_cases hv : StrictLeanPolicy.InventoryValid ds ts
      · simpa [StrictLeanPolicy.admitInventory_exact ds ts hv, Except.map, hv] using hc
      · simp [StrictLeanPolicy.admitInventory, hv, Except.map]
    · have hts : ts.toList.forM (check ds) ≠ .ok () :=
        fun h => hc fun t ht => (StrictLeanPolicy.forM_eq_ok _ _).mp h t (by simpa using ht)
      simp only [hc, false_and, iff_false, not_exists]
      intro scope h
      apply hts
      cases h' : ts.toList.forM (check ds) with
      | error e => simp [admitScopeImpl, h', bind, Except.bind] at h
      | ok u => rfl
  case fidelity =>
    intro ds ts scope h
    cases hts : ts.toList.forM (check ds) with
    | error e => simp [admitScopeImpl, hts, bind, Except.bind] at h
    | ok u =>
      by_cases hv : StrictLeanPolicy.InventoryValid ds ts
      · simp [admitScopeImpl, hts, bind, Except.bind, StrictLeanPolicy.admitInventory_exact ds ts hv,
          pure, Except.pure] at h
        subst h
        exact ⟨rfl, rfl⟩
      · simp [admitScopeImpl, hts, bind, Except.bind, StrictLeanPolicy.admitInventory, hv] at h

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

/-- Required member projection: for every declaration proved to be a member of the scope's
admitted inventory, the rule is exactly `ruleFor`'s, and so satisfies `RuleContract`. -/
def MemberRuleContract
    (rule : (decl : Declaration) → Option Profile → (scope : PolicyScope) →
      decl ∈ scope.inventory.declarations → Option RuleId) : Prop :=
  ∀ decl claim scope (member : decl ∈ scope.inventory.declarations),
    rule decl claim scope member = ruleFor decl claim scope

private def ruleForMemberImpl (decl : Declaration) (claim : Option Profile) (scope : PolicyScope)
    (member : decl ∈ scope.inventory.declarations) : Option RuleId :=
  (StrictLeanPolicy.checkedMemberFailure.run scope.inventory scope.roles decl member
    (request claim)).map StrictLean.ruleForFailure

/-- Registers `MemberRuleContract`, reducing it to `MemberFailureContract`. -/
theorem checkedMemberRule : StrictLean.ExecutableContract ruleForMemberImpl MemberRuleContract :=
  ⟨fun decl claim scope member => by
    simp only [ruleForMemberImpl, ruleFor, StrictLean.ExecutableContract.run_eq, ruleForImpl,
      StrictLeanPolicy.checkedMemberFailure.evidence _ _ _ member]⟩

/-- `ruleFor` for a member, supplied by iterating `scope.inventory.declarations`: the
membership proof replaces the inventory scan. Through `checkedMemberRule`. -/
def ruleForMember (decl : Declaration) (claim : Option Profile) (scope : PolicyScope)
    (member : decl ∈ scope.inventory.declarations) : Option RuleId :=
  checkedMemberRule.run decl claim scope member

/-- Applicability text of the rule `ruleFor` selects. -/
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

/-- Foundation class of any declaration, refusing a non-member of the scope's inventory. -/
def labelOf (decl : Declaration) (scope : PolicyScope) : Except String FoundationClass :=
  StrictLeanPolicy.foundationFor scope.inventory scope.roles decl

/-- Foundation class of a member of the scope's inventory, through
`StrictLeanPolicy.checkedMemberFoundation`: `labelOf` succeeds with exactly this class. -/
def labelOfMember (decl : Declaration) (scope : PolicyScope)
    (member : decl ∈ scope.inventory.declarations) : FoundationClass :=
  StrictLeanPolicy.checkedMemberFoundation.run scope.inventory scope.roles decl member

theorem labelOf_member (decl : Declaration) (scope : PolicyScope)
    (member : decl ∈ scope.inventory.declarations) :
    labelOf decl scope = .ok (labelOfMember decl scope member) :=
  StrictLeanPolicy.checkedMemberFoundation.evidence _ _ _ member

/-- Total bridge from execution failure kinds to the single rule registry. -/
def executionRule : StrictLeanPolicy.ExecutionFailureKind → RuleId
  | .executionUnresolved => .executionUnresolved
  | .executionBoundary => .executionBoundary

theorem executionRule_injective : Function.Injective executionRule := by
  intro a b h
  cases a <;> cases b <;> first | rfl | cases h

end StrictLean.Checker.Policy
