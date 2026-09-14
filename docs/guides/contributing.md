# Work on this repository

This guide describes this repository's layout and development commands. The
[standard](../standard/README.md) defines conformance; these instructions do not
prescribe a directory layout for other Lean projects. Read the current
[repository instructions](../../AGENTS.md) before changing the project.

## Find the relevant artifact

- **Rules and teaching:** [standard chapters](../standard/README.md).
- **Contracts, examples, and checker internals:** [Lean module map](../../lean/README.md).
- **Standalone consumers:** [example projects](../../examples/README.md).

The root `lakefile.lean` sets the package source directory to `lean/`. Module
names and imports remain independent of that physical prefix: for example,
`lean/Audit/Research.lean` is still `Audit.Research`. Run Lake commands from the
repository root. Lake's elaborated library and executable inventory owns source
discovery; directory names alone do not establish audit ownership.

## Develop and verify

Provision [elan](https://github.com/leanprover/elan), the pinned toolchain,
Mathlib artifacts (`lake exe cache get`), GNU coreutils timeout, and ShellCheck
before verification. On macOS, `brew install coreutils shellcheck` supplies the
last two tools. Verification runs offline against those pinned dependencies.

```sh
lake build                         # incremental development check
./scripts/verify.sh                 # complete local acceptance command
./scripts/verify.sh diagnostics fixtures # focused diagnostic qualification
```

The acceptance command builds its checker executables, type-checks the diagnostic
modules, audits the claimed Lean surfaces from fresh output, and checks every Lean
example under `docs/`. It has a hard seven-minute limit;
a timeout is an incomplete run, not acceptance. Provisioning happens before that limit.
CI runs the same command after restoring or provisioning pinned dependency caches.

[AGENTS.md](../../AGENTS.md#changes-and-verification) owns verification and merge policy.
The [CI workflow](../../.github/workflows/ci.yml) defines runner and cache configuration.
Reuse evidence when its relevant inputs and claims remain unchanged; instruction-only
changes need scoped review rather than another Lean run.

### Choose focused diagnostics

Use `./scripts/verify.sh diagnostics PARTITION` when changes affect the corresponding
checker behavior:

| Partition | Focus |
| --- | --- |
| `fixtures` | Positive controls and intentionally invalid Lean declarations. |
| `structural` | Surface discovery, ownership, contamination, and required application contracts. |
| `cli` | Command-line behavior and diagnostics. |
| `environments` | Isolated environments, documentation scanning, and external adopters. |
| `build-policy` | Enforcement through the example's ordinary Lake build. |

Omitting `PARTITION` requests the complete diagnostic campaign. Each invocation uses the
same deadline; choose affected checks rather than treating every campaign as a routine
prerequisite. Run `./scripts/verify.sh serialized-graph` only for the separate serialized-graph
claim. See the [verification sequence](../standard/9-compliance-audit.md#repository-verification-sequence)
for evidence requirements. Diagnostics do not replace a failed acceptance run.


## Change prose and code together

Keep a teaching example beside the prose when it helps readers. Every Lean fence
under `docs/`, including this guides directory, follows the
[checked fence convention](../standard/README.md#lean-example-convention).
Link to the actual Lean module for larger definitions and proofs; do not copy an
implementation merely to mirror the chapter structure.

For review, use the repository-local
[review toolkit](../../.agents/skills/pr-review-toolkit/SKILL.md) and the applicable
[compliance checklist](../standard/9-compliance-audit.md). Scope verification to
the affected claims, retain required checks, and distinguish historical results
from evidence for the current revision.
