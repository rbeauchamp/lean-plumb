/-
Positive control: an owned runtime replacement (`@[implemented_by]`) is not a
logical violation — the kernel statement and the exact transitive axiom set
are unchanged. It is, however, an execution boundary: compiled execution runs
the replacement, not the reference definition. The checker must pass the
logical audit while reporting the replacement as a **trusted**
runtime-replacement boundary, because nothing in this module proves the
replacement corresponds to the reference. The unmarked wrapper demonstrates
that a standard-logical PASS is not an unconditional execution guarantee: its
closure reaches the replacement through an ordinary call.
-/
def fixtures_twice_impl (n : Nat) : Nat := 2 * n

@[implemented_by fixtures_twice_impl]
def fixtures_twice (n : Nat) : Nat := n + n

def fixtures_twice_user (n : Nat) : Nat := fixtures_twice n + fixtures_twice 1
