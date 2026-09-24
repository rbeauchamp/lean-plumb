import Plumb.Checker.Lint

/-! User-facing `lint` executable root, the Lake lint driver. -/

unsafe def main (args : List String) : IO UInt32 :=
  Plumb.Checker.Lint.run args
