# 0. Core Philosophy: Precise Claims and Kernel-Checked Evidence

**Fundamental Principle**: Every property presented as established and material to a Lean development's correctness or purpose MUST be expressed as a precise type or proposition and supported by a kernel-checked term. The evidence MUST establish the exact claim, including any required non-vacuity, without proof holes or project logical axioms. Assumptions and transitive axiom dependencies MUST be explicit. The checked term establishes that formal claim under its explicit assumptions and the axioms on which it depends, directly or indirectly.

In practice:

- Support documented laws with kernel-checked proofs and checks that reject proof holes and forbidden axioms.
- Support invariant claims with proof-bearing return types or exact admission and preservation proofs.
- For each pattern, identify the precise claimed property and show how its type encoding or supporting theorem establishes that property.

This standard distinguishes three components of Lean:

- The **elaborator** converts source code into terms and checks their types.
- The **kernel** checks elaborated types, definitions, and proof terms against Lean's core type theory.
- The **compiler** generates executable code.

Compilation alone does not establish that execution preserves the proved properties. Claims about compiled behavior MUST identify the associated trust assumptions ([module 3 §3.6](3-logic-proof-patterns.md#36-contracts-for-executable-and-effectful-mechanisms), [module 8 §8.6](8-tooling-and-machine-audit.md#86-classify-lean-computation-mechanisms-exactly)).

Kernel acceptance alone does not establish conformance: Lean permits axioms and proof placeholders such as `sorry`. The standard's declaration and axiom checks reject proof holes and forbidden axioms ([module 8 §8.5](8-tooling-and-machine-audit.md#85-proof-completeness-and-foundation-strength)).

## The Role of Testing

Testing has a limited, subordinate role in this standard. Counterexample searches can identify false candidate properties; passing samples do not establish universal claims.

- Property-based testing (see module 3 §3.2.2) is an optional aid when a statement's truth is uncertain. Counterexample search helps reject false candidate statements and correct misformulated theorems before substantial proof effort. Testing may occur before, during, or after proof development; no authoring sequence is required.
- During an audit, test results neither establish theorems nor become logical dependencies reported by `#print axioms`. Mutation tests may show that a checker rejects specific invalid inputs. Those observations do not prove the Lean property under audit.

Refutation depends on the statement's quantifiers and domain. One checked counterexample can refute a universal statement. Refuting an existential statement requires showing that no candidate satisfies it. For asymptotic claims, a violation at one input need not refute the eventual bound.

Sampled testing does not replace these proof obligations. A decision procedure that produces a kernel-checked proof, including by exhaustive reasoning over a finite domain, supplies proof evidence rather than merely sampled agreement.

## Why This Matters

1. **Proofs establish the stated properties of the Lean definitions they concern.** A correspondence between an abstract model and an executable Lean definition can be stated as a Lean proposition when both are represented in Lean. A checked proof establishes that correspondence under its stated hypotheses ([module 1 §1.3](1-core-principles.md#13-the-specificationmodel-firewall), [module 2 §2.4](2-type-design-patterns.md#24-abstract-mathematical-models)). Transferring a result from one formal object to another requires a checked relation strong enough to support that result. A Lean proof alone cannot establish that an external physical system behaves as its formal representation claims. Claims about external execution retain their stated trust boundary ([module 1 §1.6](1-core-principles.md#16-claim-boundaries-and-automated-checking)).
2. **Logical assurance depends on the trusted kernel and the result's transitive axiom dependencies.** Definitions determine the objects and properties to which the result applies. Kernel checking does not establish whether those definitions adequately express the intended claim. Each declaration on a conforming surface has the least permissive actual foundation label containing its exact transitive axiom set; the selected surface profile is an allowed maximum. These profiles are defined in [module 4 §4.5](4-mathematical-foundations.md#45-foundation-strength-kernel-only-choice-free-standard-logical). Auditing these dependencies is part of compliance ([module 8](8-tooling-and-machine-audit.md), [module 9](9-compliance-audit.md)).

## How to Apply This Philosophy

Identify the Lean definition to which each claim applies ([module 1](1-core-principles.md), [module 6](6-code-organization.md)), then assess whether its type or supporting theorem establishes the intended property ([module 2](2-type-design-patterns.md)). Check the assumptions, transitive axiom dependencies, and any required non-vacuity evidence. These are audit obligations, not a prescribed development sequence.

## The Necessary Dual: Non-Vacuity

Kernel checking establishes the formal statement under its dependencies; it does not establish that the statement captures the intended claim.

`theorem safe : True := trivial` elaborates, but proves no specific safety property. An implication with an impossible antecedent or a universal statement over an empty domain can likewise have a valid proof without establishing the intended existence or behavior. A checked statement is only as strong as what it says.

Non-vacuity evidence MUST match the intended claim at exactly the required strength:

- To show a constrained type is *inhabited at all*, provide a proof of `Nonempty` or an `Inhabited` instance. `Nonempty α` suffices for an existence claim. `Inhabited α` supplies a designated element, but an executable construction claim additionally requires that the element’s definition be computable. Reuse an existing witness where possible; it needs no separate artifact. An initialization or construction function supplies a witness when applied to available inputs whose preconditions have been established. A function requiring unavailable inputs does not by itself establish inhabitance.
- To show several hypotheses are *jointly satisfiable*, provide values and proofs satisfying all of them together, or prove that such values exist.
- To show a state is *reachable* under a transition relation, prove the reachability statement. Reachability of some state implies the state type is inhabited (universally, `(∃ s : S, Reachable s) → Nonempty S`); inhabitance alone does not establish reachability under the specified relation.

The non-vacuity requirement is proportional to the intended claim:

- An *intentionally empty* exclusion type is legitimate when its emptiness expresses the intended exclusion. The absence of inhabitants is the intended result, not a vacuity defect. Do not require an inhabitant of a type whose emptiness is the claim.
- Prefer proof-bearing immutable values for invariants of every admitted value. If a raw representation is justified, verify that admission establishes the invariant and every write preserves it ([module 1 §1.1](1-core-principles.md#11-the-principle-of-representational-precision)). These guarantees differ: `∀ s, I s → I (step s)` proves conditional preservation, not that every raw `s` satisfies `I` or that any `s` is reachable.
- Claims about reachability, transitions, histories, or resource use need proofs of those properties, including initialization, preservation, and composition where the claim requires them. A subtype's proof establishes its predicate for that value. Any claimed functional behavior or use of the latest state needs evidence; it does not follow merely from using a subtype. You can still copy an older valid value.
- A deliberately conditional theorem `H → C` claims an implication; it does not claim that `H` holds. A contradiction argument or minimal-counterexample lemma may likewise reason from hypotheses without asserting their satisfiability. Such statements are not rejected merely because no inhabitant of a hypothesis is known. An unconditional existence, admitted-state, or reachability claim still requires its witness or proof. An open question may be stated as a `Prop`-valued definition that nothing claims to prove ([module 3 §3.10](3-logic-proof-patterns.md#310-research-statements-adequacy-conditional-completeness-and-open-targets)).

```lean
import Mathlib.Data.Nat.Notation

/-- This witness establishes that the refined type is inhabited.
    It does not establish reachability or a program-behavior property. -/
example : Nonempty {n : ℕ // n % 2 = 0} := ⟨⟨4, by omega⟩⟩
```

## Further Reading

- Proof patterns and contracts: [module 3](3-logic-proof-patterns.md)
- Mathematical foundations via Mathlib: [module 4](4-mathematical-foundations.md)
- Human-facing documentation: [module 5](5-documentation-standards.md)
- Repository layout and tooling: [module 8](8-tooling-and-machine-audit.md)
- Compliance scorecard and audit procedure: [module 9](9-compliance-audit.md)
