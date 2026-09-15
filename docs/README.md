# Documentation

The [Strict Lean](standard/README.md) defines the rules for mathematical proofs
and verified functional programs in Lean. The [guides](#practical-guides)
explain how to use and maintain this repository without adding conformance rules.

## Read the standard

Start with the [core philosophy](standard/0-core-philosophy.md), then choose a route:

- **Understand the rules:** use the [chapter index](standard/README.md#document-structure).
- **Review a Lean project:** read [critical violations](standard/critical-violations.md),
  then complete the [compliance checklist](standard/9-compliance-audit.md).
- **Understand the checker:** read [tooling and machine audit](standard/8-tooling-and-machine-audit.md),
  then follow the [Lean module map](../lean/README.md) into the implementation.

## Practical guides

- [Adopt the standard](guides/adoption.md): package setup, surfaces, profiles, commands,
  diagnostics, and the semantic obligations commands cannot establish.
- [Work on this repository](guides/contributing.md): artifact locations, development,
  verification, and review.

Every Lean fence anywhere below `docs/` follows the
[checked example convention](standard/README.md#lean-example-convention), including
fences in guides. A guide's location does not exempt its teaching examples from checking.

Return to the [project overview](../README.md).

- [Linter and website architecture](guides/linter-architecture.md): selected interfaces, pins, versioned help links and delivery sequence.
- [Rule registry and diagnostics](guides/rule-registry.md): implemented typed interfaces, output migration, source conventions and qualification.
- [Complete rule coverage](guides/rule-coverage.md): twenty selected diagnostics and all residual checklist obligations.

- [Policy acceptance contract](guides/policy-acceptance.md): exact scope, complete results, pure proof boundary and migration.

- [Ecosystem research and design](guides/ecosystem-design.md): evidence from Lean and other language tools, alternatives and selected architecture.
- [Developer experience](guides/developer-experience.md): planned native workflows, diagnostics, configuration and website interactions.

- [Design influences and attribution](guides/design-influences.md): actual reuse, specific inspiration, optional external checking and project scope.
