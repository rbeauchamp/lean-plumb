/-
Positive control: a structurally recursive definition is safe and
termination-checked. Lean may emit an internal range-less partial helper for
compiled execution; the checker must authenticate its exact metadata link to
this safe base rather than mistaking the base for `partial def`.
-/
def fixtures_safe_sum : List Nat → Nat
  | [] => 0
  | x :: xs => x + fixtures_safe_sum xs

theorem fixtures_safe_sum_control : fixtures_safe_sum [1, 2, 3] = 6 := rfl
