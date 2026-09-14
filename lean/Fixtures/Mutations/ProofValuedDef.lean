/-
Mutation: a proof-valued `def` (a definition whose type is a proposition)
with a hole. Proof-valued definitions are part of the proof surface and must
be policy-checked like theorems.
-/
set_option linter.defProp false in
def fixtures_proof_as_def : False := by sorry
