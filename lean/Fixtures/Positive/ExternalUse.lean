/-
External-consumer control (AC-08): a small fixture that only imports the
published `Audit` library and reasons about its declarations. The public
checker classifies the declarations introduced here and reports the exact
foundation labels — without adopting any general software process.

`#print axioms` confirms what the checker reports:
`Glossary.Probability` depends on `propext`, `Classical.choice`, and
`Quot.sound` (Standard-Logical), because it is defined over `ℝ`.
-/
import Audit

theorem ext_probability_range (p : Glossary.Probability) :
    0 ≤ p.val ∧ p.val ≤ 1 := p.property

theorem ext_real_le_refl (x : ℝ) : x ≤ x := le_refl x
