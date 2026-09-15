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
end ResultState
end StrictLeanPolicy
