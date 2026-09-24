import Plumb.MaterialClaim
/-! Reflexivity for every natural number; `reflexive` supplies its evidence. -/
/-- Every natural number equals itself, without additional hypotheses.

# Intent
Equality on natural numbers must be reflexive for every value, with no side condition. -/
@[plumb_material] theorem reflexive (n : Nat) : n = n := rfl
