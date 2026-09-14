import StrictLean.Checker.SourceAudit
import StrictLean.Checker.Lake

/-!
Balanced Markdown fence discovery and exact, verbatim Lean-source auditing.

Expected-failure markers use a deliberately small diagnostic pattern language:
`|` separates alternatives and `.*` separates ordered literal substrings. This
covers resilient compiler-diagnostic assertions without importing a second
language or pretending that diagnostic text is a stable full regular language.
-/

namespace StrictLean.Checker.Documentation

open Lean System
open StrictLean.Checker
open StrictLean.Checker.Policy

inductive MarkerKind where
  | fail (pattern : String)
  | trusted
  deriving Repr

structure PendingMarker where
  kind : MarkerKind
  line : Nat
  deriving Repr

structure Fence where
  body : String
  line : Nat
  failPattern : Option String
  trusted : Bool
  markerLine : Option Nat
  deriving Repr

structure ScanResult where
  fences : Array Fence
  problems : Array String
  deriving Repr

private def firstWord (value : String) : String :=
  String.ofList <| (value.toList.dropWhile Char.isWhitespace).takeWhile (!Char.isWhitespace ·)

private def fenceRun? (line : String) : Option (Char × Nat × String) := do
  let chars := line.toList.dropWhile Char.isWhitespace
  let first ← chars.head?
  guard (first == '`' || first == '~')
  let count := (chars.takeWhile (· == first)).length
  guard (count >= 3)
  return (first, count, String.ofList (chars.drop count) |>.trimAscii.toString)

private def closingFence (line : String) (character : Char) (minimum : Nat) : Bool :=
  match fenceRun? line with
  | some (found, count, rest) => found == character && count >= minimum && rest.isEmpty
  | none => false

private def exactTrustedMarker (line : String) : Bool :=
  line.trimAscii.toString == "<!-- lean-trusted-compiler -->"

private def failMarker? (line : String) : Option String := do
  let value := line.trimAscii.toString
  let markerPrefix := "<!-- lean-fail:"
  let markerSuffix := "-->"
  guard (value.startsWith markerPrefix && value.endsWith markerSuffix)
  let inner := value.drop markerPrefix.length |>.dropEnd markerSuffix.length
  return inner.trimAscii.toString

/-- Any HTML comment whose content begins with `lean` is treated as an
attempted fence marker, so a misspelled or misspaced marker (`<!--lean-fail:
X-->`, `<!-- lean-trusted -->`) fails as malformed instead of silently
demoting its fence to an ordinary positive example. -/
private def markerLike (line : String) : Bool :=
  let value := line.trimAscii.toString
  value.startsWith "<!--" &&
    (value.drop 4 |>.toString.trimAscii.toString.startsWith "lean")

private def unsupportedPatternChar (character : Char) : Bool :=
  #['[', ']', '(', ')', '{', '}', '?', '+', '^', '$', '\\'].contains character

/-- Validate the intentionally restricted expected-diagnostic pattern grammar. -/
def validatePattern (pattern : String) : Except String Unit := do
  let pattern := if pattern.startsWith "(?s)" then pattern.drop 4 |>.toString else pattern
  if pattern.isEmpty then throw "diagnostic pattern is empty"
  for alternative in pattern.splitOn "|" do
    if alternative.isEmpty then throw "diagnostic pattern has an empty alternative"
    let literals := alternative.splitOn ".*"
    if literals.any (·.isEmpty) then
      throw "diagnostic pattern has an empty ordered literal"
    let stripped := "".intercalate literals
    if stripped.toList.any unsupportedPatternChar || stripped.contains "*" then
      throw "diagnostic pattern contains unsupported regular-expression syntax"

private partial def orderedLiterals (text : String) : List String → Bool
  | [] => true
  | literal :: rest =>
      match text.splitOn literal with
      | _ :: suffix :: suffixes =>
          orderedLiterals (literal.intercalate (suffix :: suffixes)) rest
      | _ => false

/-- Match the restricted expected-diagnostic pattern against full compiler output. -/
def matchesPattern (pattern output : String) : Bool :=
  let pattern := if pattern.startsWith "(?s)" then pattern.drop 4 |>.toString else pattern
  pattern.splitOn "|" |>.any fun alternative =>
    orderedLiterals output (alternative.splitOn ".*")

/-- Fail-closed, balanced scanner for the documented Lean fence protocol. -/
def scan (text origin : String) : ScanResult := Id.run do
  let lines := text.splitOn "\n" |>.toArray
  let mut fences : Array Fence := #[]
  let mut problems : Array String := #[]
  let mut openCharacter : Option Char := none
  let mut openLength := 0
  let mut openInfo := ""
  let mut openLine := 0
  let mut body : Array String := #[]
  let mut pending : Option PendingMarker := none

  for index in [:lines.size] do
    let lineNo := index + 1
    let line := lines[index]!
    if let some character := openCharacter then
      if closingFence line character openLength then
        let language := firstWord openInfo
        if language == "lean" then
          let failPattern := pending.bind fun marker =>
            match marker.kind with | .fail pattern => some pattern | .trusted => none
          let trusted := pending.any fun marker =>
            match marker.kind with | .trusted => true | .fail _ => false
          fences := fences.push {
            body := "\n".intercalate body.toList
            line := openLine
            failPattern
            trusted
            markerLine := pending.map (·.line)
          }
        else if let some marker := pending then
          problems := problems.push
            s!"{origin}:{marker.line}: marker not attached to a ```lean fence"
        openCharacter := none
        pending := none
        body := #[]
      else
        body := body.push line
      continue

    let opener := fenceRun? line
    let failMarker := failMarker? line
    let trustedMarker := exactTrustedMarker line

    if let some marker := pending then
      if lineNo != marker.line + 1 then
        problems := problems.push
          s!"{origin}:{marker.line}: marker is not immediately adjacent to a ```lean fence"
        pending := none

    if failMarker.isSome || trustedMarker then
      if pending.isSome then
        problems := problems.push s!"{origin}:{lineNo}: multiple markers target one fence"
        pending := none
        continue
      if let some pattern := failMarker then
        match validatePattern pattern with
        | .ok _ => pure ()
        | .error error =>
            problems := problems.push s!"{origin}:{lineNo}: invalid lean-fail pattern: {error}"
        pending := some { kind := .fail pattern, line := lineNo }
      else
        pending := some { kind := .trusted, line := lineNo }
      continue

    if markerLike line then
      if let some marker := pending then
        problems := problems.push
          s!"{origin}:{marker.line}: previous marker is not immediately adjacent to a ```lean fence"
        pending := none
      problems := problems.push s!"{origin}:{lineNo}: malformed Lean fence marker"
      continue

    if let some (character, count, info) := opener then
      if let some marker := pending then
        if firstWord info != "lean" then
          problems := problems.push
            s!"{origin}:{marker.line}: marker not attached to a ```lean fence"
          pending := none
      openCharacter := some character
      openLength := count
      openInfo := info
      openLine := lineNo
      body := #[]
      continue

    if let some marker := pending then
      problems := problems.push
        s!"{origin}:{marker.line}: marker is not immediately adjacent to a ```lean fence"
      pending := none

  if openCharacter.isSome then
    problems := problems.push s!"{origin}:{openLine}: fence opened but never closed"
  if let some marker := pending then
    problems := problems.push s!"{origin}:{marker.line}: marker left at end of file"
  return { fences, problems }

inductive Kind where
  | positive
  | negative
  | trusted
  deriving Repr, BEq

structure Task where
  fence : Fence
  origin : String
  kind : Kind
  deriving Repr

inductive Status where
  | pass
  | passNegative
  | passTrusted
  | fail
  deriving Repr, BEq

structure Result where
  task : Task
  status : Status
  detail : String := ""
  deriving Repr

def kindOf (fence : Fence) : Kind :=
  if fence.failPattern.isSome then .negative else if fence.trusted then .trusted else .positive

def statusName : Status → String
  | .pass => "PASS"
  | .passNegative => "PASS_NEG"
  | .passTrusted => "PASS_TRUSTED"
  | .fail => "FAIL"

private def diagnostics (output : String) : String :=
  let lines := errorLines output
  " | ".intercalate (if lines.isEmpty then takeLast 4 (outputLines output) else lines).toList

private def compilationFailure (compilation : SourceAudit.Compilation)
    (task : Task) : Result :=
  let warnings := warningLines compilation.process.output
  let detail := if warnings.isEmpty then
    "did not elaborate verbatim: " ++ diagnostics compilation.process.output
  else "emitted warning: " ++ " | ".intercalate (warnings.extract 0 4).toList
  { task, status := .fail, detail }

private def assessPositive (task : Task) (declarations : Array StrictLean.Report.Declaration)
    (transcripts : Array Frontend.Transcript) : Result :=
  let native := Policy.authorizedNativeAxioms declarations transcripts
  let helpers := Policy.authorizedUnsafeRecHelpers declarations transcripts
  let claim := if task.kind == .trusted then Profile.compilerTrusting
    else Profile.standardLogical
  let (problems, compilerCount) := Id.run do
    let mut problems : Array String := #[]
    let mut compilerCount := 0
    for decl in declarations do
      if let some reason := Policy.reasonFor decl (some claim) native helpers then
        problems := problems.push s!"{reason}: {decl.name} axioms={repr decl.axioms.toList}"
      if Policy.labelOf decl.axioms native == "compiler-trusting" then
        compilerCount := compilerCount + 1
    return (problems, compilerCount)
  if !problems.isEmpty then
    { task, status := .fail, detail := "; ".intercalate (problems.extract 0 4).toList }
  else if task.kind == .trusted && compilerCount == 0 then
    ⟨task, .fail, "trusted marker found no compiler-trusting declaration"⟩
  else
    { task, status := if task.kind == .trusted then .passTrusted else .pass }

private def auditNegative (compilation : SourceAudit.Compilation) (task : Task) : Result :=
  if let some errors := compilation.errors then
   if errors.isEmpty then
    { task, status := .fail, detail := "negative example elaborated successfully" }
   else
    let pattern := task.fence.failPattern.getD ""
    if errors.any (matchesPattern pattern) then
      { task, status := .passNegative }
    else
      ⟨task, .fail, s!"failed, but not with expected diagnostic {repr pattern}: " ++
        diagnostics ("\n".intercalate errors.toList)⟩
  else
    ⟨task, .fail, "diagnostic worker did not complete: " ++ diagnostics compilation.process.output⟩

private structure PendingPositive where
  index : Nat
  task : Task
  compilation : SourceAudit.Compilation
  constantNames : Array String
  importNames : Array Name

private structure InspectionGroup where
  items : Array PendingPositive
  constantNames : Array String

private def disjoint (left right : Array String) : Bool :=
  left.all fun name => !right.contains name

private def addToGroups (groups : Array InspectionGroup)
    (item : PendingPositive) : Array InspectionGroup := Id.run do
  let mut result := groups
  for index in [:groups.size] do
    let some group := result[index]? | continue
    if (group.items.all fun other => other.importNames == item.importNames) &&
        disjoint item.constantNames group.constantNames then
      result := result.set! index {
        items := group.items.push item
        constantNames := group.constantNames ++ item.constantNames
      }
      return result
  return result.push { items := #[item], constantNames := item.constantNames }

/-- Compile every fence in bounded parallel workers, then import compatible
positive modules together. Compatibility requires the same direct imports and
disjoint exact constant names serialized in each `.olean`, so independent snippets remain verbatim while the
large shared dependency environment is loaded only once per collision group.
Each group runs in a child process so extension-held imports are released on exit.
`extraSearchRoots` carries the freshly built claimed-surface libraries of the
checked project, ahead of any inherited search path. -/
unsafe def auditTasks (repo scratch : FilePath) (jobs : Nat)
    (tasks : Array Task) (extraSearchRoots : Array FilePath := #[])
    (moduleSources : Array (Name × FilePath) := #[]) (ownedOutput : Option FilePath := none) : IO (Array Result) := do
  let indexed := tasks.mapIdx fun index task => (task, index)
  let specs := indexed.map fun (task, index) =>
    ({
      «module» := s!"DocFence_{index + 1}"
      source := task.fence.body
      warningAsError := task.kind != .negative
      rejectWarnings := task.kind != .negative
      captureRejection := task.kind == .negative
    } : SourceAudit.SourceSpec)
  let compilations ← timedPhase "fence compilation" <| SourceAudit.compileBatch repo scratch jobs specs
  IO.println s!"fence compilations complete: {tasks.size}; inspecting declarations"
  (← IO.getStdout).flush
  let mut results : Array (Option Result) := Array.replicate tasks.size none
  let mut groups : Array InspectionGroup := #[]
  for index in [:tasks.size] do
    let some task := tasks[index]?
      | throw <| IO.userError "internal error: missing documentation task"
    let some compilation := compilations[index]?
      | throw <| IO.userError "internal error: missing documentation compilation"
    if task.kind == .negative then
      results := results.set! index (some (auditNegative compilation task))
    else if !SourceAudit.compilationPassed compilation then
      results := results.set! index (some (compilationFailure compilation task))
    else
      let (moduleData, _) ← Lean.readModuleData compilation.oleanPath
      let item : PendingPositive := {
        index, task, compilation
        constantNames := moduleData.constNames.map (·.toString)
        importNames := moduleData.imports.map (·.module)
      }
      groups := addToGroups groups item

  let selfLib ← checkerPackageLibDir
  let oldSearchPath ← Lean.searchPathRef.get
  Lean.searchPathRef.set (scratch :: extraSearchRoots.toList ++ selfLib.toList ++ oldSearchPath)
  -- Each worker owns its imported environments and scratch files. Keep the
  -- search path fixed until all workers finish; merge immutable results only
  -- afterward. Limit concurrent large imports to two even when compilation
  -- uses more jobs.
  let inspectGroups := mapWorkQueue (min jobs 2) (groups.mapIdx fun i group => (i, group))
    fun (index, group) => do
      IO.println s!"inspection group {index + 1}/{groups.size}: {group.items.size} fence(s)"
      (← IO.getStdout).flush
      let modules := group.items.map (·.compilation.spec.«module»)
      try
        let inspected ← SourceAudit.inspectGroupCurrentSearchPath modules
          (group.items.map fun item => (item.compilation.spec.«module», item.compilation.sourcePath))
          moduleSources ownedOutput (includeExecution := false) (includeModuleOrigins := false)
        return group.items.map fun item =>
          let declarations := inspected.report.declarations.filter
            (·.«module» == item.compilation.spec.«module»)
          let transcripts := inspected.transcripts.filter
            (·.«module» == item.compilation.spec.«module»)
          (item.index, assessPositive item.task declarations transcripts)
      catch error =>
        return group.items.map fun item =>
          let failure : Result := { task := item.task, status := .fail, detail := s!"checker inspection failed: {error}" }
          (item.index, failure)
  let updates ← try timedPhase "fence inspection" inspectGroups
    finally Lean.searchPathRef.set oldSearchPath
  let mut finalResults := results
  for group in updates do
    for (index, result) in group do
      finalResults := finalResults.set! index (some result)

  let mut complete : Array Result := #[]
  for index in [:finalResults.size] do
    let some result := finalResults[index]?
      | throw <| IO.userError "internal error: missing documentation result slot"
    let some result := result
      | throw <| IO.userError "internal error: documentation task was not assessed"
    complete := complete.push result
  return complete

private def relativeDisplay (root path : FilePath) : String :=
  let rootComponents := root.normalize.components
  let pathComponents := path.normalize.components
  if rootComponents.isPrefixOf pathComponents then
    "/".intercalate (pathComponents.drop rootComponents.length)
  else path.toString

/-- Preserve the documentation discovery domain independently of the project
copy's build/cache exclusions. Only Markdown is consumed by the fence scanner,
and every such file is copied verbatim, including cache-named subdirectories. -/
def snapshotMarkdown (source target : FilePath) : IO Unit := do
  if !(← source.isDir) then return
  let rootComponents := source.normalize.components
  for path in ← source.walkDir do
    if path.extension != some "md" then continue
    let relative := path.normalize.components.drop rootComponents.length
    let destination := relative.foldl (fun base part => base / part) target
    if let some parent := destination.parent then IO.FS.createDirAll parent
    IO.FS.writeFile destination (← IO.FS.readFile path)

/-- Audit all documentation against the caller's freshly built isolated workspace.
The standalone command creates that workspace itself; combined verification owns
it from declaration admission through the last fence inspection. -/
unsafe def auditBuiltProject (repo docsRoot : FilePath) (inventory : Lake.SurfaceInventory)
    (jobs : Nat) (verbose : Bool) : IO UInt32 := do
  if !(← docsRoot.isDir) then
    IO.println s!"FAIL: documentation root is not a directory: {docsRoot}"
    return 1
  let markdown := ((← docsRoot.walkDir).filter fun path => path.extension == some "md")
    |>.qsort fun left right => left.toString < right.toString
  if markdown.isEmpty then
    IO.println s!"FAIL: no Markdown files found recursively below {docsRoot}"
    return 1

  let mut tasks : Array Task := #[]
  let mut structural : Array String := #[]
  for path in markdown do
    let relative := relativeDisplay docsRoot path
    let scan := Documentation.scan (← IO.FS.readFile path) relative
    structural := structural ++ scan.problems
    for fence in scan.fences do
      tasks := tasks.push {
        fence
        origin := s!"{relative}:{fence.line}"
        kind := kindOf fence
      }
  let positiveCount := (tasks.filter (·.kind == .positive)).size
  let negativeCount := (tasks.filter (·.kind == .negative)).size
  let trustedCount := (tasks.filter (·.kind == .trusted)).size
  IO.println <| s!"```lean fences: {tasks.size} " ++
    s!"(conforming-positive {positiveCount}, negative {negativeCount}, trusted {trustedCount})"
  (← IO.getStdout).flush

  let fenceScratch := repo / "tmp" / "fence-build"
  IO.FS.createDirAll fenceScratch
  let results ← auditTasks repo fenceScratch jobs tasks inventory.leanPath inventory.moduleSources (some inventory.leanLibDir)
  let mut failures := structural.size
  for problem in structural do IO.println s!"[X] {problem}"
  for result in results.qsort fun left right => left.task.origin < right.task.origin do
    let mark := match result.status with
      | .pass => "." | .passNegative => "n" | .passTrusted => "t" | .fail => "X"
    IO.println s!"[{mark}] {result.task.origin} {statusName result.status}"
    if result.status == .fail then
      failures := failures + 1
      let detail := if verbose then result.detail
        else (result.detail.splitOn " | ").head?.getD result.detail |>.take 180 |>.toString
      IO.println s!"      {detail}"
  let positivePass := (results.filter (·.status == .pass)).size
  let negativePass := (results.filter (·.status == .passNegative)).size
  let trustedPass := (results.filter (·.status == .passTrusted)).size
  IO.println <| "\nsummary: " ++
    s!"conforming-positive-pass={positivePass}/{positiveCount} " ++
    s!"negative-pass={negativePass}/{negativeCount} " ++
    s!"trusted-classified={trustedPass}/{trustedCount} fail={failures}"
  return if failures == 0 then 0 else 1

end StrictLean.Checker.Documentation
