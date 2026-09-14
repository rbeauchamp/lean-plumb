/-
Positive control: an unmarked `Float32` addition
wrapper passes the standard-logical audit — its exact transitive axiom set is
`{propext, Classical.choice, Quot.sound}` — while its execution closure
reaches native arithmetic (`Float32.add`, an `Init`-owned `@[extern]`
primitive). The checker must pass the logical audit and report the
native-runtime boundary as **trusted**, demonstrating that the logical label
is exact and distinct from execution correspondence.
-/
def fixtures_float32_add (a b : Float32) : Float32 := a + b
