import Regula.DiagnosticCodec
import Regula.Checker.ResultProtocol
import Regula.Checker.SourceAudit
import Regula.Website

/-! Focused transport and source-boundary qualification for CATALOG-01.
Universal identity/name laws are theorems, not inferred from these controls.
Canonical metadata motivation credits con-leche (Regula.RuleId). -/
open Lean Regula Regula.RegistryCodec

-- This named set is the public theorem claim, not a module-discovery substitute.
run_cmd do
  for name in #[``RuleId.parse_spelling, ``RuleId.spelling_injective, ``RuleId.mem_all,
      ``RuleId.all_nodup, ``RuleId.route_injective, ``mode_roundtrip, ``rule_roundtrip,
      ``nameParts_roundtrip, ``name_roundtrip] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun ax => #[`propext, `Quot.sound, `Classical.choice].contains ax) do
      throwError "registry theorem {name} exceeds Standard-Logical: {axioms}"

private def require (ok : Bool) (claim : String) : IO Unit :=
  unless ok do throw <| IO.userError s!"registry qualification failed: {claim}"

private def succeeded : Except ε α → Bool
  | .ok _ => true | .error _ => false

def main : IO Unit := do
  let producer := Regula.Checker.ResultProtocol.producer
  let manifest := registryJson producer
  -- Exhaustive checks over the genuinely closed 21-rule vocabulary.
  for id in RuleId.all do
    require (succeeded (parseDescriptor (descriptorJson id))) s!"descriptor {id}"
    require (!(descriptor id).title.isEmpty && !(descriptor id).normativeClauses.isEmpty)
      s!"metadata completeness {id}"
    require (!succeeded (parseDescriptor ((descriptorJson id).setObjVal! "extra" .null)))
      s!"unknown field {id}"
  require (!succeeded (parseRule (.str "RG9999"))) "unknown rule"
  require (!succeeded (parseMode "fresh")) "unknown mode"
  require (!succeeded (validateRegistry producer (manifest.setObjVal! "schemaVersion" (toJson (2 : Nat)))))
    "unsupported registry version"
  require (!succeeded (validateRegistry producer (manifest.setObjVal! "sourceRevision" (.str "stale"))))
    "stale revision"
  require (!succeeded (validateRegistry producer (manifest.setObjVal! "rules" (toJson [descriptorJson .projectAxiom, descriptorJson .projectAxiom]))))
    "duplicate and missing IDs"
  let page : RegistryCodec.Page := ⟨.projectAxiom, RuleId.projectAxiom.route, true, true⟩
  require (succeeded (validatePages producer manifest [.projectAxiom] [page])) "actual one-page scope"
  require (!succeeded (validatePages producer manifest [.projectAxiom] [])) "missing page"
  require (!succeeded (validatePages producer manifest [.projectAxiom] [page, page])) "duplicate page"
  require (!succeeded (validatePages producer manifest [.projectAxiom] [{ page with route := "wrong" }])) "wrong route"
  require (!succeeded (validatePages producer manifest [.projectAxiom] [{ page with checkedExample := false }])) "unchecked example"
  require (succeeded (validatePages producer manifest [.moduleDocumentation]
    [⟨.moduleDocumentation, RuleId.moduleDocumentation.route, true, true⟩])) "implemented module-doc detector"
  let candidate : SourceCandidate := ⟨⟨"qualification://unicode", "α😀\r\nx"⟩, ⟨0, 9⟩, ⟨2, 6⟩⟩
  let source ← IO.ofExcept (admitSource candidate)
  require (source.selectionLsp.start.line == 0 && source.selectionLsp.start.character == 1 &&
    source.selectionLsp.end.line == 0 && source.selectionLsp.end.character == 3) "UTF-8 to UTF-16 conversion"
  require (!succeeded (admitSource { candidate with selection := ⟨3, 6⟩ })) "mid-character offset"
  require (!succeeded (admitSource { candidate with selection := ⟨6, 2⟩ })) "reversed range"
  require (!succeeded (admitSource { candidate with full := ⟨0, 99⟩ })) "out-of-bounds range"
  require (!succeeded (admitSource { candidate with full := ⟨3, 9⟩ })) "selection outside full range"
  let name := Name.num (.str .anonymous "a.b") 2
  let d ← IO.ofExcept <| makeDiagnostic .projectAxiom ⟨name, "project-axiom"⟩
    (.source source) .freshFile (some "standard-logical") .violation
  let json := diagnosticJson ⟨.projectAxiom, d⟩
  let parsed ← IO.ofExcept <| DiagnosticCodec.parseDiagnostic json
  require (diagnosticJson parsed == json) "diagnostic transport control"
  require (!succeeded (DiagnosticCodec.parseDiagnostic (json.setObjVal! "extra" .null))) "unknown diagnostic field"
  require (!succeeded (DiagnosticCodec.parseDiagnostic (json.setObjVal! "mode" (.str "serializedGraph")))) "unsupported diagnostic mode"
  require (!succeeded (DiagnosticCodec.parseDiagnostic (json.setObjVal! "impact" (.str "pass")))) "unknown impact"
  require (!succeeded (DiagnosticCodec.parseDiagnostic (json.setObjVal! "severity" (.str "hidden")))) "unknown severity"
  require (succeeded (makeDiagnostic .moduleDocumentation ⟨"M", "missing docs"⟩
    (.module `M) .freshProject none .violation)) "module-doc detector admission"
  let native ← IO.ofExcept d.nativeMessage
  require (native.pos.line == 1 && native.pos.column == 1 &&
    native.endPos == some ⟨1, 2⟩) "native codepoint coordinates"
  require ((← native.data.toString) == d.text) "native/text agreement"
  let compilation : Regula.Checker.SourceAudit.Compilation := {
    spec := { «module» := "Control", source := "" }
    sourcePath := "/control.lean", oleanPath := "/control.olean", ileanPath := "/control.ilean"
    process := { exitCode := 1, stdout := "/control.lean:1:0: error: intended", stderr := "" } }
  require (Regula.Checker.SourceAudit.sourceDiagnosticFailure compilation) "completed source diagnostic"
  require (!Regula.Checker.SourceAudit.sourceDiagnosticFailure
    { compilation with process := { compilation.process with exitCode := 137 } }) "termination is incomplete"
  require (!Regula.Checker.SourceAudit.sourceDiagnosticFailure
    { compilation with process := { compilation.process with stdout := "compiler crashed" } }) "crash is incomplete"
  require (succeeded (Website.validateExample (.policyRejection .projectAxiom "project-axiom")
    (.checked #[⟨.projectAxiom, d⟩] false))) "policy rejection after elaboration"
  require (!succeeded (Website.validateExample (.compilerRejection "error") (.incomplete "worker crashed")))
    "crash cannot satisfy negative example"
  IO.println "registry qualification: PASS (closed metadata, transport, source and mode boundaries)"
