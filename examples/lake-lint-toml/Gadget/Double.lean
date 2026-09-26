import Regula.Linter

/-! Doubling with its specification. The `Regula.Linter` import enables Regula's
live feedback in this module and in every module that imports it. -/

namespace Gadget

/-- Doubling by addition. -/
def double (n : Nat) : Nat := n + n

/-- The executed definition equals multiplication by two. -/
theorem double_eq (n : Nat) : double n = 2 * n := (Nat.two_mul n).symm

end Gadget
