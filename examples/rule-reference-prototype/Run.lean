import StrictLean.Qualification.Project
import StrictLeanQualification.Website

/-! Bounded PRODUCT-01 integration probe. The separate Verso pin renders text checked
by the root compiler; it does not recheck the fixtures. Filesystem and compiler results
are operational observations. See README.md for attribution and exact evidence limits. -/
open Lean System StrictLean.Qualification

private def field (j : Json) (key : String) : IO Json := IO.ofExcept (j.getObjVal? key)
private def text (j : Json) (key : String) : IO String := IO.ofExcept (j.getObjValAs? String key)

private def page (metadata : Json) (violation diagnostic fixed : String) : IO String := do
  let clauses ← IO.ofExcept (metadata.getObjValAs? (Array String) "normativeClauses")
  let some clause := clauses[0]? | throw <| IO.userError "missing normative clause"
  let input : StrictLeanQualification.Website.PageInput := {
    id := (← text metadata "id"), title := (← text metadata "title"),
    normativePath := (clause.splitOn " §").head!, violation, diagnostic, fixed }
  let result ← IO.ofExcept (StrictLeanQualification.Website.checkedPage.run input)
  return result.val

/-- Snapshot exact relative file names and bytes. Byte equality is stronger than the
former content-hash comparison and requires no hashing implementation or utility. -/
private def snapshot (root : FilePath) : IO (List (String × ByteArray)) := do
  let root ← IO.FS.realPath root
  let mut files := []
  for path in ← root.walkDir do
    if !(← path.isDir) then
      let relative := String.intercalate "/" (path.components.drop root.components.length)
      files := (relative, ← IO.FS.readBinFile path) :: files
  return files.mergeSort (fun a b => a.1 ≤ b.1)

private def copyTree (source destination : FilePath) : IO Unit := do
  IO.FS.createDirAll destination
  for (relative, bytes) in ← snapshot source do
    let path := destination / relative
    if let some parent := path.parent then IO.FS.createDirAll parent
    IO.FS.writeBinFile path bytes

private def runPrototype : IO Unit := do
  let root ← rootDirectory
  let here := root / "examples/rule-reference-prototype"
  let out := here / "generated"
  IO.FS.createDirAll out
  let env := #[("LEAN_SRC_PATH", none), ("LEAN_PATH", some (SearchPath.toString [out, root / ".lake/build/lib/lean"]))]
  let start ← IO.monoMsNow
  let invoke (cwd : FilePath) (command : String) (args : Array String)
      (expected : UInt32) (environment : Array (String × Option String)) : IO String := do
    let elapsed := (← IO.monoMsNow) - start
    if elapsed ≥ 600000 then throw <| IO.userError "600-second prototype subprocess budget exhausted"
    let result ← run cwd command args environment
    requireChecks [⟨s!"{command} {args}: expected {expected}, got {result.exitCode}\n{result.stdout}{result.stderr}", result.exitCode == expected⟩]
    return result.stdout
  let version ← invoke root "lake" #["env", "lean", "--version"] 0 env
  requireChecks [⟨"root supported compiler", version.contains "4.33.1"⟩]
  let _ ← invoke root "lake" #["build", "axiomGate"] 0 env
  for name in #["Rule", "Probe"] do
    let _ ← invoke root "lake" #["env", "lean", "-o", (out / s!"{name}.olean").toString, (here / s!"{name}.lean").toString] 0 env
  let registry ← IO.ofExcept (Json.parse (← invoke root "lake" #["env", "lean", "--run", (here / "Export.lean").toString] 0 env))
  writeJson (out / "registry.json") registry
  let rules ← IO.ofExcept (registry.getObjValAs? (Array Json) "rules")
  let some metadata := rules.find? (fun rule => (rule.getObjValAs? String "id").toOption == some "SL1001")
    | throw <| IO.userError "registry lacks SL1001"
  requireChecks [⟨"project axiom metadata", (← text metadata "applicability") == "project-axiom"⟩]
  writeJson (out / "rule.json") metadata
  let helpRoute ← text metadata "helpRoute"
  let title ← text metadata "title"
  let mut results := Json.mkObj []
  for (name, exitCode) in #[("Fixed", (0 : UInt32)), ("Violation", 1), ("Fixed", 0)] do
    let source := here / "fixtures" / s!"{name}.lean"
    let _ ← invoke root "lake" #["env", "lean", "-o", (out / s!"{name}.olean").toString, source.toString] 0 env
    let client := out / "Client.lean"
    IO.FS.writeFile client s!"import Probe\nimport {name}\n#strict_probe {name} {(toJson source.toString).compress}\n"
    let raw ← invoke root "lake" #["env", "lean", "--json", client.toString] exitCode env
    let messages ← (raw.splitOn "\n").filterMapM fun line => do
      if line.trimAscii.isEmpty then return none
      return some (← IO.ofExcept (Json.parse line))
    if exitCode == 1 then
      let [diagnostic] := messages | throw <| IO.userError "expected exactly one violation message"
      requireChecks [
        ⟨"native error", (← text diagnostic "severity") == "error"⟩,
        ⟨"native identity", (← text diagnostic "kind") == "StrictLean.SL1001._namedError"⟩,
        ⟨"native start", (← field diagnostic "pos") == Json.mkObj [("line", toJson (2 : Nat)), ("column", toJson (6 : Nat))]⟩,
        ⟨"native end", (← field diagnostic "endPos") == Json.mkObj [("line", toJson (2 : Nat)), ("column", toJson (17 : Nat))]⟩,
        ⟨"native source", (← text diagnostic "fileName") == source.toString⟩,
        ⟨"native title", (← text diagnostic "data").contains title⟩,
        ⟨"native route", (← text diagnostic "data").endsWith ("/strict-lean/dev/" ++ helpRoute)⟩]
    else requireChecks [⟨"fixed has no diagnostics", messages.isEmpty⟩]
    results := results.setObjVal! name (Json.mkObj [("source", .str (← IO.FS.readFile source)), ("messages", toJson messages)])
  -- Isolated adopter is disposable, including on exceptional return.
  let initialResults := results
  results := ← withScratch root "prototype-adopter" fun adopter => do
    let mut adopterResults := initialResults
    prepareProject root adopter "rule_probe_adopter" "standard-logical" "Isolated prototype control."
    IO.FS.removeFile (adopter / "lakefile.lean")
    IO.FS.writeFile (adopter / "lakefile.toml") s!"name = \"rule_probe_adopter\"\nlintDriver = \"strict_lean/axiomGate\"\nlintDriverArgs = [\"--build-lint\"]\n[[require]]\nname = \"strict_lean\"\npath = {(toJson root.toString).compress}\n[[lean_lib]]\nname = \"Example\"\n"
    -- This prototype checks logical policy, not the producer suite's checked execution mode.
    let manifest ← readJson (adopter / "foundation_manifest.json")
    let surfaces ← IO.ofExcept (manifest.getObjValAs? (Array Json) "surfaces")
    let some surface := surfaces[0]? | throw <| IO.userError "missing adopter surface"
    writeJson (adopter / "foundation_manifest.json") (manifest.setObjVal! "surfaces"
      (toJson #[surface.setObjVal! "execution" (.str "report")]))
    for (name, exitCode) in #[("Fixed", (0 : UInt32)), ("Violation", 1), ("Fixed", 0)] do
      clearBuild adopter
      let prior ← field adopterResults name
      IO.FS.writeFile (adopter / "Example.lean") (← text prior "source")
      let output ← invoke adopter "lake" #["lint"] exitCode cleanEnv
      requireChecks [⟨"public checker intended result", if exitCode == 1 then
        output.contains "[project-axiom]" && output.contains "unsupported" else output.contains "PASS"⟩]
      adopterResults := adopterResults.setObjVal! name (prior.setObjVal! "publicChecker" (.str output))
    return adopterResults
  let violation ← field results "Violation"
  let fixed ← field results "Fixed"
  let messages ← IO.ofExcept (violation.getObjValAs? (Array Json) "messages")
  let some message := messages[0]? | throw <| IO.userError "missing violation diagnostic"
  let diagnostic ← text message "data"
  IO.FS.writeFile (here / "site/Docs.lean") (← page metadata (← text violation "source") diagnostic (← text fixed "source"))
  let _ ← invoke (here / "site") "lake" #["build", "site"] 0 cleanEnv
  let _ ← invoke (here / "site") "lake" #["exe", "site"] 0 cleanEnv
  let siteRoot := out / "public"
  if ← siteRoot.pathExists then IO.FS.removeDirAll siteRoot
  let route := siteRoot / "strict-lean/dev" / helpRoute
  copyTree (here / "site/_out/html-single") route
  let rendered ← IO.FS.readFile (route / "index.html")
  requireChecks [⟨"rendered rule and checked sources", rendered.contains "SL1001" && rendered.contains "unsupported" && rendered.contains "conditional"⟩]
  -- The landing link is static markup; no project-owned browser implementation is needed.
  IO.FS.writeFile (siteRoot / "index.html") s!"<!doctype html><title>Diagnostic link probe</title><a href=\"/strict-lean/dev/{helpRoute}\">Explain SL1001</a>"
  let first ← snapshot route
  let _ ← invoke (here / "site") "lake" #["exe", "site"] 0 cleanEnv
  let second ← snapshot (here / "site/_out/html-single")
  requireChecks [⟨"identical static bytes at identical inputs", first == second⟩]
  let emitted ← messages.mapM fun message => do
    return (← text message "kind").replace "StrictLean." "" |>.replace "._namedError" ""
  let fixedMessages ← IO.ofExcept (fixed.getObjValAs? (Array Json) "messages")
  let artifact := StrictLeanQualification.Website.checkedArtifact.run {
    id := (← text metadata "id"), route := helpRoute, emitted := emitted.toList,
    routeExists := (← route.isDir), violationExists := !messages.isEmpty,
    fixedEmpty := fixedMessages.isEmpty }
  writeJson (out / "site-artifact.json") artifact
  let _ ← invoke root "lake" #["exe", "axiomGate", "--validate-site", (out / "registry.json").toString, (out / "site-artifact.json").toString] 0 env
  writeJson (out / "evidence.json") (Json.mkObj [("rule", metadata), ("results", results),
    ("reproducibleFiles", toJson first.length), ("elapsedMilliseconds", toJson ((← IO.monoMsNow) - start)),
    ("editorInteraction", .str "NOT RUN; required in ADOPTION-01")])
  IO.println "Prototype PASS: actual policy, native diagnostic, Lake dependency driver, fixture correction, Verso output."
  IO.println "Static pages generated; editor interaction remains unverified."

def main (args : List String) : IO UInt32 := do
  match args with
  | ["--under-deadline"] => runPrototype; return 0
  | [] => runBounded (← rootDirectory) 600 "lake" #["env", "lean", "--run", "examples/rule-reference-prototype/Run.lean", "--under-deadline"]
  | _ => throw <| IO.userError "prototype takes no public arguments"
