import Std.Data.ExtTreeSet
import Std.Data.ExtTreeMap

/-! Canonical finite sets reuse Std's extensional ordered trees. Tree balancing is
not observable equality. Sorted serialization, membership, normalization and equality
are consequences of Std's laws, not a second hand-written set implementation. -/
namespace StrictLeanPolicy
open Std

abbrev CanonicalSet (α : Type u) [Ord α] := ExtTreeSet α

namespace CanonicalSet
variable {α : Type u} [Ord α] [TransOrd α] [LawfulEqOrd α]
  [BEq α] [LawfulBEq α]

/-- Normalize set-valued observations; never use this to admit result observations,
whose duplicates must instead be rejected. -/
def normalize (xs : List α) : CanonicalSet α := ExtTreeSet.ofList xs

/-- Exact membership for every finite input, including repetitions. -/
@[simp] theorem mem_normalize (xs : List α) (x : α) :
    x ∈ normalize xs ↔ x ∈ xs := by
  simp [normalize, ExtTreeSet.mem_ofList]

/-- Re-admitting a canonical serialization yields the identical extensional set. -/
@[simp] theorem normalize_toList (s : CanonicalSet α) : normalize s.toList = s := by
  apply ExtTreeSet.ext_mem
  intro x
  simp [ExtTreeSet.mem_toList]

/-- Normalization is idempotent through its sorted wire projection. -/
theorem normalize_idempotent (xs : List α) :
    normalize (normalize xs).toList = normalize xs := normalize_toList _

/-- Equality is exactly finite membership agreement, regardless of input order. -/
theorem normalize_eq_iff (xs ys : List α) :
    normalize xs = normalize ys ↔ ∀ x, x ∈ xs ↔ x ∈ ys := by
  constructor
  · intro h x
    have := congrArg (fun s : CanonicalSet α => x ∈ s) h
    simpa using this
  · intro h
    apply ExtTreeSet.ext_mem
    simpa using h

omit [LawfulEqOrd α] [BEq α] [LawfulBEq α] in
/-- Serialization is sorted by the supplied lawful structural comparator. -/
theorem sorted (s : CanonicalSet α) :
    s.toList.Pairwise (fun a b => compare a b = .lt) := ExtTreeSet.ordered_toList

omit [LawfulEqOrd α] [BEq α] [LawfulBEq α] in
/-- No two serialized elements compare equal. -/
theorem unique (s : CanonicalSet α) :
    s.toList.Pairwise (fun a b => compare a b ≠ .eq) := ExtTreeSet.distinct_toList

omit [BEq α] [LawfulBEq α] in
/-- Lookup returns the exact queried member, not another display-equivalent value. -/
theorem lookup (s : CanonicalSet α) (x : α) (h : x ∈ s) :
    s.get? x = some x := ExtTreeSet.get?_eq_some h
end CanonicalSet

/-- Exactly one occurrence exists, and that occurrence satisfies the required relation.
Equality to a singleton refuses duplicate occurrences even when their values agree. -/
def ExactlyOne (xs : Array α) (P : α → Prop) : Prop := ∃ x, xs = #[x] ∧ P x

/-- The only possible singleton witness is the first element. This correspondence lets
execution inspect that candidate once instead of scanning the array once per candidate. -/
theorem exactlyOne_iff_head (xs : Array α) (P : α → Prop) :
    ExactlyOne xs P ↔ ∃ x ∈ xs[0]?, xs = #[x] ∧ P x := by
  constructor
  · rintro ⟨x, rfl, hp⟩
    exact ⟨x, by simp, rfl, hp⟩
  · rintro ⟨x, _, hx, hp⟩
    exact ⟨x, hx, hp⟩

/-- A proved decision procedure using at most one witness candidate. Equality still
checks the complete occurrence sequence; this is not an unchecked length shortcut. -/
instance [DecidableEq α] (xs : Array α) (P : α → Prop) [DecidablePred P] :
    Decidable (ExactlyOne xs P) :=
  decidable_of_iff (∃ x ∈ xs[0]?, xs = #[x] ∧ P x) (exactlyOne_iff_head xs P).symm

end StrictLeanPolicy
