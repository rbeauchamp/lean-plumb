/-
Mutation: an attributed theorem with a hole. The old regex gate discovered
only bare `^theorem` spellings; attribute-carrying declarations must be
discovered too.
-/
@[simp] theorem fixtures_attributed_sorry : False := by sorry
