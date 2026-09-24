import Plumb.MaterialClaim
/-! Reflexivity for every natural number; `reflexive` supplies its evidence. -/
@[plumb_material] theorem reflexive (n : Nat) : n = n := rfl
