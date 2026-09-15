module

public meta import Lean.Attributes

public meta section

/-! Explicit selection of public declarations that state material normative claims.
Registration identifies the SL5002 presence obligation. It does not certify that all
material claims have been registered, or that their documentation is adequate. -/
namespace StrictLean

/-- Lean's persistent tag attribute retains selection across normal module imports. -/
initialize materialClaimAttribute : Lean.TagAttribute ←
  Lean.registerTagAttribute `strict_lean_material "Marks a declaration as evidence for a material normative claim."

end StrictLean
