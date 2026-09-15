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
end StrictLeanPolicy
