module


@[expose] public section
/-!
Closed public rule identity. Canonical construction is inspired by con-leche's
`PropWhen.lean` and `Cached/Installed.lean`, revision
c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0 (Lean FRO, Joachim Breitner and contributors).
No upstream code or proof is copied. Normative predicates remain in docs/standard.
-/
namespace StrictLean

/-- Reserved initial vocabulary; identity is independent of policy categories. -/
inductive RuleId where
  | projectAxiom
  | proofHole
  | unknownAxiom
  | compilerTrusting
  | profileExceeded
  | escapeHatch
  | executableContract
  | environment
  | configuration
  | sourceBuild
  | coverage
  | admission
  | executionUnresolved
  | executionBoundary
  | fenceStructure
  | positiveExample
  | negativeExample
  | trustedExample
  | moduleDocumentation
  | materialDocumentation
  deriving Repr, BEq, DecidableEq, Inhabited

namespace RuleId

def spelling : RuleId → String
  | .projectAxiom => "SL1001"
  | .proofHole => "SL1002"
  | .unknownAxiom => "SL1003"
  | .compilerTrusting => "SL1004"
  | .profileExceeded => "SL1005"
  | .escapeHatch => "SL1006"
  | .executableContract => "SL1007"
  | .environment => "SL2001"
  | .configuration => "SL2002"
  | .sourceBuild => "SL2003"
  | .coverage => "SL2004"
  | .admission => "SL2005"
  | .executionUnresolved => "SL3001"
  | .executionBoundary => "SL3002"
  | .fenceStructure => "SL4001"
  | .positiveExample => "SL4002"
  | .negativeExample => "SL4003"
  | .trustedExample => "SL4004"
  | .moduleDocumentation => "SL5001"
  | .materialDocumentation => "SL5002"

def parse? : String → Option RuleId
  | "SL1001" => some .projectAxiom
  | "SL1002" => some .proofHole
  | "SL1003" => some .unknownAxiom
  | "SL1004" => some .compilerTrusting
  | "SL1005" => some .profileExceeded
  | "SL1006" => some .escapeHatch
  | "SL1007" => some .executableContract
  | "SL2001" => some .environment
  | "SL2002" => some .configuration
  | "SL2003" => some .sourceBuild
  | "SL2004" => some .coverage
  | "SL2005" => some .admission
  | "SL3001" => some .executionUnresolved
  | "SL3002" => some .executionBoundary
  | "SL4001" => some .fenceStructure
  | "SL4002" => some .positiveExample
  | "SL4003" => some .negativeExample
  | "SL4004" => some .trustedExample
  | "SL5001" => some .moduleDocumentation
  | "SL5002" => some .materialDocumentation
  | _ => none

def all : List RuleId := [.projectAxiom, .proofHole, .unknownAxiom, .compilerTrusting, .profileExceeded, .escapeHatch, .executableContract, .environment, .configuration, .sourceBuild, .coverage, .admission, .executionUnresolved, .executionBoundary, .fenceStructure, .positiveExample, .negativeExample, .trustedExample, .moduleDocumentation, .materialDocumentation]

theorem parse_spelling (id : RuleId) : parse? id.spelling = some id := by
  cases id <;> rfl

theorem spelling_injective {a b : RuleId} (h : a.spelling = b.spelling) : a = b := by
  have e := congrArg parse? h
  simpa only [parse_spelling, Option.some.injEq] using e

theorem mem_all (id : RuleId) : id ∈ all := by
  cases id <;> simp [all]

theorem all_nodup : all.Nodup := by decide

/-- Routes derive solely from the stable ID, with no independently writable slug. -/
def route (id : RuleId) : String := "rules/" ++ id.spelling ++ "/"

theorem route_injective {a b : RuleId} (h : a.route = b.route) : a = b := by
  apply spelling_injective
  exact (String.append_right_inj "rules/").mp ((String.append_left_inj "/").mp h)

instance : ToString RuleId := ⟨spelling⟩
end RuleId
end StrictLean
