/-
Positive control: every declaration below is **choice-free** — its exact
transitive axiom set is a subset of `{propext, Quot.sound}`. Functional
extensionality and propositional extensionality are exactly the two
non-kernel principles permitted in this profile.
-/
theorem fixtures_cf_propext (a b : Prop) (h : a ↔ b) : a = b := propext h

theorem fixtures_cf_funext (f g : Nat → Nat) (h : ∀ n, f n = g n) : f = g :=
  funext h
