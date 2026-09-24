import Plumb.Diagnostic
import Plumb.StructuralName

/-! Versioned transport and website admission derived from the registry. The exact
canonical comparison follows con-leche's representation idea (RuleId attribution).
JSON syntax parsing and external producer/source identity remain trusted boundaries. -/
namespace Plumb.RegistryCodec
open Lean

def modeText := EvidenceMode.spelling

def parseMode : String → Except String EvidenceMode
  | "editorSnapshot" => .ok .editorSnapshot
  | "incrementalProject" => .ok .incrementalProject
  | "freshProject" => .ok .freshProject
  | "freshFile" => .ok .freshFile
  | "documentationExample" => .ok .documentationExample
  | "serializedGraph" => .ok .serializedGraph
  | s => .error s!"unknown evidence mode: {s}"

theorem mode_roundtrip (m : EvidenceMode) : parseMode (modeText m) = .ok m := by
  cases m <;> rfl

def ruleJson (id : RuleId) : Json := .str id.spelling

def parseRule (j : Json) : Except String RuleId := do
  let s ← j.getStr?
  match RuleId.parse? s with
  | some id => return id
  | none => throw s!"unknown rule ID: {s}"

theorem rule_roundtrip (id : RuleId) : parseRule (ruleJson id) = .ok id := by
  cases id <;> rfl

private def severityText : Severity → String
  | .error => "error" | .warning => "warning" | .information => "information"

private def categoryText : RuleCategory → String
  | .foundation => "foundation" | .declaration => "declaration"
  | .execution => "execution" | .environment => "environment"
  | .configuration => "configuration" | .elaboration => "elaboration"
  | .coverage => "coverage" | .admission => "admission" | .documentation => "documentation"

private def scopeText : RuleScope → String
  | .declaration => "declaration" | .project => "project" | .executionRoot => "executionRoot"
  | .documentationFence => "documentationFence" | .module => "module"
  | .materialDeclaration => "materialDeclaration"

private def evidenceText : EvidenceKind → String
  | .kernelAxioms => "kernelAxioms" | .generatedRole => "generatedRole"
  | .contractEvidence => "contractEvidence" | .environment => "environment"
  | .configuration => "configuration" | .compilation => "compilation"
  | .inventory => "inventory" | .admission => "admission" | .executionClosure => "executionClosure"
  | .fenceGrammar => "fenceGrammar" | .checkedExample => "checkedExample"
  | .metadataPresence => "metadataPresence"

def descriptorJson (id : RuleId) : Json :=
  let d := descriptor id
  Json.mkObj [
    ("id", ruleJson id), ("title", toJson d.title),
    ("category", toJson (categoryText d.category)),
    ("scope", toJson (scopeText d.scope)), ("evidenceKind", toJson (evidenceText d.evidenceKind)),
    ("normativeClauses", toJson d.normativeClauses),
    ("applicability", toJson d.applicability),
    ("defaultStrictSeverity", toJson (severityText d.defaultStrictSeverity)),
    ("evidenceModes", toJson (d.evidenceModes.map modeText)),
    ("messageTemplate", toJson d.messageTemplate),
    ("helpRoute", toJson id.route), ("helpUrl", toJson (helpUrl id)),
    ("introduced", toJson (match d.lifecycle with
      | .active version | .retired version _ _ => version)),
    ("retired", match d.lifecycle with
      | .active _ => Json.null | .retired _ version _ => toJson version),
    ("replacement", match d.lifecycle with
      | .active _ => Json.null
      | .retired _ _ replacement => (replacement.map (ruleJson ∘ Subtype.val)).getD Json.null),
    ("availability", toJson (match d.availability with
      | .existingChecker => "existingChecker" | .plannedEngine => "plannedEngine")),
    ("attribution", Json.mkObj [
      ("project", toJson d.attribution.project), ("authors", toJson d.attribution.authors),
      ("url", toJson d.attribution.url), ("revision", toJson d.attribution.revision),
      ("idea", toJson d.attribution.idea), ("copiedCode", toJson d.attribution.copiedCode)])]

/-- Reject metadata drift, unknown fields, missing fields, routes and lifecycle values. -/
def parseDescriptor (j : Json) : Except String RuleId := do
  let id ← parseRule (← j.getObjVal? "id")
  if j == descriptorJson id then return id
  else throw s!"noncanonical or stale descriptor: {id}"

structure ProducerIdentity where
  producerVersion : String
  toolchain : String
  sourceRevision : String
  deriving BEq

/-- Identity is supplied by the build/collector, not inferred from diagnostic text.
Registry and result envelopes carry independent schema versions. -/
def identityFields (p : ProducerIdentity) (schemaVersion : Nat := 1) : List (String × Json) := [
  ("schemaVersion", toJson schemaVersion), ("producerVersion", toJson p.producerVersion),
  ("toolchain", toJson p.toolchain), ("sourceRevision", toJson p.sourceRevision)]

def registryJson (p : ProducerIdentity) : Json :=
  Json.mkObj (identityFields p ++ [("rules", toJson (RuleId.all.map descriptorJson))])

/-- A manifest is accepted only if it is exactly the current closed registry and identity.
Array ordering is canonical; duplicate, omitted, extra and stale records all fail. -/
def validateRegistry (p : ProducerIdentity) (j : Json) : Except String Unit :=
  if j == registryJson p then .ok () else .error "registry or producer identity mismatch"

private def rangeJson (r : ByteRange) : Json :=
  Json.mkObj [("startByte", toJson r.start), ("endByte", toJson r.stop)]

def locationJson : Location → Json
  | .module n => Json.mkObj [("kind", .str "module"), ("name", nameJson n)]
  | .project s => Json.mkObj [("kind", .str "project"), ("identity", .str s)]
  | .source s => Json.mkObj [
      ("kind", .str "source"), ("uri", .str s.val.snapshot.uri),
      ("source", .str s.val.snapshot.source), ("range", rangeJson s.val.full),
      ("selectionRange", rangeJson s.val.selection),
      ("lspRange", toJson s.fullLsp), ("lspSelectionRange", toJson s.selectionLsp)]

private def argumentsJson : (id : RuleId) → Payload id → Json
  | .projectAxiom, a | .proofHole, a | .unknownAxiom, a | .compilerTrusting, a
  | .profileExceeded, a | .escapeHatch, a | .executableContract, a
  | .materialDocumentation, a =>
      Json.mkObj [("declaration", nameJson a.declaration), ("detail", toJson a.detail)]
  | .executionUnresolved, a | .executionBoundary, a =>
      Json.mkObj [("root", nameJson a.root), ("detail", toJson a.detail)]
  | .environment, a | .configuration, a | .sourceBuild, a | .coverage, a
  | .admission, a | .fenceStructure, a | .positiveExample, a | .negativeExample, a
  | .trustedExample, a | .moduleDocumentation, a =>
      Json.mkObj [("subject", toJson a.subject), ("detail", toJson a.detail)]

def diagnosticJson (f : Finding) : Json :=
  let ⟨id, d⟩ := f
  Json.mkObj [
    ("id", ruleJson id), ("arguments", argumentsJson id d.arguments),
    ("location", locationJson d.location),
    ("related", toJson (d.related.map fun r => Json.mkObj [
      ("relation", toJson r.relation), ("location", locationJson r.location)])),
    ("mode", toJson (modeText d.mode)), ("claim", toJson d.claim),
    ("impact", .str (if d.impact == .violation then "violation" else "incomplete")),
    ("severity", toJson (severityText d.severity)),
    ("text", toJson d.text), ("helpUrl", toJson (helpUrl id))]

/-- Website artifact admission uses actual produced pages, not descriptors pretending to be pages. -/
structure Page where
  rule : RuleId
  route : String
  checkedExample : Bool
  advertisedEnforced : Bool

def validatePages (p : ProducerIdentity) (manifest : Json) (required : List RuleId)
    (pages : List Page) : Except String Unit := do
  validateRegistry p manifest
  unless required.Nodup && (pages.map (·.rule)).Nodup && (pages.map (·.route)).Nodup do
    throw "duplicate rule or route"
  unless pages.length == required.length && required.all (fun id => pages.any (·.rule == id)) do
    throw "missing or unexpected rule page"
  for page in pages do
    unless page.route == page.rule.route && page.checkedExample do
      throw s!"missing checked example or wrong route: {page.rule}"
    if page.advertisedEnforced && (descriptor page.rule).availability != .existingChecker then
      throw s!"unimplemented advertised rule: {page.rule}"
end Plumb.RegistryCodec
