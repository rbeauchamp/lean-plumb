/-
Mutation: a declaration that directly uses `Classical.choice` while claimed
as choice-free.
-/
theorem fixtures_direct_choice (p : Prop) : p ∨ ¬p := Classical.em p
