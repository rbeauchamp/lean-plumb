import Plumb.MaterialClaim
/-! Reflexivity for every natural number; `reflexive` supplies its evidence. -/
/-- Every natural number equals itself, without additional hypotheses. -/
@[plumb_material] theorem reflexive (n : Nat) : n = n := rfl
