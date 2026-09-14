import Rule
import StrictLean.Probe
import StrictLean.Checker.Policy
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
  let some r := d.ranges | throwError "prototype: missing real declaration range"
  let w : Widget.WidgetInstance := {
    id := ``ruleLink, javascriptHash := ruleLink.javascriptHash
    props := pure <| Json.mkObj [("url", toJson helpUrl), ("id", toJson rule.id)] }
  let msg := (m!"{rule.id}: {d.name}: {rule.title}\n{helpUrl}" ++ .ofWidget w .nil).tagWithErrorName `StrictLean.SL1001
  logMessage { fileName := source
               pos := ⟨r.selectionRange.start.line, r.selectionRange.start.column⟩
               endPos := some ⟨r.selectionRange.«end».line, r.selectionRange.«end».column⟩
               severity := .error, data := ← addMessageContext msg }
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
      if StrictLean.Checker.Policy.reasonFor d (some .standardLogical) == some rule.reason then
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
