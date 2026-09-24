module

public import PlumbCore.Rule
public import PlumbCore.Source
public import Lean.Data.Lsp.Utf16

@[expose] public section

/-! Canonical diagnostic values and source conversion. The indexed representation credits
con-leche (see RuleId); source conversion uses pinned Lean FileMap/LSP APIs. -/
namespace Plumb
open Lean

def SourceLocation.fullLsp (s : SourceLocation) : Lsp.Range :=
  s.val.snapshot.source.toFileMap.utf8RangeToLspRange
    ⟨⟨s.val.full.start⟩, ⟨s.val.full.stop⟩⟩

def SourceLocation.selectionLsp (s : SourceLocation) : Lsp.Range :=
  s.val.snapshot.source.toFileMap.utf8RangeToLspRange
    ⟨⟨s.val.selection.start⟩, ⟨s.val.selection.stop⟩⟩

/-- Lean's LSP UTF-16 column of a position. -/
def lspUtf16Column : Utf16Column := fun fm p => (fm.leanPosToLspPos p).character

/-- A report's codepoint and UTF-16 columns must both agree with the exact source. -/
def sourceFromReport (snapshot : SourceSnapshot) (ranges : PlumbPolicy.Ranges) :
    Except String SourceLocation :=
  sourceFromReportWith lspUtf16Column snapshot ranges

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
  | .escapeHatch | .executableContract | .materialDocumentation | .materialIntent => DeclarationArguments
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
  "https://rbeauchamp.github.io/lean-plumb/dev/" ++ id.route

def argumentText : (id : RuleId) → Payload id → String
  | .projectAxiom, a | .proofHole, a | .unknownAxiom, a | .compilerTrusting, a
  | .profileExceeded, a | .escapeHatch, a | .executableContract, a
  | .materialDocumentation, a | .materialIntent, a => s!"{a.declaration}: {a.detail}"
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
end Plumb
