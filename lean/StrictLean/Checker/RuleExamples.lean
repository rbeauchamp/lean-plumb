import StrictLean.Checker.Documentation
import StrictLean.Checker.ResultProtocol
import StrictLean.Website

/-! Source-owned example adapters. These invoke the shipped compilation, admission,
policy and documentation detectors; they define no second linter. Diagnostic-only
inspection deliberately retains compiler warnings and never returns positive conformance.
Lean's compiler, process completion and filesystem observations remain trusted. -/
namespace StrictLean.Checker.RuleExamples
open Lean System

/-- A negative policy example may need inspection of an elaborated hole even though the
compiler warned. Keep that warning in the receipt; corrections use the ordinary strict gate. -/
unsafe def inspectNegative (repo path output : FilePath) : IO UInt32 := do
  let source ← IO.FS.readFile path
  let manifest ← Manifest.load (Manifest.defaultPath repo)
  if let some lines ← Lake.buildChecked repo (Manifest.positiveTargets manifest) "incrementally" then
    throw <| IO.userError ("example dependency build failed: " ++ "\n".intercalate lines.toList)
  let inventory ← Lake.surfaceInventory repo
  withScratch repo "rule-policy-example" fun scratch => do
    let compilation ← SourceAudit.compile repo scratch
      { «module» := "RuleExample", source, rejectWarnings := false }
    unless SourceAudit.compilationPassed compilation do
      throw <| IO.userError "policy example did not elaborate; compiler failure is not policy rejection"
    let inspected ← SourceAudit.inspect compilation inventory.leanPath inventory.leanSrcPath
      inventory.moduleSources (some inventory.leanLibDir)
    unless (← IO.FS.readFile path) == source do throw <| IO.userError "example source changed"
    let declarations := inspected.report.declarations.qsort fun a b => Name.quickLt a.name b.name
    let scope ← IO.ofExcept <| Policy.admitScope declarations inspected.transcripts
    let mut findings := #[]
    for decl in declarations do
      if let some id := Policy.ruleFor decl (some .standardLogical) scope then
        let location ← IO.ofExcept <| RuleDiagnostics.declarationLocation decl (some ⟨path.toString, source⟩)
        findings := findings.push (← IO.ofExcept <| RuleDiagnostics.declarationFinding id decl.name
          (Policy.classify decl scope) location .freshFile (some "standard-logical"))
    ResultProtocol.write output (Json.mkObj [
      ("file", toJson path.toString), ("source", toJson source),
      ("diagnosticOnly", toJson true), ("compilerOutput", toJson compilation.process.output),
      ("report", toJson inspected.report), ("frontendTranscripts", toJson inspected.transcripts)])
      .freshFile (if findings.isEmpty then .classified else .rejected) findings
    return if findings.isEmpty then 0 else 1

/-- Capture emitted findings from the actual documentation driver in the same canonical
result envelope used by project/file consumers. The fresh copy owns build and fence artifacts. -/
unsafe def documentation (repo docsRoot output : FilePath) : IO UInt32 := do
  let paths := ((← docsRoot.walkDir).filter (·.extension == some "md")).qsort
    (fun a b => a.toString < b.toString)
  if paths.isEmpty then throw <| IO.userError "empty example documentation tree"
  let sources ← paths.mapM fun path => do return (path, ← IO.FS.readFile path)
  withScratch repo "rule-document-example" fun scratch => do
    let copy := scratch / "project"
    copyProject repo copy scratch
    let manifest ← Manifest.load (Manifest.defaultPath copy)
    let inventory ← Lake.surfaceInventory copy
    if let some lines ← Lake.buildChecked copy (Manifest.positiveTargets manifest) "fresh" then
      throw <| IO.userError ("example dependency build failed: " ++ "\n".intercalate lines.toList)
    let findings ← IO.mkRef (#[] : Array Finding)
    let code ← Documentation.auditBuiltProject copy docsRoot inventory 1 true
      (fun finding => findings.modify (·.push finding))
    for (path, source) in sources do
      unless (← IO.FS.readFile path) == source do throw <| IO.userError "documentation source changed"
    let actual ← findings.get
    unless (code == 0) == actual.isEmpty do
      throw <| IO.userError "documentation completion/findings mismatch"
    ResultProtocol.write output (Json.mkObj [
      ("documents", toJson (sources.map fun (path, source) => Json.mkObj [
        ("uri", toJson path.toString), ("source", toJson source)]))])
      .documentationExample (if actual.any (·.2.impact == .incomplete) then .incomplete
        else if code == 0 then .completed else .rejected) actual
    return code

unsafe def run (args : List String) : IO UInt32 := do
  match args with
  | ["--policy-negative", repo, source, output] =>
      inspectNegative ⟨repo⟩ ⟨source⟩ ⟨output⟩
  | ["--documentation", repo, docs, output] =>
      documentation ⟨repo⟩ ⟨docs⟩ ⟨output⟩
  | _ => throw <| IO.userError "usage: ruleExamples (--policy-negative PROJECT SOURCE | --documentation PROJECT DOCS) OUTPUT"
end StrictLean.Checker.RuleExamples

unsafe def main (args : List String) : IO UInt32 := do
  try
    StrictLean.Checker.initializeLeanSearchPath
    StrictLean.Checker.RuleExamples.run args
  catch error =>
    IO.eprintln s!"rule example production incomplete: {error}"
    return 2
