import Lean
open Lean Elab Command

/-! A stored body of the wrong type cannot authorize logical admission. -/
run_cmd do
  let d := Declaration.defnDecl {
    name := `malformedBody
    levelParams := []
    type := mkConst ``Nat
    value := mkConst ``True.intro
    hints := .regular 0, safety := .safe }
  match (← getEnv).addDeclCore 200000 1000 d none false with
  | .ok env => setEnv env
  | .error _ => throwError "unchecked construction failed"
