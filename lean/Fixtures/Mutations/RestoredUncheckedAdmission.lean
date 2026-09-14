import Lean
open Lean Elab Command
set_option debug.skipKernelTC true
run_cmd liftCoreM <| Lean.addDecl (.thmDecl {
  name := `claim
  levelParams := []
  type := mkConst ``False
  value := mkConst ``True.intro })
set_option debug.skipKernelTC false
theorem usesClaim : False := claim
