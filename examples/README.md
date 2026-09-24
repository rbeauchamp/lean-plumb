# Adopter examples

[build-lint](build-lint/README.md) is the reference `lakefile.lean` integration: `lake lint`
and the enforcing ordinary `lake build`, with its own configuration and proof-required
executable contract. [lake-lint-toml](lake-lint-toml/README.md) is the `lakefile.toml`
integration: `lake lint` plus live editor diagnostics from `import Plumb.Linter`. The linter implementation lives in
[`lean/Plumb/Checker/`](../lean/Plumb/Checker/).

Start with the [adoption guide](../docs/guides/adoption.md) for package setup and
conformance obligations. The repository's mathematical and application proof surfaces
are described in the [Lean module map](../lean/README.md).

[rule-reference-prototype](rule-reference-prototype/README.md) is the bounded PRODUCT-01 architecture probe: one real policy rule, a native diagnostic, Lake lint dispatch and a generated Verso page. The adopter examples above supersede its dispatch evidence.
