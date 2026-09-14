/-! A configured module deliberately absent from the umbrella's imports.
The enabled build linter discovers it through the library's Lake glob. -/

namespace Widget.Additional

/-- A separate closed, kernel-only claim included in the library surface. -/
theorem reflexive (n : Nat) : n = n := rfl

end Widget.Additional
