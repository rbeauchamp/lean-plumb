# `lakefile.toml` lint and editor example

A minimal Core-only adopter in `lakefile.toml` format. It shows the two ordinary entry
points of Plumb:

- **`lake lint`**: `lintDriver = "plumb/lint"` runs the project audit over every
  manifested surface (here the `Gadget` library, choice-free, `report` execution).
- **Editor feedback**: `Gadget/Double.lean` imports `Plumb.Linter`, so VS Code with the
  Lean 4 extension shows `Plumb.PL…` warnings at their declaration ranges, with a
  **View explanation** link in the infoview and the rule URL in the message text.

From this directory:

```sh
MATHLIB_NO_CACHE_ON_UPDATE=1 lake update
lake lint
```

To use it elsewhere, replace `path = "../.."` with the git form in the
[adoption guide](../../docs/guides/adoption.md#1-require-the-checker-package).
`lakefile.toml` cannot declare the custom `policy` target of
[build-lint](../build-lint/README.md), so `lake build` here is an ordinary build, not
enforcement. Use `lake lint` locally and in CI.

A live finding is a compiler warning in the editor and in a plain `lake build`. `lake lint`
builds with `linter.plumb` off and reports the same rule as a policy violation
(`VIOLATION`, exit 1), also after a plain `lake build` cached the module with the warning.
Disabling live feedback with `set_option linter.plumb false` does not waive the project
check: `lake lint` still reports the violation (exit 1).
`lake exe checkerSelftest --build-bound --partition lint-driver` qualifies both behaviors.
The editor journeys are recorded in
[session/evidence/issue-14-editor-journeys.md](../../session/evidence/issue-14-editor-journeys.md).
