/-
Mutation: an imported project logical assumption reaching declarations
*transitively*. The assumption itself belongs to a different module, so the
owned intermediate definition and theorem must fail as unknown-axiom carriers.

-/
import Fixtures.Mutations.DirectAxiom

def fixtures_axiom_step : False := fixtures_bad_axiom

theorem fixtures_uses_indirect : False := fixtures_axiom_step
