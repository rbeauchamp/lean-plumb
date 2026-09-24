# Build-time enforcement example

[build-lint](build-lint/README.md) is the reference Lake integration for the current
build-time enforcement MVP. It is a small adopting project with its own configuration
and proof-required executable contract. The linter implementation lives in
[`lean/Plumb/Checker/`](../lean/Plumb/Checker/).

Start with the [adoption guide](../docs/guides/adoption.md) for package setup and
conformance obligations. The repository's mathematical and application proof surfaces
are described in the [Lean module map](../lean/README.md).

[rule-reference-prototype](rule-reference-prototype/README.md) is the bounded PRODUCT-01 architecture probe: one real policy rule, a native diagnostic, Lake lint dispatch and a generated Verso page. It is not the finished adopter/editor product.

[intent-screening](intent-screening/README.md) holds the calibration configuration, report,
evidence rows and cached service answers for the opt-in
[intent screen](../docs/guides/intent-screening.md), plus a sample screening configuration.
