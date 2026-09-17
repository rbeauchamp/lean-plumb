import StrictLeanPolicy.Observation
import StrictLeanPolicy.ResultState

/-! Acceptance of the concrete fixed policy plan. Every required slot is completed and
meets its named stage relation. These are conditional guarantees about observations and
exact report identity, not claims that IO acquisition or semantic intent is verified. -/
namespace StrictLeanPolicy
open Std

/-- Nat slots are only an ordered implementation of the exact frozen JobKey array. -/
def requiredSlots {c : Claim} {i : Census} (p : Plan c i) : CanonicalSet Nat :=
  CanonicalSet.normalize (List.range p.jobs.size)

/-- Payload admission binds each slot to its exact full JobKey and source/config snapshot. -/
def ResultBound {c : Claim} {i : Census} (p : Plan c i) (slot : Nat) (o : JobObservation) : Prop :=
  p.jobs[slot]? = some o.key ∧ o.snapshot = c.val.snapshot
instance {c : Claim} {i : Census} (p : Plan c i) (slot : Nat) (o : JobObservation) :
    Decidable (ResultBound p slot o) := by unfold ResultBound; infer_instance

abbrev ResultTable {c : Claim} {i : Census} (p : Plan c i) := ResultState (requiredSlots p) (ResultBound p)

/-- Completeness quantifies the independent plan, including discovery/build/scan slots when
subject inventories are empty. Unique lookup and absence of extra keys come from ResultState. -/
def CompleteFor {c : Claim} {i : Census} (p : Plan c i) (s : ResultTable p) : Prop :=
  PlanOK c i ∧ ∀ slot ∈ List.range p.jobs.size,
    ∃ o ∈ s.entries[slot]?, o.completion = .completed
instance {c : Claim} {i : Census} (p : Plan c i) (s : ResultTable p) :
    Decidable (CompleteFor p s) := by unfold CompleteFor; infer_instance

/-- Every planned job, rather than every merely returned success, meets its own policy. -/
def AllPolicyOK {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (s : ResultTable p) : Prop :=
  ∀ slot ∈ List.range p.jobs.size, ∃ o ∈ s.entries[slot]?, PolicyOK c i roles o
instance {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy) (s : ResultTable p) :
    Decidable (AllPolicyOK p roles s) := by unfold AllPolicyOK; infer_instance

inductive AcceptanceFailure where
  | incomplete | policyViolation
  deriving Repr, DecidableEq

/-- Mechanical acceptance for these exact claim, census, plan and result inputs. A negative
or teaching example remains an accepted expectation, not a conforming positive program.
No serialized accepted flag can construct either proof. -/
structure Accepted {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy) (s : ResultTable p) : Type where
  complete : CompleteFor p s
  policy : AllPolicyOK p roles s

/-- Recompute completeness and actual pure policy relations after payload admission. -/
def accept {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (s : ResultTable p) : Except AcceptanceFailure (Accepted p roles s) :=
  if hc : CompleteFor p s then
    if hp : AllPolicyOK p roles s then .ok ⟨hc, hp⟩ else .error .policyViolation
  else .error .incomplete

/-- Soundness holds for every admitted plan, role receipt and result table. It does not
assert that any external worker actually completed or that its observation is truthful. -/
theorem accept_sound {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (s : ResultTable p) (a : Accepted p roles s) (_ : accept p roles s = .ok a) :
    CompleteFor p s ∧ AllPolicyOK p roles s := ⟨a.complete, a.policy⟩

/-- Every complete table satisfying all concrete policy predicates is accepted. Completeness
is over the supported finite observed data, not theorem search, extraction or external liveness. -/
theorem accept_complete {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (s : ResultTable p) (h : CompleteFor p s ∧ AllPolicyOK p roles s) :
    ∃ a, accept p roles s = .ok a := by
  exact ⟨⟨h.1, h.2⟩, by simp [accept, h.1, h.2]⟩

/-- No refusal can discard a missing, crashed, pending, or wrong-policy job. -/
theorem accept_iff {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (s : ResultTable p) :
    (∃ a, accept p roles s = .ok a) ↔ CompleteFor p s ∧ AllPolicyOK p roles s := by
  constructor
  · rintro ⟨a, ha⟩; exact accept_sound p roles s a ha
  · exact accept_complete p roles s

/-- Explicit incomplete refusal; no error path produces an Accepted replacement value. -/
theorem accept_incomplete {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (s : ResultTable p) (h : ¬ CompleteFor p s) :
    accept p roles s = .error .incomplete := by simp [accept, h]

/-- Once every worker completed, an unsatisfied policy relation is a policy refusal. -/
theorem accept_policyViolation {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (s : ResultTable p) (hc : CompleteFor p s) (hp : ¬ AllPolicyOK p roles s) :
    accept p roles s = .error .policyViolation := by simp [accept, hc, hp]

/-- Report projection carries the exact accepted inputs; it cannot substitute a different
scope, inventory, job order, or payload table. Renderers and audit exits consume this in #7. -/
structure AcceptedReport where
  claim : Claim
  census : Census
  jobs : Array JobKey
  results : ExtTreeMap Nat JobObservation

def Accepted.report {c : Claim} {i : Census} {p : Plan c i} {roles : Roles i.policy}
    {s : ResultTable p} (_ : Accepted p roles s) : AcceptedReport :=
  ⟨c, i, p.jobs, s.entries⟩

/-- Exact report identity is by construction, not reconstructed from diagnostics or counts. -/
theorem accepted_report_identity {c : Claim} {i : Census} {p : Plan c i} {roles : Roles i.policy}
    {s : ResultTable p} (a : Accepted p roles s) :
    a.report.claim = c ∧ a.report.census = i ∧ a.report.jobs = p.jobs ∧ a.report.results = s.entries :=
  ⟨rfl, rfl, rfl, rfl⟩

/-- Every populated entry is an exact planned key, with no out-of-plan observations. -/
theorem result_bound {c : Claim} {i : Census} (p : Plan c i) (s : ResultTable p)
    (slot : Nat) (o : JobObservation) (h : s.entries[slot]? = some o) :
    slot < p.jobs.size ∧ p.jobs[slot]? = some o.key ∧ o.snapshot = c.val.snapshot := by
  have hv := s.valid slot o h
  exact ⟨by simpa [requiredSlots] using hv.1, hv.2⟩

/-- Each required slot has exactly one completed, correctly bound policy observation. -/
theorem accepted_covers_slot {c : Claim} {i : Census} {p : Plan c i} {roles : Roles i.policy}
    {s : ResultTable p} (a : Accepted p roles s) (slot : Nat) (hs : slot < p.jobs.size) :
    ∃ o, s.entries[slot]? = some o ∧ p.jobs[slot]? = some o.key ∧ PolicyOK c i roles o ∧
      ∀ other, s.entries[slot]? = some other → other = o := by
  rcases a.policy slot (by simpa using hs) with ⟨o, ho, hp⟩
  have lookup : s.entries[slot]? = some o := by simpa using ho
  refine ⟨o, lookup, (result_bound p s slot o lookup).2.1, hp, ?_⟩
  intro other hother
  rw [lookup] at hother
  exact (Option.some.inj hother).symm
/-- Collection failures and completed-policy refusals remain distinct. -/
inductive FinalizationFailure where
  | collection (reason : AdmissionFailure)
  | acceptance (reason : AcceptanceFailure)
  deriving Repr, DecidableEq

/-- The executable collector's result and acceptance travel together. The input index
retains the full response sequence, including multiplicity, instead of trusting wire flags.
This follows con-leche's checked-record/collection architecture without importing it. -/
structure Finalized {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (inputs : List (Nat × JobObservation)) where
  table : ResultTable p
  collected : ResultState.collect .empty inputs = .ok table
  accepted : Accepted p roles table

/-- The sole pure finalization path collects every response, then recomputes the approved
policies for every independently required slot. Neither stage can supply a shorter plan. -/
def finalize {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (inputs : List (Nat × JobObservation)) : Except FinalizationFailure (Finalized p roles inputs) :=
  match hc : ResultState.collect (bound := ResultBound p) .empty inputs with
  | .error failure => .error (.collection failure)
  | .ok table => match accept p roles table with
    | .error failure => .error (.acceptance failure)
    | .ok accepted => .ok ⟨table, hc, accepted⟩

/-- A finalized report is projected from its actual Accepted evidence. -/
def Finalized.report {c : Claim} {i : Census} {p : Plan c i} {roles : Roles i.policy}
    {inputs : List (Nat × JobObservation)} (result : Finalized p roles inputs) : AcceptedReport :=
  result.accepted.report

/-- Independent specification over the raw response sequence: no duplicate, unknown,
or misbound observations, and actual policy evidence for each required plan position. -/
def InputsOK {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (inputs : List (Nat × JobObservation)) : Prop :=
  ResultState.BatchOK (ResultState.empty : ResultTable p) inputs ∧
  ∀ slot ∈ List.range p.jobs.size,
    ∃ o, (slot, o) ∈ inputs ∧ PolicyOK c i roles o

/-- Finalized coverage refers to actual supplied observations, not just abstract state
invariants. Exact report identity and the full required domain are retained. -/
theorem finalized_covers_input {c : Claim} {i : Census} {p : Plan c i}
    {roles : Roles i.policy} {inputs : List (Nat × JobObservation)}
    (result : Finalized p roles inputs) (slot : Nat) (hs : slot < p.jobs.size) :
    ∃ o, (slot, o) ∈ inputs ∧ p.jobs[slot]? = some o.key ∧ PolicyOK c i roles o := by
  obtain ⟨o, lookup, key, policy, _⟩ := accepted_covers_slot result.accepted slot hs
  exact ⟨o, (ResultState.collect_empty_lookup inputs result.table result.collected slot o).mp lookup,
    key, policy⟩

/-- Completeness and policies on a collected table correspond exactly to the supplied
observations for every required slot. External producer truth is not assumed by this lemma. -/
private theorem collected_policy_iff {c : Claim} {i : Census} (p : Plan c i)
    (roles : Roles i.policy) (inputs : List (Nat × JobObservation)) (table : ResultTable p)
    (hc : ResultState.collect .empty inputs = .ok table) :
    CompleteFor p table ∧ AllPolicyOK p roles table ↔
      ∀ slot ∈ List.range p.jobs.size, ∃ o, (slot, o) ∈ inputs ∧ PolicyOK c i roles o := by
  constructor
  · rintro ⟨_, policy⟩ slot member
    obtain ⟨o, ho, hp⟩ := policy slot member
    exact ⟨o, (ResultState.collect_empty_lookup inputs table hc slot o).mp ho, hp⟩
  · intro policy
    have actual : AllPolicyOK p roles table := by
      intro slot member
      obtain ⟨o, ho, hp⟩ := policy slot member
      exact ⟨o, (ResultState.collect_empty_lookup inputs table hc slot o).mpr ho, hp⟩
    refine ⟨⟨p.valid, ?_⟩, actual⟩
    intro slot member
    obtain ⟨o, ho, hp⟩ := actual slot member
    exact ⟨o, ho, hp.2.2.1⟩

/-- Exact whole-domain success theorem for the executable collector/finalizer. This is
universal over response count/order/payloads and the independently supplied claim/plan;
no worker-success, failure-array, or producer-completeness premise is used. -/
theorem finalize_iff {c : Claim} {i : Census} (p : Plan c i) (roles : Roles i.policy)
    (inputs : List (Nat × JobObservation)) :
    (∃ result, finalize p roles inputs = .ok result) ↔ InputsOK p roles inputs := by
  constructor
  · rintro ⟨result, _⟩
    refine ⟨(ResultState.collect_success_iff inputs (ResultState.empty : ResultTable p)).mp
      ⟨result.table, result.collected⟩, ?_⟩
    exact (collected_policy_iff p roles inputs result.table result.collected).mp
      ⟨result.accepted.complete, result.accepted.policy⟩
  · rintro ⟨batch, policy⟩
    obtain ⟨table, hc⟩ := (ResultState.collect_success_iff inputs (ResultState.empty : ResultTable p)).mpr batch
    obtain ⟨accepted, ha⟩ := accept_complete p roles table
      ((collected_policy_iff p roles inputs table hc).mpr policy)
    refine ⟨⟨table, hc, accepted⟩, ?_⟩
    unfold finalize
    split
    next failure he => rw [hc] at he; contradiction
    next observed he =>
      have eq : observed = table := Except.ok.inj (he.symm.trans hc)
      subst observed
      rw [ha]

/-- The request index remains fixed through the operational boundary. The census is
obtained externally, while its plan, roles, collected observations and acceptance are
all checked here. Constructors require every proof; serialized reports carry none. -/
structure AcceptedRun (c : Claim) where
  census : Census
  plan : Plan c census
  roles : Roles census.policy
  inputs : List (Nat × JobObservation)
  result : Finalized plan roles inputs

/-- Renderers receive the report of the same accepted request, never an independently
constructed report or a status inferred from an empty diagnostic array. -/
def AcceptedRun.report {c : Claim} (run : AcceptedRun c) : AcceptedReport := run.result.report

/-- Projection cannot replace the requested scope/mode/snapshot. -/
theorem acceptedRun_claim {c : Claim} (run : AcceptedRun c) : run.report.claim = c := rfl

/-- Combined ordinary acceptance retains both independently complete plans, indexed by
one exact snapshot and the requested Markdown inventory. Neither component is promoted
to the other's scope; negative/teaching fences remain expectation evidence. -/
structure CombinedAccepted (projectClaim documentClaim : Claim) (documents : Array SourceSnapshot) where
  project : AcceptedRun projectClaim
  documentation : AcceptedRun documentClaim
  projectScope : projectClaim.val.scope = .project
  projectMode : projectClaim.val.mode = .freshProject
  documentScope : documentClaim.val.scope = .documentation documents
  documentMode : documentClaim.val.mode = .documentationExample
  sameSnapshot : projectClaim.val.snapshot = documentClaim.val.snapshot

def combineAccepted {pc dc : Claim} (documents : Array SourceSnapshot)
    (project : AcceptedRun pc) (documentation : AcceptedRun dc) :
    Except String (CombinedAccepted pc dc documents) :=
  if h : pc.val.scope = .project ∧ pc.val.mode = .freshProject ∧
      dc.val.scope = .documentation documents ∧ dc.val.mode = .documentationExample ∧
      pc.val.snapshot = dc.val.snapshot then
    .ok ⟨project, documentation, h.1, h.2.1, h.2.2.1, h.2.2.2.1, h.2.2.2.2⟩
  else .error "combined acceptance scope, mode, document inventory or snapshot mismatch"

/-- Composition preserves both exact accepted reports and their common snapshot. -/
theorem combined_reports_same_snapshot {pc dc : Claim} {documents : Array SourceSnapshot}
    (accepted : CombinedAccepted pc dc documents) :
    accepted.project.report.claim = pc ∧ accepted.documentation.report.claim = dc ∧
      accepted.project.report.claim.val.snapshot = accepted.documentation.report.claim.val.snapshot :=
  ⟨rfl, rfl, accepted.sameSnapshot⟩

/-- Both whole-domain capstones remain available at the composed public success boundary. -/
theorem combined_policy {pc dc : Claim} {documents : Array SourceSnapshot}
    (accepted : CombinedAccepted pc dc documents) :
    (CompleteFor accepted.project.plan accepted.project.result.table ∧
      AllPolicyOK accepted.project.plan accepted.project.roles accepted.project.result.table) ∧
    (CompleteFor accepted.documentation.plan accepted.documentation.result.table ∧
      AllPolicyOK accepted.documentation.plan accepted.documentation.roles accepted.documentation.result.table) :=
  ⟨⟨accepted.project.result.accepted.complete, accepted.project.result.accepted.policy⟩,
    ⟨accepted.documentation.result.accepted.complete, accepted.documentation.result.accepted.policy⟩⟩

end StrictLeanPolicy
