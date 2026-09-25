import Lean.Data.Json
import PlumbPolicy.Codec

/-! Public structural-name transport. The policy decoder is the pure wire decoder;
JSON scalar admission is the operational bridge. Names retain every constructor. -/
namespace Plumb.RegistryCodec
open Lean

def nameParts : Name → List Json
  | .anonymous => []
  | .str parent value => Json.arr #[.str "str", .str value] :: nameParts parent
  | .num parent value => Json.arr #[.str "num", toJson value] :: nameParts parent

def nameJson (name : Name) : Json := .arr (nameParts name).toArray

private def component (j : Json) : Except String PlumbPolicy.Codec.Wire := do
  let a ← j.getArr?
  match a.toList with
  | [.str "str", .str s] => return .array [.text "str", .text s]
  | [.str "num", n] => return .array [.text "num", .nat (← n.getNat?)]
  | _ => throw "invalid structural Lean name"

private def components : List Json → Except String (List PlumbPolicy.Codec.Wire)
  | [] => .ok []
  | x :: xs => return (← component x) :: (← components xs)

def parseNameParts (xs : List Json) : Except String Name := do
  PlumbPolicy.Codec.parseNameParts (← components xs)

def parseName (j : Json) : Except String Name := do
  parseNameParts (← j.getArr?).toList

private theorem components_encoded (n : Name) :
    components (nameParts n) = .ok (PlumbPolicy.Codec.nameParts n) := by
  induction n with
  | anonymous => rfl
  | str p s ih =>
    simp [components, component, nameParts, PlumbPolicy.Codec.nameParts, ih, Json.getArr?] <;> rfl
  | num p n ih =>
    simp [components, component, nameParts, PlumbPolicy.Codec.nameParts, ih, Json.getArr?,
      toJson, Json.getNat?, JsonNumber.fromNat] <;> rfl

/-- The JSON-tree bridge and pure decoder round-trip every Lean name. -/
theorem nameParts_roundtrip (n : Name) : parseNameParts (nameParts n) = .ok n := by
  unfold parseNameParts
  rw [components_encoded]
  exact PlumbPolicy.Codec.nameParts_roundtrip n

/-- Exact law for the public JSON-tree API; this is not a JSON text parser theorem. -/
theorem name_roundtrip (n : Name) : parseName (nameJson n) = .ok n := by
  simpa [parseName, nameJson, Json.getArr?] using nameParts_roundtrip n
end Plumb.RegistryCodec
