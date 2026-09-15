import StrictLean.RegistryCodec
/-! The prototype consumes the product registry. Canonical metadata construction credits
con-leche; pinned sources and the limited experiment scope remain in README.md. -/
namespace RulePrototype
abbrev RuleId := StrictLean.RuleId
def rule := StrictLean.descriptor .projectAxiom
def helpUrl := StrictLean.helpUrl .projectAxiom
end RulePrototype
