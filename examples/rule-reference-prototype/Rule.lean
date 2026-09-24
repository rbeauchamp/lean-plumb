import Plumb.RegistryCodec
/-! The prototype consumes the product registry. Canonical metadata construction credits
con-leche; pinned sources and the limited experiment scope remain in README.md. -/
namespace RulePrototype
abbrev RuleId := Plumb.RuleId
def rule := Plumb.descriptor .projectAxiom
def helpUrl := Plumb.helpUrl .projectAxiom
end RulePrototype
