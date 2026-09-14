/-
Mutation: an unsafe opaque declaration. Checking only ordinary unsafe
definitions would miss this constant kind; every `ConstantInfo` is subject to
the same escape-hatch policy.
-/
unsafe opaque fixtures_unsafe_opaque : Nat := 0
