/-
Mutation: a `partial` definition. Termination is not checked by the kernel
for partial definitions; the declaration is an escape hatch that must not
appear on a conforming positive surface.
-/
partial def fixtures_spin (n : Nat) : Nat := fixtures_spin n
