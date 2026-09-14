# Strict Lean

A strict standard for Lean projects that requires correctness guarantees to be stated precisely in types or propositions and supported by kernel-checked evidence.

The normative product is the [standard](docs/standard/README.md). Its scope is Lean: dependent types, theorem statements, proofs, foundations, elaboration, modules, and executable Lean code. It serves both mathematical research and application development, with explicit assumptions and execution boundaries.

## Community review

**Public review draft.** We invite the Lean community to challenge the rules, examples,
and checker behavior.

Please [open an issue](https://github.com/rbeauchamp/strict-lean/issues) with
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

| Component | Pin | Source of truth |
| --- | --- | --- |
| Lean | `leanprover/lean4:v4.33.1` | [lean-toolchain](lean-toolchain) |
| Mathlib | `0df444a360eaa60ab8c11dca51a86af692955474` | [lake-manifest.json](lake-manifest.json) |

Only this Lean release is supported. The checker imports no Mathlib modules; Mathlib is used by the standard's mathematical examples. See the [adoption guide](docs/guides/adoption.md) for dependency resolution and the [contributor guide](docs/guides/contributing.md#develop-and-verify) for build commands.

## Verification

Run `./scripts/verify.sh` for complete local checks under a hard seven-minute
deadline, including cold root-package builds. CI runs the same command after
restoring or provisioning pinned toolchain and dependency caches. See the
[contributor guide](docs/guides/contributing.md#develop-and-verify) for setup and
focused diagnostics.

## License

[MIT](LICENSE).
