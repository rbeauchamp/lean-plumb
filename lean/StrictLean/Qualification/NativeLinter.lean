import StrictLean.Qualification.Launcher
import StrictLeanQualification.Native

/-! Operational controls for native collector/logger/metadata linkage. Intentionally
invalid source is only written to disposable paths. The pure diagnostic oracle lives
in `StrictLeanQualification.Native`; actual compiler behavior is observed, not proved. -/

namespace StrictLean.Qualification.NativeLinter
open Lean System

private def base := "import StrictLean.Linter\n/-! Collector qualification control. -/\n/-- A registered material claim. -/\n@[strict_lean_material] theorem documented : True := .intro\nprivate def privateValue : Nat := 1\ninductive Branch where\n  | node : List Branch → Branch\n"

/-- One native control's invocation options and expected diagnostic contract. -/
structure Control where
  label : String
  source : String
  ids : List String := []
  errors : Bool := false
  options : Array String := #[]
  output : Bool := false
  compiler : List StrictLeanQualification.Native.CompilerMessage := []
  detail : Option String := none
  nativeSeverity : Option String := none

/-- Decode required message fields without silently defaulting malformed values. A
missing `kind` denotes a compiler diagnostic, as in Lean's native JSON protocol. -/
def decode (value : Json) : Except String StrictLeanQualification.Native.Message := do
  let kind ← match value.getObjVal? "kind" with
    | .ok field => field.getStr?
    | .error _ => pure ""
  return {
    kind, severity := (← value.getObjValAs? String "severity"),
    data := (← value.getObjValAs? String "data"), fileName := (← value.getObjValAs? String "fileName") }

private def check (root scratch : FilePath) (launcher : Launcher.State) (control : Control)
    (env : Array (String × Option String) := #[]) : IO (List Json) := do
  let path := scratch / s!"{control.label}.lean"
  IO.FS.writeFile path control.source
  let args := #["--json", "--root", scratch.toString] ++ control.options ++
    (if control.output then #["-o", (path.withExtension "olean").toString] else #[]) ++ #[path.toString]
  let result ← Launcher.runLean root launcher args env
  let messages ← (result.stdout.splitOn "\n").filterMapM fun line => do
    if line.trimAscii.isEmpty then return none
    return some (← IO.ofExcept (Json.parse line))
  let decoded ← IO.ofExcept (messages.mapM decode)
  let expected : StrictLeanQualification.Native.Expected := {
    kinds := control.ids.map (fun id => s!"StrictLean.{id}._namedError"),
    fileName := path.toString, errors := control.errors, compiler := control.compiler,
    detail := control.detail, severity := control.nativeSeverity.getD
      (if control.options.contains "-DwarningAsError=true" then "error" else "warning") }
  match StrictLeanQualification.Native.checkedValidation.run expected result.exitCode.toNat result.stderr decoded with
  | .ok () => pure ()
  | .error detail => throw <| IO.userError s!"{control.label}: {detail}\n{result.stdout}{result.stderr}"
  return messages

private def position (messages : List Json) (id : String) : IO Json := do
  let some message := messages.find? (fun message =>
    (message.getObjValAs? String "kind").toOption == some s!"StrictLean.{id}._namedError")
    | throw <| IO.userError s!"missing {id} diagnostic"
  IO.ofExcept (message.getObjVal? "pos")

/-- Preserve all native source controls, including imported-artifact and restored
controls. Search-path augmentation is child-local rather than a global mutation. -/
def checkAt (root scratch : FilePath) (launcher : Launcher.State) : IO Unit := do
    let check := check root scratch launcher
    let _ ← check { label := "Control", source := base, output := true }
    let axiomSource := base ++ "\naxiom forbidden : False\n"
    let messages ← check { label := "Axiom", source := axiomSource, ids := ["SL1001"] }
    requireChecks [⟨"axiom diagnostic selection position", (← position messages "SL1001") ==
      Json.mkObj [("line", toJson (9 : Nat)), ("column", toJson (6 : Nat))]⟩]
    let _ ← check {
      label := "PromotedAxiom", source := axiomSource, ids := ["SL1001"],
      errors := true, options := #["-DwarningAsError=true"] }
    let missing := base.replace "/-! Collector qualification control. -/\n" "" |>.replace
      "/-- A registered material claim. -/\n" ""
    let messages ← check { label := "Missing", source := missing, ids := ["SL5001", "SL5002"], output := true }
    requireChecks [⟨"missing module documentation position", (← position messages "SL5001") ==
      Json.mkObj [("line", toJson (missing.splitOn "\n").length), ("column", toJson (0 : Nat))]⟩]
    let controls : List Control := [
      { label := "PromotedMissing", source := missing, ids := ["SL5001", "SL5002"], errors := true,
        options := #["-DwarningAsError=true"] },
      { label := "Disabled", source := base.replace "/-!" "set_option linter.strictLean false\n/-!" ++
        "axiom forbidden : False\n" },
      { label := "Narrow", source := base ++ "set_option strictLean.localFoundation \"kernel-only\"\n" ++
        "theorem classicalClaim (p : Prop) : p ∨ ¬p := Classical.em p\n", ids := ["SL1005"] },
      { label := "EmptyBadRequest", source := "import StrictLean.Linter\n/-! Configuration control. -/\n" ++
        "set_option strictLean.localFoundation \"unsupported\"\n", ids := ["SL2002"] },
      { label := "TrailingBadRequest", source := base ++ "set_option strictLean.localFoundation \"unsupported\"\n", ids := ["SL2002"] },
      { label := "InitialBadRequest", source := "import StrictLean.Linter\n", ids := ["SL2002"],
        options := #["-DstrictLean.localFoundation=unsupported"] },
      { label := "ScopedBadRequest", source := base ++ "set_option strictLean.localFoundation \"unsupported\" in\n" ++
        "def selected : Nat := 1\n", ids := ["SL2002"] },
      { label := "ScopedNarrow", source := base ++ "set_option strictLean.localFoundation \"kernel-only\" in\n" ++
        "theorem classicalClaim (p : Prop) : p ∨ ¬p := Classical.em p\n", ids := ["SL1005"] },
      { label := "ScopedDisabled", source := base ++ "set_option linter.strictLean false in\naxiom forbidden : False\n" },
      { label := "ScopedPromoted", source := base ++ "set_option warningAsError true in\naxiom forbidden : False\n",
        ids := ["SL1001"], errors := true, nativeSeverity := some "error" },
      { label := "Hole", source := base ++ "theorem unfinished : True := by sorry\n", ids := ["SL1002"],
        compiler := [⟨"warning", "declaration uses `sorry`"⟩] },
      { label := "RecoveredError", source := base ++ "theorem broken : True := by exact missingProof\n",
        ids := ["SL1002"], errors := true, compiler := [⟨"error", "Unknown identifier `missingProof`"⟩] },
      { label := "Synchronous", source := axiomSource, ids := ["SL1001"], options := #["-DElab.async=false"] },
      { label := "UnknownAxiom", source := base ++ "private axiom assumed : False\ntheorem dependent : False := assumed\n",
        ids := ["SL1001", "SL1003"] },
      { label := "CompilerTrust", source := base ++ "theorem trustedCompiler : True := Lean.trustCompiler\n", ids := ["SL1004"],
        compiler := [⟨"warning", "`Lean.trustCompiler` has been deprecated: in-kernel native reduction is deprecated; assert native evaluations with axioms instead"⟩] },
      { label := "Escape", source := base ++ "unsafe def escape : Nat := 0\n", ids := ["SL1006"] },
      { label := "Contract", source := base ++ "def implementation (n : Nat) : Nat := n\n" ++
        "theorem unsupported (n : Nat) : StrictLean.ExecutableContract (implementation n) (fun value => value = n) := ⟨rfl⟩\n",
        ids := ["SL1007"] },
      { label := "Pending", source := base ++ "theorem nativeTruth : (2 + 2 : Nat) = 4 := by native_decide\n",
        ids := ["SL2005"], detail := some "fresh generated-role evidence remains required" }]
    let config ← check {
      label := "BadRequest", source := base ++
      "set_option strictLean.localFoundation \"unsupported\"\ndef selected : Nat := 1\n", ids := ["SL2002", "SL2002"] }
    let lines ← IO.ofExcept (config.mapM fun value => do
      (← value.getObjVal? "pos").getObjValAs? Nat "line")
    requireChecks [⟨"configuration diagnostic ordering/positions", lines == [8, 9]⟩]
    for control in controls do let _ ← check control
    let malformed := base ++ "open Lean Elab Command in\nelab \"bad_range \" name:ident : command => do\n  elabCommand (← `(axiom $name:ident : False))\n  let some ranges ← findDeclarationRangesCore? name.getId | throwError \"missing control range\"\n  let invalid := { ranges.range with pos := ⟨9999, 0⟩, endPos := ⟨9999, 1⟩ }\n  addDeclarationRanges name.getId { range := invalid, selectionRange := invalid }\nbad_range corrupted\n"
    let restored := malformed.replace "{ ranges.range with pos := ⟨9999, 0⟩, endPos := ⟨9999, 1⟩ }" "ranges.range"
    let _ ← check { label := "ValidRange", source := restored, ids := ["SL1001"] }
    let _ ← check {
      label := "InvalidRange", source := malformed, ids := ["SL2005"],
      detail := some "reported source coordinates disagree with the snapshot" }
    let _ ← check { label := "RestoredRange", source := restored, ids := ["SL1001"] }
    let verso := base.replace "/-!" "set_option doc.verso true\nset_option doc.verso.module true\n/-!"
    let _ ← check { label := "Verso", source := verso, output := true }
    let _ ← check { label := "Inherited", source := base ++ "/-- Reused documentation. -/\ndef parent : Nat := 1\n@[inherit_doc parent, strict_lean_material] def child : Nat := 1\n@[strict_lean_material] private def privateMaterial : Nat := 1\n" }
    let moduleStyle := base.replace "import StrictLean.Linter" "module\nimport StrictLean.Linter" |>.replace
      "@[strict_lean_material] theorem" "@[strict_lean_material] public theorem"
    let _ ← check { label := "ModuleSystem", source := moduleStyle ++ "@[strict_lean_material] theorem privateMaterial : True := .intro\n" }
    let _ ← check { label := "ModuleAxiom", source := moduleStyle ++ "public axiom forbidden : False\n", ids := ["SL1001"] }
    let _ ← check {
      label := "ModuleMissing", source := (moduleStyle.replace "/-! Collector qualification control. -/\n" "").replace
        "/-- A registered material claim. -/\n" "", ids := ["SL5001", "SL5002"] }
    let inspect := base ++ "run_cmd Lean.Elab.Command.liftCoreM <| Lean.addDecl (.axiomDecl {\n  name := `hiddenAxiom, levelParams := [], type := Lean.mkSort .zero, isUnsafe := false })\nrun_cmd do\n  let env ← Lean.getEnv\n  let ds ← StrictLean.Collect.currentModule\n  unless ds.any (fun d => d.name == `hiddenAxiom && d.kind == .«axiom») do\n    throwError \"binder-less declaration missing\"\n  unless ds.any (fun d => d.private) do throwError \"private declaration missing\"\n  unless ds.any (fun d => d.name == `Branch.rec) do throwError \"generated declaration missing\"\n  unless ds.all (fun d => d.module == env.mainModule) do throwError \"wrong local ownership\"\n  let a ← StrictLean.Collect.declaration `documented .snapshot\n  let b ← StrictLean.Collect.declaration `documented .replayCandidate\n  unless a == b do throwError \"stage changed ordinary canonical record\"\n  unless (StrictLean.Collect.moduleOf env `unknownDeclaration).toOption.isNone do\n    throwError \"invented unknown ownership\"\n  if env.header.modules.any (fun m => m.module.getRoot == `Mathlib) then\n    throwError \"public import required Mathlib\"\n"
    let _ ← check { label := "Collect", source := inspect }
    let observer := "import Control\n/-! Imported observation control. -/\nrun_cmd do\n  let env ← Lean.getEnv\n  for moduleName in #[`Control] do\n    unless (StrictLean.Linter.Documentation.modulePresent env moduleName).toOption == some true do\n      throwError \"imported module documentation absent\"\n  unless StrictLean.Linter.Documentation.selected env `documented do\n    throwError \"imported registration missing\"\n  unless (← StrictLean.Linter.Documentation.declarationPresent env `documented) == true do\n    throwError \"imported declaration documentation mismatch\"\n  let d ← StrictLean.Collect.declaration `documented .snapshot\n  unless d.module == `Control do throwError \"wrong imported ownership\"\n  unless (StrictLean.Linter.Documentation.modulePresent env `Unknown).toOption.isNone do\n    throwError \"unknown module treated as absent\"\n"
    let search := SearchPath.parse (← Launcher.leanPath root launcher)
    let env := #[("LEAN_PATH", some (SearchPath.toString (search ++ [scratch])))]
    let _ ← NativeLinter.check root scratch launcher { label := "Imported", source := observer } env
    let _ ← NativeLinter.check root scratch launcher { label := "ImportedVerso", source := observer.replace "Control" "Verso" } env
    let _ ← NativeLinter.check root scratch launcher {
      label := "ImportedMissing", source := ((observer.replace "Control" "Missing").replace
        "== true" "== false").replace "some true" "some false" } env
    let _ ← check { label := "Restored", source := base }
    IO.println s!"native bridge qualification: PASS ({controls.length + 18} actual Lean source controls)"

/-- Normal acceptance uses the cached actual Lake environment, never a cached verdict. -/
def checkAll : IO Unit := do
  let root ← rootDirectory
  withScratch root "native-controls" fun scratch => do checkAt root scratch (← Launcher.create)

/-- Paired baseline-first diagnostic with the same scratch path, source, argv, observed
outputs, environment and executable. Measurements describe only these actual runs. -/
def paired : IO Unit := do
  let root ← rootDirectory
  let output := root / "tmp/native-launcher-diagnostic.json"
  IO.FS.createDirAll (root / "tmp")
  if ← output.pathExists then IO.FS.removeFile output
  let started ← IO.monoMsNow
  let report ← IO.mkRef (Json.mkObj [("outcome", .str "INCOMPLETE"), ("equivalent", .bool false)])
  try
    withScratch root "launcher-pair" fun scratch => do
      let controls := scratch / "controls"
      let mut observations := #[]
      let mut runs := #[]
      for legacy in #[true, false] do
        IO.FS.createDir controls
        let launcher ← Launcher.create legacy
        let start ← IO.monoMsNow
        try checkAt root controls launcher finally IO.FS.removeDirAll controls
        let elapsed := (← IO.monoMsNow) - start
        let records ← launcher.records.get
        observations := observations.push records
        -- Environment values intentionally never leave memory.
        let encoded := records.map fun r => Json.mkObj [
          ("label", toJson r.label), ("args", toJson r.args), ("source", toJson r.source),
          ("returncode", toJson r.exitCode), ("stdout", toJson r.stdout), ("stderr", toJson r.stderr)]
        runs := runs.push (Json.mkObj [("legacy", .bool legacy), ("millis", toJson elapsed),
          ("captureMillis", toJson (← launcher.captureMillis.get)), ("controlMillis", toJson (← launcher.timings.get)),
          ("controls", toJson encoded)])
        report.modify (·.setObjVal! "runs" (toJson runs))
      let some before := observations[0]? | throw <| IO.userError "missing baseline"
      let some after := observations[1]? | throw <| IO.userError "missing candidate"
      requireChecks [⟨"36 exact paired controls", StrictLeanQualification.Launcher.checkedEquivalence.run before after⟩]
      report.modify fun value => (value.setObjVal! "equivalent" (.bool true)).setObjVal! "outcome" (.str "PASS")
      IO.println "launcher diagnostic: PASS (36 exact paired controls; timing is an observation only)"
  catch e =>
    report.modify (·.setObjVal! "outcome" (.str "FAIL"))
    throw e
  finally
    writeJson output ((← report.get).setObjVal! "totalMillis" (toJson ((← IO.monoMsNow) - started)))

end StrictLean.Qualification.NativeLinter
