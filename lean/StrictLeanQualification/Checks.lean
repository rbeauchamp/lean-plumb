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

/-- Pure `Except` traversal succeeds exactly when every element succeeds. Shared by
`evaluate` and the checker's transcript-coordinate admission. -/
theorem forM_eq_ok {α ε : Type} (f : α → Except ε Unit) (l : List α) :
    l.forM f = .ok () ↔ ∀ x ∈ l, f x = .ok () := by
  induction l with
  | nil => exact ⟨fun _ _ h => (List.not_mem_nil h).elim, fun _ => rfl⟩
  | cons y l ih =>
    rw [show (y :: l).forM f = (f y >>= fun _ => l.forM f) from rfl]
    cases hy : f y with
    | error e =>
      simp only [bind, Except.bind, List.mem_cons, forall_eq_or_imp, hy, reduceCtorEq, false_and]
    | ok u =>
      cases u
      simp only [bind, Except.bind, List.mem_cons, forall_eq_or_imp, hy, true_and, ih]

/-- Pure `Except` traversal refuses with `e` exactly when some element refuses with `e`
after a prefix whose elements all succeed; the suffix is not evaluated. -/
theorem forM_eq_error {α ε : Type} (f : α → Except ε Unit) (l : List α) (e : ε) :
    l.forM f = .error e ↔ ∃ before x after, l = before ++ x :: after ∧
      (∀ b ∈ before, f b = .ok ()) ∧ f x = .error e := by
  induction l with
  | nil =>
    refine ⟨fun h => (by cases h), ?_⟩
    rintro ⟨before, x, after, h, -⟩
    cases before <;> cases h
  | cons y l ih =>
    rw [show (y :: l).forM f = (f y >>= fun _ => l.forM f) from rfl]
    simp only [List.cons_eq_append_iff]
    cases hy : f y with
    | error e' =>
      simp only [bind, Except.bind, Except.error.injEq]
      constructor
      · rintro rfl; exact ⟨[], y, l, Or.inl ⟨rfl, rfl⟩, nofun, hy⟩
      · rintro ⟨before, x, after, ⟨rfl, h⟩ | ⟨tail, rfl, _⟩, hb, hx⟩
        · simp only [List.cons.injEq] at h
          rw [h.1, hy] at hx
          exact Except.error.inj hx
        · have := hb y List.mem_cons_self
          rw [hy] at this; cases this
    | ok u =>
      cases u
      simp only [bind, Except.bind, ih]
      constructor
      · rintro ⟨before, x, after, rfl, hb, hx⟩
        refine ⟨y :: before, x, after, Or.inr ⟨before, rfl, rfl⟩, fun b hb' => ?_, hx⟩
        rcases List.mem_cons.mp hb' with rfl | hb'
        · exact hy
        · exact hb b hb'
      · rintro ⟨before, x, after, ⟨rfl, h⟩ | ⟨tail, rfl, rfl⟩, hb, hx⟩
        · simp only [List.cons.injEq] at h
          rw [h.1, hy] at hx; cases hx
        · exact ⟨tail, x, after, rfl, fun b hb' => hb b (List.mem_cons_of_mem y hb'), hx⟩

/-- One assertion as a pure `Except` step: its label is the refusal. -/
def Check.step (check : Check) : Except String Unit :=
  if check.holds then .ok () else .error check.label

/-- The evaluator is exactly the standard traversal of `Check.step`; its recursion is
retained as the executed definition. -/
theorem evaluate_eq_forM (checks : List Check) : evaluate checks = checks.forM Check.step := by
  induction checks with
  | nil => rfl
  | cons check rest ih =>
    show _ = (check.step >>= fun _ => rest.forM Check.step)
    cases h : check.holds <;> rw [evaluate, Check.step, h]
    · rfl
    · exact ih

/-- Success is equivalent to every supplied assertion holding. No assumptions about
list size, labels, or observations; in particular an always-refusing implementation
cannot satisfy this equivalence. -/
theorem evaluate_success (checks : List Check) :
    evaluate checks = .ok () ↔ Satisfied checks := by
  rw [evaluate_eq_forM, forM_eq_ok]
  refine forall₂_congr fun check _ => ?_
  cases h : check.holds <;> simp [Check.step, h]

/-- Refusal reports exactly the first false assertion, with a satisfied prefix and
an arbitrary unevaluated suffix. Duplicate labels do not affect the statement. -/
theorem evaluate_error (checks : List Check) (label : String) :
    evaluate checks = .error label ↔
      ∃ before check after, checks = before ++ check :: after ∧
        Satisfied before ∧ check.holds = false ∧ check.label = label := by
  rw [evaluate_eq_forM, forM_eq_error]
  refine exists_congr fun before => exists_congr fun check => exists_congr fun after =>
    and_congr_right fun _ => and_congr ?_ ?_
  · refine forall₂_congr fun b _ => ?_
    cases hb : b.holds <;> simp [Check.step, hb]
  · cases hc : check.holds <;> simp [Check.step, hc]

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
