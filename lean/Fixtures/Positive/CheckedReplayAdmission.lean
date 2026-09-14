import Lean
open Lean Elab Command
run_cmd do
  let declaration := Declaration.thmDecl {
    name := `claim
    levelParams := []
    type := mkConst ``True
    value := mkConst ``True.intro }
  let original ← getEnv
  match original.addDeclCore 200000 1000 declaration none false with
  | .error _ => throwError "preliminary construction failed"
  | .ok _ => pure ()
  match original.addDeclCore 200000 1000 declaration none true with
  | .ok env => setEnv env
  | .error _ => throwError "checked replay failed"
