/-! Agreement only on the diagonal omits an independent input. -/
def fixtures_repeated_impl (_n m : Nat) : Nat := m
@[implemented_by fixtures_repeated_impl]
def fixtures_repeated_reference (_n _m : Nat) : Nat := _n
theorem fixtures_repeated_correspondence (n : Nat) :
    fixtures_repeated_reference n n = fixtures_repeated_impl n n := rfl
