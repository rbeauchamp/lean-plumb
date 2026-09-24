module


@[expose] public section
/-!
Closed public rule identity. Canonical construction is inspired by con-leche's
`PropWhen.lean` and `Cached/Installed.lean`, revision
c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0 (Lean FRO, Joachim Breitner and contributors).
No upstream code or proof is copied. Normative predicates remain in docs/standard.
-/
namespace Plumb

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
  | .projectAxiom => "PL1001"
  | .proofHole => "PL1002"
  | .unknownAxiom => "PL1003"
  | .compilerTrusting => "PL1004"
  | .profileExceeded => "PL1005"
  | .escapeHatch => "PL1006"
  | .executableContract => "PL1007"
  | .environment => "PL2001"
  | .configuration => "PL2002"
  | .sourceBuild => "PL2003"
  | .coverage => "PL2004"
  | .admission => "PL2005"
  | .executionUnresolved => "PL3001"
  | .executionBoundary => "PL3002"
  | .fenceStructure => "PL4001"
  | .positiveExample => "PL4002"
  | .negativeExample => "PL4003"
  | .trustedExample => "PL4004"
  | .moduleDocumentation => "PL5001"
  | .materialDocumentation => "PL5002"

def parse? : String → Option RuleId
  | "PL1001" => some .projectAxiom
  | "PL1002" => some .proofHole
  | "PL1003" => some .unknownAxiom
  | "PL1004" => some .compilerTrusting
  | "PL1005" => some .profileExceeded
  | "PL1006" => some .escapeHatch
  | "PL1007" => some .executableContract
  | "PL2001" => some .environment
  | "PL2002" => some .configuration
  | "PL2003" => some .sourceBuild
  | "PL2004" => some .coverage
  | "PL2005" => some .admission
  | "PL3001" => some .executionUnresolved
  | "PL3002" => some .executionBoundary
  | "PL4001" => some .fenceStructure
  | "PL4002" => some .positiveExample
  | "PL4003" => some .negativeExample
  | "PL4004" => some .trustedExample
  | "PL5001" => some .moduleDocumentation
  | "PL5002" => some .materialDocumentation
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
end Plumb
