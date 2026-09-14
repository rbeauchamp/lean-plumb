/-
Positive control: well-founded recursion. A top-level well-founded
recursive definition with an explicit `termination_by`/`decreasing_by` block
is safe and termination-checked. Lean emits an internal range-less partial
helper for compiled execution; the checker must authenticate its exact
metadata link to this safe base without requiring a namespaced declaration or
a particular decreasing tactic spelling.
-/

/-- A total recursive function with an explicit decrease proof. -/
def countdown (n : Nat) : Nat :=
  if h : n = 0 then 0 else countdown (n - 1) + 1
termination_by n
decreasing_by
  exact Nat.sub_lt (Nat.pos_of_ne_zero h) (Nat.zero_lt_succ 0)
