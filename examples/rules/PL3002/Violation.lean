/-! The identity specification is replaced with extensionally equal code. -/
def alternative (n : Nat) : Nat := 0 + n
@[implemented_by alternative] def identity (n : Nat) : Nat := n
