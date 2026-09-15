import StrictLean.Checker.RuleDiagnostics

/-! Versioned result output. This records scoped checker observations; it is not the
future proof-bearing Accepted value. Complete policy integration belongs to CL-04.
Canonical output construction credits con-leche (StrictLean.RuleId). -/
namespace StrictLean.Checker.ResultProtocol
open Lean

/-- Captured when this module is elaborated, not from an adopter's working directory. -/
elab "strict_lean_build_revision" : term => do
  let source := System.FilePath.mk (← getFileName)
  let some root := source.parent >>= (·.parent) >>= (·.parent) >>= (·.parent)
    | throwError "cannot identify checker package source directory"
  let root ← IO.FS.realPath root
  unless ← (root / "lakefile.lean").pathExists do throwError "checker package configuration unavailable"
  let head ← IO.Process.output { cmd := "git", args := #["-C", root.toString, "rev-parse", "HEAD"] }
  unless head.exitCode == 0 do throwError "cannot identify checker source revision"
  let state ← IO.Process.output { cmd := "git", args := #["-C", root.toString, "status", "--porcelain", "--untracked-files=normal"] }
  unless state.exitCode == 0 do throwError "cannot identify checker source state"
  let suffix := if state.stdout.isEmpty then "" else ":unreleased-worktree"
  return mkStrLit (head.stdout.trimAscii.toString ++ suffix)

def producer : RegistryCodec.ProducerIdentity := {
  producerVersion := "unreleased"
  toolchain := Lean.versionString
  sourceRevision := strict_lean_build_revision }

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

/-- Legacy export keeps its established record shape during schema migration. -/
partial def legacyJson : Json → Json
  | .arr values => .arr (values.map legacyJson)
  | .obj fields => Json.mkObj <| fields.toList.filterMap fun (k, v) =>
      if k == "structuralName" then none else some (k, legacyJson v)
  | value => value
end StrictLean.Checker.ResultProtocol
