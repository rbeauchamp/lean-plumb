import Plumb.Checker.ResultProtocol
/-! Export the actual shared registry. Canonical construction credits con-leche (RuleId). -/
def main : IO Unit :=
  IO.println (Plumb.RegistryCodec.registryJson Plumb.Checker.ResultProtocol.producer).compress
