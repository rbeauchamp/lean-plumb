import Init

/-- Count matching inputs with structurally decreasing tail recursion. -/
def countMatching (predicate : Nat → Bool) (xs : List Nat) : Nat :=
  go xs 0
where
  go : List Nat → Nat → Nat
    | [], count => count
    | x :: rest, count =>
        go rest (if predicate x then count + 1 else count)
