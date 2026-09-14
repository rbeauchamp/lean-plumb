/-
Mutation: a declaration claimed as choice-free whose choice dependence is
*transitive* — it is proved over `ℝ`, whose Mathlib construction goes
through a rational Cauchy completion and the classical linear-order instance.
Importing Mathlib is not itself disqualifying; the transitive axiom set
decides the label.
-/
import Mathlib.Data.Real.Basic

theorem fixtures_transitive_choice (x : ℝ) : x ≤ x := le_refl x
