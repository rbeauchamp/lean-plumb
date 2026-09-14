/-
Mutation: an unmarked wrapper reaches runtime-replaced code while the audit
is invoked with a checked-correspondence execution claim (`--execution
checked`) that the module does not have. No theorem relates the replacement
to the reference definition and the values are not definitionally equal, so
the boundary stays trusted and the execution claim must fail — it must never
pass silently.
-/
def fixtures_quiet_impl (n : Nat) : Nat := 2 * n

@[implemented_by fixtures_quiet_impl]
def fixtures_quiet (n : Nat) : Nat := n + n

def fixtures_quiet_user (n : Nat) : Nat := fixtures_quiet n
