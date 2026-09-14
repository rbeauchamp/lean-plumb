import Init

/-- Sum accepted words; specialization may exploit the fixed predicate. -/
@[specialize] def sumAccepted (accept : UInt64 → Bool)
    (xs : List UInt64) (acc : UInt64) : UInt64 :=
  match xs with
  | [] => acc
  | x :: rest =>
      sumAccepted accept rest (if accept x then acc + x else acc)
