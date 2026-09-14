/-
Positive control: a runtime replacement with **checked** correspondence. The
general equality between the reference definition and its
`@[implemented_by]` replacement is proved by an ordinary standard-logical
theorem, so the boundary is reported as checked and the surface passes even
under a checked-correspondence execution claim (`--execution checked`).

-/
def fixtures_checked_twice_impl (n : Nat) : Nat := 2 * n

@[implemented_by fixtures_checked_twice_impl]
def fixtures_checked_twice (n : Nat) : Nat := n + n

theorem fixtures_checked_twice_correspondence :
    fixtures_checked_twice = fixtures_checked_twice_impl :=
  funext fun n => (Nat.two_mul n).symm
