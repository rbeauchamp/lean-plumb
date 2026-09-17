import StrictLean.Checker.Documentation
import StrictLean.Checker.Lake

/-! Public Lean executable for normative Markdown fence auditing. -/

namespace StrictLean.Checker.DocFenceAudit

open Lean System
open StrictLean.Checker
open StrictLean.Checker.Documentation

structure Options where
  jobs : Nat := 4
  docsRoot : Option FilePath := none
  manifest : Option FilePath := none
  project : Option FilePath := none
  verbose : Bool := false
  help : Bool := false

private def usage : String :=
  "usage: lake exe docFenceAudit -- [--jobs N] [--verbose] [--docs-root PATH] " ++
  "[--project DIR] [--manifest PATH]"

private partial def parseArgs : List String → Options → IO Options
  | [], options => return options
  | "--" :: rest, options => parseArgs rest options
  | "--jobs" :: value :: rest, options => do
      let jobs ← parseNatArg "--jobs" value
      parseArgs rest { options with jobs }
  | "--docs-root" :: value :: rest, options =>
      parseArgs rest { options with docsRoot := some (FilePath.mk value) }
  | "--manifest" :: value :: rest, options =>
      parseArgs rest { options with manifest := some (FilePath.mk value) }
  | "--project" :: value :: rest, options =>
      parseArgs rest { options with project := some (FilePath.mk value) }
  | "--verbose" :: rest, options => parseArgs rest { options with verbose := true }
  | "--help" :: rest, options | "-h" :: rest, options =>
      parseArgs rest { options with help := true }
  | flag :: _, _ => throw <| IO.userError s!"unknown or incomplete argument: {flag}"

private def resolve (repo path : FilePath) : FilePath :=
  if path.isAbsolute then path else repo / path.toString

unsafe def run (args : List String) : IO UInt32 := do
  let options ← parseArgs args {}
  if options.help then IO.println usage; return 0
  if options.jobs == 0 then throw <| IO.userError "--jobs must be positive"
  let repo ← match options.project with
    | some dir => findRepoRoot dir
    | none => repoRoot
  let docsRoot := options.docsRoot.map (resolve repo) |>.getD (repo / "docs")
  withScratch repo "doc-fence-audit" fun scratch => do
    let copy := scratch / "project"
    copyProject repo copy scratch
    let manifestPath := options.manifest.map (resolve repo) |>.getD (Manifest.defaultPath copy)
    let configuration ← SourceBinding.configuration copy manifestPath
    let outcome ← SourceBinding.withUnchanged #[] configuration do
      let manifest ← Manifest.load manifestPath
      let inventory ← Lake.surfaceInventory copy
      let sources ← SourceBinding.capture inventory.moduleSources
      SourceBinding.withUnchanged sources configuration do
        SourceBinding.configurationUnchanged configuration
        let (buildProcess, buildResult) ← Lake.buildCheckedObservation copy (Manifest.positiveTargets manifest) "fresh"
        SourceBinding.unchanged sources
        SourceBinding.configurationUnchanged configuration
        if let some lines := buildResult then
          for line in lines do IO.println s!"    {line}"
          return 1
        IO.println "claimed surface built fresh; compiling fences"
        (← IO.getStdout).flush
        Documentation.auditBuiltProject copy docsRoot inventory sources configuration (Acceptance.buildObservation buildProcess) options.jobs options.verbose
    let outcome := outcome.bind id
    match outcome with
    | .ok result => return result
    | .error failure =>
        let finding ← IO.ofExcept <| RuleDiagnostics.contextFinding .admission docsRoot.toString
          failure.detail .documentationExample .incomplete
        IO.println finding.2.text
        return 1

end StrictLean.Checker.DocFenceAudit

unsafe def main (args : List String) : IO UInt32 := do
  try
    StrictLean.Checker.initializeLeanSearchPath
    StrictLean.Checker.DocFenceAudit.run args
  catch error =>
    IO.eprintln s!"FAIL: {error}"
    return 1
