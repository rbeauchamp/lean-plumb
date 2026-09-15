import StrictLean.Checker.ResultProtocol
/-! Export the actual shared registry. Canonical construction credits con-leche (RuleId). -/
def main : IO Unit :=
  IO.println (StrictLean.RegistryCodec.registryJson StrictLean.Checker.ResultProtocol.producer).compress
