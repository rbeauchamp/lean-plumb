# Plumb for Lean

This standard specifies requirements for mathematical proofs and verified functional programs in Lean.

## Overview

The numbered modules define requirements for Lean types, definitions, proofs, and the claims made about them. Begin with [Core Philosophy](0-core-philosophy.md), which explains what kernel-checked evidence establishes and where its guarantees end. [Module 9](9-compliance-audit.md) is the single audit checklist; its rows link to the modules that define each requirement and its rationale. The [adoption guide](../guides/adoption.md) provides setup steps, supported pins, and audit commands.

## Scope

The standard covers dependent types, theorem statements, proofs, axioms, elaboration, modules, namespaces, and Lean computation. It also covers mathematical models, executable definitions, monadic and effectful programs, and metaprograms. Each claimed surface must satisfy the applicable declaration, foundation, and computation rules; the claim kinds in [module 1 §1.3](1-core-principles.md#13-the-specificationmodel-firewall) distinguish what the evidence concerns.

A complete executable component has explicit behavioral proof requirements tied to its actual Lean definitions. Types, proof-bearing constructions, and existing theorems may discharge those requirements. Semantic review must still confirm that the requirements express the intended behavior and cover the actual call paths. A logical foundation label alone does not establish execution correctness. To transfer a result to another formal representation, provide checked correspondence sufficient for that transfer. Applying a result to native execution or an external system retains the stated compiler, runtime, and external assumptions ([module 3 §3.6](3-logic-proof-patterns.md#36-contracts-for-executable-and-effectful-mechanisms), [module 8 §8.5–§8.6](8-tooling-and-machine-audit.md#85-proof-completeness-and-foundation-strength)).

These Lean requirements are intended for systems where correctness is critical. The standard does not certify or guarantee any external system. It does not address development lifecycles, organizational processes, traceability frameworks, CI/CD platforms, supply-chain provenance, releases, risk waivers, or certification schemes.

## Document Structure

| Module | Subject |
| --- | --- |
| [0. Core Philosophy](0-core-philosophy.md) | Kernel-checked claims, assumptions, non-vacuity, and the limits of the evidence. |
| [1. Core Principles](1-core-principles.md) | Representational precision, theorem-backed behavior, mathematical modeling, and claim boundaries. |
| [2. Type Design Patterns](2-type-design-patterns.md) | Semantic types, refined values, phantom tags, and abstract models. |
| [3. Logic and Proof Patterns](3-logic-proof-patterns.md) | Exact contracts, lawful interfaces, proof economy, refinement, and research statements. |
| [4. Mathematical Foundations](4-mathematical-foundations.md) | Numeric representations, mathematical structures, and exact logical foundation profiles. |
| [5. Documentation Standards](5-documentation-standards.md) | Faithful explanations of formal claims and useful declaration and module documentation. |
| [6. Code Organization](6-code-organization.md) | Dependencies, namespaces, imports, visibility, and abstraction boundaries. |
| [7. Performance Best Practices](7-performance-best-practices.md) | Representations, ownership, traversal, proof erasure, and conditional performance guidance. |
| [8. Tooling and Machine Audit](8-tooling-and-machine-audit.md) | Elaboration, declaration and execution coverage, foundation checks, and checker qualification. |
| [9. Compliance and Quality Audit](9-compliance-audit.md) | The single checklist of applicable requirements and their verification. |

[Critical Violations](critical-violations.md) lists issues that require immediate attention. The absence of a listed issue does not establish that a component conforms to the standard.

## Lean Example Convention

Every `lean` fence in this repository’s `docs/` tree follows the checked-example convention. The default `lake exe docFenceAudit` scans the entire tree recursively, including guides. The standard tree (`docs/standard/` here) is normative and must be covered completely; scanning the guides does not make them normative. An explicit `--docs-root` selects another audit tree, so a result must identify the scope it covers.

- **Unmarked `lean` fence:** a positive elaboration example. It must first elaborate exactly as printed, with its own imports and no checker imports or wrappers inserted. The resulting module and its owned logical dependencies first pass completed kernel admission (§8.3); the module is then checked under the declaration policy with the Standard-Logical axiom allowance. Emitted warnings, proof holes, project or unknown axioms, compiler-trusting proof axioms, and forbidden declarations fail this check. The narrowly authenticated recursive-helper exception remains as specified in module 8 §8.4. A narrower foundation claim or an execution-correspondence claim requires separate evidence.
- **`<!-- lean-fail: PATTERN -->` immediately before a `lean` fence:** an expected elaboration failure. The nonempty pattern must be valid, the frontend must complete with source rejection, and one effective-error message must match the entire pattern. The restricted grammar supports `|` alternatives and `.*` between ordered literal fragments; it is not general regular-expression syntax. Unsupported syntax and empty fragments are rejected. The complete grammar and matching rules are in [module 8 §8.7](8-tooling-and-machine-audit.md#87-check-lean-documentation-verbatim).
- **`<!-- lean-trusted-compiler -->` immediately before a `lean` fence:** an example of a compiler-trusting proof mechanism, such as `native_decide`. The example must elaborate warning-free and receive the required compiler-trusting classification. Such examples are not included in conforming positive proof surfaces or in the three logical foundation labels.
- **`text` or another non-Lean fence:** pseudocode, a multi-file sketch, or tool output. It carries no claim that the displayed text elaborates as Lean.

A positive fence result establishes the specified elaboration and declaration checks. It does not prove that the example satisfies its intended specification or every other rule. A valid Lean program may illustrate a semantic defect; the explanation must identify that defect. Use a negative fence when claiming that Lean rejects the printed code for the stated diagnostic.

Malformed or orphaned markers, invalid diagnostic patterns, misplaced or multiple markers, and unclosed fences fail the audit. The exact scanner requirements are in [module 8 §8.7](8-tooling-and-machine-audit.md#87-check-lean-documentation-verbatim). `lean/Audit/` contains checked definitions and proofs supporting representative claims; `lean/Fixtures/` contains isolated controls and mutations. Their evidence scope is specified in [module 8](8-tooling-and-machine-audit.md).

## Quick Start

1. Read [Core Philosophy](0-core-philosophy.md) for the meaning and limits of the evidence.
2. Use [Critical Violations](critical-violations.md) for initial triage.
3. Read the chapters applicable to the claims you are making and complete [the audit matrix](9-compliance-audit.md). Checker results do not replace its semantic review obligations.
4. Follow the [adoption guide](../guides/adoption.md) to configure and run the checker in your project.

## Requirement Keywords

Throughout this standard, uppercase requirement keywords carry the meanings defined in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.html):

- **MUST / REQUIRED / SHALL:** a condition that conformance requires.
- **MUST NOT / SHALL NOT:** a prohibited condition or action.
- **SHOULD / RECOMMENDED:** the expected choice; departing from it needs a valid technical reason and consideration of the consequences.
- **SHOULD NOT / NOT RECOMMENDED:** a choice to avoid unless a valid technical reason and consideration of the consequences support it.
- **MAY / OPTIONAL:** a choice the standard permits. When an optional claim is made, its applicable requirements must still be met.

Formal Lean statements claimed as conforming SHALL elaborate on the declared toolchain. Their explanations SHALL preserve the quantifiers, assumptions, conclusions, and relevant definitions without strengthening the result ([module 5 §5.2](5-documentation-standards.md#52-faithful-explanation-of-formal-claims)). Kernel acceptance and fidelity to the intended claim are distinct obligations. Elaborating a `Prop`-valued definition establishes its statement, not a proof of that proposition. Every material result presented as established requires the checked evidence specified in module 0.

## Mathlib Reuse and Foundation Profiles

Mathematical concepts MUST use or extend Mathlib’s canonical definitions where they fit the intended concept. Custom definitions require a precise statement and an explanation of why no existing definition fits. [Module 1 §1.4](1-core-principles.md#14-principled-mathematical-modeling) defines this rule and its rationale; it does not require domain concepts to belong in Mathlib.

Library reuse and logical foundation strength are separate questions. [Module 4 §4.5](4-mathematical-foundations.md#45-foundation-strength-kernel-only-choice-free-standard-logical) defines Kernel-only, Choice-Free, and Standard-Logical by their permitted axiom sets. The label comes from a declaration’s exact transitive dependencies, not from its library or tactic name, and does not rank overall software assurance. For an admissible set, the actual label is the least containing profile; the selected surface profile is an allowed maximum. Forbidden and compiler-trusting axioms remain excluded from conforming positive proofs.
