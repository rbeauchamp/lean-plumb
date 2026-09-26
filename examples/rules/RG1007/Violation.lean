import Regula.Contract
/-! Identity on natural numbers, with its full-domain contract. -/
def identity (n : Nat) : Nat := n
theorem contract (n : Nat) : Regula.ExecutableContract (identity n) (fun value => value = n) := ⟨rfl⟩
