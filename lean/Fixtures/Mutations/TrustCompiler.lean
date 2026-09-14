/-
Mutation: a proof depending directly on Lean's compiler-trust axiom. It must be
classified as compiler-trusting even though no `native_decide` auxiliary name
is present.
-/
set_option linter.deprecated false in
theorem fixtures_direct_trust_compiler : True := Lean.trustCompiler
