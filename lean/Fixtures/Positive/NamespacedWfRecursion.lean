/-
Positive control: well-founded and structural recursion away from the top
level. The decreasing proofs are ordinary `exact` blocks, not the
`clean_wf`/`simp`/`omega` spelling, and the declarations appear inside a
`namespace … end` block and under a dotted declaration name. The checker must
authenticate the generated helpers at any namespace depth and for any
decreasing tactic block.
-/
namespace RecursionProbe

def nsCountdown (n : Nat) : Nat :=
  if h : n = 0 then 0 else nsCountdown (n - 1) + 1
termination_by n
decreasing_by
  exact Nat.sub_lt (Nat.pos_of_ne_zero h) (Nat.zero_lt_succ 0)

end RecursionProbe

def RecursionProbe.Dotted.dottedCountdown (n : Nat) : Nat :=
  if h : n = 0 then 0 else RecursionProbe.Dotted.dottedCountdown (n - 1) + 1
termination_by n
decreasing_by
  exact Nat.sub_lt (Nat.pos_of_ne_zero h) (Nat.zero_lt_succ 0)

def RecursionProbe.Dotted.dottedSum : List Nat → Nat
  | [] => 0
  | x :: xs => x + RecursionProbe.Dotted.dottedSum xs
