module

public meta import StrictLean.Linter.Rules
public meta import StrictLean.Linter.Documentation
public meta import Lean.Linter.Basic

public meta section

/-! Opt-in production import for Lean-native local feedback. Lean owns command
snapshots, cancellation and publication. Local options govern editor feedback;
they cannot discharge or disable mandatory project checks. -/
namespace StrictLean.Linter
open Lean Elab Command

register_option linter.strictLean : Bool := {
  defValue := true
  descr := "Emit Strict Lean local feedback; project checking remains required." }
register_option strictLean.localFoundation : String := {
  defValue := "classification-only"
  descr := "Local feedback request: classification-only, kernel-only, choice-free or standard-logical." }

private def enabled : CommandElabM Bool := do
  return Lean.Linter.getLinterValue linter.strictLean (← Lean.Linter.getLinterOptions)

/-- Source findings use the admitted range; module findings keep module attribution
without fabricating a declaration or a source span. -/
private def emit (finding : Finding) (host? : Option Syntax := none) : CommandElabM Unit := do
  let ⟨id, diagnostic⟩ := finding
  let data := (MessageData.tagged Lean.Linter.linterMessageTag
    (toMessageData diagnostic.text)).tagWithErrorName (Name.str `StrictLean id.spelling)
  let severity : MessageSeverity := if warningAsError.get (← getOptions) then .error else .warning
  match diagnostic.location with
  | .source _ =>
      let native ← IO.ofExcept diagnostic.nativeMessage
      logMessage { native with severity, data := ← addMessageContext data }
  | .module _ | .project _ =>
      -- Configuration refusals belong to a command snapshot. Other contextual
      -- findings use EOF. Canonical module/project attribution is unchanged.
      let ctx ← read
      logMessage {
        fileName := ctx.fileName
        pos := ctx.fileMap.toPosition ((host?.bind Syntax.getPos?).getD
          ⟨ctx.fileMap.source.utf8ByteSize⟩)
        severity := severity
        data := ← addMessageContext data }

private def unavailable (detail : String) : CommandElabM Unit := do
  let finding ← IO.ofExcept <| Findings.contextFinding .admission
    (← getEnv).mainModule.toString detail .editorSnapshot .incomplete
  emit finding

/-- Refuse each affected command snapshot, including declaration-free
commands. Async commands do not share linter message logs: per-region deduplication
would require additional configuration ownership, not a global mutable cursor. -/
private def localRequest (stx : Syntax) : CommandElabM (Option StrictLeanPolicy.InspectionRequest) := do
  match Rules.request (strictLean.localFoundation.get (← getOptions)) with
  | .ok request => return some request
  | .error error =>
    emit (← IO.ofExcept <| Findings.contextFinding .configuration
      (← getEnv).mainModule.toString error .editorSnapshot .violation) (some stx)
    return none

initialize addLinter {
  name := `StrictLean.Linter.declarations
  run := Lean.withSetOptionIn fun stx => withRef stx do
    if Parser.isTerminalCommand stx then return
    unless ← enabled do return
    try
      let some request ← localRequest stx | return
      let ds ← Collect.commandDeclarations
      if ds.isEmpty then return
      -- A recoverable compiler error may still leave a real declaration with
      -- a hole. Diagnose that actual observation; retain the compiler error.
      let source : SourceSnapshot := ⟨(← read).fileName, (← read).fileMap.source⟩
      let result ← IO.ofExcept <| Rules.declarations ds source request
      for finding in result.findings do emit finding
      if !result.pending.isEmpty then
        unavailable s!"fresh generated-role evidence remains required for {result.pending}"
    catch ex =>
      if ex.isInterrupt then throw ex
      unavailable s!"local declaration analysis unavailable: {← ex.toMessageData.toString}" }

initialize addModuleLinter {
  name := `StrictLean.Linter.documentation
  run := fun commands => withRef (commands.back?.getD Syntax.missing) do
    unless ← enabled do return
    -- The supported language frontend passes preceding commands here. Each
    -- nonterminal command owns its refusal; imports-only files need this fallback.
    if (Rules.request (strictLean.localFoundation.get (← getOptions))).toOption.isNone then
      if commands.isEmpty then discard <| localRequest Syntax.missing
      return
    if (← get).messages.hasErrors then
      unavailable "module elaboration has errors; completed-module checking remains unavailable"
      return
    try
      let env ← getEnv
      if let some finding ← IO.ofExcept <| Documentation.moduleFinding env env.mainModule .editorSnapshot then
        emit finding
      -- Complete local-map traversal also includes declarations lacking binders,
      -- private/generated constants and additions made by metaprograms.
      let ds ← Collect.currentModule
      let source : SourceSnapshot := ⟨(← read).fileName, (← read).fileMap.source⟩
      for decl in ds do
        if let some finding ← Documentation.declarationFinding env decl (some source) .editorSnapshot then
          emit finding
    catch ex =>
      if ex.isInterrupt then throw ex
      unavailable s!"completed-module documentation analysis unavailable: {← ex.toMessageData.toString}" }

end StrictLean.Linter
