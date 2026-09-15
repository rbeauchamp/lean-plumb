import StrictLean.Rule
import StrictLeanPolicy.Domain
import Lean.Data.Lsp.Utf16

/-! Canonical diagnostic values and source conversion. The indexed representation credits
con-leche (see RuleId); source conversion uses pinned Lean FileMap/LSP APIs. -/
namespace StrictLean
open Lean

abbrev SourceSnapshot := StrictLeanPolicy.SourceSnapshot
abbrev ByteRange := StrictLeanPolicy.ByteRange

/-- Raw coordinates are admitted only after checking character boundaries and containment. -/
structure SourceCandidate where
  snapshot : SourceSnapshot
  full : ByteRange
  selection : ByteRange
  deriving Repr, BEq

namespace SourceCandidate
private def boundary (source : String) (n : Nat) : Bool :=
  n ≤ source.utf8ByteSize &&
    (source.toFileMap.ofPosition (source.toFileMap.toPosition ⟨n⟩)).byteIdx == n

def valid (c : SourceCandidate) : Bool :=
  !c.snapshot.uri.isEmpty && c.full.start ≤ c.selection.start &&
  c.selection.start ≤ c.selection.stop && c.selection.stop ≤ c.full.stop &&
  [c.full.start, c.full.stop, c.selection.start, c.selection.stop].all
    (boundary c.snapshot.source)
end SourceCandidate

/-- Invalid coordinates cannot inhabit an admitted source location. -/
abbrev SourceLocation := { c : SourceCandidate // c.valid = true }

def admitSource (c : SourceCandidate) : Except String SourceLocation :=
  if h : c.valid = true then .ok ⟨c, h⟩ else .error "invalid source coordinates"

def SourceLocation.fullLsp (s : SourceLocation) : Lsp.Range :=
  s.val.snapshot.source.toFileMap.utf8RangeToLspRange
    ⟨⟨s.val.full.start⟩, ⟨s.val.full.stop⟩⟩

def SourceLocation.selectionLsp (s : SourceLocation) : Lsp.Range :=
  s.val.snapshot.source.toFileMap.utf8RangeToLspRange
    ⟨⟨s.val.selection.start⟩, ⟨s.val.selection.stop⟩⟩

/-- A report's codepoint and UTF-16 columns must both agree with the exact source. -/
def sourceFromReport (snapshot : SourceSnapshot) (ranges : StrictLeanPolicy.Ranges) :
    Except String SourceLocation := do
  let fm := snapshot.source.toFileMap
  let convert (r : StrictLeanPolicy.Range) : Except String ByteRange := do
    let a : Lean.Position := ⟨r.start.line, r.start.column⟩
    let b : Lean.Position := ⟨r.end.line, r.end.column⟩
    let start := fm.ofPosition a
    let stop := fm.ofPosition b
    unless r.start.line > 0 && r.end.line > 0 && fm.toPosition start == a &&
        fm.toPosition stop == b && (fm.leanPosToLspPos a).character == r.startUtf16 &&
        (fm.leanPosToLspPos b).character == r.endUtf16 do
      throw "reported source coordinates disagree with the snapshot"
    return ⟨start.byteIdx, stop.byteIdx⟩
  admitSource ⟨snapshot, ← convert ranges.range, ← convert ranges.selectionRange⟩

/-- Range-less generated declarations retain honest module attribution. -/
inductive Location where
  | source (value : SourceLocation)
  | module (name : Name)
  | project (identity : String)

inductive Impact where
  | violation | incomplete
  deriving Repr, BEq, DecidableEq

structure DeclarationArguments where
  declaration : Name
  detail : String
  deriving Repr
structure ExecutionArguments where
  root : Name
  detail : String
  deriving Repr
structure ContextArguments where
  subject : String
  detail : String
  deriving Repr

/-- Distinct argument domains prevent constructing a declaration rule with a project payload. -/
def Payload : RuleId → Type
  | .projectAxiom | .proofHole | .unknownAxiom | .compilerTrusting | .profileExceeded
  | .escapeHatch | .executableContract | .materialDocumentation => DeclarationArguments
  | .executionUnresolved | .executionBoundary => ExecutionArguments
  | .environment | .configuration | .sourceBuild | .coverage | .admission
  | .fenceStructure | .positiveExample | .negativeExample | .trustedExample
  | .moduleDocumentation => ContextArguments

structure RelatedLocation where
  relation : String
  location : Location

/-- Display severity is separate from the mandatory strict impact. -/
structure Diagnostic (id : RuleId) where
  arguments : Payload id
  location : Location
  related : Array RelatedLocation := #[]
  mode : EvidenceMode
  claim : Option String
  impact : Impact
  severity : Severity := .error
  supportedMode : mode ∈ (descriptor id).evidenceModes

/-- Mode admission happens at the construction boundary, not only when displaying a result. -/
def makeDiagnostic (id : RuleId) (arguments : Payload id) (location : Location)
    (mode : EvidenceMode) (claim : Option String) (impact : Impact)
    (severity : Severity := .error) (related : Array RelatedLocation := #[]) :
    Except String (Diagnostic id) :=
  if h : mode ∈ (descriptor id).evidenceModes then
    .ok { arguments, location, mode, claim, impact, severity, related, supportedMode := h }
  else .error s!"unsupported diagnostic mode {mode.spelling} for {id}"

abbrev Finding := (id : RuleId) × Diagnostic id

/-- Development routes are explicit; this does not claim that a page is deployed. -/
def helpUrl (id : RuleId) : String :=
  "https://rbeauchamp.github.io/strict-lean/dev/" ++ id.route

def argumentText : (id : RuleId) → Payload id → String
  | .projectAxiom, a | .proofHole, a | .unknownAxiom, a | .compilerTrusting, a
  | .profileExceeded, a | .escapeHatch, a | .executableContract, a
  | .materialDocumentation, a => s!"{a.declaration}: {a.detail}"
  | .executionUnresolved, a | .executionBoundary, a => s!"{a.root}: {a.detail}"
  | .environment, a | .configuration, a | .sourceBuild, a | .coverage, a
  | .admission, a | .fenceStructure, a | .positiveExample, a | .negativeExample, a
  | .trustedExample, a | .moduleDocumentation, a => s!"{a.subject}: {a.detail}"

def Diagnostic.text {id : RuleId} (d : Diagnostic id) : String :=
  let impact := if d.impact == .violation then "violation" else "incomplete"
  let scope := match d.location with
    | .source s => s.val.snapshot.uri
    | .module n => s!"module {n}"
    | .project p => s!"project/configuration {p}"
  s!"{id} [{impact}; {d.mode.spelling}; claim={d.claim.getD "classification-only"}; {scope}]: " ++
    s!"{argumentText id d.arguments}\n{helpUrl id}"

/-- Native logging consumes the same typed diagnostic and genuine selection span. -/
def Diagnostic.nativeMessage {id : RuleId} (d : Diagnostic id) : Except String Message := do
  let .source source := d.location | throw "native source message requires a source location"
  let fm := source.val.snapshot.source.toFileMap
  return {
    fileName := source.val.snapshot.uri
    pos := fm.toPosition ⟨source.val.selection.start⟩
    endPos := some (fm.toPosition ⟨source.val.selection.stop⟩)
    severity := match d.severity with
      | .error => .error | .warning => .warning | .information => .information
    data := toMessageData d.text }
end StrictLean
