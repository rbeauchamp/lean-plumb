import StrictLean.Checker.Producer
import StrictLean.Checker.RuleDiagnostics

/-! Versioned result output. This records scoped checker observations; it is not the
future proof-bearing Accepted value. Complete policy integration belongs to CL-04.
Canonical output construction credits con-leche (StrictLean.RuleId). -/
namespace StrictLean.Checker.ResultProtocol
open Lean

abbrev producer := StrictLean.Checker.Producer.identity

inductive Status where
  | completed | rejected | incomplete | classified

def statusText : Status → String
  | .completed => "completed" | .rejected => "rejected"
  | .incomplete => "incomplete" | .classified => "classified"

/-- Completed is scoped observation, never a synonym for whole-standard conformance. -/
def resultJson (scope : Json) (mode : EvidenceMode) (status : Status)
    (findings : Array Finding) (unresolved : Array String) : Json :=
  Json.mkObj (RegistryCodec.identityFields producer ++ [
    ("scope", scope), ("mode", .str (RegistryCodec.modeText mode)),
    ("status", .str (statusText status)),
    ("diagnostics", toJson (findings.map RegistryCodec.diagnosticJson)),
    ("unresolved", toJson unresolved)])

def write (path : System.FilePath) (scope : Json) (mode : EvidenceMode) (status : Status)
    (findings : Array Finding) (unresolved : Array String := #[]) : IO Unit := do
  if let some parent := path.parent then IO.FS.createDirAll parent
  IO.FS.writeFile path ((resultJson scope mode status findings unresolved).pretty ++ "\n")

/-- Structural names are rendered only at this legacy display boundary. -/
private def legacyName (value : Json) : Json :=
  match StrictLean.RegistryCodec.parseName value with
  | .ok n => .str n.toString
  | .error _ => value

private def remapDisplayPath (value : Json) (sourceRoot targetRoot : String) : Json :=
  match value with
  | .str path =>
    if sourceRoot.isEmpty || sourceRoot == targetRoot then value
    else if path == sourceRoot then .str targetRoot
    else if path.startsWith (sourceRoot ++ "/") then
      .str (targetRoot ++ (path.drop sourceRoot.length).toString)
    else value
  | _ => value

/-- Preserve the legacy record shape and remap only identified display-path fields.
Proof text, types, diagnostic prose, and arbitrary strings are never rewritten. -/
partial def legacyJson (value : Json) (sourceRoot targetRoot : String := "") : Json :=
  match value with
  | .arr values => .arr (values.map fun v => legacyJson v sourceRoot targetRoot)
  | .obj fields => Json.mkObj <| fields.toList.filterMap fun (k, v) =>
      if ["structuralName", "occurrence", "nativeOrigin", "sourceContent"].contains k then none
      else
        let value := if ["name", "module", "root", "replacement", "implementedBy", "unsafeRecBase",
            "elaborator", "kind", "commandElaborator", "commandKind"].contains k then legacyName v
          else if ["modules", "axioms", "valueConstants", "all", "levelParams", "nativeUseParents",
            "unsafeRecEquationAxioms", "compilerCallers", "added", "imports"].contains k then
              match v with
              | .arr values => .arr (values.map legacyName)
              | _ => v
          else if ["compilerEdges", "runtimeReplacements"].contains k then
              match v with
              | .arr values => .arr (values.map fun edge => match edge with
                  | .arr names => .arr (names.map legacyName)
                  | _ => edge)
              | _ => v
          else v
        let value := legacyJson value sourceRoot targetRoot
        some (k, if ["source", "olean", "sourcePath", "oleanPath", "ileanPath"].contains k then
          remapDisplayPath value sourceRoot targetRoot else value)
  | value => value
end StrictLean.Checker.ResultProtocol
