# Source-owned rule examples and diagnostic demonstrations

The corpus in [`examples/rules/`](../../examples/rules/) supplies page inputs for all twenty
registry IDs. `corpus.json` fixes invocation, evidence mode, expected IDs, legacy subreasons,
message patterns, subjects and full primary locations before execution. Sources are copied
verbatim into disjoint Core-only adopters. `StrictLean.Qualification.RuleExamples`
orchestrates processes and files in Lean; the
existing Lean detectors produce the findings and `Checker.RuleExampleQualification` admits
the canonical evidence. This is scoped qualification, not a universal detector proof or
whole-project `Accepted` construction.

## Accepted examples and separate demonstrations

`Website.ExampleExpectation` retains exactly four kinds: positive, compiler rejection,
policy rejection, and trusted teaching. Compiler rejection uses the shared restricted pattern
language on one effective error. Policy rejection can follow successful elaboration and can
list every expected finding, including generated declarations and underlying diagnostics.
No extra finding may disappear. A source-free detector keeps its module/project location;
an example adapter must not manufacture a source range.

SL2001, SL2005 and SL3001 have **diagnostic demonstrations** for unavailable analysis. They
require completed, authentic diagnostic production and exact source/configuration/mode,
registry ID, reason, primary/related location evidence. The checker result remains
`incomplete`. A crash, missing response, stale source or unrelated error is not a demonstration.
Demonstrations are outside the four accepted-example kinds and do not supply positive or
negative accepted-program evidence. Each corrected counterpart runs its applicable completed
positive checks. No rule can become conforming by expecting its unavailability.

`Website.ExampleBinding` retains an admitted snapshot, mode and typed `ExampleRequest`.
The producer captures its own parsed invocation and configuration, including absent files and
Lake package overrides. `admitExampleRequest` admits only exact expected/observed equality;
its soundness theorem concerns that data equality, not process authentication. The qualifier
also compares the actual effective configuration and file or per-surface claim/execution.
Copied configuration paths are compared relative to their explicitly recorded roots, without
rewriting source or diagnostic identities. A changed effective package override is refused;
this example qualifier does not authorize configuration relocation transformations or combined
`--with-docs` requests. After initial configuration capture succeeds, early terminal failures
retain the producer request and any effective configuration captured before failure. If the
initial configuration read itself fails, the terminal result retains the original IO diagnostic
as SL2001/incomplete with an empty source account and no request/effective account; it cannot
qualify as an example or demonstration. The [producer transport contract](engine-producers.md#transport-and-consumer-boundary)
owns source retention on terminal exits; absent source evidence refuses qualification. The shared
`admitExampleSources` guard requires every observed source to belong to the frozen snapshot
and the displayed source text to occur in that account. File requests additionally require
that text at the requested path. Its soundness/completeness proofs concern these exact data
relations; capture, JSON decoding and process authenticity remain operational trust boundaries. `validateBoundExample` checks
binding/completion and the exact diagnostic list before applying the four-kind policy.
`admitDemonstration` returns the unchanged observation with a proof of `DemonstrationOK`:
completed production, nonempty expected findings, a selected-rule incomplete finding, exact mode and
canonical diagnostic equality. The observed list itself must contain an incomplete finding for the selected rule,
without assuming injectivity of JSON rendering. Its soundness/completeness theorems concern these data, not
process authenticity. `StrictLeanPolicy.incomplete_example_refused` proves that an incomplete
outcome satisfies none of the existing fence expectations. The executed validator additionally proves `demonstration_not_accepted`: every admitted
demonstration fails each accepted-example classification, for any expected finding list.
All six named new guarantees
(`incomplete_example_refused`, `admitDemonstration_complete`, `admitDemonstration_sound`,
`demonstration_completed`, `demonstration_observed_incomplete`,
`demonstration_not_accepted`) currently depend exactly on
`propext`, `Classical.choice` and `Quot.sound`: Standard-Logical, not Kernel-only.
`demonstration_selected_rule` exposes the selected-rule obligation directly. Documentation
receipts retain each actual fence classification. The shared `PositiveClassifications` guard
requires a nonempty list with every fence positive, passing and complete, both when the adapter
emits `completed` and when the qualifier admits a positive correction. Successful compiler
negatives and trusted teaching remain `classified`; failed and incomplete checks retain their
own outcomes. `positiveClassifications_sound` states the exact admitted relation.
Global policy acceptance remains
issue #7; a corpus PASS is not full-standard conformance.

## Exact source and remediation map

| Rule | Source-owned input | What the correction preserves and changes |
| --- | --- | --- |
| SL1001 | `SL1001/{Violation,Fixed}.lean` | Proves the same `∀ n : Nat, n = n` instead of assuming it as an axiom. |
| SL1002 | `SL1002/{Violation,Fixed}.lean` | Fills the same reflexivity proof with `rfl`; diagnostic-only inspection retains the original compiler warning. The fixed side uses the ordinary warning-rejecting gate. |
| SL1003 | `SL1003/Example.lean` and dependency `{Violation,Fixed}.lean` | The unchanged client imports reflexivity from an unowned dependency; the dependency supplies a proof of the same proposition instead of an axiom. Imported dependencies remain a declared trust boundary. |
| SL1004 | `SL1004/{Violation,Fixed}.lean` | Proves the same concrete equality by kernel reduction instead of native proof evaluation. Both native axiom and parent findings are retained. |
| SL1005 | `SL1005/{Violation,Fixed}.lean` | Proves the same universally quantified reflexivity without `propext`, under the unchanged Kernel-only maximum. |
| SL1006 | `SL1006/{Violation,Fixed}.lean` | Keeps identity's domain and body; removes an unnecessary `unsafe` declaration. |
| SL1007 | `SL1007/{Violation,Fixed}.lean` | Moves the complete natural-number domain inside the identity contract's predicate, retaining the same pointwise equality. |
| SL2001 | `SL2001/Example.lean` and `{Violation,Fixed}.json` | Removes the unavailable Lake dependency; the requested reflexivity source is unchanged. The unavailable-workspace result is a demonstration. |
| SL2002 | `SL2002/Example.lean` and `{Violation,Fixed}.json` | Removes an unknown manifest key without changing the selected source, profile or execution requirement. |
| SL2003 | `SL2003/{Violation,Fixed}.lean` | Removes a dead lambda binding while preserving identity's complete natural-number behavior. No warning or linter is disabled. |
| SL2004 | `SL2004/{Violation,Fixed}.lean` | Removes an unused forbidden reporter import; preserves reflexivity and its assumptions. |
| SL2005 | `SL2005/{Violation,Fixed}.lean` | Replaces ill-typed unchecked evidence with a checked proof of the same reflexivity statement. Admission failure is a demonstration, never accepted evidence. |
| SL3001 | `SL3001/{Violation,Fixed}.lean` | Removes a no-effect custom evaluator that prevents history authentication; preserves the same reference, replacement and correspondence. |
| SL3002 | `SL3002/{Violation,Fixed}.lean` | Adds the missing equality on the full natural-number domain; keeps the checked execution claim and both implementations. |
| SL4001 | `SL4001/{Violation,Fixed}.md` | Removes an orphan marker; the positive reflexivity fence is unchanged. |
| SL4002 | `SL4002/{Violation,Fixed}.md` | Proves the same reflexivity claim in a positive fence; retains the SL1001 underlying rejection alongside SL4002. |
| SL4003 | `SL4003/{Violation,Fixed}.md` | Correctly labels an already valid reflexivity proof as positive; does not invent a compiler failure. |
| SL4004 | `SL4004/{Violation,Fixed}.md` | Correctly labels the same kernel proof as positive rather than native teaching. |
| SL5001 | `SL5001/{Violation,Fixed}.lean` | Adds module documentation to unchanged reflexivity evidence. |
| SL5002 | `SL5002/{Violation,Fixed}.lean` | Adds the registered public theorem's docstring; registration, proposition and proof are unchanged. |

## Authoring and export contract

Add or change source files first. Select the actual supported detector stage; do not force a
project-only rule into an editor callback. Fix the intended diagnostic specification in
`corpus.json`, including all additional findings. Its location fields are explicit expected
coordinates, checked against the exact source by the registry codec. Whole-field placeholders
refer to invocation paths or exact source-owned bytes; they never rewrite actual findings.
Markdown snippet slices are explicit fixture byte anchors, not a second Markdown detector.
The production Markdown scanner still owns classification and fence semantics.

The adapters reuse `SourceBinding.withUnchanged`, typed `SourceAudit` outcomes and the
documentation driver’s frozen project snapshots. They serialize only after snapshot
checks complete; a typed refusal or process exception cannot become a qualifying example.

The runner starts fixed, violation and restored phases with separate empty root build output,
uses unique result paths and checks source/configuration readback. At most two independent
detector processes run concurrently; evidence consumption stays in registry/phase order.
File fixtures are separate from the warning-free positive library used to prepare dependencies. Its export embeds exact
sources, commands, original compiler output, canonical schema-1 results, expected locations,
mode and checker build identity, plus exact checker source bytes before and after the campaign.
The campaign additionally exercises authentic Standard-Logical output against a Kernel-only
request and actual successful negative/trusted documentation against a positive correction
expectation, then restores fresh positives. Relabelling a demonstration's selected rule is
refused while retaining its complete findings. Authentic early SL2003/SL2005 results are also
refused against corrected caller snapshots or after removal of producer source evidence.
These controls qualify the adapters; the
universal data predicates and their proofs remain distinct from observed process behavior.
The Lean qualifier checks selected coverage against the
closed registry and requires all three phases once. Unrun selected rules cannot be called
full-corpus PASS. Version fields alone do not authenticate whole binaries; the producer and
filesystem remain the existing trusted operational boundary.

After provisioning pinned dependencies, build both detector executables and the qualifier executable.
The campaign invokes the compiled qualifier instead of re-elaborating it for every receipt:

```sh
lake build axiomGate ruleExamples ruleExampleQualification qualify
lake exe qualify rule-examples --evidence tmp/rule-examples.json
```

`./scripts/verify.sh diagnostics rule-examples` wraps this build and campaign under the
repository's diagnostic deadline and includes its housekeeping checks.

The `ruleExamples` and `ruleExampleQualification` executables are excluded in the root manifest solely as operational
qualification tooling, alongside the existing checker executables. Their modules belong to the
already-excluded `StrictLean` tooling library; no product module or detector is newly exempted
from its applicable qualification.

For development, append `--rules SL1001 SL1002` after `--evidence PATH` to produce
explicitly scoped evidence. [Lean qualification](lean-qualification.md) specifies the
proved template transformation, Lake-discovered source snapshot and trusted IO boundary. Ordinary
`./scripts/verify.sh` remains the separate unpartitioned 420-second acceptance command.
Do not substitute the corpus campaign for that command. No website, editor-interaction,
serialized-graph or full-project completion claim follows from the corpus alone.

The website must render these exported sources directly and retain the result identity.
Reject a stale source/registry or unmatched source/configuration/mode; never replace an
unavailable version with current source. The actual linter/examples use Lean 4.33.1 and the
root pinned dependencies. Verso's separate Lean 4.33.0 toolchain renders them as text.

Detectors, ranges and elaboration reuse Lean/Lake facilities. The registry's canonical/indexed
representation retains its specific [design attribution](design-influences.md); no con-leche
code or theorem is imported, and these fixtures do not claim its checker proof.
