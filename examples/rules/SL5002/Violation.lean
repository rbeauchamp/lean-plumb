import StrictLean.MaterialClaim
/-! Reflexivity for every natural number; `reflexive` supplies its evidence. -/
@[strict_lean_material] theorem reflexive (n : Nat) : n = n := rfl
