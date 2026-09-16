import StrictLean.Checker.ResultProtocol
import StrictLean.Checker.PolicyCodec
import StrictLean.Website

/-! Qualification and export admission for actual source-owned example receipts.
Expected selectors are fixed before running the detector. This module checks canonical
registry diagnostics and binds them to observed exact source/configuration/mode. -/
-- Exact dependency ceiling for the new claimed data-level guarantees. Acquisition,
-- JSON and compiler authenticity are expressly outside these theorem statements.
run_cmd do
  for name in #[``StrictLean.Website.admitDemonstration_complete,
      ``StrictLean.Website.admitDemonstration_sound, ``StrictLean.Website.demonstration_completed,
      ``StrictLean.Website.demonstration_observed_incomplete,
      ``StrictLean.Website.demonstration_not_accepted,
      ``StrictLeanPolicy.incomplete_example_refused] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun ax => #[`propext, `Quot.sound, `Classical.choice].contains ax) do
      throwError "example theorem {name} exceeds Standard-Logical: {axioms}"

namespace StrictLean.Checker.RuleExampleQualification
open Lean StrictLean StrictLean.Website

private def field (j : Json) (key : String) : Except String Json := j.getObjVal? key
private def string (j : Json) (key : String) : Except String String := do
  (← field j key).getStr?

private def sources (j : Json) : Except String (Array StrictLeanPolicy.SourceSnapshot) := do
  (← j.getArr?).mapM fun source => do
    PolicyCodec.exactFields source ["uri", "source"]
    return ⟨← string source "uri", ← string source "source"⟩

private def binding (record : Json) (mode : EvidenceMode) : Except String ExampleBinding := do
  let input ← field record "before"
  let after ← field record "after"
  unless input == after do throw "example source/configuration changed"
  let ss ← sources (← field input "sources")
  let configuration : StrictLeanPolicy.SourceSnapshot :=
    ⟨← string (← field input "configuration") "uri", ← string (← field input "configuration") "source"⟩
  let result ← field record "result"
  let snapshot ← StrictLeanPolicy.admitSnapshot {
    sources := ss, configuration
    toolchain := {
      leanVersion := ← string result "toolchain"
      compilerCommit := Lean.githash
      producerRevision := ← string result "sourceRevision" }
    dependencies := #[{
      package := "strict_lean"
      nominalRevision := some (← string result "sourceRevision")
      dirty := true
      files := ← sources (← field record "checkerSources") }] }
  return ⟨snapshot, mode⟩

/-- Successful program/example checks must retain their own source account. Caller
readback alone cannot bind a stale successful result to a different requested source. -/
private def sourceAccount (result : Json) (bound : ExampleBinding) : Except String Unit := do
  let scope ← field result "scope"
  let admitted := bound.snapshot.val.sources
  if let .ok path := string scope "file" then
    let text ← string scope "source"
    unless admitted.contains ⟨path, text⟩ do throw "wrong file source account"
  else if let .ok raw := field scope "sources" then
    let entries ← raw.getArr?
    unless !entries.isEmpty do throw "missing project source account"
    for entry in entries do
      unless admitted.contains ⟨← string entry "path", ← string entry "source"⟩ do
        throw "wrong project source account"
  else if let .ok raw := field scope "documents" then
    let entries ← sources raw
    unless !entries.isEmpty && entries.all admitted.contains do throw "wrong documentation source account"
  else throw "missing result source account"

/-- Every declared selector is required; no filtering of the actual findings occurs.
Patterns use the same proved single-message language as compiler-negative fences. -/
private def matchFinding (expected : Json) (actual : Finding) (input : ExampleBinding) : Except String Unit := do
  PolicyCodec.exactFields expected ["id", "subreason", "detailPattern", "location", "subject", "impact", "claim"]
  let id ← RegistryCodec.parseRule (← field expected "id")
  unless actual.1 == id do throw "unexpected rule diagnostic"
  unless (← string expected "subreason") == (descriptor id).applicability do
    throw "wrong expected rule subreason"
  let encoded := RegistryCodec.diagnosticJson actual
  let arguments ← field encoded "arguments"
  unless StrictLeanPolicy.matchesPattern (← string expected "detailPattern") (← string arguments "detail") do
    throw s!"wrong diagnostic reason for {id}"
  unless (← field expected "impact") == (← field encoded "impact") do throw "wrong diagnostic impact"
  unless (← field expected "claim") == (← field encoded "claim") && actual.2.severity == .error do
    throw "wrong diagnostic claim or severity"
  unless actual.2.mode == input.mode do throw "wrong diagnostic mode"
  unless actual.2.related.isEmpty do throw "unexpected related diagnostics"
  let subject ← field expected "subject"
  let args := (← arguments.getObj?).toList.filter (·.1 != "detail")
  unless Json.mkObj args == subject do throw s!"wrong diagnostic subject for {id}"
  let location ← field expected "location"
  unless (← field encoded "location") == location do throw s!"wrong primary location for {id}"
  match actual.2.location with
  | .source source =>
      unless input.snapshot.val.sources.any (fun s => s == source.val.snapshot) do
        throw "diagnostic source is outside the fixed example snapshot"
  | .module name => unless name != .anonymous do throw "anonymous diagnostic module"
  | .project name => unless !name.isEmpty do throw "missing diagnostic context"

/-- Validate an actual subprocess record. A normal terminal exit, bound canonical result,
exact expectation list and source stability are jointly required. No exit-only acceptance. -/
def qualify (record : Json) : Except String Unit := do
  let result ← field record "result"
  for (key, value) in RegistryCodec.identityFields ResultProtocol.producer do
    unless (← field result key) == value do throw s!"stale result identity: {key}"
  let mode ← RegistryCodec.parseMode (← string record "mode")
  unless (← string result "mode") == mode.spelling do throw "wrong example evidence mode"
  let bound ← binding record mode
  let code ← (← field record "exitCode").getNat?
  unless code ≤ 1 do throw "example process did not complete normally"
  let actual ← (← (← field result "diagnostics").getArr?).mapM DiagnosticCodec.parseDiagnostic
  let expected ← (← field record "expected").getArr?
  unless expected.size == actual.size do throw "missing or unexpected diagnostic"
  for (spec, finding) in expected.zip actual do matchFinding spec finding bound
  let unresolved ← (← (← field result "unresolved").getArr?).mapM Json.getStr?
  let patterns ← (← (← field record "unresolvedPatterns").getArr?).mapM Json.getStr?
  unless unresolved.size == patterns.size && (patterns.zip unresolved).all
      (fun (pattern, detail) => StrictLeanPolicy.matchesPattern pattern detail) do
    throw "unexpected unresolved evidence"
  let status ← string result "status"
  let kind ← string record "kind"
  let observation : BoundObservation := ⟨bound, .completed, .checked actual false⟩
  match kind with
  | "positive" =>
      sourceAccount result bound
      unless code == 0 && status == "completed" && actual.isEmpty do throw "positive check incomplete"
      validateBoundExample bound .positive #[] observation
  | "policyRejection" =>
      let rule ← RegistryCodec.parseRule (← field record "rule")
      -- Configuration/build/coverage rejection can precede a completed source account.
      unless [.configuration, .sourceBuild, .coverage].contains rule do sourceAccount result bound
      unless code == 1 && status == "rejected" && !actual.isEmpty do throw "policy rejection incomplete"
      let rule ← RegistryCodec.parseRule (← field record "rule")
      validateBoundExample bound (.policyRejection rule (descriptor rule).applicability) actual observation
  | "diagnosticDemonstration" =>
      unless code == 1 && status == "incomplete" do throw "not the expected unavailable-analysis result"
      let _ ← admitDemonstration ⟨bound, actual⟩ observation
      pure ()
  | _ => throw "unknown example or demonstration kind"

/-- Qualify transport refusals using a real production record, restoring it after each
single mutation. These exercise the operational JSON adapter, not a policy proof by samples. -/
def qualifyMutations (record : Json) : Except String Unit := do
  qualify record
  let result ← field record "result"
  let mutations : Array (String × Json) := #[
    ("example process did not complete normally", record.setObjVal! "exitCode" (toJson (137 : Nat))),
    ("example source/configuration changed", record.setObjVal! "after" Json.null),
    ("wrong example evidence mode", record.setObjVal! "mode" (.str "editorSnapshot")),
    ("stale result identity", record.setObjVal! "result" (result.setObjVal! "sourceRevision" (.str "stale"))),
    ("unknown example or demonstration kind", record.setObjVal! "kind" (.str "expectedUnavailable"))]
  for (reason, mutation) in mutations do
    match qualify mutation with
    | .ok _ => throw "invalid example evidence admitted"
    | .error detail => unless detail.contains reason do throw s!"wrong mutation refusal: {detail}"
    qualify record

/-- Full-corpus coverage derives from the sole closed registry; every selected rule has
one fixed, one intended diagnostic, and one independently restored record. -/
def qualifyCorpus (json : Json) : Except String Unit := do
  unless (← field json "schemaVersion") == toJson (1 : Nat) do throw "unsupported corpus schema"
  let selected ← (← (← field json "selected").getArr?).mapM RegistryCodec.parseRule
  unless decide selected.toList.Nodup do throw "duplicate selected rule"
  let complete ← (← field json "completeCorpus").getBool?
  if complete then
    unless selected.size == RuleId.all.length && RuleId.all.all selected.contains do
      throw "incomplete twenty-rule corpus"
  let checkerBefore ← field json "checkerBefore"
  unless checkerBefore == (← field json "checkerAfter") do throw "checker sources changed"
  let checkerFiles ← sources checkerBefore
  unless !checkerFiles.isEmpty do throw "missing checker source state"
  let records := (← (← field json "records").getArr?).map
    (fun record => record.setObjVal! "checkerSources" checkerBefore)
  unless records.size == selected.size * 3 do throw "missing or extra fixture phase"
  for rule in selected do
    for phase in #["Fixed", "Violation", "Restored"] do
      let matching ← records.filterM fun record => do
        return (← string record "rule") == rule.spelling && (← string record "phase") == phase
      unless matching.size == 1 do throw "missing or repeated fixture phase"
      let some record := matching[0]? | throw "missing fixture record"
      unless ((← string record "kind") == "positive") == (phase != "Violation") do
        throw "fixture phase classification mismatch"
      qualify record
  if let some record := records[0]? then qualifyMutations record

end StrictLean.Checker.RuleExampleQualification

/-- Validate a whole exported corpus, or one in-progress record without a corpus claim. -/
def main (args : List String) : IO Unit := do
  let (path, single) ← match args with
    | ["--record", path] => pure (path, true)
    | [path] => pure (path, false)
    | _ => throw <| IO.userError "usage: RuleExampleQualification [--record] EVIDENCE.json"
  let json ← IO.ofExcept <| StrictLean.Checker.PolicyCodec.parse (← IO.FS.readFile path)
  if single then
    let before ← IO.ofExcept (json.getObjVal? "checkerBefore")
    let after ← IO.ofExcept (json.getObjVal? "checkerAfter")
    unless before == after do throw <| IO.userError "checker sources changed"
    for record in ← IO.ofExcept ((json.getObjVal? "records").bind Lean.Json.getArr?) do
      IO.ofExcept (StrictLean.Checker.RuleExampleQualification.qualify (record.setObjVal! "checkerSources" before))
  else IO.ofExcept (StrictLean.Checker.RuleExampleQualification.qualifyCorpus json)
  IO.println "rule example evidence: PASS (scoped diagnostic qualification; no Accepted claim)"
