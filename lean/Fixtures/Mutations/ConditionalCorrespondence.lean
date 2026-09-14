import Init
/-! A theorem-only impossible premise cannot establish unconditional agreement. -/
def falseReplacement (n : Nat) : Nat := n + 1
@[implemented_by falseReplacement]
def falseReference (n : Nat) : Nat := n
theorem falseCorrespondence (n : Nat) (h : False) :
    falseReference n = falseReplacement n := False.elim h
