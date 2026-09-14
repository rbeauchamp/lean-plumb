/-
Mutation: an authored partial declaration imitates Lean's generated
`._unsafe_rec` spelling and matches a safe base's type. Its own elaborated
declaration is not the range-less helper for that safe base, and the real
generated helper points to this partial/opaque declaration. Name and type shape
alone must not waive either one.
-/
def Attack (n : Nat) : Nat := n

partial def Attack._unsafe_rec (n : Nat) : Nat := Attack._unsafe_rec n
