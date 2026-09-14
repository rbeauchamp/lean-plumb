/-
Mutation: an unmarked `sorry`. The hole is reported through the environment
(`sorryAx` in the declaration's transitive axiom set), not through source
text.
-/
theorem fixtures_hidden_sorry : 1 = 2 := by sorry
