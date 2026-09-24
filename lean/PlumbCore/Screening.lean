import PlumbCore.Account
import PlumbPolicy.Screening

/-! The report account of one opt-in intent screen (`docs/guides/intent-screening.md`).

A judged answer is its own evidence class, `screened`, next to the #42 classes an accepted
run reports (checked relation, trusted mechanisms, open semantic review). Its data records
the model identifier, the exact question text, the support probability and the digest of the
request the model answered. The finding severity and the escalation route are not stored:
they are computed from the user's policy by the proved `classify` and `route`, so a record
cannot carry a severity its probability does not justify.

A claim's screen status is `screened` or `escalated`; there is no constructor for a checked
or reviewed intent, so no screen, however high its probabilities, records the claim as
checked or its R-INTENT review as completed. Only the implication of a formally discharged
clause is checked: Lean's kernel admitted the discharge theorem, the adapter compared its
hypothesis with the claim by the kernel's definitional equality, and its axioms are recorded
and bounded by the Standard-Logical foundation. Its English-to-Lean correspondence is still a
screened judgment. None of this authenticates the
service, the network or the process that carried the request. -/

namespace Plumb.Checker.Screening

open PlumbPolicy.Screening
open Plumb.Checker.Account (Residual)

/-- Evidence classes a screen report distinguishes. -/
inductive EvidenceClass where
  /-- Kernel-checked: the implication proved by a discharge theorem. -/
  | checked
  /-- A calibrated model judgment: never proof and never a completed review. -/
  | screened
  /-- A semantic-review obligation that remains open. -/
  | openReview
  deriving Repr, DecidableEq

def EvidenceClass.spelling : EvidenceClass → String
  | .checked => "checked" | .screened => "screened" | .openReview => "open semantic review"

/-- One judged answer, as recorded evidence. `support` is the probability that the claim
meets the intent in the judged respect (for strength, equivalent or stronger). -/
structure Judged where
  judgment : Judgment
  /-- The clause text, or `claim` for a whole-claim judgment. -/
  subject : String
  model : PinnedModel
  question : String
  support : Decimal
  /-- Distribution confidence, reported for Choice answers only. -/
  confidence : Option Decimal
  /-- SHA-256 of the exact request (model, state and every question) the model answered. -/
  inputsDigest : String

/-- The user's policy for every judgment; off (no thresholds) unless configured. -/
abbrev Policy := Judgment → JudgmentPolicy

/-- The finding a judged answer raises under the user's policy, by the proved `classify`. -/
def Judged.severity (policy : Policy) (j : Judged) : Option ScreenSeverity :=
  (policy j.judgment).thresholds.bind (classify · j.support)

/-- Where a judged answer goes under the user's policy, by the proved `route`. -/
def Judged.route (policy : Policy) (j : Judged) : Route :=
  PlumbPolicy.Screening.route (policy j.judgment) j.support j.confidence

/-- A result that raises a finding always escalates: no judged answer is both a finding and
left screened. -/
theorem Judged.escalate_of_severity (policy : Policy) (j : Judged) (h : j.severity policy ≠ none) :
    j.route policy = .escalate := by
  cases hr : j.route policy with
  | escalate => rfl
  | screened =>
    obtain ⟨t, ht, hw, _⟩ := (checkedRoute.evidence (policy j.judgment) j.support j.confidence).mp hr
    exact absurd (by
      unfold Judged.severity
      rw [ht]; exact ((checkedClassify.evidence t j.support).2.2).mpr hw) h

/-- With no thresholds configured for its judgment, an answer raises no finding and escalates. -/
theorem Judged.unconfigured (policy : Policy) (j : Judged) (h : (policy j.judgment).thresholds = none) :
    j.severity policy = none ∧ j.route policy = .escalate := by
  refine ⟨by simp [Judged.severity, h], ?_⟩
  show routeImpl (policy j.judgment) j.support j.confidence = .escalate
  simp [routeImpl, h]

/-- How one intent clause was compared with the claim. -/
inductive ClauseEvidence where
  /-- `proof` proves that the claim implies `formal` under exactly `axioms`, admitted by Lean's
  kernel; whether `formal` states the English clause is the screened `correspondence` judgment. -/
  | discharged (proof : Lean.Name) (formal : String) (axioms : List Lean.Name) (correspondence : Judged)
  /-- No formal statement: whether the claim guarantees the clause is judged. -/
  | judged (coverage : Judged)

def ClauseEvidence.judgedAnswer : ClauseEvidence → Judged
  | .discharged _ _ _ j => j
  | .judged j => j

/-- Evidence classes of a clause: `checked` only for a discharge's implication. -/
def ClauseEvidence.classes : ClauseEvidence → List EvidenceClass
  | .discharged .. => [.checked, .screened]
  | .judged _ => [.screened]

/-- A screened clause is never only checked: its English-to-Lean link is always judged. -/
theorem ClauseEvidence.screened_mem (e : ClauseEvidence) : EvidenceClass.screened ∈ e.classes := by
  cases e <;> simp [classes]

/-- The screen of one material claim. -/
structure ClaimScreen where
  claim : Lean.Name
  clauses : List (String × ClauseEvidence)
  strength : Judged
  targeted : List Judged

/-- Every judged answer of the screen. -/
def ClaimScreen.answers (s : ClaimScreen) : List Judged :=
  s.clauses.map (·.2.judgedAnswer) ++ s.strength :: s.targeted

/-- The strongest status a screen can record. There is deliberately no checked or reviewed
status. -/
inductive Status where
  | screened | escalated
  deriving Repr, DecidableEq

def Status.spelling : Status → String
  | .screened => "screened" | .escalated => "escalated to review"

/-- `screened` exactly when every answer stays screened under the policy. -/
def ClaimScreen.status (policy : Policy) (s : ClaimScreen) : Status :=
  if s.answers.all (·.route policy == .screened) then .screened else .escalated

theorem ClaimScreen.status_eq_screened_iff (policy : Policy) (s : ClaimScreen) :
    s.status policy = .screened ↔ ∀ j ∈ s.answers, j.route policy = .screened := by
  unfold status
  split <;> simp_all

/-- A claim with any finding is escalated. -/
theorem ClaimScreen.escalated_of_finding (policy : Policy) (s : ClaimScreen) (j : Judged)
    (hj : j ∈ s.answers) (h : j.severity policy ≠ none) : s.status policy = .escalated := by
  cases hs : s.status policy with
  | escalated => rfl
  | screened =>
    have := (status_eq_screened_iff policy s).mp hs j hj
    rw [Judged.escalate_of_severity policy j h] at this
    cases this

/-- Findings: the answers that raise a finding under the policy, with their severity. -/
def ClaimScreen.findings (policy : Policy) (s : ClaimScreen) : List (Judged × ScreenSeverity) :=
  s.answers.filterMap fun j => (j.severity policy).map (j, ·)

theorem ClaimScreen.mem_findings (policy : Policy) (s : ClaimScreen) (j : Judged) (sev : ScreenSeverity) :
    (j, sev) ∈ s.findings policy ↔ j ∈ s.answers ∧ j.severity policy = some sev := by
  simp only [findings, List.mem_filterMap, Option.map_eq_some_iff, Prod.mk.injEq]
  constructor
  · rintro ⟨j', hj', sev', hsev, rfl, rfl⟩; exact ⟨hj', hsev⟩
  · rintro ⟨hj, hsev⟩; exact ⟨j, hj, sev, hsev, rfl, rfl⟩

/-- Review obligations a screen leaves open, whatever its answers: R-INTENT (the requirement
owner's read-back against the intent) and R-DOC (explanation fidelity). -/
def unresolved : List Residual := [.intent, .doc]

/-- Evidence line for one judged answer. -/
def Judged.evidence (j : Judged) : String :=
  let confidence := match j.confidence with
    | some c => s!", confidence {c.render}" | none => ""
  s!"screened: p = {j.support.render}{confidence}, model {j.model.val}, inputs sha256:{j.inputsDigest}"

private def severityText : Option ScreenSeverity → String
  | none => "no finding"
  | some .warning => "warning"
  | some .error => "error"

private def routeText : Route → String
  | .screened => "screened" | .escalate => "escalate to reasoning-model or human review"

/-- Human lines for one claim screen. -/
def ClaimScreen.lines (policy : Policy) (s : ClaimScreen) : Array String :=
  let answer (label : String) (j : Judged) :=
    s!"  {label}: {j.evidence}; {severityText (j.severity policy)}; {routeText (j.route policy)}"
  let clause := fun ((text, e) : String × ClauseEvidence) =>
    match e with
    | .discharged thm formal axioms j =>
      #[s!"  clause \"{text}\": checked: `{thm}` proves the claim implies `{formal}` " ++
          s!"(kernel-admitted; axioms: {if axioms.isEmpty then "none" else ", ".intercalate (axioms.map toString)})",
        answer "  correspondence of the formal clause to the English" j]
    | .judged j => #[answer s!"clause \"{text}\" coverage" j]
  #[s!"{s.claim}: intent {(s.status policy).spelling}; " ++
      s!"open semantic review: {", ".intercalate (unresolved.map (·.spelling))} " ++
      "(a screen never completes it)"] ++
    s.clauses.toArray.flatMap clause ++
    #[answer "strength (equivalent or stronger)" s.strength] ++
    s.targeted.toArray.map fun j => answer j.judgment.spelling j

end Plumb.Checker.Screening
