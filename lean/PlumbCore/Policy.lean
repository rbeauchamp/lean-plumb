import PlumbCore.Rule
import PlumbCore.EditorPolicy
import PlumbPolicy.Decision
import PlumbPolicy.Execution
import PlumbPolicy.Guards
import PlumbPolicy.Traversal
import Plumb.Contract

/-! Pure checker projections of the policy decisions: claim spelling and request,
scope admission, declaration rules and execution rules. Each requirement is a named
`Prop`; a closed `ExecutableContract` proves it about the executed definition, and the
operational adapter `Plumb.Checker.Policy` runs these registrations. Scope admission
takes the transcript-coordinate check as a parameter, so `ScopeContract` holds for every
check; the adapter supplies `PlumbCore.Coordinates`'s `checkedCoordinates`. These
contracts do not authenticate transcripts, sources or environment observations. -/

namespace Plumb.Checker.Policy

open PlumbPolicy (Declaration FoundationClass)

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
`PlumbPolicy.Roles.eq_authorize` determines `roles` from `inventory`. -/
structure PolicyScope where
  inventory : PlumbPolicy.Inventory
  roles : PlumbPolicy.Roles inventory

def PolicyScope.native (s : PolicyScope) : Array Lean.Name := s.roles.native
def PolicyScope.helpers (s : PolicyScope) : Array Lean.Name := s.roles.helpers

/-- A transcript-coordinate check over the declaration inventory. The operational
adapter supplies `Frontend.validateCoordinates`, which runs `checkedCoordinates`. -/
abbrev CoordinateCheck :=
  Array Declaration → PlumbPolicy.Frontend.Transcript → Except String Unit

/-- Required admission relation, for every coordinate check. The check runs first, over
transcripts in order, and the first refusal is returned. Afterwards admission is exactly
inventory admission with recomputed roles. Success retains the exact declaration and
transcript arrays, and occurs exactly when every check and the inventory predicate hold. -/
def ScopeContract
    (admit : CoordinateCheck → Array Declaration → Array PlumbPolicy.Frontend.Transcript →
      Except String PolicyScope) : Prop :=
  ∀ check : CoordinateCheck,
    (∀ ds ts before t after e, ts.toList = before ++ t :: after →
        (∀ b ∈ before, check ds b = .ok ()) →
        check ds t = .error e → admit check ds ts = .error e) ∧
    (∀ ds ts, (∀ t ∈ ts, check ds t = .ok ()) →
        admit check ds ts = (PlumbPolicy.admitInventory ds ts).map
          fun inventory => ⟨inventory, PlumbPolicy.authorize inventory⟩) ∧
    (∀ ds ts, (∃ scope, admit check ds ts = .ok scope) ↔
        (∀ t ∈ ts, check ds t = .ok ()) ∧ PlumbPolicy.InventoryValid ds ts) ∧
    (∀ ds ts scope, admit check ds ts = .ok scope →
        scope.inventory.declarations = ds ∧ scope.inventory.transcripts = ts)

private def admitScopeImpl (check : CoordinateCheck) (ds : Array Declaration)
    (ts : Array PlumbPolicy.Frontend.Transcript) : Except String PolicyScope := do
  ts.toList.forM (check ds)
  let inventory ← PlumbPolicy.admitInventory ds ts
  return ⟨inventory, PlumbPolicy.authorize inventory⟩

private theorem admitScopeImpl_checked (check : CoordinateCheck) (ds : Array Declaration)
    (ts : Array PlumbPolicy.Frontend.Transcript) (h : ∀ t ∈ ts, check ds t = .ok ()) :
    admitScopeImpl check ds ts = (PlumbPolicy.admitInventory ds ts).map
      fun inventory => ⟨inventory, PlumbPolicy.authorize inventory⟩ := by
  have hts : ts.toList.forM (check ds) = .ok () :=
    PlumbPolicy.Guards.listForM_eq_ok.mpr fun t ht => h t (by simpa using ht)
  simp only [admitScopeImpl, hts, bind, Except.bind]
  cases PlumbPolicy.admitInventory ds ts <;> rfl

/-- Registers `ScopeContract` about the executed admission; the adapter's `admitScope`
runs it with the frontend coordinate check. -/
theorem checkedScope : Plumb.ExecutableContract admitScopeImpl ScopeContract := by
  refine ⟨fun check => ⟨?first, admitScopeImpl_checked check, ?success, ?fidelity⟩⟩
  case first =>
    intro ds ts before t after e hts hb ht
    have refused := (PlumbPolicy.forM_eq_error _ _ e).mpr ⟨before, t, after, hts, hb, ht⟩
    simp only [admitScopeImpl, refused, bind, Except.bind]
  case success =>
    intro ds ts
    by_cases hc : ∀ t ∈ ts, check ds t = .ok ()
    · rw [admitScopeImpl_checked check ds ts hc]
      by_cases hv : PlumbPolicy.InventoryValid ds ts
      · simpa [PlumbPolicy.admitInventory_exact ds ts hv, Except.map, hv] using hc
      · simp [PlumbPolicy.admitInventory, hv, Except.map]
    · have hts : ts.toList.forM (check ds) ≠ .ok () :=
        fun h => hc fun t ht => PlumbPolicy.Guards.listForM_eq_ok.mp h t (by simpa using ht)
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
      by_cases hv : PlumbPolicy.InventoryValid ds ts
      · simp [admitScopeImpl, hts, bind, Except.bind, PlumbPolicy.admitInventory_exact ds ts hv,
          pure, Except.pure] at h
        subst h
        exact ⟨rfl, rfl⟩
      · simp [admitScopeImpl, hts, bind, Except.bind, PlumbPolicy.admitInventory, hv] at h

/-- Required meaning of a claim: no claim selects classification, compiler-trusting selects
teaching inspection, and every other profile selects the conforming profile of its spelling. -/
def RequestContract (request : Option Profile → PlumbPolicy.InspectionRequest) : Prop :=
  request none = .classification ∧
  ∀ profile, (request (some profile) = .teaching ↔ profile = .compilerTrusting) ∧
    ∀ conforming, request (some profile) = .conforming conforming ↔
      profile.toString = conforming.spelling

private def requestImpl : Option Profile → PlumbPolicy.InspectionRequest
  | none => .classification
  | some .compilerTrusting => .teaching
  | some .kernelOnly => .conforming .kernelOnly
  | some .choiceFree => .conforming .choiceFree
  | some .standardLogical => .conforming .standardLogical

/-- Registers `RequestContract` about the executed projection; callers use `request`. -/
theorem checkedRequest : Plumb.ExecutableContract requestImpl RequestContract :=
  ⟨⟨rfl, fun profile => by
    cases profile <;> refine ⟨by simp [requestImpl], fun conforming => ?_⟩ <;>
      cases conforming <;> simp [requestImpl, Profile.toString,
        PlumbPolicy.ConformingProfile.spelling]⟩⟩

/-- The policy request selected by a claim, through `checkedRequest`. -/
def request (claim : Option Profile) : PlumbPolicy.InspectionRequest :=
  checkedRequest.run claim

/-- `RequestContract` stated about `request` itself, for reuse by its consumers. -/
theorem request_contract : RequestContract request :=
  checkedRequest.evidence

/-- Required declaration projection: no rule exactly when the inventory-bound policy decision
for the selected request succeeds, and otherwise the registry rule of that decision's failure.
With `ruleForFailure_injective`, the rule identifies the first failed requirement proved by
`PlumbPolicy.policyFor_ordered`. -/
def RuleContract (rule : Declaration → Option Profile → PolicyScope → Option RuleId) : Prop :=
  ∀ decl claim scope,
    (rule decl claim scope = none ↔
      PlumbPolicy.policyFor scope.inventory scope.roles decl (request claim) = none) ∧
    ∀ failure, rule decl claim scope = some (Plumb.ruleForFailure failure) ↔
      PlumbPolicy.policyFor scope.inventory scope.roles decl (request claim) = some failure

private def ruleForImpl (decl : Declaration) (claim : Option Profile) (scope : PolicyScope) :
    Option RuleId :=
  (PlumbPolicy.policyFor scope.inventory scope.roles decl (request claim)).map
    Plumb.ruleForFailure

/-- Registers `RuleContract` about the executed projection; callers use `ruleFor`. -/
theorem checkedRule : Plumb.ExecutableContract ruleForImpl RuleContract :=
  ⟨fun decl claim scope => by
    unfold ruleForImpl
    cases PlumbPolicy.policyFor scope.inventory scope.roles decl (request claim) with
    | none => simp
    | some found =>
      refine ⟨by simp, fun failure => ?_⟩
      simp only [Option.map_some, Option.some.injEq]
      exact ⟨fun h => (Plumb.ruleForFailure_injective h).symm ▸ rfl,
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
  (PlumbPolicy.checkedMemberFailure.run scope.inventory scope.roles decl member
    (request claim)).map Plumb.ruleForFailure

/-- Registers `MemberRuleContract`, reducing it to `MemberFailureContract`. -/
theorem checkedMemberRule : Plumb.ExecutableContract ruleForMemberImpl MemberRuleContract :=
  ⟨fun decl claim scope member => by
    simp only [ruleForMemberImpl, ruleFor, Plumb.ExecutableContract.run_eq, ruleForImpl,
      PlumbPolicy.checkedMemberFailure.evidence _ _ _ member]⟩

/-- `ruleFor` for a member, supplied by iterating `scope.inventory.declarations`: the
membership proof replaces the inventory scan. Through `checkedMemberRule`. -/
def ruleForMember (decl : Declaration) (claim : Option Profile) (scope : PolicyScope)
    (member : decl ∈ scope.inventory.declarations) : Option RuleId :=
  checkedMemberRule.run decl claim scope member

/-- `MemberRuleContract` stated about `ruleForMember` itself. -/
theorem ruleForMember_eq (decl : Declaration) (claim : Option Profile) (scope : PolicyScope)
    (member : decl ∈ scope.inventory.declarations) :
    ruleForMember decl claim scope member = ruleFor decl claim scope :=
  checkedMemberRule.evidence decl claim scope member

/-- `RuleContract` stated about `ruleFor` itself. -/
theorem ruleFor_contract : RuleContract ruleFor :=
  checkedRule.evidence

/-- The editor's request domain is the project request's without teaching: every value the
editor option accepts selects `request claim` for a claim other than compiler-trusting. -/
theorem editor_request_sound {value : String} {r : PlumbPolicy.InspectionRequest}
    (h : Plumb.Linter.editorRequest value = some r) :
    ∃ claim, claim ≠ some .compilerTrusting ∧ request claim = r := by
  rcases (Plumb.Linter.editorRequest_contract value r).mp h with ⟨_, rfl⟩ | ⟨p, _, rfl⟩
  · exact ⟨none, by simp, rfl⟩
  · cases p
    · exact ⟨some .kernelOnly, by simp, rfl⟩
    · exact ⟨some .choiceFree, by simp, rfl⟩
    · exact ⟨some .standardLogical, by simp, rfl⟩

/-- Every project request other than teaching is selectable by some editor option value. -/
theorem editor_request_complete (claim : Option Profile) (h : claim ≠ some .compilerTrusting) :
    ∃ value, Plumb.Linter.editorRequest value = some (request claim) := by
  rcases claim with _ | ⟨_ | _ | _ | _⟩
  · exact ⟨"classification-only", by decide⟩
  · exact ⟨"kernel-only", by decide⟩
  · exact ⟨"choice-free", by decide⟩
  · exact ⟨"standard-logical", by decide⟩
  · exact absurd rfl h

/-- For the same member and request, the editor passes a declaration exactly when the
project rule projection selects no rule. -/
theorem editor_decision_none_iff (scope : PolicyScope) (decl : Declaration)
    (member : decl ∈ scope.inventory.declarations) (claim : Option Profile) :
    Plumb.Linter.editorDecision scope.inventory scope.roles decl member (request claim) = none ↔
      ruleForMember decl claim scope member = none := by
  rw [(Plumb.Linter.editorDecision_contract _ _ _ member _).1, ruleForMember_eq,
    (ruleFor_contract decl claim scope).1]

/-- A rule the editor renders is the project rule projection's rule for the same member and
request (`checkedMemberRule`). -/
theorem editor_decision_rule (scope : PolicyScope) (decl : Declaration)
    (member : decl ∈ scope.inventory.declarations) (claim : Option Profile) (id : RuleId)
    (h : Plumb.Linter.editorDecision scope.inventory scope.roles decl member (request claim) =
      some (.rule id)) :
    ruleForMember decl claim scope member = some id := by
  obtain ⟨f, hf, _, rfl⟩ :=
    ((Plumb.Linter.editorDecision_contract _ _ _ member _).2.2 id).mp h
  rw [ruleForMember_eq]
  exact ((ruleFor_contract decl claim scope).2 f).mpr hf

/-- A pending editor decision withholds a rule the project projection selects; the failure
needs fresh generated-role evidence that only a project or fresh-file audit supplies. -/
theorem editor_decision_pending (scope : PolicyScope) (decl : Declaration)
    (member : decl ∈ scope.inventory.declarations) (claim : Option Profile)
    (h : Plumb.Linter.editorDecision scope.inventory scope.roles decl member (request claim) =
      some .pending) :
    ∃ f, ruleForMember decl claim scope member = some (Plumb.ruleForFailure f) ∧
      Plumb.Linter.needsRoleEvidence decl f = true := by
  obtain ⟨f, hf, hn⟩ := ((Plumb.Linter.editorDecision_contract _ _ _ member _).2.1).mp h
  refine ⟨f, ?_, hn⟩
  rw [ruleForMember_eq]
  exact ((ruleFor_contract decl claim scope).2 f).mpr hf

/-- Applicability text of the rule `ruleFor` selects. -/
def reasonFor (decl : Declaration) (claim : Option Profile) (scope : PolicyScope) : Option String :=
  (ruleFor decl claim scope).map (fun id => (descriptor id).applicability)

/-- Declaration-failure rules have pairwise distinct applicability text. -/
theorem applicability_ruleForFailure_injective (a b : PlumbPolicy.DeclarationFailure)
    (h : (descriptor (Plumb.ruleForFailure a)).applicability =
      (descriptor (Plumb.ruleForFailure b)).applicability) : a = b := by
  cases a <;> cases b <;> first | rfl | (simp [descriptor, Plumb.ruleForFailure] at h)

/-- The rendered reason is the applicability of the decision's failure, and only of it. -/
theorem reasonFor_eq_some_iff (decl : Declaration) (claim : Option Profile) (scope : PolicyScope)
    (failure : PlumbPolicy.DeclarationFailure) :
    reasonFor decl claim scope =
        some (descriptor (Plumb.ruleForFailure failure)).applicability ↔
      PlumbPolicy.policyFor scope.inventory scope.roles decl (request claim) =
        some failure := by
  have contract := checkedRule.evidence decl claim scope
  rw [← (contract.2 failure)]
  unfold reasonFor ruleFor
  rw [Plumb.ExecutableContract.run_eq]
  cases hr : ruleForImpl decl claim scope with
  | none => simp
  | some id =>
    have found : ∃ found, id = Plumb.ruleForFailure found := by
      cases hp : PlumbPolicy.policyFor scope.inventory scope.roles decl (request claim) with
      | none => rw [← contract.1, hr] at hp; cases hp
      | some found =>
        exact ⟨found, Option.some.inj (hr.symm.trans ((contract.2 found).mpr hp))⟩
    obtain ⟨found, rfl⟩ := found
    simp only [Option.map_some, Option.some.injEq]
    exact ⟨fun h => applicability_ruleForFailure_injective _ _ h ▸ rfl, fun h => h ▸ rfl⟩

/-- Foundation class of any declaration, refusing a non-member of the scope's inventory. -/
def labelOf (decl : Declaration) (scope : PolicyScope) : Except String FoundationClass :=
  PlumbPolicy.foundationFor scope.inventory scope.roles decl

/-- Foundation class of a member of the scope's inventory, through
`PlumbPolicy.checkedMemberFoundation`: `labelOf` succeeds with exactly this class. -/
def labelOfMember (decl : Declaration) (scope : PolicyScope)
    (member : decl ∈ scope.inventory.declarations) : FoundationClass :=
  PlumbPolicy.checkedMemberFoundation.run scope.inventory scope.roles decl member

theorem labelOf_member (decl : Declaration) (scope : PolicyScope)
    (member : decl ∈ scope.inventory.declarations) :
    labelOf decl scope = .ok (labelOfMember decl scope member) :=
  PlumbPolicy.checkedMemberFoundation.evidence _ _ _ member

/-- Total bridge from execution failure kinds to the single rule registry. -/
def executionRule : PlumbPolicy.ExecutionFailureKind → RuleId
  | .executionUnresolved => .executionUnresolved
  | .executionBoundary => .executionBoundary

theorem executionRule_injective : Function.Injective executionRule := by
  intro a b h
  cases a <;> cases b <;> first | rfl | cases h

/-- One failure's text: its registry rule's applicability and the decision's detail. -/
def executionFailureLine (failure : PlumbPolicy.ExecutionFailure) : String :=
  s!"{(descriptor (executionRule failure.id)).applicability}: {failure.detail}"

/-- Required meaning of the rendered execution failures: line `k` renders the decision's
record `k`, with no line added or dropped. The lines are therefore empty exactly when
`ExecutionOK` holds, so rendering cannot hide a failure. -/
def ExecutionFailuresContract
    (render : PlumbPolicy.ExecutionInventory → PlumbPolicy.ExecutionClaim → Array String) : Prop :=
  ∀ inventory claim,
    (render inventory claim).size = (PlumbPolicy.executionFailureRecords inventory claim).size ∧
    (∀ k (h : k < (render inventory claim).size)
        (h' : k < (PlumbPolicy.executionFailureRecords inventory claim).size),
      (render inventory claim)[k] =
        executionFailureLine (PlumbPolicy.executionFailureRecords inventory claim)[k]) ∧
    (render inventory claim = #[] ↔ PlumbPolicy.ExecutionOK inventory claim)

private def executionFailuresImpl (inventory : PlumbPolicy.ExecutionInventory)
    (claim : PlumbPolicy.ExecutionClaim) : Array String :=
  (PlumbPolicy.executionFailureRecords inventory claim).map executionFailureLine

/-- Registers `ExecutionFailuresContract` about the executed renderer. -/
theorem checkedExecutionFailures :
    Plumb.ExecutableContract executionFailuresImpl ExecutionFailuresContract := by
  refine ⟨fun inventory claim => ⟨by simp [executionFailuresImpl], fun k _ _ => by
    simp [executionFailuresImpl], ?_⟩⟩
  rw [← PlumbPolicy.executionFailureRecords_empty_iff]
  simp [executionFailuresImpl]

/-- The gate's failure subreasons, through `checkedExecutionFailures`. -/
def executionFailures (inventory : PlumbPolicy.ExecutionInventory)
    (claim : PlumbPolicy.ExecutionClaim) : Array String :=
  checkedExecutionFailures.run inventory claim

end Plumb.Checker.Policy
