import Lean
import PlumbCore.Screening
import Plumb.Screen.Jev
import Plumb.Screen.Questions

/-! Reading a claim from a loaded environment and screening it.

A claim's docstring is found by Lean's `findDocString?`; its clauses, explanation and any
discharge references come from the proved `PlumbPolicy.Screening` definitions. A clause that
ends with ``(discharged by `Name`)`` is formally discharged when `Name` is a theorem, admitted
with the environment, of type `S → P`, where `S` is definitionally equal to the claim's
statement by Lean's kernel definitional-equality check and `P` does not depend on the
hypothesis, and whose transitive axioms lie within the Standard-Logical foundation (`propext`,
`Quot.sound`, `Classical.choice`). Then `Name` applied to the claim proves `P`: the kernel
admitted the implication, and only whether `P` states the English clause is judged. A marker
that fails any of these conditions makes the claim's screen unavailable; it never downgrades
to a judged clause. -/

namespace Plumb.Screen

open Lean Meta
open PlumbPolicy.Screening
open Plumb.Checker.Screening
open Questions

/-- A checked discharge: `proof` proves the claim implies `formal`, under exactly `axioms`. -/
structure Discharge where
  proof : Name
  formal : String
  axioms : List Name

/-- Axioms a discharge may use: the Standard-Logical foundation (standard §4.5). A project
axiom, `sorryAx`, or a compiler-trusting axiom (`Lean.ofReduceBool`, `Lean.trustCompiler`)
refuses the discharge. -/
def dischargeAxioms : List Name := [``propext, ``Quot.sound, ``Classical.choice]

/-- One claim as read from its environment. -/
structure ClaimInput where
  name : Name
  text : ClaimText
  discharges : List (Option Discharge)

/-- The claim's statement: a theorem's type, or the body of a definition whose type is `Prop`
(calibration corpus items are such definitions), otherwise the declaration's type. -/
def statementExpr (info : ConstantInfo) : Expr :=
  match info with
  | .defnInfo d => if d.type.isProp then d.value else d.type
  | _ => info.type

def pretty (e : Expr) : MetaM String := do
  return toString (← ppExpr e)

/-- Check a discharge reference against the claim's statement. -/
def checkDischarge (claim : Expr) (proof : Name) : MetaM Discharge := do
  let some info := (← getEnv).find? proof
    | throwError "discharge {proof} is not a declaration of the loaded environment"
  let .thmInfo thm := info | throwError "discharge {proof} is not a theorem"
  unless thm.levelParams.isEmpty do throwError "discharge {proof} is universe-polymorphic (unsupported)"
  let .forallE _ hypothesis formal _ := thm.type
    | throwError "discharge {proof} is not an implication from the claim"
  if formal.hasLooseBVars then throwError "discharge {proof}'s conclusion depends on its hypothesis"
  match Kernel.isDefEq (← getEnv) {} hypothesis claim with
  | .ok true => pure ()
  | .ok false => throwError "discharge {proof}'s hypothesis is not definitionally equal to the claim's statement"
  | .error _ => throwError "the kernel could not compare discharge {proof}'s hypothesis with the claim"
  let axioms := (← collectAxioms proof).toList.mergeSort (·.toString ≤ ·.toString)
  if let some a := axioms.find? (!dischargeAxioms.contains ·) then
    throwError "discharge {proof} depends on {a}, outside the Standard-Logical foundation"
  return ⟨proof, ← pretty formal, axioms⟩

/-- Read one declaration's intent clauses, explanation, statement and discharges. -/
def readClaim (name : Name) : MetaM ClaimInput := do
  let some info := (← getEnv).find? name | throwError "unknown declaration {name}"
  unless info.levelParams.isEmpty do throwError "{name} is universe-polymorphic (unsupported)"
  let some doc ← findDocString? (← getEnv) name | throwError "{name} has no docstring"
  let raw := intentClauses doc
  if raw.isEmpty then throwError "{name} has no nonempty Intent section clauses (PL5003)"
  let statement := statementExpr info
  let mut clauses := #[]
  let mut discharges := #[]
  for clause in raw do
    match discharge? clause with
    | some (english, proof) =>
      clauses := clauses.push english
      discharges := discharges.push (some (← checkDischarge statement proof.toName))
    | none =>
      clauses := clauses.push clause
      discharges := discharges.push none
  return { name, text := ⟨clauses.toList, PlumbPolicy.Screening.explanation doc, ← pretty statement⟩,
           discharges := discharges.toList }

/-- Run a `MetaM` reader over a loaded environment. -/
def runMeta (env : Environment) (x : MetaM α) : IO α := do
  let ctx : Core.Context := { fileName := "<intent-screen>", fileMap := default, options := {} }
  let (a, _) ← (x.run' {} {}).toIO ctx { env }
  return a

/-- Screening configuration. -/
structure Config where
  model : PinnedModel
  cache : System.FilePath
  mode : StateMode
  policy : Policy

/-- Accumulated service usage of a run. -/
structure Usage where
  requests : Nat := 0
  cached : Nat := 0
  inputTokens : Nat := 0

def Usage.add (u : Usage) (r : Jev.Response) : Usage :=
  { requests := u.requests + (if r.cached then 0 else 1), cached := u.cached + (if r.cached then 1 else 0)
    inputTokens := u.inputTokens + (if r.cached then 0 else r.inputTokens) }

def noulOf (r : Jev.Response) (id : String) : IO Probability := do
  match r.answers.lookup id with
  | some (.noul p) => return p
  | _ => throw <| IO.userError s!"no Noul answer for {id}"

/-- Support and confidence of the strength Choice. -/
def strengthOf (r : Jev.Response) : IO (Decimal × Decimal) := do
  match r.answers.lookup "strength" with
  | some (.choice ps confidence) =>
    let get (o : String) : IO Decimal := match ps.lookup o with
      | some p => pure p.val
      | none => throw <| IO.userError s!"strength answer lacks option {o}"
    return (strengthSupport (← get "equivalent") (← get "stronger"), confidence.val)
  | _ => throw <| IO.userError "no Choice answer for strength"

/-- Screen one claim: one request for the claim's judgments and one per discharged clause. -/
def screenClaim (cfg : Config) (input : ClaimInput) : StateT Usage IO ClaimScreen := do
  let questions := claimQuestions cfg.mode input.text fun i => (input.discharges[i]?.bind id).isSome
  let response ← Jev.ask cfg.cache cfg.model (state cfg.mode input.text) questions
  modify (·.add response)
  let judged (judgment : Judgment) (subject id : String) (support : Decimal)
      (confidence : Option Decimal) (digest : String) : Judged :=
    { judgment, subject, model := cfg.model, support, confidence, inputsDigest := digest
      question := questionText ((questions.lookup id).getD .null) }
  let mut clauses := #[]
  for ((clause, discharge), i) in (input.text.clauses.zip input.discharges).zipIdx do
    match discharge with
    | none =>
      let p ← noulOf response s!"coverage_{i}"
      clauses := clauses.push (clause, .judged (judged .coverage clause s!"coverage_{i}" p.val none response.digest))
    | some d =>
      let q := [("correspondence", Questions.correspondence)]
      let r ← Jev.ask cfg.cache cfg.model (correspondenceState clause d.formal) q
      modify (·.add r)
      let p ← noulOf r "correspondence"
      clauses := clauses.push (clause, .discharged d.proof d.formal d.axioms
        { judgment := .correspondence, subject := clause, model := cfg.model, support := p.val
          confidence := none, inputsDigest := r.digest, question := questionText Questions.correspondence })
  let (support, confidence) ← strengthOf response
  let targeted ← targetedJudgments.mapM fun (id, j) => do
    let p ← noulOf response id
    pure (judged j "claim" id p.val none response.digest)
  return { claim := input.name, clauses := clauses.toList
           strength := judged .strength "claim" "strength" support (some confidence) response.digest
           targeted }

end Plumb.Screen
