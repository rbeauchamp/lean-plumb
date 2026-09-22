import StrictLean.Checker.AxiomGate

/-! User-facing `axiomGate` executable root. Its only behavior is
`AxiomGate.entry`; it never installs injected Git facts. -/

unsafe def main (args : List String) : IO UInt32 :=
  StrictLean.Checker.AxiomGate.entry args
