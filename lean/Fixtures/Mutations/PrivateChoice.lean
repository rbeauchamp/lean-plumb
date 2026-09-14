/-
Mutation: an unused private theorem whose proof depends on classical choice.
Private declarations remain part of their owning module's proof surface and
must obey its claimed foundation profile.
-/
private theorem fixtures_private_choice (p : Prop) : p ∨ ¬p := Classical.em p
