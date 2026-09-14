/-
Positive control: every declaration below is **standard-logical** — its exact
transitive axiom set is a subset of
`{propext, Quot.sound, Classical.choice}`. Using Lean's standard logical
axioms is not a defect; the requirement is that the label be reported
honestly and never conflated with the choice-free profile.
-/
theorem fixtures_sl_em (p : Prop) : p ∨ ¬p := Classical.em p

theorem fixtures_sl_by_contra (n : Nat) : n ≠ 0 → 0 < n := by
  intro h
  omega
