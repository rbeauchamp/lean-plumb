/-
Positive control: an owned external declaration (`@[extern]`). The reference
body is kernel-checked and the exact transitive axiom set is unchanged, so
the logical audit passes; but compiled execution calls the named external
symbol, whose behavior the body does not establish. The checker must report
the declaration as a **trusted** external execution boundary rather than
failing the logical classification or hiding the edge.
-/
@[extern "lean_fixtures_ext_fn"]
def fixtures_ext_fn (n : Nat) : Nat := n + 1
