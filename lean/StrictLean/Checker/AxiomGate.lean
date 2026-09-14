import StrictLean.Checker.Lake
import StrictLean.Checker.SourceAudit
import StrictLean.Checker.Diagnostics
import StrictLean.Checker.Documentation

/-!
Lake-semantic declaration, computation, and foundation gate implemented
entirely in Lean.
-/

namespace StrictLean.Checker.AxiomGate

open Lean System
open StrictLean.Checker
open StrictLean.Checker.Policy

structure Options where
  file : Option FilePath := none
  claim : Option Profile := none
  execution : ExecutionClaim := .report
  manifest : Option FilePath := none
  project : Option FilePath := none
  jsonOut : Option FilePath := none
  withDocs : Bool := false
  incremental : Bool := false
  buildLint : Bool := false
  verbose : Bool := false
  help : Bool := false

private def usage : String :=
  "usage: lake exe axiomGate -- [--verbose] [--project DIR] [--manifest PATH] [--json-out PATH] [--with-docs]\n" ++
  "       lake exe axiomGate -- --file FILE [--claim PROFILE] [--execution MODE] [--json-out PATH]\n" ++
  "profiles: kernel-only, choice-free, standard-logical, compiler-trusting\n" ++
  "execution modes: report (default), checked"

private partial def parseArgs : List String → Options → IO Options
  | [], options => return options
  | "--" :: rest, options => parseArgs rest options
  | "--file" :: value :: rest, options =>
      parseArgs rest { options with file := some (FilePath.mk value) }
  | "--claim" :: value :: rest, options => do
      let some claim := Profile.parse? value
        | throw <| IO.userError s!"unknown foundation profile: {value}"
      parseArgs rest { options with claim := some claim }
  | "--execution" :: value :: rest, options => do
      let some mode := ExecutionClaim.parse? value
        | throw <| IO.userError s!"unknown execution mode: {value}"
      parseArgs rest { options with execution := mode }
  | "--manifest" :: value :: rest, options =>
      parseArgs rest { options with manifest := some (FilePath.mk value) }
  | "--project" :: value :: rest, options =>
      parseArgs rest { options with project := some (FilePath.mk value) }
  | "--json-out" :: value :: rest, options =>
      parseArgs rest { options with jsonOut := some (FilePath.mk value) }
  | "--with-docs" :: rest, options =>
      parseArgs rest { options with withDocs := true }
  | "--incremental" :: rest, options =>
      parseArgs rest { options with incremental := true }
  | "--build-lint" :: rest, options =>
      parseArgs rest { options with buildLint := true, incremental := true }
  | "--verbose" :: rest, options =>
      parseArgs rest { options with verbose := true }
  | "--help" :: rest, options => parseArgs rest { options with help := true }
  | "-h" :: rest, options => parseArgs rest { options with help := true }
  | flag :: _, _ => throw <| IO.userError s!"unknown or incomplete argument: {flag}"

private def resolve (repo path : FilePath) : FilePath :=
  if path.isAbsolute then path else repo / path.toString

/-- Write the audit report JSON, translating paths of an isolated disposable
copy back to the checked project's own root. -/
private def writeRemappedJson (path : FilePath) (value : Json)
    (sourceRoot targetRoot : FilePath) : IO Unit := do
  let mut text := Json.pretty value
  if sourceRoot.toString != targetRoot.toString then
    text := text.replace (sourceRoot.toString ++ "/") (targetRoot.toString ++ "/")
    text := text.replace (sourceRoot.toString ++ "\"") (targetRoot.toString ++ "\"")
  if let some parent := path.parent then IO.FS.createDirAll parent
  IO.FS.writeFile path (text ++ "\n")

structure LibraryInfo where
  name : String
  modules : Array String
  sources : Array Lake.SourceEntry

private def infoFor (libraries : Array LibraryInfo) (name : String) :
    IO LibraryInfo :=
  match libraries.find? (·.name == name) with
  | some info => return info
  | none => throw <| IO.userError s!"internal error: missing library inventory for {name}"

private def sameStringSet (left right : Array String) : Bool :=
  left.size == right.size && left.all right.contains && right.all left.contains

private def manifestJson (manifest : Manifest.Manifest) : Json :=
  Json.mkObj [
    ("schema-version", Json.num 2),
    ("surfaces", Json.arr <| manifest.surfaces.map fun surface => Json.mkObj [
      ("library", Json.str surface.library),
      ("executables", Json.arr <| surface.executables.map Json.str),
      ("claim", Json.str surface.claim.toString),
      ("execution", Json.str surface.execution.toString),
      ("rationale", Json.str surface.rationale)
    ]),
    ("excluded-libraries", Json.arr <| manifest.excludedLibraries.map fun item =>
      Json.mkObj [
        ("library", Json.str item.library),
        ("rationale", Json.str item.rationale)
      ]),
    ("excluded-executables", Json.arr <| manifest.excludedExecutables.map fun item =>
      Json.mkObj [
        ("executable", Json.str item.executable),
        ("rationale", Json.str item.rationale)
      ])
  ]

private def libraryInfoJson (info : LibraryInfo) : Json :=
  Json.mkObj [
    ("library", Json.str info.name),
    ("modules", Json.arr <| info.modules.map Json.str),
    ("sources", Json.arr <| info.sources.map fun source => Json.mkObj [
      ("module", Json.str source.«module»),
      ("source", Json.str source.source.toString)
    ])
  ]

private def candidateModules (decls : Array StrictLean.Report.Declaration) : Array String :=
  Id.run do
    let mut modules : Array String := #[]
    for decl in decls do
      if Policy.needsFrontendTranscript #[decl]
          && !modules.contains decl.«module» then
        modules := modules.push decl.«module»
    modules

/-- Only typed data crosses these worker boundaries. Each imported environment
and frontend's persistent import regions die before that surface's next operation. -/
private structure ReportWorkerRequest where
  modules : Array String
  searchRoots : Array String
  sourceRoots : Array String
  moduleSources : Array (String × String)
  ownedOutput : String
  deriving FromJson, ToJson

private structure SurfaceInspection where
  info : LibraryInfo
  report : StrictLean.Report.Environment
  transcripts : Array Frontend.Transcript
  frontendFailures : Array String

private unsafe def auditSurfaceAt (repo manifestPath : FilePath)
    (fresh verbose : Bool) (reportRoot : FilePath)
    (jsonOut : Option FilePath) : IO UInt32 := do
  let manifest ← Manifest.load manifestPath
  let inventory ← Lake.surfaceInventory repo
  let rootInventory : Lake.RootInventory := {
    libraries := inventory.libraries.map (·.library)
    leanLibDir := inventory.leanLibDir
  }
  let manifested := Manifest.libraries manifest
  if !sameStringSet manifested rootInventory.libraries then
    let missing := rootInventory.libraries.filter fun name => !manifested.contains name
    let extra := manifested.filter fun name => !rootInventory.libraries.contains name
    let details := (if missing.isEmpty then #[] else
      #[s!"unclassified root Lean libraries {repr missing.toList}"]) ++
      (if extra.isEmpty then #[] else #[s!"non-root Lean libraries {repr extra.toList}"])
    throw <| IO.userError s!"manifest-incomplete: {"; ".intercalate details.toList}"
  let manifestedExes := Manifest.executables manifest
  let discoveredExes := inventory.executables.map (·.executable)
  if !sameStringSet manifestedExes discoveredExes then
    let missing := discoveredExes.filter fun name => !manifestedExes.contains name
    let extra := manifestedExes.filter fun name => !discoveredExes.contains name
    let details := (if missing.isEmpty then #[] else
      #[s!"unclassified root Lean executables {repr missing.toList}"]) ++
      (if extra.isEmpty then #[] else #[s!"non-root Lean executables {repr extra.toList}"])
    throw <| IO.userError s!"manifest-incomplete: {"; ".intercalate details.toList}"

  let mut libraries : Array LibraryInfo := #[]
  for library in manifested do
    let some info := inventory.libraries.find? (·.library == library)
      | throw <| IO.userError s!"lake-query-malformed: auditPlan omitted {library}"
    libraries := libraries.push {
      name := library, modules := info.modules, sources := info.sources
    }

  let exeInfoFor (name : String) : IO Lake.ExecutableInventory :=
    match inventory.executables.find? (·.executable == name) with
    | some info => return info
    | none => throw <| IO.userError s!"lake-query-malformed: auditPlan omitted {name}"
  let claimedModules := manifest.surfaces.foldl (fun all surface =>
    match libraries.find? (·.name == surface.library) with
    | some info => all ++ info.modules
    | none => all) #[]
  for surface in manifest.surfaces do
    for exeName in surface.executables do
      let exe ← exeInfoFor exeName
      if let some owner := libraries.find? (·.modules.contains exe.root) then
        throw <| IO.userError <| s!"manifest-conflict: claimed executable '{exeName}' " ++
          s!"root {exe.root} is already a module of root library '{owner.name}'"
  for excluded in manifest.excludedExecutables do
    let exe ← exeInfoFor excluded.executable
    if claimedModules.contains exe.root then
      throw <| IO.userError <| s!"manifest-conflict: excluded executable " ++
        s!"'{excluded.executable}' root {exe.root} is a module of a claimed library"

  let mut surfaces : Array LibraryInfo := #[]
  for surface in manifest.surfaces do
    let base ← infoFor libraries surface.library
    let mut modules := base.modules
    let mut sources := base.sources
    for exeName in surface.executables do
      let exe ← exeInfoFor exeName
      modules := modules.push exe.root
      sources := sources.push { «module» := exe.root, source := exe.source }
    surfaces := surfaces.push { name := surface.library, modules, sources }

  let positiveTargets := Manifest.positiveTargets manifest
  if let some lines ← timedPhase "claimed-source build" <| Lake.buildChecked repo positiveTargets (if fresh then "fresh" else "incrementally") then
    for line in lines do IO.println s!"    {line}"
    return 1

  let excludedModules := Id.run do
    let mut result : Array String := #[]
    for excluded in manifest.excludedLibraries do
      let info := libraries.find? (·.name == excluded.library)
      if let some info := info then result := result ++ info.modules
    for excluded in manifest.excludedExecutables do
      let info := inventory.executables.find? (·.executable == excluded.executable)
      if let some info := info then result := result.push info.root
    result
  let configuredModules := libraries.foldl (fun result info => result ++ info.modules) #[]
    ++ inventory.executables.map (·.root)
  -- At most two surface inspections read the completed common build at once.
  -- Each owns its report and sequential frontend subprocesses. A report may
  -- retain its environment while awaiting an existing replacement-history helper.
  let inspectSurface (surface : Manifest.Surface) : IO SurfaceInspection := do
    let info ← infoFor surfaces surface.library
    let request : ReportWorkerRequest := {
      modules := info.modules
      searchRoots := inventory.leanPath.map (·.toString)
      sourceRoots := inventory.leanSrcPath.map (·.toString)
      moduleSources := inventory.moduleSources.map fun (name, path) => (name.toString, path.toString)
      ownedOutput := inventory.leanLibDir.toString
    }
    let report : StrictLean.Report.Environment ← timedPhase s!"declaration inspection {surface.library}" <|
      runTypedWorker "--declaration-report-worker" request
    let mut frontendFailures : Array String := #[]
    let mut transcripts : Array Frontend.Transcript := #[]
    for moduleName in candidateModules report.declarations do
      let some source := info.sources.find? (·.«module» == moduleName)
        | frontendFailures := frontendFailures.push s!"frontend-source-missing: {moduleName}"; continue
      try
        transcripts := transcripts.push <|
          ← timedPhase s!"frontend attribution {moduleName}" <| Frontend.buildIsolated moduleName source.source inventory.leanPath
      catch error =>
        frontendFailures := frontendFailures.push s!"frontend-transcript-failed: {moduleName}: {error}"
    return { info, report, transcripts, frontendFailures }
  let inspections ← mapWorkQueue 2 manifest.surfaces fun surface => do
    -- Capture failures as values so every started worker is joined, then choose
    -- fatal errors in manifest order instead of worker-completion order.
    return (surface, ← (inspectSurface surface).toBaseIO)

  let mut failures : Array String := #[]
  let mut totalDeclarations := 0
  let mut surfaceReports : Array Json := #[]
  for (surface, outcome) in inspections do
    let inspected ← IO.ofExcept outcome
    let { info, report, transcripts, frontendFailures } := inspected
    let envModules := report.modules.filter
      (!Environment.probeModuleNames.contains ·)
    for moduleName in info.modules do
      if !envModules.contains moduleName then
        failures := failures.push s!"surface-omission: Lake module {moduleName} was not elaborated"
      let origins := report.moduleOrigins.filter (·.name == moduleName)
      let freshOrigin ← match origins[0]? with
        | some origin => pathWithin (FilePath.mk origin.olean) rootInventory.leanLibDir
        | none => pure false
      if origins.size != 1 || !freshOrigin then
        failures := failures.push s!"surface-not-fresh: {moduleName} did not resolve from the fresh Lake output"
    for moduleName in envModules do
      if excludedModules.contains moduleName then
        failures := failures.push s!"unexpected-project-module: excluded module {moduleName} was imported into positive library {surface.library}"
    -- The probe modules are exempt from the environment-level exclusion check
    -- because the force import always brings them in. Any other module in the
    -- audited environment that imports the probe or its report records is
    -- contamination by an excluded checker module, whatever package owns the
    -- importer: Lake resolves imports workspace-wide, so a dependency module
    -- can import root modules, and only a scan of every module's recorded
    -- direct imports closes every chain from a claimed module to the probe.
    for origin in report.moduleOrigins do
      if Environment.probeModuleNames.contains origin.name then continue
      for imported in origin.imports do
        if Environment.probeOnlyModuleNames.contains imported then
          failures := failures.push s!"unexpected-project-module: checker probe module {imported} was imported into positive library {surface.library} by {origin.name}"
    for origin in report.moduleOrigins do
      if Environment.probeModuleNames.contains origin.name then continue
      if ← pathWithin (FilePath.mk origin.olean) rootInventory.leanLibDir then
        if !configuredModules.contains origin.name then
          failures := failures.push s!"unexpected-project-module: root-owned module {origin.name} is outside every manifested Lake library"
    if report.declarations.any fun decl => !info.modules.contains decl.«module» then
      failures := failures.push s!"declaration-attribution-mismatch: {surface.library}"

    failures := failures ++ frontendFailures
    let native := Policy.authorizedNativeAxioms report.declarations transcripts
    let unsafeHelpers := Policy.authorizedUnsafeRecHelpers report.declarations transcripts
    totalDeclarations := totalDeclarations + report.declarations.size
    for decl in report.declarations do
      if let some reason := Policy.reasonFor decl (some surface.claim) native unsafeHelpers then
        failures := failures.push s!"{reason}: {decl.name} [claim: {surface.claim}] {Policy.classify decl native}"
      if let some contract := decl.executableContract then
        IO.println s!"executable contract {decl.name}: {contract.root} requires {contract.requirement}"
    failures := failures ++ Policy.executionFailures report.execution surface.execution
    if verbose then
      for moduleName in info.modules do
        IO.println s!"module {moduleName} [claimed: {surface.claim}]"
        let declarations := report.declarations.filter (·.«module» == moduleName)
          |>.qsort fun left right => left.name < right.name
        for decl in declarations do IO.println s!"  {Policy.classify decl native}"
    let (rootCount, boundaryCount, checkedCount, trustedCount, unresolvedCount) :=
      Policy.executionSummary report.execution
    IO.println <| s!"execution coverage for {surface.library} [claim: {surface.execution}]: " ++
      s!"{rootCount} root(s), {boundaryCount} boundary(ies) " ++
      s!"({checkedCount} checked, {trustedCount} trusted), {unresolvedCount} unresolved"
    for root in report.execution do
      if !root.boundaries.isEmpty || !root.unresolved.isEmpty then
        IO.println s!"  execution root {root.name}"
        for boundary in root.boundaries do
          IO.println s!"    {Policy.describeBoundary boundary}"
        for item in root.unresolved do
          IO.println s!"    unresolved {item}"
    surfaceReports := surfaceReports.push <| Json.mkObj [
      ("library", Json.str surface.library),
      ("claim", Json.str surface.claim.toString),
      ("execution", Json.str surface.execution.toString),
      ("modules", Json.arr <| info.modules.map Json.str),
      ("authorizedNativeAxioms", Json.arr <| native.map Json.str),
      ("authorizedUnsafeRecHelpers", Json.arr <| unsafeHelpers.map Json.str),
      ("frontendTranscripts", Json.arr <| transcripts.map toJson),
      ("report", toJson report)
    ]

  let ownedModules := manifest.surfaces.foldl (fun count surface =>
    match surfaces.find? (·.name == surface.library) with
    | some info => count + info.modules.size
    | none => count) 0
  let claimedExes := manifest.surfaces.foldl
    (fun count surface => count + surface.executables.size) 0
  IO.println <| s!"claimed libraries: {manifest.surfaces.size}   " ++
    s!"claimed executables: {claimedExes}   " ++
    s!"owned modules: {ownedModules}   owned declarations: {totalDeclarations}"
  for surface in manifest.surfaces do
    IO.println <| s!"claimed profile for {surface.library}: {surface.claim} " ++
      s!"(execution: {surface.execution})"
  for excluded in manifest.excludedLibraries do
    let count := (libraries.find? (·.name == excluded.library)).map (·.modules.size) |>.getD 0
    IO.println s!"excluded library {excluded.library}: {count} module(s)"
  for excluded in manifest.excludedExecutables do
    IO.println s!"excluded executable {excluded.executable}"

  if let some output := jsonOut then
    writeRemappedJson output (Json.mkObj [
      ("manifest", manifestJson manifest),
      ("rootInventory", Json.mkObj [
        ("libraries", Json.arr <| rootInventory.libraries.map Json.str),
        ("executables", Json.arr <| inventory.executables.map fun exe => Json.mkObj [
          ("executable", Json.str exe.executable),
          ("root", Json.str exe.root),
          ("source", Json.str exe.source.toString)
        ]),
        ("leanLibDir", Json.str rootInventory.leanLibDir.toString)
      ]),
      ("libraries", Json.arr <| libraries.map libraryInfoJson),
      ("surfaces", Json.arr surfaceReports)
    ]) repo reportRoot
  if !failures.isEmpty then
    IO.println s!"\nFAIL: {failures.size} violation(s)"
    for failure in failures do
      let reason := (failure.splitOn ":").head?.getD "violation"
      IO.println s!"  [{reason}] {failure}"
    return 1
  IO.println "Explicit proof requirements are checked by elaboration; contract adequacy and completeness require semantic review."
  IO.println <| if fresh then
    "\naxiom gate: PASS — exact Lake surfaces conform"
  else "\naxiom gate: PASS — incremental elaboration and current policy inspection"
  return 0

/-- Internal transport for auditing the parent's already-isolated source copy. -/
private structure SurfaceWorkerRequest where
  project : String
  manifest : String
  reportRoot : String
  jsonOut : Option String
  verbose : Bool
  deriving FromJson, ToJson

/-- Frontend attribution uses persistent imported environments. End that process
before compiling fences, retaining the same freshly built source copy on disk. -/
private def auditSurfaceWorker (request : SurfaceWorkerRequest) (scratch : FilePath) : IO UInt32 := do
  let input := scratch / "surface-request.json"
  writeJson input (toJson request)
  let some selfLib ← checkerPackageLibDir
    | throw <| IO.userError "checker library directory unavailable"
  let binary := selfLib.parent.getD selfLib / ".." / "bin" / "axiomGate"
  let child ← IO.Process.spawn {
    cmd := binary.toString
    args := #["--surface-worker", input.toString]
    stdin := .null
    stdout := .inherit
    stderr := .inherit
    setsid := false
  }
  child.wait

private unsafe def auditSurface (repo : FilePath) (manifest : Option FilePath)
    (incremental verbose : Bool) (jsonOut : Option FilePath) (withDocs : Bool) : IO UInt32 :=
  if incremental then
    auditSurfaceAt repo (manifest.getD (Manifest.defaultPath repo)) false verbose repo jsonOut
  else withScratch repo "axiom-gate" fun scratch => do
    let copy := scratch / "project"
    timedPhase "isolated source copy" <| copyProject repo copy scratch
    if withDocs then Documentation.snapshotMarkdown (repo / "docs") (copy / "docs")
    let result ← timedPhase "complete declaration audit" <|
      if withDocs then auditSurfaceWorker {
        project := copy.toString
        manifest := (manifest.getD (Manifest.defaultPath copy)).toString
        reportRoot := repo.toString
        jsonOut := jsonOut.map (·.toString)
        verbose
      } scratch
      else auditSurfaceAt copy (manifest.getD (Manifest.defaultPath copy)) true verbose repo jsonOut
    if result != 0 || !withDocs then return result
    let inventory ← Lake.surfaceInventory copy
    Documentation.auditBuiltProject copy (copy / "docs") inventory 4 verbose

private unsafe def auditFile (repo path : FilePath) (claim : Option Profile)
    (execution : ExecutionClaim) (manifest : Option FilePath) (jsonOut : Option FilePath) : IO UInt32 := do
  if !(← path.pathExists) then
    IO.println s!"FAIL: missing source file {path}"
    return 1
  let manifestPath := manifest.getD (Manifest.defaultPath repo)
  if manifest.isSome || (← manifestPath.pathExists) then
    let claimed ← Manifest.load manifestPath
    if let some lines ← Lake.buildChecked repo (Manifest.positiveTargets claimed) "incrementally" then
      for line in lines do IO.println s!"    {line}"
      return 1
  let inventory ← Lake.surfaceInventory repo
  let source ← IO.FS.readFile path
  withScratch repo "file-audit" fun scratch => do
    let moduleName := s!"AuditFile_{← IO.monoNanosNow}"
    let result ← SourceAudit.compileAndInspect repo scratch {
      «module» := moduleName, source
    } inventory.leanPath inventory.leanSrcPath inventory.moduleSources (some inventory.leanLibDir)
    match result with
    | .error output =>
        IO.println s!"FAIL: {path} does not elaborate:"
        let diagnostics := if !(errorLines output).isEmpty then errorLines output
          else takeLast 10 (outputLines output)
        for line in diagnostics do IO.println s!"    {line}"
        return 1
    | .ok inspected =>
        let declarations := inspected.report.declarations.qsort fun left right =>
          left.name < right.name
        let native := Policy.authorizedNativeAxioms declarations inspected.transcripts
        let unsafeHelpers := Policy.authorizedUnsafeRecHelpers declarations inspected.transcripts
        let mut reasons : Array String := #[]
        for decl in declarations do
          let reason := Policy.reasonFor decl claim native unsafeHelpers
          let verdict := match reason with
            | none => "OK"
            | some value => s!"VIOLATION[{value}]"
          IO.println s!"[{verdict}] {Policy.classify decl native}"
          if let some value := reason then reasons := reasons.push value
        let executionViolations := Policy.executionFailures inspected.report.execution execution
        let (rootCount, boundaryCount, checkedCount, trustedCount, unresolvedCount) :=
          Policy.executionSummary inspected.report.execution
        IO.println <| s!"execution coverage [claim: {execution}]: {rootCount} root(s), " ++
          s!"{boundaryCount} boundary(ies) ({checkedCount} checked, {trustedCount} trusted), " ++
          s!"{unresolvedCount} unresolved"
        for root in inspected.report.execution do
          if !root.boundaries.isEmpty || !root.unresolved.isEmpty then
            IO.println s!"  execution root {root.name}"
            for boundary in root.boundaries do
              IO.println s!"    {Policy.describeBoundary boundary}"
            for item in root.unresolved do
              IO.println s!"    unresolved {item}"
        for violation in executionViolations do
          let reason := (violation.splitOn ":").head?.getD "execution-unresolved"
          IO.println s!"[VIOLATION[{reason}]] {violation}"
          reasons := reasons.push reason
        if let some output := jsonOut then
          writeJson output <| Json.mkObj [
            ("claim", (claim.map (Json.str ∘ Profile.toString)).getD Json.null),
            ("execution", Json.str execution.toString),
            ("authorizedNativeAxioms", Json.arr <| native.map Json.str),
            ("authorizedUnsafeRecHelpers", Json.arr <| unsafeHelpers.map Json.str),
            ("frontendTranscripts", Json.arr <| inspected.transcripts.map toJson),
            ("report", toJson inspected.report)
          ]
        if !reasons.isEmpty then
          IO.println <| s!"\nfile audit: FAIL ({reasons.size} violation(s))" ++
            (claim.map (fun profile => s!" against claim '{profile}'")).getD ""
          return 1
        IO.println <| s!"\nfile audit: PASS ({declarations.size} declaration(s)" ++
          (claim.map (fun profile => s!", claim '{profile}'")).getD "" ++ ")"
        return 0

unsafe def run (args : List String) : IO UInt32 := do
  if let ["--declaration-report-worker", input, out] := args then
    let json ← IO.ofExcept <| Json.parse (← IO.FS.readFile input)
    let request : ReportWorkerRequest ← IO.ofExcept (fromJson? json)
    let report ← Environment.loadReport request.modules
      (request.searchRoots.map FilePath.mk) (request.sourceRoots.map FilePath.mk)
      (request.moduleSources.map fun (name, path) => (name.toName, FilePath.mk path))
      (some (FilePath.mk request.ownedOutput))
    writeJson out (toJson report)
    return 0
  if let ["--frontend-worker", input, out] := args then
    let json ← IO.ofExcept <| Json.parse (← IO.FS.readFile input)
    let request : Frontend.WorkerRequest ← IO.ofExcept (fromJson? json)
    let transcript ← Frontend.build request.moduleName request.source
      (request.searchRoots.map FilePath.mk)
    writeJson out (toJson transcript)
    return 0
  if let ["--surface-worker", input] := args then
    let json ← IO.ofExcept <| Json.parse (← IO.FS.readFile input)
    let request : SurfaceWorkerRequest ← IO.ofExcept (fromJson? json)
    return ← auditSurfaceAt request.project request.manifest true request.verbose
      request.reportRoot (request.jsonOut.map FilePath.mk)
  if let ["--compile-batch-worker", input, out] := args then
    let json ← IO.ofExcept <| Json.parse (← IO.FS.readFile input)
    let request ← IO.ofExcept (fromJson? json)
    writeJson out (toJson (← SourceAudit.compileBatchWorker request))
    return 0
  if let ["--inspection-group-worker", input, out] := args then
    let json ← IO.ofExcept <| Json.parse (← IO.FS.readFile input)
    let request ← IO.ofExcept (fromJson? json)
    writeJson out (toJson (← SourceAudit.inspectGroupWorker request))
    return 0
  if let ["--diagnostic-worker", moduleName, source, out] := args then
    writeJson out (toJson (← Diagnostics.errors moduleName.toName source))
    return 0
  if let ["--replacement-history-worker", moduleName, source, out] := args then
    let transcript ← Frontend.buildReplacementHistoryCurrentSearchPath moduleName source
    if !transcript.replacementHistoryUnsupported.isEmpty then
      throw <| IO.userError s!"unsupported replacement-history evaluators: {transcript.replacementHistoryUnsupported}"
    writeJson out (toJson transcript.runtimeReplacements)
    return 0
  let options ← parseArgs args {}
  if options.help then IO.println usage; return 0
  if options.file.isNone && options.claim.isSome then
    throw <| IO.userError "--claim requires --file"
  if options.file.isNone && options.execution != .report then
    throw <| IO.userError "--execution requires --file (surface mode uses the manifest)"
  if options.file.isSome && options.incremental then
    throw <| IO.userError "--incremental applies only to surface mode"
  if options.withDocs && (options.file.isSome || options.incremental) then
    throw <| IO.userError "--with-docs requires fresh surface mode"
  let repo ← match options.project with
    | some dir => findRepoRoot dir
    | none => repoRoot
  let jsonOut := options.jsonOut.map (resolve repo)
  match options.file with
  | some path =>
      return ← auditFile repo (resolve repo path) options.claim options.execution
        (options.manifest.map (resolve repo)) jsonOut
  | none =>
      if options.buildLint then
        IO.println "build policy linter: enforcing all manifested Lake modules (incremental elaboration; fresh policy inspection)"
      let result ← auditSurface repo (options.manifest.map (resolve repo))
        options.incremental options.verbose jsonOut options.withDocs
      if options.buildLint && result == 0 then
        IO.println "build policy linter: PASS (declared requirements only; not fresh-source conformance)"
      return result

end StrictLean.Checker.AxiomGate

unsafe def main (args : List String) : IO UInt32 := do
  try
    StrictLean.Checker.initializeLeanSearchPath
    StrictLean.Checker.AxiomGate.run args
  catch error =>
    IO.eprintln s!"FAIL: {error}"
    return 1
