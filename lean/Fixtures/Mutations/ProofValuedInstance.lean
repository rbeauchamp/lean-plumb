/-
Mutation: a genuinely proposition-valued class instance whose construction is
a hole. Both `instance` metadata and `isProp` come from elaboration; the
`sorryAx` carrier must be policy-checked like any declaration.

-/
class FixturesWitness (p : Prop) : Prop where
  witness : p

instance fixtures_proof_instance (p : Prop) : FixturesWitness p := by sorry
