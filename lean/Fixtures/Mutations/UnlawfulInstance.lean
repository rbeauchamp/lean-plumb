/-
Negative fixture: the operation alone is insufficient to instantiate a lawful
interface. Lean must report the omitted proof-requiring law field.
-/
class FixturesLawful (α : Type) where
  op : α → α
  law : ∀ x, op x = x

instance : FixturesLawful Nat where
  op := Nat.succ
