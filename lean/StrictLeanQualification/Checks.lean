import StrictLean.Contract
import Lean.Data.Json

/-! Pure qualification assertions. `evaluate` accepts exactly a list whose assertions
are all true, and otherwise identifies its first false assertion. This is a contract
about supplied observations, not the truth of compiler, filesystem, or process effects.
The operational adapters call the registered, proof-requiring entrypoint. -/

namespace StrictLeanQualification

/-- A labeled executable assertion about an observation. Labels explain refusal;
the Boolean is the exact predicate being checked, not evidence about external IO. -/
structure Check where
  label : String
  holds : Bool
  deriving Repr, DecidableEq

/-- Conjunction of all supplied assertions, including the empty conjunction. -/
def Satisfied (checks : List Check) : Prop :=
  ∀ check ∈ checks, check.holds = true

/-- Stop at the first false assertion; never turn an unknown observation into success. -/
def evaluate : List Check → Except String Unit
  | [] => .ok ()
  | check :: rest => if check.holds then evaluate rest else .error check.label

/-- Success is equivalent to every supplied assertion holding. No assumptions about
list size, labels, or observations; in particular an always-refusing implementation
cannot satisfy this equivalence. -/
theorem evaluate_success (checks : List Check) :
    evaluate checks = .ok () ↔ Satisfied checks := by
  induction checks with
  | nil => simp [evaluate, Satisfied]
  | cons check rest ih =>
    cases h : check.holds <;> simp [evaluate, Satisfied, h, Satisfied] at ih ⊢
    exact ih

/-- Refusal reports exactly the first false assertion, with a satisfied prefix and
an arbitrary unevaluated suffix. Duplicate labels do not affect the statement. -/
theorem evaluate_error (checks : List Check) (label : String) :
    evaluate checks = .error label ↔
      ∃ before check after, checks = before ++ check :: after ∧
        Satisfied before ∧ check.holds = false ∧ check.label = label := by
  induction checks with
  | nil => simp [evaluate]
  | cons check rest ih =>
    cases h : check.holds
    · constructor
      · intro he
        have hl : check.label = label := by simpa [evaluate, h] using he
        exact ⟨[], check, rest, rfl, by simp [Satisfied], h, hl⟩
      · rintro ⟨before, bad, after, he, hs, hb, hl⟩
        cases before with
        | nil =>
          simp only [List.nil_append, List.cons.injEq] at he
          simpa [evaluate, h, ← he.1] using hl
        | cons first preceding =>
          simp only [List.cons_append, List.cons.injEq] at he
          have hf := hs first (by simp)
          rw [← he.1, h] at hf
          contradiction
    · rw [evaluate, if_pos h, ih]
      constructor
      · rintro ⟨before, bad, after, he, hs, hb, hl⟩
        exact ⟨check :: before, bad, after, by simp [he],
          by simpa [Satisfied, h] using hs, hb, hl⟩
      · rintro ⟨before, bad, after, he, hs, hb, hl⟩
        cases before with
        | nil =>
          simp only [List.nil_append, List.cons.injEq] at he
          rw [← he.1, h] at hb
          contradiction
        | cons first preceding =>
          simp only [List.cons_append, List.cons.injEq] at he
          exact ⟨preceding, bad, after, he.2,
            fun c hc => hs c (by simp [hc]), hb, hl⟩

/-- Composition runs the suffix only after prefix success and retains the exact
first error otherwise. This describes pure `Except`, not rollback of external IO. -/
theorem evaluate_append (xs ys : List Check) :
    evaluate (xs ++ ys) = (evaluate xs).bind (fun _ => evaluate ys) := by
  induction xs with
  | nil => rfl
  | cons check rest ih =>
    cases h : check.holds <;> simp [evaluate, h, ih, Except.bind]

/-- Required success, refusal, and composition behavior of the actual evaluator. -/
def EvaluationContract (run : List Check → Except String Unit) : Prop :=
  (∀ checks, run checks = .ok () ↔ Satisfied checks) ∧
  (∀ checks label, run checks = .error label ↔
    ∃ before check after, checks = before ++ check :: after ∧
      Satisfied before ∧ check.holds = false ∧ check.label = label) ∧
  (∀ xs ys, run (xs ++ ys) = (run xs).bind (fun _ => run ys))

/-- The IO adapters invoke this contract's `run`, which is definitionally `evaluate`. -/
theorem checkedEvaluation : StrictLean.ExecutableContract evaluate EvaluationContract :=
  ⟨evaluate_success, evaluate_error, evaluate_append⟩

/-- Non-vacuity: a genuine true assertion succeeds. -/
theorem positive_control : evaluate [⟨"positive", true⟩] = .ok () := rfl

/-- A false assertion refuses even when surrounded by successful assertions. -/
theorem negative_control :
    evaluate [⟨"before", true⟩, ⟨"defect", false⟩, ⟨"after", true⟩] = .error "defect" := rfl

end StrictLeanQualification
