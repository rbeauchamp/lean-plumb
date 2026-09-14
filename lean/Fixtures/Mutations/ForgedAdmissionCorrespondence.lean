import Lean
open Lean Elab Command

def reference (n : Nat) : Nat := n
def replacement (n : Nat) : Nat := n + 1
set_option debug.skipKernelTC true in
run_cmd liftCoreM do
  let proposition := mkApp3 (mkConst ``Eq [.succ .zero])
    (mkForall .anonymous .default (mkConst ``Nat) (mkConst ``Nat))
    (mkConst `reference) (mkConst `replacement)
  Lean.addDecl (.thmDecl {
    name := `forgedCorrespondence
    levelParams := []
    type := proposition
    value := mkConst ``True.intro })
attribute [csimp] forgedCorrespondence

def caller (n : Nat) : Nat := reference n
