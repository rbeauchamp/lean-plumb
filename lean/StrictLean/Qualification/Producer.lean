import StrictLean.Qualification.Project
import StrictLeanQualification.Producer

/-! Actual producer qualification: 18 documented-source controls, existing transport
mutations and three standalone-executable controls. The source files remain authoritative;
this driver copies their bytes rather than maintaining another theorem fixture. -/
namespace StrictLean.Qualification.Producer
open Lean System

/-- Run all source-bound producer controls, optionally retaining emitted evidence. -/
def check (evidence : Option FilePath) : IO Unit := do
  let root ← rootDirectory
  let records ← withScratch root "producer-controls" fun project => do
    prepareProject root project "producer_adopter" "kernel-only"
      "The unchanged reflexivity proposition and exact doc presence."
    let mut records : Array Json := #[]
    let mut theoremType : Option Json := none
    let mut lastOutput : Option FilePath := none
    for (invocation, flags, mode) in #[
        ("fresh", #[], "freshProject"), ("incremental", #["--incremental"], "incrementalProject"),
        ("build-lint", #["--build-lint"], "incrementalProject")] do
      for rule in #["SL5001", "SL5002"] do
        for kind in #["Fixed", "Violation", "Fixed"] do
          let relative := s!"examples/rules/{rule}/{kind}.lean"
          let bytes ← IO.FS.readBinFile (root / relative)
          let some source := String.fromUTF8? bytes | throw <| IO.userError "fixture must be valid UTF-8"
          IO.FS.writeBinFile (project / "Example.lean") bytes
          if kind == "Fixed" then clearBuild project
          let output := project / s!"result-{records.size}.json"
          let (result, report) ← observeProject root project output flags
          let account ← IO.ofExcept (StrictLeanQualification.Producer.account report)
          let declarations ← IO.ofExcept (account.getObjValAs? (Array Json) "declarations")
          let some declaration := declarations[0]? | throw <| IO.userError "missing theorem declaration"
          let observedType ← IO.ofExcept (declaration.getObjVal? "type")
          let expectedType := theoremType.getD observedType
          theoremType := some expectedType
          IO.ofExcept (StrictLeanQualification.Producer.checkedValidation.run report result.exitCode.toNat
            rule mode source (kind == "Fixed") expectedType)
          requireChecks [⟨"fixture bytes unchanged", (← IO.FS.readBinFile (project / "Example.lean")) == bytes⟩]
          records := records.push (Json.mkObj [
            ("rule", .str rule), ("case", .str kind), ("invocation", .str invocation),
            ("path", .str relative), ("source", .str source), ("result", report)])
          lastOutput := some output
          IO.println s!"{invocation} project {rule}/{kind}: PASS"
    let some output := lastOutput | throw <| IO.userError "no producer controls ran"
    transportControl root "lean/StrictLean/Checker/ProducerQualification.lean" output
    let config := project / "lakefile.lean"
    IO.FS.writeFile config ((← IO.FS.readFile config) ++ "\nlean_exe sampleTool where\n  root := `SelftestMain\n")
    let manifestPath := project / "foundation_manifest.json"
    let manifest ← readJson manifestPath
    let surfaces ← IO.ofExcept (manifest.getObjValAs? (Array Json) "surfaces")
    let some surface := surfaces[0]? | throw <| IO.userError "missing scratch manifest surface"
    writeJson manifestPath (manifest.setObjVal! "surfaces"
      (toJson #[surface.setObjVal! "executables" (toJson #["sampleTool"])]))
    let mainSource := "/-! Standalone no-effect IO entrypoint. -/\ndef main : IO Unit := pure ()\n"
    for phase in #["positive", "axiom", "restored"] do
      let source := mainSource ++ (if phase == "axiom" then "axiom ownedAssumption : True\n" else "")
      IO.FS.writeFile (project / "SelftestMain.lean") source
      clearBuild project
      let (result, report) ← observeProject root project (project / s!"standalone-{phase}.json") #[]
      IO.ofExcept (StrictLeanQualification.checkedDecoded.run
        (StrictLeanQualification.Producer.standaloneRequirements report result.exitCode.toNat (phase == "axiom")))
      IO.println s!"standalone executable {phase}: PASS"
    return records
  if let some path := evidence then
    if let some parent := path.parent then IO.FS.createDirAll parent
    writeJson path (Json.mkObj [("schemaVersion", toJson (1 : Nat)), ("examples", toJson records)])
  IO.println "producer qualification: PASS (scoped operational evidence)"

end StrictLean.Qualification.Producer
