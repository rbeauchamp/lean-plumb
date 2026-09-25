import PlumbPolicy.Acceptance
import PlumbCore.Account
import Plumb.Website
import Plumb.Checker.Producer
import Plumb.Checker.RuleDiagnostics

/-! Versioned observation output and accepted-report rendering. JSON is display/transport
of scoped evidence, never a deserializable proof or whole-standard conformance certificate.
The accepted constructor requires the executed con-leche-inspired indexed finalization. -/
namespace Plumb.Checker.ResultProtocol
open Lean

abbrev producer := Plumb.Checker.Producer.identity

/-- Result schema 2 omits the frozen configuration and dependency text from the snapshot
(`snapshotJson`: a clean dependency is identified by its pinned revision, a dirty one only
by package and `dirty` status) and omits imported-environment module lists (`acceptedJson`,
`ProducerReport.Environment.resultJson`). Schema 1 embedded them. -/
def schemaVersion : Nat := 2

/-- Envelope identity of every result file. -/
def identityFields : List (String × Json) := RegistryCodec.identityFields producer schemaVersion

/-- `Account.Status`: `completed` carries an accepted account, so it cannot be written from
missing or incomplete evidence (`Account.Status.completed_accepted`). -/
abbrev Status := Plumb.Checker.Account.Status

def statusText (status : Status) : String := status.spelling

/-- Completed is scoped observation, never a synonym for whole-standard conformance. A
completed envelope takes its mode from the status's account, not from `mode`. -/
def resultJson (scope : Json) (mode : EvidenceMode) (status : Status)
    (findings : Array Finding) (unresolved : Array String) : Json :=
  let mode := match status with
    | .completed account => account.val.mode
    | _ => mode
  Json.mkObj (identityFields ++ [
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

private def sourceJson (source : PlumbPolicy.SourceSnapshot) : Json :=
  Json.mkObj [("uri", toJson source.uri), ("source", toJson source.source)]

private def declarationKeyJson (key : PlumbPolicy.DeclarationKey) : Json :=
  Json.mkObj [("module", RegistryCodec.nameJson key.moduleKey.name.name),
    ("name", RegistryCodec.nameJson key.name.name)]

private def localSubjectJson : PlumbPolicy.LocalJobSubject → Json
  | .scope => Json.mkObj [("kind", .str "scope")]
  | .module key => Json.mkObj [("kind", .str "module"), ("module", RegistryCodec.nameJson key.name.name)]
  | .declaration key => Json.mkObj [("kind", .str "declaration"), ("declaration", declarationKeyJson key)]
  | .root key => Json.mkObj [("kind", .str "root"), ("root", declarationKeyJson key)]
  | .boundary key => Json.mkObj [("kind", .str "boundary"), ("root", declarationKeyJson key.root),
      ("reached", declarationKeyJson key.reached), ("boundary", .str key.kind.spelling),
      ("occurrence", toJson key.occurrence), ("replacement", key.replacement.map declarationKeyJson |>.getD .null)]

private def subjectJson : PlumbPolicy.JobSubject → Json
  | .scope => Json.mkObj [("kind", .str "scope")]
  | .environment key subject => Json.mkObj [("kind", .str "environment"),
      ("environment", toJson key.index), ("subject", localSubjectJson subject)]
  | .fence key => Json.mkObj [("kind", .str "fence"), ("document", toJson key.document.uri),
      ("opening", toJson (key.opening.start, key.opening.stop)),
      ("body", toJson (key.body.start, key.body.stop)), ("closing", toJson (key.closing.start, key.closing.stop)),
      ("expectation", toJson (reprStr key.expectation))]

/-- Machine rendering of the report account (an unproved adapter): coverage, the acceptance
theorem and job count, contracts, execution counts, fence kinds, trusted mechanisms and
residual identifiers; mode, scope, surfaces and toolchain are rendered by `acceptedJson`.
Contract entries keep their rule, implementation and requirement with the review they leave
open; `unresolvedReview` names open obligations, never completed reviews. -/
def accountJson (account : Plumb.Checker.Account.Account) : Json :=
  let a := account.val
  let residuals (rs : List Plumb.Checker.Account.Residual) := toJson (rs.map (·.spelling))
  Json.mkObj [
    ("coverage", toJson a.coverage.spelling),
    ("checked", Json.mkObj [("theorem", RegistryCodec.nameJson Plumb.Checker.Account.acceptanceTheorem),
      ("jobs", toJson a.jobs)]),
    ("contracts", toJson (a.contracts.map fun contract => Json.mkObj [
      ("rule", toJson Plumb.RuleId.executableContract.spelling),
      ("registration", RegistryCodec.nameJson contract.registration),
      ("module", RegistryCodec.nameJson contract.module),
      ("implementation", RegistryCodec.nameJson contract.implementation),
      ("requirement", toJson contract.requirement),
      ("unresolvedReview", residuals Plumb.Checker.Account.ContractAccount.unresolved)])),
    ("execution", toJson (a.execution.mapIdx fun environment summary => Json.mkObj [
      ("environment", toJson environment), ("roots", toJson summary.roots),
      ("boundaries", toJson summary.boundaries), ("checked", toJson summary.checked),
      ("trusted", toJson summary.trusted), ("unresolved", toJson summary.unresolved)])),
    ("fences", Json.mkObj [("positive", toJson a.fences.positive),
      ("compilerRejection", toJson a.fences.compilerRejection),
      ("policyRejection", toJson a.fences.policyRejection),
      ("trustedTeaching", toJson a.fences.trustedTeaching)]),
    ("trusted", toJson (a.trusted.map fun boundary => Json.mkObj [
      ("boundary", toJson boundary.spelling), ("detail", toJson boundary.detail)])),
    ("unresolvedReview", residuals a.unresolved)]

/-- Result rendering of a frozen snapshot: the audited sources in full, the configuration
by URI, and each dependency by package, nominal revision and input-scoped `dirty` status.
`configuration.source` serializes the project configuration and every Lake dependency's
captured source and configuration text, which for any Mathlib-dependent project is all of
Mathlib. Acceptance compares those exact bytes in memory (`PlumbPolicy.Snapshot`) and
rechecks them before success; they are not rendered here. The project configuration is
rendered in full as `scope.configuration` only by axiomGate and ruleExamples results; the
freshChecker serialized-graph output has no `scope`, so it carries no configuration text,
and no consumer reads it there. A clean dependency is identified by its pinned revision. A
dirty dependency, including any path dependency without its own Git revision, is rendered
only as package, revision and `dirty: true`: it carries no content identity, and its frozen
text is not recorded. -/
def snapshotJson (snapshot : PlumbPolicy.Snapshot) : Json :=
  Json.mkObj [("sources", toJson (snapshot.sources.map sourceJson)),
    ("configuration", Json.mkObj [("uri", toJson snapshot.configuration.uri)]),
    ("toolchain", toJson (reprStr snapshot.toolchain)),
    ("dependencies", toJson (snapshot.dependencies.map fun dependency => Json.mkObj [
      ("package", toJson dependency.package), ("revision", toJson dependency.nominalRevision),
      ("dirty", toJson dependency.dirty)]))]

/-- The rendering is independent of the serialized configuration and dependency text, so
its size is independent of the dependencies' content (kernel-checked by `rfl`). -/
theorem snapshotJson_configuration_independent (snapshot : PlumbPolicy.Snapshot)
    (source : String) :
    snapshotJson { snapshot with configuration := { snapshot.configuration with source } } =
      snapshotJson snapshot := rfl

/-- One environment's assigned, infrastructure, admission, declaration and root inventory
and its file binding. Merely imported modules (`importedModules`, `origins`,
`importedSources`: the whole import closure) are decided in memory and not rendered. -/
def environmentJson (environment : PlumbPolicy.EnvironmentCensus) : Json :=
  Json.mkObj [
    ("index", toJson environment.request.key.index),
    ("modules", toJson (environment.request.modules.map fun key => RegistryCodec.nameJson key.name.name)),
    ("infrastructureModules", toJson (environment.infrastructureModules.map fun key => RegistryCodec.nameJson key.name.name)),
    ("admissionModules", toJson (environment.admissionModules.map fun key => RegistryCodec.nameJson key.name.name)),
    ("admissionDeclarations", toJson (environment.admissionDeclarations.map declarationKeyJson)),
    ("declarations", toJson (environment.declarations.map declarationKeyJson)),
    ("roots", toJson (environment.roots.map declarationKeyJson)),
    ("fileSource", environment.fileSource.map (fun binding => Json.mkObj [
      ("requested", sourceJson binding.requested), ("compiled", sourceJson binding.compiled)]) |>.getD .null)]

/-- The rendering is independent of the import closure (kernel-checked by `rfl`). -/
theorem environmentJson_imports_independent (environment : PlumbPolicy.EnvironmentCensus)
    (importedModules : Array PlumbPolicy.ModuleKey) (origins : Array PlumbPolicy.ModuleOrigin)
    (importedSources : Array (PlumbPolicy.ModuleKey × PlumbPolicy.SourceSnapshot)) :
    environmentJson { environment with importedModules, origins, importedSources } =
      environmentJson environment := rfl

/-- Renderer accepts only a proof-bearing run and projects its exact report. The common
snapshot is rendered once, by `snapshotJson`; each subject inherits it. Each environment
lists its assigned, admission, declaration, root and infrastructure inventory, not the
modules it merely imports. These rendered fields are observations, not serialized
authority, and consumers must never deserialize them into Accepted. -/
def acceptedJson {claim : PlumbPolicy.Claim} (accepted : PlumbPolicy.AcceptedRun claim) : Json :=
  let report := accepted.report
  let snapshot := report.claim.val.snapshot
  Json.mkObj [
    ("mode", toJson report.claim.val.mode.spelling),
    ("scope", toJson (reprStr report.claim.val.scope)),
    ("surfaces", toJson (report.claim.val.surfaces.map fun surface => Json.mkObj [
      ("target", toJson surface.target), ("modules", toJson (surface.modules.map fun n => RegistryCodec.nameJson n.name)),
      ("profile", toJson surface.profile.spelling), ("execution", toJson surface.execution.spelling)])),
    ("snapshot", snapshotJson snapshot),
    ("modules", toJson (report.census.modules.map fun key => RegistryCodec.nameJson key.name.name)),
    ("environments", toJson (report.census.environments.map environmentJson)),
    ("graphRoots", toJson (report.census.graphRoots.map fun key => RegistryCodec.nameJson key.name.name)),
    ("graphCoverage", toJson (report.census.graphCoverage.map fun (key, modules) => Json.mkObj [
      ("root", RegistryCodec.nameJson key.name.name), ("modules", toJson (modules.map fun (moduleKey : PlumbPolicy.ModuleKey) => RegistryCodec.nameJson moduleKey.name.name))])),
    ("jobs", toJson (report.jobs.mapIdx fun slot key => Json.mkObj [
      ("slot", toJson slot), ("stage", toJson (reprStr key.stage)), ("subject", subjectJson key.subject)])),
    ("account", accountJson (Plumb.Checker.Account.account accepted))]

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
def acceptedValue {claim : PlumbPolicy.Claim}
    (accepted : PlumbPolicy.AcceptedRun claim) (scope : Json) : Json :=
  (resultJson scope accepted.report.claim.val.mode
    (.completed (Plumb.Checker.Account.account accepted)) #[] #[]).setObjVal!
    "acceptance" (acceptedJson accepted)

def writeAccepted {claim : PlumbPolicy.Claim} (path : System.FilePath)
    (accepted : PlumbPolicy.AcceptedRun claim) (scope : Json) : IO Unit := do
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
  match Plumb.Checker.PolicyCodec.parse (Json.compress value ++ "\n") with
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

open Std.DTreeMap.Internal in
mutual
/-- Node count of a JSON value in which every scalar, however long, weighs one. Replacing a
value by a string never raises it, which is how `legacyJson` terminates. -/
private def weight : Json → Nat
  | .arr ⟨values⟩ => 1 + weightList values
  | .obj ⟨⟨fields⟩⟩ => 1 + weightImpl fields
  | _ => 1

private def weightList : List Json → Nat
  | [] => 0
  | value :: values => weight value + weightList values

private def weightImpl : Impl String (fun _ => Json) → Nat
  | .leaf => 0
  | .inner _ _ value l r => weightImpl l + weight value + weightImpl r
end

private theorem one_le_weight (j : Json) : 1 ≤ weight j := by
  cases j <;> simp [weight] <;> omega

private theorem weight_le_list {values : List Json} {v : Json} (h : v ∈ values) :
    weight v ≤ weightList values := by
  induction values with
  | nil => cases h
  | cons x xs ih =>
    simp only [weightList]
    rcases List.mem_cons.mp h with rfl | h
    · omega
    · have := ih h; omega

private theorem weight_arr (values : Array Json) :
    weight (.arr values) = 1 + weightList values.toList := by
  cases values; simp [weight]

private theorem weight_lt_arr {values : Array Json} {v : Json} (h : v ∈ values) :
    weight v < weight (.arr values) := by
  have := weight_le_list (Array.mem_def.mp h)
  rw [weight_arr]; omega

open Std.DTreeMap.Internal in
private theorem weight_foldrM {t : Impl String (fun _ => Json)} {acc : List (String × Json)}
    {k : String} {v : Json}
    (h : (k, v) ∈ Id.run (t.foldrM (fun k v l => pure ((k, v) :: l)) acc)) :
    (k, v) ∈ acc ∨ weight v ≤ weightImpl t := by
  induction t generalizing acc with
  | leaf => left; simpa [Impl.foldrM] using h
  | inner _ k' v' l r ihl ihr =>
    simp only [Impl.foldrM, Id.run_bind, Id.run_pure] at h
    simp only [weightImpl]
    rcases ihl h with h | h
    · rcases List.mem_cons.mp h with h | h
      · cases h; right; omega
      · rcases ihr h with h | h
        · exact .inl h
        · right; omega
    · right; omega

private theorem weight_lt_obj {fields : Std.TreeMap.Raw String Json} {k : String} {v : Json}
    (h : (k, v) ∈ fields.toList) : weight v < weight (.obj fields) := by
  have e : weight (.obj fields) = 1 + weightImpl fields.inner.inner := by
    rcases fields with ⟨⟨t⟩⟩; simp [weight]
  rcases weight_foldrM (acc := []) h with h | h
  · cases h
  · omega

private theorem weight_map_le {values : Array Json} {f : Json → Json}
    (h : ∀ x ∈ values, weight (f x) ≤ weight x) :
    weight (.arr (values.map f)) ≤ weight (.arr values) := by
  rcases values with ⟨values⟩
  simp only [List.map_toArray, weight]
  suffices weightList (values.map f) ≤ weightList values by omega
  induction values with
  | nil => simp [weightList]
  | cons x xs ih =>
    simp only [List.map_cons, weightList]
    have h1 := h x (by simp)
    have h2 := ih (fun y hy => h y (by simp_all))
    omega

/-- Structural names are rendered only at this legacy display boundary. -/
private def legacyName (value : Json) : Json :=
  match Plumb.RegistryCodec.parseName value with
  | .ok n => .str n.toString
  | .error _ => value

private theorem weight_legacyName (v : Json) : weight (legacyName v) ≤ weight v := by
  unfold legacyName
  split
  · have := one_le_weight v; simp [weight]; omega
  · omega

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
Proof text, types, diagnostic prose, and arbitrary strings are never rewritten.
Total by well-founded recursion on `weight`: each call is on an element or field value,
possibly renamed by `legacyName` first, and renaming never raises the weight. `attach`
only supplies the field-membership proof. -/
def legacyJson (value : Json) (sourceRoot targetRoot : String := "") : Json :=
  match value with
  | .arr values => .arr (values.map fun v => legacyJson v sourceRoot targetRoot)
  | .obj fields => Json.mkObj <| fields.toList.attach.filterMap fun ⟨(k, v), _⟩ =>
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
termination_by weight value
decreasing_by
  · exact weight_lt_arr (by assumption)
  · refine Nat.lt_of_le_of_lt ?_ (weight_lt_obj ‹_›)
    have names : ∀ values : Array Json,
        weight (.arr (values.map legacyName)) ≤ weight (.arr values) :=
      fun _ => weight_map_le fun x _ => weight_legacyName x
    split
    · exact weight_legacyName v
    · split
      · split
        · exact names _
        · exact Nat.le_refl _
      · split
        · split
          · apply weight_map_le; intro edge _; split
            · exact names _
            · exact Nat.le_refl _
          · exact Nat.le_refl _
        · exact Nat.le_refl _
end Plumb.Checker.ResultProtocol
