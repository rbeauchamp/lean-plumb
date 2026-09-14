/-
Mutation: an `unsafe` definition. Unsafe declarations bypass kernel
soundness guarantees and must not appear on a conforming positive surface.

-/
unsafe def fixtures_unsafe_id (n : Nat) : Nat := n
