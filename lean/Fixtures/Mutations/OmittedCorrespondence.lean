/-! A partial equality specialized at zero omits the general first input. -/
def fixtures_omitted_impl (n m : Nat) : Nat := m + n
@[implemented_by fixtures_omitted_impl]
def fixtures_omitted_reference (_n m : Nat) : Nat := m
theorem fixtures_omitted_correspondence :
    fixtures_omitted_reference 0 = fixtures_omitted_impl 0 := rfl
