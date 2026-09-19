import StrictLean.Checker.RuleExampleQualification

/-- Validate a whole exported corpus, or one in-progress record without a corpus claim. -/
def main (args : List String) : IO Unit := do
  let (path, single) ← match args with
    | ["--record", path] => pure (path, true)
    | [path] => pure (path, false)
    | _ => throw <| IO.userError "usage: RuleExampleQualification [--record] EVIDENCE.json"
  let json ← IO.ofExcept <| StrictLean.Checker.PolicyCodec.parse (← IO.FS.readFile path)
  if single then
    let before ← IO.ofExcept (json.getObjVal? "checkerBefore")
    let after ← IO.ofExcept (json.getObjVal? "checkerAfter")
    unless before == after do throw <| IO.userError "checker sources changed"
    for record in ← IO.ofExcept ((json.getObjVal? "records").bind Lean.Json.getArr?) do
      IO.ofExcept (StrictLean.Checker.RuleExampleQualification.qualify (record.setObjVal! "checkerSources" before))
  else IO.ofExcept (StrictLean.Checker.RuleExampleQualification.qualifyCorpus json)
  IO.println "rule example evidence: PASS (scoped diagnostic qualification; no Accepted claim)"
