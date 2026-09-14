import Lean
/-! Prototype descriptor. Canonical metadata design credits con-leche's Installed/PropWhen.
See README.md for pinned sources and the limited evidence scope. -/
namespace RulePrototype
inductive RuleId where | projectAxiom deriving Repr, DecidableEq
structure Descriptor where
  id : String
  reason : String
  title : String
  normative : String
  path : String
  credit : String
  deriving Lean.ToJson
/-- One total descriptor function; the full registry belongs to CATALOG-01. -/
def describe : RuleId → Descriptor
  | .projectAxiom => {
    id := "SL1001", reason := "project-axiom", title := "Project logical axioms are forbidden"
    normative := "docs/standard/8-tooling-and-machine-audit.md#85-proof-completeness-and-foundation-strength"
    path := "rules/SL1001/"
    credit := "Canonical metadata design: con-leche, https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean" }
def rule := describe .projectAxiom
def helpUrl := "https://rbeauchamp.github.io/strict-lean/dev/" ++ rule.path
end RulePrototype
