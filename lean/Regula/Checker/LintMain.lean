import Regula.Checker.Lint

/-! User-facing `lint` executable root, the Lake lint driver. -/

unsafe def main (args : List String) : IO UInt32 :=
  Regula.Checker.Lint.run args
