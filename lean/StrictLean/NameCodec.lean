import Lean.Data.Json

/-! Structural names for registry transport. Canonical representation credits con-leche;
see StrictLean.RuleId. JSON syntax parsing is a trusted external boundary. -/
namespace StrictLean.RegistryCodec
open Lean

/-- Outermost-first tagged components retain numeric components and anonymous roots. -/
def nameParts : Name → List Json
  | .anonymous => []
  | .str parent value => Json.arr #[.str "str", .str value] :: nameParts parent
  | .num parent value => Json.arr #[.str "num", toJson value] :: nameParts parent

def nameJson (name : Name) : Json := .arr (nameParts name).toArray

def parseNameParts : List Json → Except String Name
  | [] => .ok .anonymous
  | item :: rest => do
      let a ← item.getArr?
      match a.toList with
      | [.str "str", .str s] => return .str (← parseNameParts rest) s
      | [.str "num", n] => return .num (← parseNameParts rest) (← n.getNat?)
      | _ => throw "invalid structural Lean name"

def parseName (j : Json) : Except String Name := do
  parseNameParts (← j.getArr?).toList

theorem nameParts_roundtrip (n : Name) : parseNameParts (nameParts n) = .ok n := by
  induction n with
  | anonymous => rfl
  | str p s ih => simp [nameParts, parseNameParts, ih, Json.getArr?] <;> rfl
  | num p k ih => simp [nameParts, parseNameParts, ih, Json.getArr?, toJson,
      Json.getNat?, JsonNumber.fromNat] <;> rfl

theorem name_roundtrip (n : Name) : parseName (nameJson n) = .ok n := by
  simpa [parseName, nameJson, Json.getArr?] using nameParts_roundtrip n

end StrictLean.RegistryCodec
