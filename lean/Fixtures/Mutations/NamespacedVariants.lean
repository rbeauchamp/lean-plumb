/-
Mutation: source-format variants. A deeply namespaced, `protected`,
attribute-carrying, multi-line theorem with a hole — all spellings the old
`^theorem (\w+)` regex missed. Discovery here is semantic: the environment
contains the declaration wherever it is written.

-/
namespace Fixtures.Deep.Nested

@[simp]
protected
theorem
  fixtures_variant_sorry :
    False := by
      sorry

end Fixtures.Deep.Nested
