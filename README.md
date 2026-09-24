# Plumb for Lean

A strict linter and correctness standard for Lean.

Plumb pairs a Lean linter and linked rule-reference website with a standard requiring precise types, propositions, and kernel-checked evidence.

The [standard](docs/standard/README.md) defines normative meaning. The current checker enforces declaration, foundation, execution-boundary, and checked-example requirements; the [product architecture](docs/guides/linter-architecture.md) specifies the typed rule catalogue, editor integration, and GitHub Pages website being built. The website and complete editor integration are not yet published. Its scope is Lean: dependent types, theorem statements, proofs, foundations, elaboration, modules, and executable Lean code. It serves both mathematical research and application development, with explicit assumptions and execution boundaries.

## Community review

**Public review draft.** We invite the Lean community to challenge the rules, examples,
and checker behavior.

Please [open an issue](https://github.com/rbeauchamp/lean-plumb/issues) with
unclear or unnecessarily restrictive requirements, incorrect Lean claims, checker false
positives or omissions, or adoption difficulties. Cite the relevant section and include
a small Lean example and toolchain version where useful. Feedback should help establish
which requirements are sound, useful, and practical for real Lean projects.

## Start here

- **Read the standard:** begin with the [core philosophy](docs/standard/0-core-philosophy.md), then use the [document map](docs/README.md) to find the relevant rules.
- **Use it in a project:** follow the [adoption guide](docs/guides/adoption.md) and the [standalone examples](examples/README.md).
- **Inspect or improve it:** explore the [Lean module map](lean/README.md) and the [contributor guide](docs/guides/contributing.md).

Conformance means satisfying every applicable row of the [compliance checklist](docs/standard/9-compliance-audit.md). A passing checker command establishes its stated property; semantic review still determines whether the theorems express the intended claims and complete contracts.

## Repository map

| Area | Purpose |
| --- | --- |
| [docs/](docs/README.md) | Normative standard and practical guides. |
| [lean/](lean/README.md) | Contracts, checked examples, checkers, and isolated qualification fixtures. |
| [examples/](examples/README.md) | Self-contained adopting projects, each with its own README and Lake configuration. |

Root configuration files keep this a directly usable Lake package. Tool-owned hidden directories stay in their expected locations; build output and temporary probes are not maintained content areas.

## Supported toolchain

| Component | Authoritative pin |
| --- | --- |
| Lean | [lean-toolchain](lean-toolchain) |
| Mathlib | The `mathlib` entry in [lake-manifest.json](lake-manifest.json) |

Only the pinned Lean release is supported. The checker imports no Mathlib modules; Mathlib is used by the standard's mathematical examples. See the [adoption guide](docs/guides/adoption.md) for dependency resolution and the [contributor guide](docs/guides/contributing.md#develop-and-verify) for build commands.

## Verification

Run `./scripts/verify.sh` for complete local checks under a hard seven-minute
deadline, including cold root-package builds. CI runs the same command after
restoring or provisioning pinned toolchain and dependency caches. See the
[contributor guide](docs/guides/contributing.md#develop-and-verify) for setup and
focused diagnostics.

## License

[MIT](LICENSE).
