import StrictLeanPolicy.Collections

/-! Invariant-preserving finite result admission. The required key set and binding
relation are parameters fixed by the caller's plan. This module proves representation
closure, not that an external census is complete or a policy observation is true. -/
namespace StrictLeanPolicy
open Std

inductive AdmissionFailure where
  | unknownKey | duplicateResult | invalidBinding
  deriving Repr, DecidableEq

/-- Every occupied slot belongs to the fixed plan and satisfies its payload binding.
Std's extensional map supplies unique lookup. `insertResult` refuses occupied slots;
direct proof-bearing construction enforces only this stated subset/binding invariant. -/
structure ResultState {κ : Type u} {β : Type v} [Ord κ] [TransOrd κ]
    (required : CanonicalSet κ) (bound : κ → β → Prop) where
  entries : ExtTreeMap κ β
  valid : ∀ k v, entries[k]? = some v → k ∈ required ∧ bound k v

namespace ResultState
variable {κ : Type u} {β : Type v} [Ord κ] [TransOrd κ] [LawfulEqOrd κ]
  {required : CanonicalSet κ} {bound : κ → β → Prop}

/-- Empty state contains no result claims, including for a nonempty required plan. -/
def empty : ResultState required bound :=
  ⟨∅, by intro k v h; simp at h⟩

/-- Admission checks membership, then occupancy, then binding. Failure returns no
replacement state; the immutable previous state remains available unchanged. -/
def insertResult [DecidableRel bound] (s : ResultState required bound) (k : κ) (v : β) :
    Except AdmissionFailure (ResultState required bound) :=
  if hk : k ∈ required then
    if s.entries[k]?.isSome then .error .duplicateResult
    else if hb : bound k v then
      .ok ⟨s.entries.insert k v, by
        intro key value h
        rw [ExtTreeMap.getElem?_insert] at h
        split at h
        next he =>
          have eq := LawfulEqOrd.eq_of_compare he
          subst key
          cases h
          exact ⟨hk, hb⟩
        next => exact s.valid key value h⟩
    else .error .invalidBinding
  else .error .unknownKey

/-- Every successful insertion carries exactly the state invariant, for all payloads. -/
theorem insertResult_valid [DecidableRel bound] (s : ResultState required bound)
    (k : κ) (v : β) (next : ResultState required bound)
    (_ : insertResult s k v = .ok next) :
    ∀ key value, next.entries[key]? = some value → key ∈ required ∧ bound key value :=
  next.valid

/-- An occupied key is rejected even if the repeated payload is identical. -/
theorem duplicate_refused [DecidableRel bound] (s : ResultState required bound)
    (k : κ) (v old : β) (h : s.entries[k]? = some old) :
    insertResult s k v = .error .duplicateResult := by
  have hk := (s.valid k old h).1
  simp [insertResult, hk, h]

omit [LawfulEqOrd κ] in
/-- States with the same map are equal; invariant proofs add no observational state. -/
theorem ext (s t : ResultState required bound) (h : s.entries = t.entries) : s = t := by
  cases s
  cases t
  cases h
  rfl

/-- Success stores the requested map insertion, not merely some invariant-preserving state. -/
theorem insertResult_entries [DecidableRel bound] (s : ResultState required bound)
    (k : κ) (v : β) (next : ResultState required bound)
    (h : insertResult s k v = .ok next) : next.entries = s.entries.insert k v := by
  unfold insertResult at h
  split at h
  · split at h
    · cases h
    · split at h
      · cases h; rfl
      · cases h
  · cases h

/-- Every admissible fresh binding succeeds; unknown, duplicate and invalid observations
are the only refusals of this finite insertion API. -/
theorem insertResult_complete [DecidableRel bound] (s : ResultState required bound)
    (k : κ) (v : β) (hk : k ∈ required) (hf : s.entries[k]? = none) (hb : bound k v) :
    ∃ next, insertResult s k v = .ok next := by
  simp [insertResult, hk, hf, hb]

/-- Successful insertion installs the exact requested payload. -/
theorem insertResult_lookup [DecidableRel bound] (s : ResultState required bound)
    (k : κ) (v : β) (next : ResultState required bound)
    (h : insertResult s k v = .ok next) : next.entries[k]? = some v := by
  rw [insertResult_entries s k v next h]
  simp

/-- Every other lookup is preserved, including existing completed observations. -/
theorem insertResult_frame [DecidableRel bound] (s : ResultState required bound)
    (k other : κ) (v : β) (next : ResultState required bound)
    (h : insertResult s k v = .ok next) (hne : other ≠ k) :
    next.entries[other]? = s.entries[other]? := by
  rw [insertResult_entries s k v next h, ExtTreeMap.getElem?_insert]
  split
  next he => exact False.elim (hne (LawfulEqOrd.eq_of_compare he).symm)
  next => rfl

/-- Unknown keys are refused before considering a payload or binding. -/
theorem unknown_refused [DecidableRel bound] (s : ResultState required bound)
    (k : κ) (v : β) (hk : k ∉ required) :
    insertResult s k v = .error .unknownKey := by simp [insertResult, hk]

/-- A fresh required key with invalid payload binding is refused. No replacement state
is returned, so refusal cannot replace or modify the immutable input map. -/
theorem binding_refused [DecidableRel bound] (s : ResultState required bound)
    (k : κ) (v : β) (hk : k ∈ required) (hf : s.entries[k]? = none) (hb : ¬ bound k v) :
    insertResult s k v = .error .invalidBinding := by simp [insertResult, hk, hf, hb]

/-- Exact success admission conditions, universally quantified over payloads and keys. -/
theorem insertResult_success_iff [DecidableRel bound] (s : ResultState required bound)
    (k : κ) (v : β) :
    (∃ next, insertResult s k v = .ok next) ↔
      k ∈ required ∧ s.entries[k]? = none ∧ bound k v := by
  constructor
  · rintro ⟨next, h⟩
    unfold insertResult at h
    split at h
    next hk =>
      split at h
      · cases h
      next hf =>
        split at h
        next hb => exact ⟨hk, by simpa using hf, hb⟩
        next => cases h
    next => cases h
  · rintro ⟨hk, hf, hb⟩
    exact insertResult_complete s k v hk hf hb

/-- Collect the complete supplied sequence without filtering, normalizing or overwriting
any occurrence. Failure exposes no partial replacement table. Both operational worker
admission and the concrete acceptance finalizer use this fold. -/
def collect [DecidableRel bound] (s : ResultState required bound) :
    List (κ × β) → Except AdmissionFailure (ResultState required bound)
  | [] => .ok s
  | (k, v) :: rest => match insertResult s k v with
    | .error failure => .error failure
    | .ok next => collect next rest

/-- Independent batch specification: distinct keys, each required, initially vacant,
and bound to its actual supplied payload. It does not assume the collector succeeds. -/
def BatchOK (s : ResultState required bound) (inputs : List (κ × β)) : Prop :=
  (inputs.map Prod.fst).Nodup ∧
  ∀ entry ∈ inputs, entry.1 ∈ required ∧ s.entries[entry.1]? = none ∧ bound entry.1 entry.2

/-- A successful fold retains precisely the previous entries and all supplied pairs.
In particular, the collector cannot invent, silently omit, or replace an observation. -/
theorem collect_lookup [DecidableRel bound] (inputs : List (κ × β))
    (s final : ResultState required bound) (h : collect s inputs = .ok final)
    (key : κ) (value : β) :
    final.entries[key]? = some value ↔
      s.entries[key]? = some value ∨ (key, value) ∈ inputs := by
  induction inputs generalizing s with
  | nil => cases h; simp
  | cons entry rest ih =>
    rcases entry with ⟨k, v⟩
    simp only [collect] at h
    cases hi : insertResult s k v with
    | error failure => simp [hi] at h
    | ok next =>
      simp only [hi] at h
      rw [ih next h]
      have conditions := (insertResult_success_iff s k v).mp ⟨next, hi⟩
      by_cases he : key = k
      · subst key
        rw [insertResult_lookup s k v next hi, conditions.2.1]
        simp [eq_comm]
      · rw [insertResult_frame s k key v next hi he]
        simp [he]

/-- A step consumes exactly one fresh input obligation; the remaining obligations
refer to the actual new table. This proves the fold against a nonrecursive specification. -/
private theorem batchOK_step [DecidableRel bound] (s next : ResultState required bound)
    (k : κ) (v : β) (rest : List (κ × β)) (hi : insertResult s k v = .ok next) :
    BatchOK s ((k, v) :: rest) ↔ BatchOK next rest := by
  have conditions := (insertResult_success_iff s k v).mp ⟨next, hi⟩
  constructor
  · rintro ⟨unique, valid⟩
    refine ⟨(List.nodup_cons.mp unique).2, ?_⟩
    intro entry member
    have hv := valid entry (List.mem_cons_of_mem _ member)
    have different : entry.1 ≠ k := by
      intro eq
      apply (List.nodup_cons.mp unique).1
      exact List.mem_map.mpr ⟨entry, member, eq⟩
    exact ⟨hv.1, (insertResult_frame s k entry.1 v next hi different).trans hv.2.1, hv.2.2⟩
  · rintro ⟨unique, valid⟩
    have different : ∀ entry ∈ rest, entry.1 ≠ k := by
      intro entry member eq
      have vacant := (valid entry member).2.1
      rw [eq, insertResult_lookup s k v next hi] at vacant
      contradiction
    refine ⟨?_, ?_⟩
    · simp only [List.map_cons, List.nodup_cons]
      refine ⟨?_, unique⟩
      rintro member
      obtain ⟨entry, hm, eq⟩ := List.mem_map.mp member
      exact different entry hm eq
    · intro entry member
      rcases List.mem_cons.mp member with rfl | member
      · exact conditions
      · have hv := valid entry member
        exact ⟨hv.1, (insertResult_frame s k entry.1 v next hi (different entry member)).symm.trans hv.2.1,
          hv.2.2⟩

/-- Universal success characterization for the executed fold, including every sequence
length and payload. Missing whole-plan coverage is checked separately by `accept`. -/
theorem collect_success_iff [DecidableRel bound] (inputs : List (κ × β))
    (s : ResultState required bound) :
    (∃ final, collect s inputs = .ok final) ↔ BatchOK s inputs := by
  induction inputs generalizing s with
  | nil => simp [collect, BatchOK]
  | cons entry rest ih =>
    rcases entry with ⟨k, v⟩
    constructor
    · rintro ⟨final, h⟩
      simp only [collect] at h
      cases hi : insertResult s k v with
      | error failure => simp [hi] at h
      | ok next =>
        simp only [hi] at h
        exact (batchOK_step s next k v rest hi).mpr ((ih next).mp ⟨final, h⟩)
    · intro valid
      have head := valid.2 (k, v) (by simp)
      obtain ⟨next, hi⟩ := (insertResult_success_iff s k v).mpr head
      obtain ⟨final, hf⟩ := (ih next).mpr ((batchOK_step s next k v rest hi).mp valid)
      exact ⟨final, by simp [collect, hi, hf]⟩

/-- Starting empty, every result lookup is exactly a supplied occurrence. -/
theorem collect_empty_lookup [DecidableRel bound] (inputs : List (κ × β))
    (final : ResultState required bound) (h : collect .empty inputs = .ok final)
    (key : κ) (value : β) :
    final.entries[key]? = some value ↔ (key, value) ∈ inputs := by
  simpa [empty] using collect_lookup inputs .empty final h key value

end ResultState
end StrictLeanPolicy
