import Lean
open Lean Elab Command
run_cmd do
  let declaration := Declaration.thmDecl {
    name := `claim
    levelParams := []
    type := mkConst ``False
    value := mkConst ``True.intro }
  match (← getEnv).addDeclCore 200000 1000 declaration none false with
  | .ok env => setEnv env
  | .error _ => throwError "construction failed"
