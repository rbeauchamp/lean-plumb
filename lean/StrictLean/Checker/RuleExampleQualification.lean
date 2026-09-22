import StrictLean.Checker.Documentation
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
      ``StrictLean.Website.demonstration_selected_rule,
      ``StrictLean.Website.demonstration_not_accepted,
      ``StrictLeanPolicy.incomplete_example_refused,
      ``StrictLean.Website.admitExampleRequest_sound,
      ``StrictLean.Website.admitExampleSources_sound,
      ``StrictLean.Website.admitExampleSources_complete,
      ``StrictLean.Checker.Documentation.positiveClassifications_sound] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun ax => #[`propext, `Quot.sound, `Classical.choice].contains ax) do
      throwError "example theorem {name} exceeds Standard-Logical: {axioms}"

namespace StrictLean.Checker.RuleExampleQualification
open Lean StrictLean StrictLean.Website

def field (j : Json) (key : String) : Except String Json := j.getObjVal? key
def string (j : Json) (key : String) : Except String String := do
  (← field j key).getStr?

def sources (j : Json) : Except String (Array StrictLeanPolicy.SourceSnapshot) := do
  (← j.getArr?).mapM fun source => do
    PolicyCodec.exactFields source ["uri", "source"]
    return ⟨← string source "uri", ← string source "source"⟩

private def parseRequest (json : Json) : Except String ExampleRequest := do
  let request : ExampleRequest ← fromJson? json
  unless ["file", "project", "documentation", "policyNegative"].contains request.kind do
    throw "unsupported example request kind"
  unless toJson (request : ExampleRequest) == json do throw "invalid example request account"
  return request

def binding (record : Json) (mode : EvidenceMode) : Except String ExampleBinding := do
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
  let request ← parseRequest (← field record "request")
  unless request.project == configuration.uri &&
      toJson request.configuration == (← PolicyCodec.parse configuration.source) do
    throw "request configuration differs from frozen snapshot"
  return ⟨snapshot, mode, request⟩

def sourceAccount (result : Json) (bound : ExampleBinding) (displayed : String) :
    Except String Unit := do
  let scope ← field result "scope"
  let observed ← if let .ok raw := field result "sourceAccount" then do
      let entries ← fromJson? (α := Array ProducerReport.SourceBinding) raw
      pure (entries.map fun entry => (⟨entry.path, entry.content⟩ : StrictLeanPolicy.SourceSnapshot))
    else if bound.request.kind == "policyNegative" then do
      pure #[⟨← string scope "file", ← string scope "source"⟩]
    else if bound.request.kind == "documentation" then sources (← field scope "documents")
    else throw "missing result source account"
  let _ ← admitExampleSources bound.snapshot.val.sources observed displayed
  if bound.request.kind == "file" || bound.request.kind == "policyNegative" then
    unless observed.any (fun source => source.uri == bound.request.subject && source.source == displayed) do
      throw "missing requested file source account"

private def configurationAccount (root : String) (configuration : Array (String × Option String)) :
    Except String (Array (String × Option String)) := do
  unless !root.isEmpty do throw "missing configuration root"
  configuration.mapM fun (path, source) => do
    unless path.startsWith (root ++ "/") do throw "configuration outside captured project"
    return ((path.drop (root.length + 1)).toString, source)

def requestAccount (result : Json) (bound : ExampleBinding) : Except String ExampleRequest := do
  let observed ← parseRequest (← field result "request")
  let admitted ← admitExampleRequest bound.request observed
  let requested ← configurationAccount admitted.val.project admitted.val.configuration
  let effectiveAccount ← field result "effective"
  if effectiveAccount != Json.null then
    let effective ← configurationAccount (← string effectiveAccount "root")
      (← fromJson? (α := Array (String × Option String)) (← field effectiveAccount "configuration"))
    unless effective == requested do throw "effective configuration differs from request"
  let scope ← field result "scope"
  if let .ok _ := scope.getObj? then
    unless effectiveAccount != Json.null do throw "missing effective request account"
    let configuration ← fromJson? (α := Array (String × Option String)) (← field scope "configuration")
    let effective ← configurationAccount (← string scope "configurationRoot") configuration
    unless effective == requested &&
        (← field scope "configuration") == (← field effectiveAccount "configuration") &&
        (← field scope "configurationRoot") == (← field effectiveAccount "root") do
      throw "effective configuration differs from request"
    match admitted.val.kind with
    | "file" =>
        unless (← field scope "claim") == toJson admitted.val.claim &&
            (← field scope "execution") == toJson admitted.val.execution &&
            (← string scope "file") == admitted.val.subject do
          throw "effective file claim or execution differs from request"
    | "policyNegative" =>
        unless (← field scope "claim") == toJson (some "standard-logical" : Option String) &&
            (← field scope "execution") == Json.null && (← string scope "file") == admitted.val.subject &&
            (← field scope "diagnosticOnly") == toJson true do
          throw "wrong diagnostic-only effective request"
    | "documentation" => pure ()
    | "project" =>
        unless (← string scope "project") == admitted.val.subject do throw "wrong effective project"
        let some (_, some text) := requested.find? (·.1 == "foundation_manifest.json")
          | throw "missing requested manifest"
        let manifest ← PolicyCodec.parse text
        let surfaces ← (← field manifest "surfaces").getArr?
        let actual ← (← field scope "surfaces").getArr?
        unless actual.size == surfaces.size do throw "effective surface coverage differs from request"
        for (expected, actual) in surfaces.zip actual do
          unless (← field expected "library") == (← field actual "library") &&
              (← field expected "claim") == (← field actual "claim") &&
              ((field expected "execution").toOption.getD (.str "report")) == (← field actual "execution") do
            throw "effective surface claim or execution differs from request"
    | _ => throw "unknown example request kind"
  return admitted.val

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
  let observedRequest ← requestAccount result bound
  let matchingMode : Bool := match observedRequest.kind with
    | "file" | "policyNegative" => mode == .freshFile
    | "documentation" => mode == .documentationExample
    | "project" => mode == .freshProject || mode == .incrementalProject
    | _ => false
  unless matchingMode do throw "request invocation differs from evidence mode"
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
  sourceAccount result bound (← string record "source")
  let observation : BoundObservation := ⟨{ bound with request := observedRequest }, .completed, .checked actual false⟩
  match kind with
  | "positive" =>
      unless bound.request.kind != "policyNegative" do throw "diagnostic-only adapter cannot qualify positive"
      if mode == .documentationExample then
        let raw ← (← field (← field result "scope") "fences").getArr?
        let classifications ← raw.mapM (fromJson? (α := Documentation.Classification))
        let _ ← Documentation.admitPositiveClassifications classifications
        pure ()
      unless code == 0 && status == "completed" && actual.isEmpty do throw "positive check incomplete"
      validateBoundExample bound .positive #[] observation
  | "policyRejection" =>
      unless code == 1 && status == "rejected" && !actual.isEmpty do throw "policy rejection incomplete"
      let rule ← RegistryCodec.parseRule (← field record "rule")
      validateBoundExample bound (.policyRejection rule (descriptor rule).applicability) actual observation
  | "diagnosticDemonstration" =>
      unless code == 1 && status == "incomplete" do throw "not the expected unavailable-analysis result"
      let rule ← RegistryCodec.parseRule (← field record "rule")
      let _ ← admitDemonstration ⟨bound, rule, actual⟩ observation
      pure ()
  | _ => throw "unknown example or demonstration kind"

/-- Qualify transport refusals using a real production record, restoring it after each
single mutation. These exercise the operational JSON adapter, not a policy proof by samples. -/
def qualifyMutations (record : Json) : Except String Unit := do
  qualify record
  let result ← field record "result"
  let request ← field record "request"
  let mutations : Array (String × Json) := #[
    ("example process did not complete normally", record.setObjVal! "exitCode" (toJson (137 : Nat))),
    ("example source/configuration changed", record.setObjVal! "after" Json.null),
    ("wrong example evidence mode", record.setObjVal! "mode" (.str "editorSnapshot")),
    ("stale result identity", record.setObjVal! "result" (result.setObjVal! "sourceRevision" (.str "stale"))),
    ("unknown example or demonstration kind", record.setObjVal! "kind" (.str "expectedUnavailable")),
    ("producer request differs", record.setObjVal! "request" (request.setObjVal! "claim" (.str "different-profile"))),
    ("producer request differs", record.setObjVal! "request" (request.setObjVal! "execution" (.str "different-execution")))]
  for (reason, mutation) in mutations do
    match qualify mutation with
    | .ok _ => throw "invalid example evidence admitted"
    | .error detail => unless detail.contains reason do throw s!"wrong mutation refusal: {detail}"
    qualify record

/-- Full-corpus coverage derives from the sole closed registry; every selected rule has
one fixed and one intended diagnostic record, each produced in its own fresh workspace
with no restored rerun (docs/standard/8 §8.8). -/
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
  unless records.size == selected.size * 2 do throw "missing or extra fixture phase"
  for rule in selected do
    for phase in #["Fixed", "Violation"] do
      let matching ← records.filterM fun record => do
        return (← string record "rule") == rule.spelling && (← string record "phase") == phase
      unless matching.size == 1 do throw "missing or repeated fixture phase"
      let some record := matching[0]? | throw "missing fixture record"
      unless ((← string record "kind") == "positive") == (phase != "Violation") do
        throw "fixture phase classification mismatch"
      qualifyMutations record

end StrictLean.Checker.RuleExampleQualification
