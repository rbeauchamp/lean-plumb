/-! The identity specification and replacement agree on every input. -/
def alternative (n : Nat) : Nat := 0 + n
@[implemented_by alternative] def identity (n : Nat) : Nat := n
theorem correspondence (n : Nat) : identity n = alternative n := (Nat.zero_add n).symm
