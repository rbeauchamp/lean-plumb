import Lean

/-! A source-local handler with the built-in navigation reference is not the
pinned specialization handler, even when it delegates to that handler. -/
open Lean Elab Command

run_cmd do
  let env ← getEnv
  let .ok original := getAttributeImpl env `specialize
    | throwError "missing built-in specialization"
  let replacement := { original with add := fun name attrSyntax kind => do
    logInfo "source-local specialization wrapper"
    original.add name attrSyntax kind }
  let state := attributeExtension.getState env
  setEnv <| attributeExtension.setState env
    { state with map := state.map.insert `specialize replacement }

@[specialize] def fixtures_specialize_replaced (accept : Nat → Bool) : List Nat → Nat
  | [] => 0
  | x :: xs => (if accept x then x else 0) + fixtures_specialize_replaced accept xs
