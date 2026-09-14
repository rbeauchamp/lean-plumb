/-
Mutation: a `native_decide` proof. The kernel accepts it, but its transitive
axiom set contains a compiler-generated, per-invocation `._native.` axiom in
addition to any standard logical axioms, so it must be reported as
compiler-trusting and rejected on a standard-logical surface.

-/
theorem fixtures_native_proof : (List.range 1001).sum = 500500 := by
  native_decide
