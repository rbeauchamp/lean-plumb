/-! Mutually inductive propositions and their constructors/recursors must
survive checked admission as one dependency group. -/
mutual
  inductive AdmissionEven : Nat → Prop where
    | zero : AdmissionEven 0
    | step : AdmissionOdd n → AdmissionEven (n + 1)
  inductive AdmissionOdd : Nat → Prop where
    | step : AdmissionEven n → AdmissionOdd (n + 1)
end

theorem admission_mutual_inhabited : AdmissionOdd 1 :=
  .step .zero
