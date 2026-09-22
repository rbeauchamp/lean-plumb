import StrictLean.Checker.Documentation
import StrictLean.Checker.AxiomGate
import StrictLean.Checker.ResultProtocol
import StrictLean.Website

/-! Source-owned example adapters. These invoke the shipped compilation, admission,
policy and documentation detectors; they define no second linter. Diagnostic-only
inspection deliberately retains compiler warnings and never returns positive conformance.
Lean's compiler, process completion and filesystem observations remain trusted. -/
namespace StrictLean.Checker.RuleExamples
open Lean System

/-- Reuse the engine's owner for all completed and exceptional exits. A refused adapter
returns no qualifying result; no exception text is classified as a diagnostic. -/
private def stable (sources : Array ProducerReport.SourceBinding)
    (configuration : Array (FilePath × Option String)) (action : IO α) : IO α := do
  IO.ofExcept <| (← SourceBinding.withUnchanged sources configuration action).mapError (·.detail)

/-- A negative policy example may need inspection of an elaborated hole even though the
compiler warned. Keep that warning in the receipt; corrections use the ordinary strict gate. -/
unsafe def inspectNegative (repo path output : FilePath) : IO UInt32 := do
  let configuration ← SourceBinding.configuration repo (Manifest.defaultPath repo)
  let (scopeJson, findings) ← stable #[] configuration do
    let source ← IO.FS.readFile path
    let inventory ← Lake.surfaceInventory repo
    let sources := (← SourceBinding.capture inventory.moduleSources).push {
      moduleName := `RuleExample, path := path.toString, content := source }
    stable sources configuration do
      let manifest ← Manifest.load (Manifest.defaultPath repo)
      if let some lines ← Lake.buildChecked repo (Manifest.positiveTargets manifest) "incrementally" then
        throw <| IO.userError ("example dependency build failed: " ++ "\n".intercalate lines.toList)
      withScratch repo "rule-policy-example" fun scratch => do
        let compilation ← IO.ofExcept <| (← SourceAudit.compile repo scratch
          { «module» := "RuleExample", source, rejectWarnings := false }).mapError (·.detail)
        unless SourceAudit.compilationPassed compilation do
          throw <| IO.userError "policy example did not elaborate; compiler failure is not policy rejection"
        let inspected ← IO.ofExcept <| (← SourceAudit.inspectOutcome compilation inventory.leanPath
          inventory.leanSrcPath inventory.moduleSources (some inventory.leanLibDir)).mapError (·.detail)
        let declarations := inspected.report.declarations.qsort fun a b => Name.quickLt a.name b.name
        let scope ← IO.ofExcept <| Policy.admitScope declarations inspected.transcripts
        let mut findings := #[]
        for decl in declarations do
          if let some id := Policy.ruleFor decl (some .standardLogical) scope then
            let location ← IO.ofExcept <| RuleDiagnostics.declarationLocation decl (some ⟨path.toString, source⟩)
            findings := findings.push (← IO.ofExcept <| RuleDiagnostics.declarationFinding id decl.name
              (Policy.classify decl scope) location .freshFile (some "standard-logical"))
        return (Json.mkObj [
          ("file", toJson path.toString), ("source", toJson source),
          ("configuration", toJson configuration), ("configurationRoot", toJson repo.toString),
          ("claim", toJson (some "standard-logical" : Option String)), ("execution", Json.null),
          ("diagnosticOnly", toJson true), ("compilerOutput", toJson compilation.process.output),
          ("report", toJson inspected.report), ("frontendTranscripts", toJson inspected.transcripts)], findings)
  ResultProtocol.write output scopeJson .freshFile
    (if findings.isEmpty then .classified else .rejected) findings
  let value ← IO.ofExcept <| PolicyCodec.parse (← IO.FS.readFile output)
  let request := ResultProtocol.requestJson "policyNegative" repo.toString path.toString none none configuration
  writeJson output ((value.setObjVal! "request" request).setObjVal! "effective"
    (Json.mkObj [("root", toJson repo.toString), ("configuration", toJson configuration)]))
  return if findings.isEmpty then 0 else 1

/-- Capture emitted findings from the actual documentation driver in the same canonical
result envelope used by project/file consumers. The fresh copy owns build and fence artifacts. -/
unsafe def documentation (repo docsRoot output : FilePath) : IO UInt32 := do
  let requestedConfiguration ← SourceBinding.configuration repo (Manifest.defaultPath repo)
  let documents ← Documentation.captureMarkdown docsRoot
  if documents.isEmpty then throw <| IO.userError "empty example documentation tree"
  let sources := documents.map fun document => (FilePath.mk document.uri, document.source)
  let outcome ← (stable #[] requestedConfiguration <| withScratch repo "rule-document-example" fun scratch => do
    let copy := scratch / "project"
    copyProject repo copy scratch
    let configuration ← SourceBinding.configuration copy (Manifest.defaultPath copy)
    stable #[] configuration do
      let manifest ← Manifest.load (Manifest.defaultPath copy)
      let inventory ← Lake.surfaceInventory copy
      let projectSources ← SourceBinding.capture inventory.moduleSources
      let dependencies ← Snapshot.dependencies inventory
      stable projectSources configuration do
        let (buildProcess, buildResult) ← Lake.buildCheckedObservation copy (Manifest.positiveTargets manifest) "fresh"
        if let some lines := buildResult then
          throw <| IO.userError ("example dependency build failed: " ++ "\n".intercalate lines.toList)
        let findings ← IO.mkRef (#[] : Array Finding)
        let classifications ← IO.mkRef (#[] : Array Documentation.Classification)
        let certificate ← IO.mkRef (none : Option ((c : StrictLeanPolicy.Claim) × StrictLeanPolicy.AcceptedRun c))
        let code ← Documentation.auditBuiltProject copy docsRoot inventory projectSources configuration dependencies documents (Acceptance.buildObservation buildProcess) 1 true
          (fun finding => findings.modify (·.push finding))
          (fun results => classifications.set (results.map Documentation.classification))
          (fun claim accepted => certificate.set (some ⟨claim, accepted⟩))
        let actual ← findings.get
        unless (code == 0) == actual.isEmpty do
          throw <| IO.userError "documentation completion/findings mismatch"
        return (code, actual, ← classifications.get, copy.toString, configuration, ← certificate.get)).toBaseIO
  -- Markdown is not a Lean module map. Preserve its own exact snapshots even on errors.
  Documentation.checkMarkdown docsRoot documents
  let (code, actual, classifications, configurationRoot, configuration, certificate) ← IO.ofExcept <| outcome.mapError (fun error => toString error)
  let completion ← if code == 0 then do
      let some ⟨_, accepted⟩ := certificate
        | throw <| IO.userError "documentation adapter lacks accepted evidence"
      let report := accepted.report
      unless report.claim.val.scope == .documentation (sources.map fun (path, source) => ⟨path.toString, source⟩) do
        throw <| IO.userError "documentation adapter request mismatch"
      pure (if report.census.fences.size > 0 && report.census.fences.all
        (fun fence => decide (fence.expectation = .positive)) then ResultProtocol.Status.completed else .classified)
    else pure (if actual.any (·.2.impact == .incomplete) then .incomplete else .rejected)
  ResultProtocol.write output (Json.mkObj [
    ("configuration", toJson configuration), ("configurationRoot", toJson configurationRoot),
    ("fences", toJson classifications),
    ("documents", toJson (sources.map fun (path, source) => Json.mkObj [
      ("uri", toJson path.toString), ("source", toJson source)]))])
    .documentationExample completion actual
  let value ← IO.ofExcept <| PolicyCodec.parse (← IO.FS.readFile output)
  let value := match certificate with
    | some ⟨_, accepted⟩ => value.setObjVal! "acceptance" (ResultProtocol.acceptedJson accepted)
    | none => value
  let request := ResultProtocol.requestJson "documentation" repo.toString docsRoot.toString none none requestedConfiguration
  writeJson output ((value.setObjVal! "request" request).setObjVal! "effective"
    (Json.mkObj [("root", toJson configurationRoot), ("configuration", toJson configuration)]))
  return code

unsafe def run (args : List String) : IO UInt32 := do
  match args with
  | ["--policy-negative", repo, source, output] =>
      inspectNegative ⟨repo⟩ ⟨source⟩ ⟨output⟩
  | ["--documentation", repo, docs, output] =>
      documentation ⟨repo⟩ ⟨docs⟩ ⟨output⟩
  | _ => throw <| IO.userError "usage: ruleExamples (--policy-negative PROJECT SOURCE | --documentation PROJECT DOCS) OUTPUT"
end StrictLean.Checker.RuleExamples

private unsafe def ruleExamplesEntry (args : List String) : IO UInt32 := do
  try
    StrictLean.Checker.initializeLeanSearchPath
    StrictLean.Checker.RuleExamples.run args
  catch error =>
    IO.eprintln s!"rule example production incomplete: {error}"
    return 2

/-- Qualification-only binary. `--injected-git-facts FACTS` is the internal
corpus-producer entry: it installs the runner's once-captured shared-dependency
Git facts (`Snapshot.GitFacts`), then runs either the exact `axiomGate` body
(`AxiomGate.entry`) or this binary's own modes. Facts only replace the Git part
of a capture whose exact request they answer; every source and configuration
byte is still read fresh. The user-facing `axiomGate` never accepts them. -/
unsafe def main (args : List String) : IO UInt32 := do
  match args with
  | "--injected-git-facts" :: facts :: rest =>
    let loaded ← (do
      let json ← IO.ofExcept (Lean.Json.parse (← IO.FS.readFile facts))
      IO.ofExcept (Lean.fromJson? (α := Array StrictLean.Checker.Snapshot.GitFacts) json)).toBaseIO
    match loaded with
    | .error error =>
      IO.eprintln s!"rule example production incomplete: injected git facts: {error}"
      return 2
    | .ok table =>
      if table.isEmpty then
        IO.eprintln "rule example production incomplete: empty injected git facts"
        return 2
      StrictLean.Checker.Snapshot.injectedGitFacts.set table
      match rest with
      | "axiomGate" :: gateArgs => StrictLean.Checker.AxiomGate.entry gateArgs
      | "--injected-git-facts" :: _ =>
        IO.eprintln "rule example production incomplete: repeated injected git facts"
        return 2
      | _ => ruleExamplesEntry rest
  | _ => ruleExamplesEntry args
