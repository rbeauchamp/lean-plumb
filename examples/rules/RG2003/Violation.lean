/-! Identity on natural numbers. -/
def identity (n : Nat) : Nat := (fun unused : Nat => n) 0
