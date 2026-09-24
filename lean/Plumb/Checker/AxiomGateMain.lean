import Plumb.Checker.AxiomGate

/-! User-facing `axiomGate` executable root. Its only behavior is
`AxiomGate.entry`; it never installs injected Git facts. -/

unsafe def main (args : List String) : IO UInt32 :=
  Plumb.Checker.AxiomGate.entry args
