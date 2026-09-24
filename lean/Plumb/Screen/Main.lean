import Plumb.MaterialClaim
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

private def judgmentPolicy (value : Json) : Except String JudgmentPolicy := do
  exactFields value ["error", "warning", "minConfidence"] "a judgment policy"
  let error ← decimalOf (← value.getObjVal? "error")
  let warning ← decimalOf (← value.getObjVal? "warning")
  let thresholds ← if h : error ≤ warning then pure (Thresholds.mk error warning h)
    else throw "the error threshold exceeds the warning threshold"
  let minConfidence ← match value.getObjVal? "minConfidence" with
    | .ok c => some <$> decimalOf c
    | .error _ => pure none
  return { thresholds := some thresholds, minConfidence }

/-- Parse the configuration file (schema version 1, no unknown fields). -/
def parseConfig (text : String) : Except String Config := do
  let json ← Json.parse text
  exactFields json ["schemaVersion", "model", "cache", "state", "judgments"] "the configuration"
  unless (← json.getObjValAs? Nat "schemaVersion") == 1 do throw "unsupported schemaVersion"
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
  | none => "none" | some .warning => "warning" | some .error => "error"

private def routeText : Route → String
  | .screened => "screened" | .escalate => "escalate"

def judgedJson (policy : Policy) (claim : Name) (j : Judged) : Json :=
  Json.mkObj [("claim", .str claim.toString), ("class", "screened"), ("judgment", .str j.judgment.spelling),
    ("subject", .str j.subject), ("model", .str j.model.val), ("question", .str j.question),
    ("probability", .str j.support.render),
    ("confidence", match j.confidence with | some c => .str c.render | none => .null),
    ("inputsDigest", .str j.inputsDigest), ("severity", .str (severityText (j.severity policy))),
    ("route", .str (routeText (j.route policy)))]

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

def costNote (u : Usage) : String :=
  s!"service usage: {u.requests} request(s) sent, {u.cached} answered from cache, " ++
    s!"{u.inputTokens} input tokens billed (output tokens are free; the jev-1.13.0 list price " ++
    "was $0.042 per million input tokens on 2026-09-24)"

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
  let mut errors := 0
  for name in selected do
    let input ← runMeta env (readClaim name)
    let (s, u) ← (screenClaim cfg input).run usage
    usage := u
    for line in s.lines cfg.policy do IO.println line
    records := records ++ (s.answers.map (judgedJson cfg.policy name)).toArray
    errors := errors + ((s.findings cfg.policy).filter (·.2 == .error)).length
  IO.println (costNote usage)
  if let some path := args.json then
    IO.FS.writeFile path (Json.mkObj [("schemaVersion", (1 : Nat)), ("class", "screened"),
      ("note", "Screened results are model judgments: never checked evidence and never a completed R-INTENT review."),
      ("results", Json.arr records)]).pretty
  return if errors > 0 then 1 else 0

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
