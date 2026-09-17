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
| `producers` | [Project producer and documentation qualification](engine-producers.md). |
| `history` | [Source-bound replacement history qualification](engine-producers.md). |
| `rule-examples` | [Source-owned corpus and diagnostic demonstrations](rule-examples.md). |

Omitting `PARTITION` requests the `checkerSelftest` campaign; the `producers`, `history` and
`rule-examples` campaigns remain separate explicit selections. Each invocation uses the
same deadline; choose affected checks rather than treating every campaign as a routine
prerequisite. Run `./scripts/verify.sh serialized-graph` only for the separate serialized-graph
claim. See the [verification sequence](../standard/9-compliance-audit.md#repository-verification-sequence)
for evidence requirements. Diagnostics do not replace a failed acceptance run.

CI requires `producers` followed by `history` as separate sequential invocations, each
with its own hard420-second limit. This explicitly permits up to840 seconds for their
combined diagnostics; it is not a pass under the former combined420 contract. Both
suites retain their full controls and order. Ordinary cold420, corpus and site checks
remain separate requirements.


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

## Change an acceptance boundary

Use the [success-owner and API map](policy-acceptance.md) when changing a driver.
Freeze the request and independently discovered census before result collection;
reuse `ResultState.collect`, `finalize` and `AcceptedRun` instead of another transition
or success Boolean. Require accepted evidence in success renderers. Worker packets
carry raw observations and strict request identity; serialized `acceptance` fields
are never proof inputs. Keep file, fresh/incremental project, documentation, optional
graph and classification-only meanings separate. Con-leche's complete indexed assembly
is credited at this boundary; its proofs are not imported.

Trace the actual theorem-to-execution path and preserve all source/admission guards.
An axiom census or theorem-statement reference alone does not establish semantic linkage.
Collection proofs establish universal finite-data guarantees; public positive/refusal/
restored controls qualify the IO boundary. Record commands, exact relevant input identity,
failed attempts and pending gates in the issue evidence rather than inferring coverage
from a few mutations or a worker exit.

## Linter and website development

Follow the [architecture](linter-architecture.md), [comparative design decisions](ecosystem-design.md), [developer experience](developer-experience.md) and [coverage map](rule-coverage.md). A rule change updates its descriptor, actual detector, source fixtures, expected typed diagnostics and explanatory page together. Follow the [attribution scope](design-influences.md): preserve actual code/license notices and cite relevant component-level design influences; examples such as CA1416, Ruff and Pyrefly are not exclusive design mandates. Never replace semantic review with docstring presence or generated-page counts.

The [prototype README](../../examples/rule-reference-prototype/README.md) specifies separate pinned website setup and `python3 examples/rule-reference-prototype/run.py`. This bounded integration check complements the unchanged 420-second acceptance command. Review workflow must inspect rule IDs, exact scopes/modes, source ranges, versioned help routes and generated-source agreement where affected; no extra mandatory benchmark campaign is introduced.

The acceptance transport groups are maintained, capability-triggered diagnostics. Run
all affected groups when worker dispatch, codecs, joins, request reconstruction or
terminal output ownership changes. Their positive/refusal/restoration observations
qualify those IO boundaries; `collect_success_iff` and `finalize_iff` already quantify
universally over supplied finite observations. Do not add the multi-minute groups to
every ordinary acceptance run. Existing CI builds transitively check all proof and
adapter modules; complete ordinary, producer, corpus and site checks remain required.
After fixes, reuse a diagnostic only with an explicit unchanged-relevant-input argument.
