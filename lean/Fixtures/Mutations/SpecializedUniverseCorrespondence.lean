/-!
A proof specialized to Type 0 cannot establish agreement at arbitrary universes.
The functions do agree universally, but this module supplies only restricted
evidence and they are not definitionally equal.
-/
universe u
def fixtures_universe_impl {α : Type u} (a : α) (n : Nat) : α × Nat := (a, 2 * n)
@[implemented_by fixtures_universe_impl]
def fixtures_universe_reference {α : Type u} (a : α) (n : Nat) : α × Nat := (a, n + n)
theorem fixtures_universe_correspondence {α : Type} (a : α) (n : Nat) :
    fixtures_universe_reference a n = fixtures_universe_impl a n := by
  simp only [fixtures_universe_reference, fixtures_universe_impl, Nat.two_mul]
