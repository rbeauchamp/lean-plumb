module

public meta import Lean.Attributes

public meta section

/-! Explicit selection of public declarations that state material normative claims.
Registration identifies the PL5002 presence obligation. It does not certify that all
material claims have been registered, or that their documentation is adequate. -/
namespace Plumb

/-- Lean's persistent tag attribute retains selection across normal module imports. -/
initialize materialClaimAttribute : Lean.TagAttribute ←
  Lean.registerTagAttribute `plumb_material "Marks a declaration as evidence for a material normative claim."

end Plumb
