import StrictLean.Contract
/-! Identity on natural numbers, with its full-domain contract. -/
def identity (n : Nat) : Nat := n
theorem contract : StrictLean.ExecutableContract identity (fun f => ∀ n, f n = n) := ⟨fun _ => rfl⟩
