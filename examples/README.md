# Adopter examples

[build-lint](build-lint/README.md) is the reference `lakefile.lean` integration: `lake lint`
and the enforcing ordinary `lake build`, with its own configuration and proof-required
executable contract. [lake-lint-toml](lake-lint-toml/README.md) is the `lakefile.toml`
integration: `lake lint` plus live editor diagnostics from `import Plumb.Linter`. The linter implementation lives in
[`lean/Plumb/Checker/`](../lean/Plumb/Checker/).

Start with the [adoption guide](../docs/guides/adoption.md) for package setup and
conformance obligations. The repository's mathematical and application proof surfaces
are described in the [Lean module map](../lean/README.md).

[intent-screening](intent-screening/README.md) holds the calibration configuration, report,
evidence rows and cached service answers for the opt-in
[intent screen](../docs/guides/intent-screening.md), plus a sample screening configuration.

The checked violating and corrected sources shown on the [rule reference](https://rbeauchamp.github.io/lean-plumb/dev/rules/) live in [rules](rules/README.md); they are qualification fixtures, not adopter projects.
