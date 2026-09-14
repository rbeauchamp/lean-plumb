import Rule
/-! Export the prototype's one Lean descriptor; attribution in README.md. -/
def main : IO Unit := IO.println (Lean.toJson RulePrototype.rule).compress
