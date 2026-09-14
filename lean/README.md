# Lean sources

These modules implement the contracts and checkers and supply checked examples for
the [standard](../docs/standard/README.md). The package's source directory is `lean/`;
imports retain their Lean module names, such as `Audit.Research` and
`StrictLean.Contract`.

## Choose a starting point

| Purpose | Start here | Boundary |
| --- | --- | --- |
| Use the proof-bearing contract interface | [StrictLean.Contract](StrictLean/Contract.lean) | Public interface tying evidence to the named executable definition. |
| Inspect mathematical/specification examples | [Audit](Audit.lean) | Claimed abstract-specification surface; representative checks of the standard's claims. |
| Inspect the verified application | [Main](Main.lean), [AuditApp](AuditApp.lean) | Claimed limiter application; proofs concern its actual definitions and its IO boundary remains reported. |
| Understand declaration and execution auditing | [AxiomGate](StrictLean/Checker/AxiomGate.lean) | Operational checker implementation, qualified separately from the claimed proof surfaces. |
| Understand documentation auditing | [DocFenceAudit](StrictLean/Checker/DocFenceAudit.lean) | Checks recursively discovered Markdown fences as printed. |
| Inspect checker qualification | [CheckerSelftest](StrictLean/Checker/CheckerSelftest.lean), [fixture manifest](Fixtures/fixtures.json) | Isolated positive controls and intended-failure mutations; never import mutations into a claimed surface. |
| Inspect optional serialized-graph checking | [FreshChecker](StrictLean/Checker/FreshChecker.lean) | Separate fresh replay and exact Lake coverage; no claim of native execution correctness. |

## Follow the sources

Module docstrings describe purpose and assumptions. The
[Lake configuration](../lakefile.lean) defines module/target discovery, and the
[surface manifest](../foundation_manifest.json) defines claims and exclusions.
Those files, not this navigation table or folder names, own the inventory.

The checkers and the `ExecutableContract` interface share the `StrictLean`
library. The interface may be imported by a claimed surface as described in the
[standard](../docs/standard/8-tooling-and-machine-audit.md#810-dogfooding);
this does not make the operational checker a claimed proof surface.

For runnable consumers with their own configurations, use the
[standalone examples](../examples/README.md). For commands and review instructions,
use the [contributor guide](../docs/guides/contributing.md).
