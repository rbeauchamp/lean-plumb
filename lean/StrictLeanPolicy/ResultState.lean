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

end ResultState
end StrictLeanPolicy
