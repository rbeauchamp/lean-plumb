import StrictLean.Report
import StrictLean.Checker.Common
import Lean

/-!
Fresh source-elaboration transcripts for the two narrowly allowed generated
roles. The source is compared byte-for-byte before and after elaboration;
isolated callers release frontend imports before consuming the typed result.
-/

namespace StrictLean.Checker.Frontend

open Lean Lean.Elab

structure ImportRecord where
  «module» : String
  importAll : Bool
  isExported : Bool
  isMeta : Bool
  deriving Repr, BEq, FromJson, ToJson

structure SyntaxRange where
  start : StrictLean.Report.Position
  «end» : StrictLean.Report.Position
  deriving Repr, BEq, FromJson, ToJson

structure Evaluator where
  role : String
  elaborator : String
  kind : String
  range : Option SyntaxRange
  pinned : Bool
  deriving Repr, BEq, FromJson, ToJson

structure AddedDeclaration where
  name : String
  kind : String
  «type» : String
  deriving Repr, BEq, FromJson, ToJson

structure DeclarationBinding where
  name : String
  range : Option SyntaxRange
  deriving Repr, BEq, FromJson, ToJson

structure Command where
  commandElaborator : String
  commandKind : String
  commandRange : Option SyntaxRange
  added : Array String
  addedDeclarations : Array AddedDeclaration
  evaluators : Array Evaluator
  bindings : Array DeclarationBinding := #[]
  deriving Repr, BEq, FromJson, ToJson

structure Transcript where
  «module» : String
  source : String
  sourceBytes : Nat
  leanVersion : String
  leanGitHash : String
  imports : Array ImportRecord
  commands : Array Command
  runtimeReplacements : Array (String × String) := #[]
  replacementHistoryUnsupported : Array String := #[]
  deriving Repr, BEq, FromJson, ToJson

/-- Keep every implementation selected in a command context, before later
attribute assignments can overwrite it. Nested command contexts matter: a
namespace's final environment is not its complete compilation history. -/
private partial def replacementRecords (tree : InfoTree)
    (seen : Array (String × String)) : Array (String × String) := Id.run do
  let mut seen := seen
  match tree with
  | .context (.commandCtx ctx) child =>
      for env in #[ctx.env] ++ ctx.cmdEnv?.toArray do
        for (reference, target) in
            (Lean.Compiler.implementedByAttr.ext.getState env).2.toArray do
          let edge := (reference.toString, target.toString)
          if !seen.contains edge then seen := seen.push edge
      return replacementRecords child seen
  | .context _ child => return replacementRecords child seen
  | .node _ children =>
      return children.toArray.foldl (fun seen child => replacementRecords child seen) seen
  | .hole _ => return seen

private partial def commandRecord? (tree : InfoTree) :
    Option (CommandContextInfo × CommandInfo) :=
  match tree with
  | .context (.commandCtx ctx) child =>
      match child with
      | .node (.ofCommandInfo info) _ => some (ctx, info)
      | _ => commandRecord? child
  | .context _ child => commandRecord? child
  | .node _ children => children.toArray.findSome? commandRecord?
  | .hole _ => none

private def position (p : Lean.Position) : StrictLean.Report.Position :=
  { line := p.line, column := p.column }

private def syntaxRange (fileMap : FileMap) (stx : Syntax) : Option SyntaxRange :=
  stx.getRange? (canonicalOnly := true) |>.map fun range =>
    { start := position <| fileMap.toPosition range.start
      «end» := position <| fileMap.toPosition range.stop }

/-- An evaluator is pinned when its elaborator is Lean's anonymous built-in
scaffolding, a syntax macro registered in the command's own environment
(macros are pure syntax transformations; their expansions produce their own
evaluator records and are audited in turn), or an elaborator registered for
that exact syntax kind in the module's post-import environment, i.e. by the
pinned toolchain or an explicitly imported library rather than by the audited
module itself. -/
private def pinnedElaborator (baselineEnv commandEnv : Environment)
    (role : String) (elaborator : Name) (kind : Name) (specializeSame := false) : Bool :=
  if elaborator.isAnonymous then true
  else if role == "command" && elaborator == `Lean.Compiler.specializeAttr &&
      #[`Lean.Parser.Attr.specialize, `specialize].contains kind then
    let registered := fun env =>
      (getAttributeImpl env `specialize).toOption.any (·.ref == elaborator)
    specializeSame && registered baselineEnv && registered commandEnv &&
      !(commandEnv.contains elaborator && (commandEnv.getModuleIdxFor? elaborator).isNone)
  else if (macroAttribute.getEntries commandEnv kind).any (·.declName == elaborator) then true
  else if role == "tactic" then
    (Tactic.tacticElabAttribute.getEntries baselineEnv kind).any (·.declName == elaborator)
  else if role == "term" then
    (Term.termElabAttribute.getEntries baselineEnv kind).any (·.declName == elaborator) ||
      -- `do` elements produce TermInfo too, but use their own keyed registry.
      (Do.doElemElabAttribute.getEntries baselineEnv kind).any (·.declName == elaborator)
  else
    (Command.commandElabAttribute.getEntries baselineEnv kind).any (·.declName == elaborator)

/-- Every information node carrying elaborator attribution participates, including
unfinished terms and alternative elaboration choices. -/
private def evaluatorInfo? : Info → Option (String × ElabInfo)
  | .ofCommandInfo i => some ("command", i.toElabInfo)
  | .ofTacticInfo i => some ("tactic", i.toElabInfo)
  | .ofTermInfo i => some ("term", i.toElabInfo)
  | .ofPartialTermInfo i => some ("term", i.toElabInfo)
  | .ofChoiceInfo i => some ("term", i.toElabInfo)
  | _ => none

private partial def evaluatorRecords (baselineEnv commandEnv : Environment)
    (fileMap : FileMap) (tree : InfoTree) (specializeSame : Bool) : Array Evaluator :=
  match tree with
  | .context _ child => evaluatorRecords baselineEnv commandEnv fileMap child specializeSame
  | .node info children =>
      let own := match evaluatorInfo? info with
        | some (role, i) => #[{
            role
            elaborator := i.elaborator.toString
            kind := i.stx.getKind.toString
            range := syntaxRange fileMap i.stx
            pinned := pinnedElaborator baselineEnv commandEnv role
              i.elaborator i.stx.getKind specializeSame
          }]
        | none => #[]
      children.toArray.foldl
        (fun acc child => acc ++ evaluatorRecords baselineEnv commandEnv fileMap child specializeSame) own
  | .hole _ => #[]

/-- Pinned predefinition elaboration records the exact constant binder at its
declaration identifier, including nested `where` definitions. -/
private partial def declarationBindings (fileMap : FileMap) (tree : InfoTree) :
    Array DeclarationBinding :=
  match tree with
  | .context _ child => declarationBindings fileMap child
  | .node info children =>
      let own := match info with
        | .ofTermInfo i => match i.expr with
          | .const name _ =>
            if i.isBinder then #[{ name := name.toString, range := syntaxRange fileMap i.stx }]
            else #[]
          | _ => #[]
        | _ => #[]
      children.toArray.foldl (fun result child => result ++ declarationBindings fileMap child) own
  | .hole _ => #[]

/-- Source metaprograms can compile with a temporary replacement and restore
the map within one command. Command snapshots cannot certify that history.
Imported trusted elaborators remain inside the documented process boundary. -/
private partial def unsupportedReplacementEvaluators (compilerEnv : Environment) (attributeRefs : Array Name)
    (baselineEnv commandEnv : Environment)
    (tree : InfoTree) : Array String :=
  match tree with
  | .context _ child => unsupportedReplacementEvaluators compilerEnv attributeRefs baselineEnv commandEnv child
  | .node info children => Id.run do
      let evaluator? := (evaluatorInfo? info).map fun (role, i) =>
        (role, i.elaborator, i.stx.getKind)
      let own := match evaluator? with
        | some (role, elaborator, kind) =>
            let scaffold := elaborator == `header || elaborator == `import
            -- Helpers and attribute parameters can report synthetic syntax
            -- kinds. Resolve their declaration against the pinned compiler or
            -- the source's actual imports; a source-local override is not that
            -- trusted declaration. This does not relax generated-role policy.
            let sourceLocal := commandEnv.contains elaborator &&
              (commandEnv.getModuleIdxFor? elaborator).isNone
            let trustedCode := !sourceLocal &&
              (compilerEnv.contains elaborator || attributeRefs.contains elaborator ||
                (commandEnv.getModuleIdxFor? elaborator).isSome)
            if #[`Lean.Elab.Command.elabRunCmd, `Lean.Elab.Command.elabRunMeta,
                `Lean.Elab.Command.elabRunElab, `Lean.Elab.Term.elabRunElab,
                `Lean.Elab.Tactic.evalRunTac].contains elaborator
                || (!scaffold && !trustedCode &&
                  !pinnedElaborator baselineEnv commandEnv role elaborator kind) then
              #[s!"{role}: {elaborator} ({kind})"]
            else #[]
        | none => #[]
      return children.toArray.foldl (fun found child =>
        found ++ unsupportedReplacementEvaluators compilerEnv attributeRefs baselineEnv commandEnv child) own
  | .hole _ => #[]

private def constantKind : ConstantInfo → String
  | .axiomInfo _  => "axiom"
  | .defnInfo _   => "def"
  | .thmInfo _    => "theorem"
  | .opaqueInfo _ => "opaque"
  | .ctorInfo _   => "ctor"
  | .inductInfo _ => "inductive"
  | .recInfo _    => "recursor"
  | .quotInfo _   => "quot"

private def constantRecord (env : Environment) (name : Name) : AddedDeclaration :=
  let info := env.constants.find! name
  { name := name.toString
    kind := constantKind info
    «type» := toString (repr info.type) }

/-- In ordinary command snapshots, only the local map can gain declarations.
When pointer identity confirms the same immutable imported map allocation, scan
only local declarations; otherwise preserve the complete environment difference. -/
private unsafe def newConstants (before after : Environment) : Array Name :=
  let previous := before.constants
  let current := after.constants
  let collect := fun (names : Array Name) name (_ : ConstantInfo) =>
    if previous.contains name then names else names.push name
  if !previous.stage₁ && !current.stage₁ && ptrEq previous.map₁ current.map₁ then
    current.foldStage2 collect #[]
  else
    current.fold collect #[]

/-- Elaborate one exact source from a fresh frontend state and return the
first-introduction transcript. Any diagnostic error or concurrent source
change fails the call. -/
private unsafe def buildCore (moduleName : String) (sourcePath : System.FilePath)
    (history : Bool := false) : IO Transcript := do
  unsafe Lean.enableInitializersExecution
  let sourceBefore ← IO.FS.readFile sourcePath
  -- A separate metadata environment identifies pinned elaborator helpers;
  -- these imports are not added to the source being re-elaborated.
  let compilerEnv ← Lean.importModules #[{ module := `Lean, importAll := true }] {} 0
    (loadExts := true) (level := .private)
  let compilerEnv? := if history then some compilerEnv else none
  unsafe Lean.enableInitializersExecution
  let attributeRefs := (← Lean.attributeMapRef.get).toArray.map (·.2.ref)
  let inputCtx := Parser.mkInputContext sourceBefore sourcePath.toString
  let ctx := { inputCtx with }
  let opts := Lean.Elab.async.set (warningAsError.set {} true) false
  let processor := Lean.Language.Lean.process
  let importsRef ← IO.mkRef (#[] : Array Import)
  let snap ← processor (fun stx => do
    importsRef.set stx.imports
    return Except.ok {
      imports := stx.imports
      isModule := stx.isModule
      mainModuleName := moduleName.toName
      opts
      trustLevel := 0
      plugins := #[]
    }) none ctx
  let snapshots := Lean.Language.toSnapshotTree snap
  let hasErrors ← snapshots.runAndReport opts false
  if hasErrors then
    throw <| IO.userError s!"fresh frontend elaboration failed for {moduleName}"
  let imports ← importsRef.get
  let mut before? : Option Environment := none
  let mut baseline? : Option Environment := none
  let mut commands : Array Command := #[]
  let mut runtimeReplacements : Array (String × String) := #[]
  let mut replacementHistoryUnsupported : Array String := #[]
  for snapshot in snapshots.getAll do
    if let some tree := snapshot.infoTree? then
      if history then runtimeReplacements := replacementRecords tree runtimeReplacements
      if let some (commandCtx, info) := commandRecord? tree then
        if baseline?.isNone then
          baseline? := some commandCtx.env
        if let some compilerEnv := compilerEnv? then
          for evaluator in unsupportedReplacementEvaluators compilerEnv attributeRefs (baseline?.getD commandCtx.env)
              commandCtx.env tree do
            if !replacementHistoryUnsupported.contains evaluator then
              replacementHistoryUnsupported := replacementHistoryUnsupported.push evaluator
        if let some after := commandCtx.cmdEnv? then
          if let some before := before? then
            let added := newConstants before after
            if !added.isEmpty then
              -- Attribute refs are navigation metadata. Require the actual
              -- immutable registered handler object from the compiler baseline,
              -- not a source replacement retaining its name/ref.
              let specializeSame := match (getAttributeImpl compilerEnv `specialize),
                  (getAttributeImpl (baseline?.getD commandCtx.env) `specialize),
                  (getAttributeImpl commandCtx.env `specialize) with
                | .ok expected, .ok baseline, .ok current =>
                    ptrEq expected baseline && ptrEq expected current
                | _, _, _ => false
              commands := commands.push {
                commandElaborator := info.elaborator.toString
                commandKind := info.stx.getKind.toString
                commandRange := syntaxRange commandCtx.fileMap info.stx
                added := added.map (·.toString)
                addedDeclarations := added.map (constantRecord after)
                evaluators := evaluatorRecords (baseline?.getD commandCtx.env)
                  commandCtx.env commandCtx.fileMap tree specializeSame
                bindings := declarationBindings commandCtx.fileMap tree
              }
          before? := some after
        else if before?.isNone then
          before? := some commandCtx.env
  let sourceAfter ← IO.FS.readFile sourcePath
  if sourceAfter != sourceBefore then
    throw <| IO.userError s!"source changed during frontend transcript: {sourcePath}"
  return {
    «module» := moduleName
    source := sourcePath.toString
    sourceBytes := sourceBefore.toUTF8.size
    leanVersion := Lean.versionString
    leanGitHash := Lean.githash
    imports := imports.map fun item => {
      «module» := item.module.toString
      importAll := item.importAll
      isExported := item.isExported
      isMeta := item.isMeta
    }
    commands
    runtimeReplacements
    replacementHistoryUnsupported
  }

/-- Elaborate with the already configured module search path. A caller may use
this variant while it owns one read-only search-path scope for bounded workers. -/
unsafe def buildCurrentSearchPath (moduleName : String)
    (sourcePath : System.FilePath) : IO Transcript :=
  buildCore moduleName sourcePath

/-- Source-history worker variant; it additionally resolves operational
elaborator attribution and records overwritten implementation targets. -/
unsafe def buildReplacementHistoryCurrentSearchPath (moduleName : String)
    (sourcePath : System.FilePath) : IO Transcript :=
  buildCore moduleName sourcePath true

/-- Run `buildCore` with any freshly built package search roots taking
precedence, then restore the executable's original search path. -/
unsafe def build (moduleName : String) (sourcePath : System.FilePath)
    (extraSearchRoots : Array System.FilePath := #[]) : IO Transcript := do
  let oldSearchPath ← Lean.searchPathRef.get
  Lean.searchPathRef.set (extraSearchRoots.toList ++ oldSearchPath)
  try buildCore moduleName sourcePath
  finally Lean.searchPathRef.set oldSearchPath

structure WorkerRequest where
  moduleName : String
  source : String
  searchRoots : Array String
  deriving FromJson, ToJson

/-- Release the frontend's persistent imported environments on worker exit. -/
def buildIsolated (moduleName : String) (sourcePath : System.FilePath)
    (extraSearchRoots : Array System.FilePath := #[]) : IO Transcript :=
  runTypedWorker "--frontend-worker" ({
    moduleName, source := sourcePath.toString,
    searchRoots := extraSearchRoots.map (·.toString)
  } : WorkerRequest)

end StrictLean.Checker.Frontend
