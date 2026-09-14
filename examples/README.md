# Build-time enforcement example

[build-lint](build-lint/README.md) is the reference Lake integration for the current
build-time enforcement MVP. It is a small adopting project with its own configuration
and proof-required executable contract. The linter implementation lives in
[`lean/StrictLean/Checker/`](../lean/StrictLean/Checker/).

Start with the [adoption guide](../docs/guides/adoption.md) for package setup and
conformance obligations. The repository's mathematical and application proof surfaces
are described in the [Lean module map](../lean/README.md).
