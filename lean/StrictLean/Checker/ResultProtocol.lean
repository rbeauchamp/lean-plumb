import StrictLeanPolicy.Acceptance
import StrictLean.Website
import StrictLean.Checker.Producer
import StrictLean.Checker.RuleDiagnostics

/-! Versioned observation output and accepted-report rendering. JSON is display/transport
of scoped evidence, never a deserializable proof or whole-standard conformance certificate.
The accepted constructor requires the executed con-leche-inspired indexed finalization. -/
namespace StrictLean.Checker.ResultProtocol
open Lean

abbrev producer := StrictLean.Checker.Producer.identity

inductive Status where
  | completed | rejected | incomplete | classified

def statusText : Status → String
  | .completed => "completed" | .rejected => "rejected"
  | .incomplete => "incomplete" | .classified => "classified"

/-- Completed is scoped observation, never a synonym for whole-standard conformance. -/
def resultJson (scope : Json) (mode : EvidenceMode) (status : Status)
    (findings : Array Finding) (unresolved : Array String) : Json :=
  Json.mkObj (RegistryCodec.identityFields producer ++ [
    ("scope", scope), ("mode", .str (RegistryCodec.modeText mode)),
    ("status", .str (statusText status)),
    ("diagnostics", toJson (findings.map RegistryCodec.diagnosticJson)),
    ("unresolved", toJson unresolved)])

def requestJson (kind project subject : String) (claim execution : Option String)
    (configuration : Array (System.FilePath × Option String)) : Json :=
  toJson (⟨kind, project, subject, claim, execution,
    configuration.map fun (path, source) => (path.toString, source)⟩ : Website.ExampleRequest)

def write (path : System.FilePath) (scope : Json) (mode : EvidenceMode) (status : Status)
    (findings : Array Finding) (unresolved : Array String := #[]) : IO Unit := do
  if let some parent := path.parent then IO.FS.createDirAll parent
  let spanStart ← IO.monoMsNow
  let encoded := Json.compress (resultJson scope mode status findings unresolved) ++ "\n"
  IO.println s!"diagnostic span: ResultProtocol.write encode: {(← IO.monoMsNow) - spanStart}ms"
  let writeStart ← IO.monoMsNow
  IO.FS.writeFile path encoded
  IO.println s!"diagnostic span: ResultProtocol.write write: {(← IO.monoMsNow) - writeStart}ms"

private def sourceJson (source : StrictLeanPolicy.SourceSnapshot) : Json :=
  Json.mkObj [("uri", toJson source.uri), ("source", toJson source.source)]

private def declarationKeyJson (key : StrictLeanPolicy.DeclarationKey) : Json :=
  Json.mkObj [("module", RegistryCodec.nameJson key.moduleKey.name.name),
    ("name", RegistryCodec.nameJson key.name.name)]

private def localSubjectJson : StrictLeanPolicy.LocalJobSubject → Json
  | .scope => Json.mkObj [("kind", .str "scope")]
  | .module key => Json.mkObj [("kind", .str "module"), ("module", RegistryCodec.nameJson key.name.name)]
  | .declaration key => Json.mkObj [("kind", .str "declaration"), ("declaration", declarationKeyJson key)]
  | .root key => Json.mkObj [("kind", .str "root"), ("root", declarationKeyJson key)]
  | .boundary key => Json.mkObj [("kind", .str "boundary"), ("root", declarationKeyJson key.root),
      ("reached", declarationKeyJson key.reached), ("boundary", .str key.kind.spelling),
      ("occurrence", toJson key.occurrence), ("replacement", key.replacement.map declarationKeyJson |>.getD .null)]

private def subjectJson : StrictLeanPolicy.JobSubject → Json
  | .scope => Json.mkObj [("kind", .str "scope")]
  | .environment key subject => Json.mkObj [("kind", .str "environment"),
      ("environment", toJson key.index), ("subject", localSubjectJson subject)]
  | .fence key => Json.mkObj [("kind", .str "fence"), ("document", toJson key.document.uri),
      ("opening", toJson (key.opening.start, key.opening.stop)),
      ("body", toJson (key.body.start, key.body.stop)), ("closing", toJson (key.closing.start, key.closing.stop)),
      ("expectation", toJson (reprStr key.expectation))]

/-- Renderer accepts only a proof-bearing run and projects its exact report. The common
snapshot is stored once; each subject inherits it. These rendered fields are observations,
not serialized authority, and consumers must never deserialize them into Accepted. -/
def acceptedJson {claim : StrictLeanPolicy.Claim} (accepted : StrictLeanPolicy.AcceptedRun claim) : Json :=
  let report := accepted.report
  let snapshot := report.claim.val.snapshot
  Json.mkObj [
    ("mode", toJson report.claim.val.mode.spelling),
    ("scope", toJson (reprStr report.claim.val.scope)),
    ("surfaces", toJson (report.claim.val.surfaces.map fun surface => Json.mkObj [
      ("target", toJson surface.target), ("modules", toJson (surface.modules.map fun n => RegistryCodec.nameJson n.name)),
      ("profile", toJson surface.profile.spelling), ("execution", toJson surface.execution.spelling)])),
    ("snapshot", Json.mkObj [("sources", toJson (snapshot.sources.map sourceJson)),
      ("configuration", sourceJson snapshot.configuration), ("toolchain", toJson (reprStr snapshot.toolchain)),
      ("dependencies", toJson (snapshot.dependencies.map fun dependency => Json.mkObj [
        ("package", toJson dependency.package), ("revision", toJson dependency.nominalRevision),
        ("dirty", toJson dependency.dirty), ("files", toJson (dependency.files.map sourceJson))]))]),
    ("modules", toJson (report.census.modules.map fun key => RegistryCodec.nameJson key.name.name)),
    ("environments", toJson (report.census.environments.map fun environment => Json.mkObj [
      ("index", toJson environment.request.key.index),
      ("modules", toJson (environment.request.modules.map fun key => RegistryCodec.nameJson key.name.name)),
      ("importedModules", toJson (environment.importedModules.map fun key => RegistryCodec.nameJson key.name.name)),
      ("infrastructureModules", toJson (environment.infrastructureModules.map fun key => RegistryCodec.nameJson key.name.name)),
      ("admissionModules", toJson (environment.admissionModules.map fun key => RegistryCodec.nameJson key.name.name)),
      ("admissionDeclarations", toJson (environment.admissionDeclarations.map declarationKeyJson)),
      ("declarations", toJson (environment.declarations.map declarationKeyJson)),
      ("roots", toJson (environment.roots.map declarationKeyJson)),
      ("fileSource", environment.fileSource.map (fun binding => Json.mkObj [
        ("requested", sourceJson binding.requested), ("compiled", sourceJson binding.compiled)]) |>.getD .null)])),
    ("graphRoots", toJson (report.census.graphRoots.map fun key => RegistryCodec.nameJson key.name.name)),
    ("graphCoverage", toJson (report.census.graphCoverage.map fun (key, modules) => Json.mkObj [
      ("root", RegistryCodec.nameJson key.name.name), ("modules", toJson (modules.map fun (moduleKey : StrictLeanPolicy.ModuleKey) => RegistryCodec.nameJson moduleKey.name.name))])),
    ("jobs", toJson (report.jobs.mapIdx fun slot key => Json.mkObj [
      ("slot", toJson slot), ("stage", toJson (reprStr key.stage)), ("subject", subjectJson key.subject)]))]

/-- The wrapper's composed-publication decision: a composed success is
publishable only for a fully successful guarded action. Executed literally by
the run wrapper. -/
def composeDecision (code : UInt32) (composed : Option Json) : Option Json :=
  if code = 0 then composed else none

/-- Execution-linked state invariant: a failed guarded action cannot publish
composed success. -/
theorem failure_drops_composed (code : UInt32) (composed : Option Json)
    (h : ¬ code = 0) : composeDecision code composed = none := by
  simp [composeDecision, h]

/-- Public audit completion cannot be constructed from diagnostic counts or
worker exits. The composed accepted result value (pure): the historical
`writeAccepted` payload construction. -/
def acceptedValue {claim : StrictLeanPolicy.Claim}
    (accepted : StrictLeanPolicy.AcceptedRun claim) (scope : Json) : Json :=
  (resultJson scope accepted.report.claim.val.mode .completed #[] #[]).setObjVal!
    "acceptance" (acceptedJson accepted)

def writeAccepted {claim : StrictLeanPolicy.Claim} (path : System.FilePath)
    (accepted : StrictLeanPolicy.AcceptedRun claim) (scope : Json) : IO Unit := do
  let spanStart ← IO.monoMsNow
  let value := acceptedValue accepted scope
  if let some parent := path.parent then IO.FS.createDirAll parent
  let encoded := Json.compress value ++ "\n"
  IO.println s!"diagnostic span: writeAccepted encode: {(← IO.monoMsNow) - spanStart}ms"
  let writeStart ← IO.monoMsNow
  IO.FS.writeFile path encoded
  IO.println s!"diagnostic span: writeAccepted write: {(← IO.monoMsNow) - writeStart}ms"

/-- The historical parse/compress normalization hop, retained verbatim:
roundtrip identity over arbitrary `Json`/`JsonNumber` is not assumed. The
re-parse consumes exactly the bytes `writeJson` historically produced
(`Json.compress` output plus the trailing newline) with the same
`PolicyCodec.parse`. -/
def normalize (value : Json) : Json :=
  match StrictLean.Checker.PolicyCodec.parse (Json.compress value ++ "\n") with
  | .ok parsed => parsed
  | .error _ => value

/-- Pure composition of the layered finalization in its executed order:
`sourceAccount` retention, then the run wrapper's conditional account
completion and `request`/`effective` additions, with both historical
normalization hops retained in memory. -/
def composedFinal (base account recovery request effective : Json) : Json :=
  let retained := (normalize base).setObjVal! "sourceAccount" account
  let readBack := normalize retained
  let completed := if (readBack.getObjVal? "sourceAccount").isOk then readBack
    else readBack.setObjVal! "sourceAccount" recovery
  (completed.setObjVal! "request" request).setObjVal! "effective" effective

/-- Definitional correspondence: `composedFinal` is exactly the historical
layered chain in executed order — normalize the accepted value (the re-read of
write 1), retain `sourceAccount` (write 2's transformation), normalize again
(the re-read of write 2), the wrapper's conditional account completion and
`request`/`effective` additions (write 3's transformation) — with both
intervening parse/compress normalization hops retained. -/
theorem composedFinal_eq (base account recovery request effective : Json) :
    composedFinal base account recovery request effective =
      let retained := (normalize base).setObjVal! "sourceAccount" account
      let readBack := normalize retained
      let completed := if (readBack.getObjVal? "sourceAccount").isOk then readBack
        else readBack.setObjVal! "sourceAccount" recovery
      (completed.setObjVal! "request" request).setObjVal! "effective" effective := rfl

/-- Structural names are rendered only at this legacy display boundary. -/
private def legacyName (value : Json) : Json :=
  match StrictLean.RegistryCodec.parseName value with
  | .ok n => .str n.toString
  | .error _ => value

private def remapDisplayPath (value : Json) (sourceRoot targetRoot : String) : Json :=
  match value with
  | .str path =>
    if sourceRoot.isEmpty || sourceRoot == targetRoot then value
    else if path == sourceRoot then .str targetRoot
    else if path.startsWith (sourceRoot ++ "/") then
      .str (targetRoot ++ (path.drop sourceRoot.length).toString)
    else value
  | _ => value

/-- Preserve the legacy record shape and remap only identified display-path fields.
Proof text, types, diagnostic prose, and arbitrary strings are never rewritten. -/
partial def legacyJson (value : Json) (sourceRoot targetRoot : String := "") : Json :=
  match value with
  | .arr values => .arr (values.map fun v => legacyJson v sourceRoot targetRoot)
  | .obj fields => Json.mkObj <| fields.toList.filterMap fun (k, v) =>
      if ["structuralName", "occurrence", "nativeOrigin", "sourceContent",
          "census", "admission", "documentation", "histories", "closure", "sourceBindings"].contains k then none
      else
        let value := if ["name", "module", "root", "replacement", "implementedBy", "unsafeRecBase",
            "elaborator", "kind", "commandElaborator", "commandKind"].contains k then legacyName v
          else if ["modules", "axioms", "valueConstants", "all", "levelParams", "nativeUseParents",
            "unsafeRecEquationAxioms", "compilerCallers", "added", "imports"].contains k then
              match v with
              | .arr values => .arr (values.map legacyName)
              | _ => v
          else if ["compilerEdges", "runtimeReplacements"].contains k then
              match v with
              | .arr values => .arr (values.map fun edge => match edge with
                  | .arr names => .arr (names.map legacyName)
                  | _ => edge)
              | _ => v
          else v
        let value := legacyJson value sourceRoot targetRoot
        some (k, if ["source", "olean", "sourcePath", "oleanPath", "ileanPath"].contains k then
          remapDisplayPath value sourceRoot targetRoot else value)
  | value => value
end StrictLean.Checker.ResultProtocol
