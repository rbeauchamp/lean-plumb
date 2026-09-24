import Plumb.MaterialClaim
import Plumb.RegistryCodec
import Plumb.Screen.Calibrate

/-! `intentScreen`: the opt-in probabilistic intent screen (`docs/guides/intent-screening.md`).

    lake exe intentScreen screen --config FILE --module M [--module M ...]
      [--declaration NAME ...] [--json FILE]
    lake exe intentScreen calibrate --config FILE --split dev|test --report FILE --records FILE

`screen` judges every public `@[plumb_material]` declaration of the listed modules (or exactly
the listed declarations) and prints screened evidence, findings at the configured severities
and escalation routes. It exits 0 when no error-severity finding is raised, 1 when one is, and
2 when the screen is incomplete (missing key, network or service failure, malformed answer,
unreadable claim or invalid discharge). It is never part of offline acceptance. -/

namespace Plumb.Screen.Main

open Lean System
open PlumbPolicy.Screening
open Plumb.Checker.Screening
open Questions

private def decimalOf (value : Json) : Except String Decimal := do
  let .num n := value | throw "threshold is not a number"
  if n.mantissa < 0 then throw "threshold is negative"
  return ⟨n.mantissa.toNat, n.exponent⟩

private def exactFields (value : Json) (allowed : List String) (what : String) : Except String Unit := do
  let .obj fields := value | throw s!"{what} is not an object"
  for (key, _) in fields.toList do
    unless allowed.contains key do throw s!"unknown field `{key}` in {what}"

/-- A judgment's thresholds are keyed by the rule-severity spellings; `information` is
optional and defaults to the warning threshold (an empty information band). -/
private def judgmentPolicy (value : Json) : Except String JudgmentPolicy := do
  let (e, w, i) := (Plumb.Severity.error.spelling, Plumb.Severity.warning.spelling,
    Plumb.Severity.information.spelling)
  exactFields value [e, w, i, "min-confidence"] "a judgment policy"
  let error ← decimalOf (← value.getObjVal? e)
  let warning ← decimalOf (← value.getObjVal? w)
  let information ← match value.getObjVal? i with
    | .ok v => decimalOf v
    | .error _ => pure warning
  let thresholds ← if h : error ≤ warning ∧ warning ≤ information then pure (Thresholds.mk error warning information h.1 h.2)
    else throw "thresholds must satisfy error ≤ warning ≤ information"
  let minConfidence ← match value.getObjVal? "min-confidence" with
    | .ok c => some <$> decimalOf c
    | .error _ => pure none
  return { thresholds := some thresholds, minConfidence }

/-- Parse the configuration file (schema version 1, no unknown fields). -/
def parseConfig (text : String) : Except String Config := do
  let json ← Json.parse text
  exactFields json ["schema-version", "model", "cache", "state", "judgments"] "the configuration"
  unless (← json.getObjValAs? Nat "schema-version") == 1 do throw "unsupported schema-version"
  let model ← json.getObjValAs? String "model"
  let model : PinnedModel ← if h : isPinned model = true then pure ⟨model, h⟩
    else throw s!"model `{model}` is not a pinned version such as jev-1.13.0"
  let cache ← json.getObjValAs? String "cache"
  let some mode := StateMode.parse? (← json.getObjValAs? String "state")
    | throw "state must be full, statement or explanation"
  let judgments ← match json.getObjVal? "judgments" with
    | .ok j => pure j
    | .error _ => pure (Json.mkObj [])
  exactFields judgments (Judgment.all.map (·.spelling)) "judgments"
  let mut table : List (Judgment × JudgmentPolicy) := []
  for j in Judgment.all do
    if let .ok p := judgments.getObjVal? j.spelling then
      table := (j, ← judgmentPolicy p) :: table
  let final := table
  return { model, cache, mode, policy := fun j => (final.lookup j).getD {} }

private def severityText : Option ScreenSeverity → String
  | none => "none" | some s => s.toSeverity.spelling

private def routeText : Route → String
  | .screened => "screened" | .escalate => "escalate"

def judgedJson (policy : Policy) (claim : Name) (j : Judged) : Json :=
  Json.mkObj [("claim", .str claim.toString), ("class", .str j.evidenceClass.spelling),
    ("judgment", .str j.judgment.spelling),
    ("subject", .str j.subject), ("model", .str j.model.val), ("question", .str j.question),
    ("probability", .str j.support.render),
    ("confidence", match j.confidence with | some c => .str c.render | none => .null),
    ("inputsDigest", .str j.inputsDigest), ("severity", .str (severityText (j.severity policy))),
    ("route", .str (routeText (j.route policy)))]

private def locationText : Plumb.Location → String
  | .source s => s!"{s.val.snapshot.uri}:{s.selectionLsp.start.line + 1}:{s.selectionLsp.start.character + 1}"
  | .module n => s!"module {n}"
  | .project p => s!"project/configuration {p}"

/-- One finding in the linter diagnostic shape (`Plumb.RegistryCodec.diagnosticJson`), with
its judgment's `findingId` in place of a registry rule and its evidence class. -/
structure ScreenFinding where
  claim : Name
  location : Plumb.Location
  answer : Judged
  severity : ScreenSeverity

def ScreenFinding.detail (f : ScreenFinding) : String :=
  s!"{f.answer.judgment.spelling} of \"{f.answer.subject}\": {f.answer.evidence}"

def ScreenFinding.text (f : ScreenFinding) : String :=
  s!"{f.answer.judgment.findingId} [{f.answer.evidenceClass.spelling}; {f.severity.toSeverity.spelling}; " ++
    s!"{locationText f.location}]: {f.claim}: {f.detail}"

def ScreenFinding.json (f : ScreenFinding) : Json :=
  Json.mkObj [("id", .str f.answer.judgment.findingId),
    ("arguments", Json.mkObj [("declaration", Plumb.RegistryCodec.nameJson f.claim), ("detail", .str f.detail)]),
    ("location", Plumb.RegistryCodec.locationJson f.location), ("related", Json.arr #[]),
    ("class", .str f.answer.evidenceClass.spelling), ("severity", .str f.severity.toSeverity.spelling),
    ("text", .str f.text)]

private unsafe def loadEnvironment (modules : Array Name) : IO Environment := do
  initSearchPath (← findSysroot)
  enableInitializersExecution
  importModules (modules.map fun module => { module, importAll := true }) {} 0 (loadExts := true)
    (level := .private)

structure Args where
  command : String := ""
  config : Option String := none
  modules : Array Name := #[]
  declarations : Array Name := #[]
  json : Option String := none
  split : Option String := none
  report : Option String := none
  records : Option String := none

partial def parseArgs (args : List String) (acc : Args := {}) : Except String Args :=
  match args with
  | [] => .ok acc
  | "--config" :: v :: rest => parseArgs rest { acc with config := some v }
  | "--module" :: v :: rest => parseArgs rest { acc with modules := acc.modules.push v.toName }
  | "--declaration" :: v :: rest => parseArgs rest { acc with declarations := acc.declarations.push v.toName }
  | "--json" :: v :: rest => parseArgs rest { acc with json := some v }
  | "--split" :: v :: rest => parseArgs rest { acc with split := some v }
  | "--report" :: v :: rest => parseArgs rest { acc with report := some v }
  | "--records" :: v :: rest => parseArgs rest { acc with records := some v }
  | cmd :: rest => if acc.command.isEmpty && !cmd.startsWith "-" then parseArgs rest { acc with command := cmd }
    else .error s!"unexpected argument {cmd}"

def usage : String :=
  "usage: intentScreen screen --config FILE --module M [--module M ...] [--declaration NAME ...] [--json FILE]\n" ++
  "       intentScreen calibrate --config FILE --split dev|test --report FILE --records FILE"

def costNote (model : PinnedModel) (u : Usage) : String :=
  let price := if model.val == "jev-1.13.0" then
      "; the jev-1.13.0 list price was $0.042 per million input tokens on 2026-09-24" else ""
  s!"service usage: {u.requests} request(s) sent, {u.cached} answered from cache, " ++
    s!"{u.tokensText} input tokens billed (output tokens are free{price})"

/-- The machine record of one claim: each clause with its evidence classes (a discharge's
checked implication beside, not inside, its screened correspondence) and the open review
obligations. -/
def claimJson (s : ClaimScreen) : Json :=
  Json.mkObj [("claim", .str s.claim.toString),
    ("clauses", Json.arr (s.clauses.map fun (text, e) =>
      let discharge := match e with
        | .discharged proof formal axioms _ => Json.mkObj [("theorem", .str proof.toString),
            ("formalClause", .str formal), ("axioms", Json.arr (axioms.map (.str ·.toString)).toArray)]
        | .judged _ => .null
      Json.mkObj [("clause", .str text), ("classes", Json.arr (e.classes.map (.str ·.spelling)).toArray),
        ("discharge", discharge)]).toArray),
    ("openReview", Json.mkObj [("class", .str EvidenceClass.openReview.spelling),
      ("obligations", Json.arr (unresolved.map (.str ·.spelling)).toArray)])]

unsafe def screen (args : Args) (cfg : Config) : IO UInt32 := do
  if args.modules.isEmpty then throw <| IO.userError "screen requires at least one --module"
  let env ← loadEnvironment args.modules
  let selected ← if !args.declarations.isEmpty then pure args.declarations else do
    let mut names := #[]
    for (name, _) in env.constants.toList do
      if Plumb.materialClaimAttribute.hasTag env name && !isPrivateName name then
        if let some idx := env.getModuleIdxFor? name then
          if args.modules.contains env.header.modules[idx.toNat]!.module then names := names.push name
    pure (names.qsort (·.toString < ·.toString))
  if selected.isEmpty then
    IO.println "intent screen: no registered material declarations in the listed modules"
    return 0
  let mut usage : Usage := {}
  let mut records := #[]
  let mut claims := #[]
  let mut findings : Array ScreenFinding := #[]
  for name in selected do
    let input ← runMeta env (readClaim name)
    let location ← runMeta env (claimLocation name)
    let (s, u) ← (screenClaim cfg input).run usage
    usage := u
    for line in s.lines cfg.policy do IO.println line
    records := records ++ (s.answers.map (judgedJson cfg.policy name)).toArray
    claims := claims.push (claimJson s)
    findings := findings ++ ((s.findings cfg.policy).map fun (answer, severity) =>
      { claim := name, location, answer, severity : ScreenFinding }).toArray
  for f in findings do IO.println f.text
  IO.println (costNote cfg.model usage)
  if let some path := args.json then
    IO.FS.writeFile path (Json.mkObj [("schemaVersion", (1 : Nat)), ("class", .str EvidenceClass.screened.spelling),
      ("note", "Screened results are model judgments: never checked evidence and never a completed R-INTENT review."),
      ("findings", Json.arr (findings.map (·.json))), ("claims", Json.arr claims), ("results", Json.arr records)]).pretty
  return if findings.any (·.severity == .error) then 1 else 0

unsafe def main (argv : List String) : IO UInt32 := do
  try
    let args ← IO.ofExcept (parseArgs argv)
    let some configPath := args.config | throw <| IO.userError usage
    let cfg ← IO.ofExcept (parseConfig (← IO.FS.readFile configPath))
    match args.command with
    | "screen" => screen args cfg
    | "calibrate" =>
      let (some split, some report, some records) := (args.split, args.report, args.records)
        | throw <| IO.userError usage
      let split ← match split with
        | "dev" => pure Corpus.Split.dev | "test" => pure Corpus.Split.test
        | _ => throw <| IO.userError usage
      let env ← loadEnvironment #[`Plumb.Screen.Corpus]
      Calibrate.run cfg.cache cfg.model split env report records
      return 0
    | _ => throw <| IO.userError usage
  catch e =>
    IO.eprintln s!"intent screen incomplete: {e}"
    return 2

end Plumb.Screen.Main

unsafe def main (argv : List String) : IO UInt32 := Plumb.Screen.Main.main argv
