import Lean
open Lean Elab Command

/-! A stored body of the wrong type cannot authorize logical admission. -/
run_cmd do
  let d := Declaration.opaqueDecl {
    name := `malformedBody
    levelParams := []
    type := mkConst ``Nat
    value := mkConst ``True.intro
    isUnsafe := false }
  match (← getEnv).addDeclCore 200000 1000 d none false with
  | .ok env => setEnv env
  | .error _ => throwError "unchecked construction failed"
