/-
Negative fixture for the semantic distinction between nominal `Time` and the
canonical `ResourceAmount` alias. Direct cross-use must fail by type mismatch.
-/
import Audit.DocPrelude

def fixtures_consume (_amount : Glossary.ResourceAmount) : Unit := ()

def fixtures_wrong_domain (t : Glossary.Time) : Unit := fixtures_consume t
