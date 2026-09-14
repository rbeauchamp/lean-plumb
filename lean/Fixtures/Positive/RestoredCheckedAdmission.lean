import Lean
open Lean Elab Command
run_cmd liftCoreM <| Lean.addDecl (.thmDecl {
  name := `claim
  levelParams := []
  type := mkConst ``True
  value := mkConst ``True.intro })
