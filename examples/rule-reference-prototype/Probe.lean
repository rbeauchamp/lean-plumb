import Rule
import StrictLean.Probe
import StrictLean.Checker.RuleDiagnostics
import Lean.Linter.EnvLinter.Basic
/-! Bounded API probe, not the product engine. Reuses Strict Lean's actual report and policy.
The direct Message adapter follows Lean.Log, credit Lean authors; canonical metadata and
proof-boundary motivation credit con-leche. See README.md for pinned citations. -/
open Lean Elab Command
open RulePrototype
namespace RulePrototype
@[widget_module] def ruleLink : Widget.Module where
  javascript := "import {createElement} from 'react'; export default function(p) { return createElement('a', {href:p.url, target:'_blank', rel:'noopener noreferrer'}, 'Explain ' + p.id); }"
/-- Preserve named diagnostic code, bypass the core logger's hard-coded manual URL. -/
def emitRule (source : String) (d : StrictLean.Report.Declaration) : CommandElabM Unit := do
  let location ← IO.ofExcept <| StrictLean.Checker.RuleDiagnostics.declarationLocation d
    (some ⟨source, ← IO.FS.readFile source⟩)
  let finding ← IO.ofExcept <| StrictLean.Checker.RuleDiagnostics.declarationFinding
    .projectAxiom (← IO.ofExcept (StrictLean.Checker.RuleDiagnostics.declarationName d)) rule.title location .editorSnapshot (some "standard-logical")
  let native ← IO.ofExcept finding.2.nativeMessage
  let w : Widget.WidgetInstance := {
    id := ``ruleLink, javascriptHash := ruleLink.javascriptHash
    props := pure <| Json.mkObj [("url", toJson helpUrl), ("id", toJson finding.1.spelling)] }
  let msg := (native.data ++ .ofWidget w .nil).tagWithErrorName
    (Name.str `StrictLean finding.1.spelling)
  logMessage { native with data := ← addMessageContext msg }
syntax (name := strictProbe) "#strict_probe" ident str : command
elab_rules : command | `(#strict_probe $_:ident $_:str) => pure ()
/-- The explicit trigger bounds the experiment; production scheduling is ENGINE-01. -/
initialize addLinter {
  name := `RulePrototype.projectAxiom
  run := fun stx => do
    if stx.getKind != ``strictProbe then return
    let `(#strict_probe $mod:ident $source:str) := stx | return
    let report ← StrictLean.Probe.environmentReport [mod.getId]
      (includeExecution := false) (includeModuleOrigins := false)
    for d in report.declarations do
      if StrictLean.Checker.Policy.reasonFor d (some .standardLogical) == some rule.applicability then
        emitRule source.getString d
}
-- Verify the supported type without pretending an independent dummy test is the detector.
-- Registration-only compatibility probe; this empty test is not a rule detector.
register_option linter.rulePrototypeApi : Bool := {
  defValue := false, descr := "Registration-only architecture probe" }
@[builtin_env_linter RulePrototype.linter.rulePrototypeApi]
public meta def environmentApi : Lean.Linter.EnvLinter.EnvLinter where
  test := fun _ => pure none
  noErrorsFound := "registration-only probe"
  errorsFound := "registration-only probe"
  isDefault := false
#check Lean.Linter.EnvLinter.EnvLinter
#check Lean.Elab.Command.addModuleLinter
#check Lean.findDeclarationRangesCore?
end RulePrototype
