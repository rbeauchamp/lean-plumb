import VersoManual
import PlumbSite
import Generated

/-! Renders the generated rule reference as multi-page HTML. Run through
`lake exe site build` in the repository root, which generates `Generated` first. -/

open Verso.Genre Manual

def main := manualMain (%doc Generated) (config := {
  emitTeX := false, emitHtmlSingle := .no, emitHtmlMulti := .immediately, htmlDepth := 2,
  sourceLink := some "https://github.com/rbeauchamp/lean-plumb",
  issueLink := some "https://github.com/rbeauchamp/lean-plumb/issues" })
