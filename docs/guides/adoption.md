# Adopt the standard

To adopt the [standard](../standard/README.md), identify the correctness claims your
project presents as established, express them precisely in types or propositions, and
supply kernel-checked evidence. Review whether those statements capture the intended
claims, including their assumptions and execution boundaries. Conformance requires every
applicable row of the [compliance checklist](../standard/9-compliance-audit.md); the
checker supports that review by checking the mechanical requirements.

The steps below cover checker setup and the semantic review needed for a conformance
claim. Use the [supported toolchain](../../README.md#supported-toolchain).

This is the ordinary path from an existing Lean project to a conformance claim. It uses
your project's own layout, module names, and lakefile format; nothing named `Audit`,
`Fixtures`, or `tmp` from this repository is required. The normative definitions behind
each step are in [docs/standard/8 §8.11](../standard/8-tooling-and-machine-audit.md#811-adopting-the-checker-in-another-project).

## 1. Require the checker package

The repository is named `strict-lean`, the Lake package is `strict_lean`, and
imports use `StrictLean.*`.
Use the repository URL below with those package and module identifiers.

Pin the package to an exact revision. A git dependency and a local path resolve through the
same Lake workspace discovery; use whichever your project already uses for dependencies.

`lakefile.lean`:

```text
require «strict_lean» from git
  "https://github.com/rbeauchamp/strict-lean" @ "<exact commit>"
```

`lakefile.toml`:

```toml
[[require]]
name = "strict_lean"
git = "https://github.com/rbeauchamp/strict-lean"
rev = "<exact commit>"
```

Your `lean-toolchain` must match the checker's pin above. The checker's transitive
`require`s (Mathlib) resolve into your `lake-manifest.json` as usual but are compiled only
if your own code imports them.

## 2. Declare the claimed surface

Conformance is claimed per Lake library or executable, and the checker discovers modules
through Lake's elaborated inventory, not through your umbrella import or a file list
([docs/standard/8 §8.2](../standard/8-tooling-and-machine-audit.md#82-define-surfaces-through-lake-semantics)).
Give every claimed library a glob that covers its intended modules:

- `lakefile.lean`: ``globs := #[.andSubmodules `Widget]``
- `lakefile.toml`: `globs = ["Widget", "Widget.+"]` (`"Widget.+"` alone omits `Widget`
  itself)

A module inside the glob that your umbrella does not import is still part of the surface
and is still inspected. A `lakefile.toml` also needs `defaultTargets` for a bare
`lake build` to build anything; the gate builds the claimed surface explicitly either way.
For a runnable Core-only project using the enforcing ordinary-build integration, see
[`examples/build-lint/`](../../examples/build-lint/).

## 3. Choose foundation profiles and execution mode

Write `foundation_manifest.json` at your project root classifying every root-package
`lean_lib` and `lean_exe`. Empty exclusion arrays are valid when nothing is excluded:

```json
{
  "schema-version": 2,
  "surfaces": [
    { "library": "Widget", "executables": ["widget_tool"], "claim": "choice-free",
      "execution": "report", "rationale": "..." }
  ],
  "excluded-libraries": [],
  "excluded-executables": []
}
```

`claim` is the strongest foundation any declaration on the surface may use
([docs/standard/4 §4.5](../standard/4-mathematical-foundations.md#45-foundation-strength-kernel-only-choice-free-standard-logical)):

| Profile | Permitted transitive axioms |
| --- | --- |
| `kernel-only` | none |
| `choice-free` | `propext`, `Quot.sound` |
| `standard-logical` | `propext`, `Quot.sound`, `Classical.choice` |

Every declaration is labeled from its own exact axiom set and must fit the claim. Label
from the report, not from the kind of surface. For example, `def main : IO Unit := pure ()`
depends on no axiom. Neither an `IO` type nor recursion alone determines a declaration's
foundation profile; inspect its actual transitive dependencies. Compiler-trusting axioms
(for example from `native_decide`) never fit any profile and are reported separately.

`execution` states what you claim about compiled code
([docs/standard/8 §8.6](../standard/8-tooling-and-machine-audit.md#86-classify-lean-computation-mechanisms-exactly)):

| Mode | Meaning |
| --- | --- |
| `report` (default) | Every execution boundary reached from an owned executable root is reported with its kind and correspondence state; trusted boundaries are recorded, not failed. |
| `checked` | Additionally fails on any trusted boundary other than the toolchain's own native-runtime primitives. |

In both modes an unresolved path blocks the execution claim. Native arithmetic and the
Lean runtime remain trusted in every mode; the checker verifies Lean source, not the
compiler or the machine.

## 4. Run the ordinary conformance check

From your project root, or with `--project DIR`:

```sh
lake exe axiomGate --json-out tmp/axiom-report.json
```

The gate copies your project into an isolated temporary directory under your `tmp/`,
shares your pinned dependency checkouts, builds the claimed surface from empty output with
warnings as errors, inspects the elaborated environment, and removes the copy. The JSON
report holds every owned declaration with its exact transitive axiom set and every
execution root with its boundaries. The verdict is the printed transcript and the exit
status: each declaration failure is printed with its reason and that declaration's label,
the run ends with `axiom gate: PASS` (exit 0) or `FAIL: N violation(s)` (exit 1), and
`--verbose` prints every declaration's label.

Two narrower commands are useful before a full run:

```sh
lake exe axiomGate --file F.lean --claim standard-logical   # audit one file under this profile
lake exe docFenceAudit --jobs 4                            # elaborate every docs/ Lean fence
```

`docFenceAudit` applies when your project keeps Lean teaching examples in Markdown under
`docs/` using the [fence convention](../standard/README.md#lean-example-convention).

## 5. Read a failure

Each failing declaration or root carries one reason. The reason names the Lean fact, not a
style preference:

| Reason | Meaning | Where the rule lives |
| --- | --- | --- |
| `project-axiom` | An owned `axiom` declaration outside Lean's foundation. Make the assumption a binder or proof-bearing field. | [docs/standard/3 §3.4](../standard/3-logic-proof-patterns.md#34-foundation-strength-axioms-are-reported-never-assumed) |
| `hole` | The declaration depends on `sorryAx` (`sorry`, `admit`, or an unfinished tactic). | [docs/standard/3 §3.4](../standard/3-logic-proof-patterns.md#34-foundation-strength-axioms-are-reported-never-assumed) |
| `unknown-axiom` | A transitive axiom outside `propext`, `Quot.sound`, `Classical.choice` other than `sorryAx` and the compiler-trusting axioms, which have their own reasons. | [docs/standard/4 §4.5](../standard/4-mathematical-foundations.md#45-foundation-strength-kernel-only-choice-free-standard-logical) |
| `label-exceeds-claim` | The declaration's exact label is stronger than the surface's `claim`. Prove the same statement using fewer axioms, or explicitly revise the permitted foundation profile and its rationale. | [docs/standard/4 §4.5](../standard/4-mathematical-foundations.md#45-foundation-strength-kernel-only-choice-free-standard-logical) |
| `compiler-trusting` | A native-evaluation proof axiom (for example `native_decide`) on a positive surface. | [docs/standard/8 §8.5](../standard/8-tooling-and-machine-audit.md#85-proof-completeness-and-foundation-strength) |
| `escape-hatch` | An authored `partial` or `unsafe` declaration on a positive surface. | [docs/standard/8 §8.6](../standard/8-tooling-and-machine-audit.md#86-classify-lean-computation-mechanisms-exactly) |
| `executable-contract` | An `ExecutableContract` registration is not closed, does not name a complete implementation constant, or names an ineligible implementation: missing, noncomputable, unsafe, partial, proposition-valued, type-producing, or not an executable definition. The Lean type checker separately checks the supplied proof against the registered predicate. | [docs/standard/8 §8.12](../standard/8-tooling-and-machine-audit.md#812-opt-in-enforcing-build-linter) |
| `execution-unresolved` | A compiled path whose replacement, `extern`, or unsafe target cannot be classified. Blocks the execution claim in every mode. | [docs/standard/8 §8.6](../standard/8-tooling-and-machine-audit.md#86-classify-lean-computation-mechanisms-exactly) |
| `execution-trusted-boundary` | A runtime replacement or `extern` boundary without kernel-checked correspondence on a surface claiming `checked` execution. | [docs/standard/8 §8.6](../standard/8-tooling-and-machine-audit.md#86-classify-lean-computation-mechanisms-exactly) |

Surface-level failures name the Lake fact. `build-failed` means the claimed surface did not
elaborate warning-free from empty output (a zero exit with a warning still fails);
`manifest-incomplete` means a root library or executable is neither claimed nor excluded,
an excluded name is not a root target, or a required name or rationale is missing or
malformed; a claimed surface library or executable that Lake does not discover fails
earlier with `manifest surface missing from Lake discovery` or `manifest executable missing
from Lake discovery`; `manifest-schema` means a manifest key, value, or schema version is invalid; `unexpected-project-module` means a claimed library imports an
excluded module or owns a module outside every manifested library.

## 6. Optionally enforce during ordinary `lake build`

The [standalone example](../../examples/build-lint/) shows how to make a `policy` target the sole
default target so that every `lake build` re-inspects the manifested surface, even for
cached modules. `import StrictLean.Contract` gives a proof-bearing registration
tying an executable to its exact required predicate. See
[docs/standard/8 §8.12](../standard/8-tooling-and-machine-audit.md#812-opt-in-enforcing-build-linter) for
scope, cache semantics, and limits. The incremental build does not replace the isolated
gate for a fresh-source conformance claim.

## 7. Complete semantic review

A green gate establishes hole-freedom, exact axiom sets, module coverage, and boundary
classification. The current checker does not establish that your theorems say what your prose says, that your
required contracts are complete, or that your types encode the invariant you advertise.
Those are the semantic-review rows of [docs/standard/9](../standard/9-compliance-audit.md), including
`SCOPE-*`, `TYPE-*`, `THEOREM-*`, `COMP-01`, `COMP-04`, `DOC-01`, and `DOC-02`.
Conformance is the whole matrix with one terminal result (`PASS`, `FAIL`, or `INCOMPLETE`),
not the gate alone.

## What you are not asked to do

- **Checker qualification is not adopter conformance.** The `MUT-*` rows and the
  `checkerSelftest` suite qualify a checker implementation. An adopter using the shipped
  checker unchanged does not rerun them.
- **`DOGFOOD-*` rows apply only to this repository.**
- **`freshChecker`** (fresh `leanchecker` over the serialized module graph) is optional
  defense in depth for the separate `MUT-05` claim, not part of the ordinary loop.

## Planned linter and linked rule reference

The [registry](rule-registry.md) is implemented. The [product architecture](linter-architecture.md) and [developer experience](developer-experience.md) specify conventional `lake lint`, editor integration and the GitHub Pages site still under development. The latter includes coexistence with an existing Mathlib lint driver and explicit local/project scope. Use the existing supported instructions above until their delivery issues integrate. The [one-rule prototype](../../examples/rule-reference-prototype/README.md) is interface evidence, not a complete adopter configuration or a published site. Canonical metadata and accepted-result design credit con-leche as detailed in the architecture.

## Accepted results and modes

Audit success is finalized against the exact requested claim and independently frozen
inventory. Project, explicit conforming-file and documentation drivers retain a
proof-bearing `AcceptedRun`; combined project/docs also checks the shared snapshot.
`--json-out` renders acceptance metadata from that value. Treat it as a report of
observations, never as a deserializable Lean proof or an authenticated external attestation.
See the [API and success-owner map](policy-acceptance.md).

`--build-lint`/`--incremental` still mean current policy inspection over an incremental
build. A fresh file claim covers the original file's bytes and its isolated compilation,
with incrementally built dependencies. No-profile and compiler-trusting file requests
report `CLASSIFIED`, not conforming success. Documentation accepts each configured
positive, rejection or teaching expectation without promoting negatives/teaching to
positive conformance. Help, worker and optional graph planning exits have no audit certificate.
The complete cold-root `./scripts/verify.sh` remains the ordinary420 acceptance command;
external-adopter/build-integration diagnostics and serialized-graph checking remain separate.

This boundary is informed by con-leche's complete indexed result assembly, without
importing its code or asserting its kernel/model guarantees for Lean/Lake, the filesystem,
JSON parsing, process completion or compiled machine code. Semantic adequacy and the
standard's residual review accounts remain separate obligations.
