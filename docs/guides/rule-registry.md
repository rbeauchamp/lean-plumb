# Rule registry and diagnostic interface

The implementation lives in `RegulaCore.RuleId`, `RegulaCore.Rule`,
`Regula.Diagnostic`, `Regula.NameCodec`, `Regula.RegistryCodec`,
`Regula.DiagnosticCodec` and `Regula.Website`; the first two are on the claimed
`RegulaCore` surface, whose declarations the gate audits. These modules supply one
vocabulary to the checker, the native editor linter and the
[rule-reference website](website.md), whose pages `RegulaCore.Site*` derive from `descriptor`. The [coverage map](rule-coverage.md) defines the twenty-one
reserved predicates and their residual semantic obligations.

## Identity and authoring

`RuleId` is a closed inductive type. `RuleId.spelling`, `parse?`, `all` and
`route` are the executing definitions. A route is `rules/<ID>/`; it cannot be
independently changed in a descriptor. `descriptor : (id : RuleId) →
RuleDescriptor id` is exhaustive. There is no runtime registration table whose
missing entries silently disappear.

A descriptor supplies title, category, scope, evidence kind, normative clauses, applicability
identifier, strict default, supported evidence modes,
implementation availability, lifecycle and attribution. The message form is not a field: it is
`messageForm id`, the same `messageLine` the checker renders. `existingChecker`
means the named existing predicate has a checker implementation; it does not
mean that every planned live editor adapter is complete.
RG5001–RG5003 now have native metadata-presence observers. RG1001–RG1007
have partial command feedback; RG2002 covers invalid local foundation requests,
and RG2005 covers unavailable or pending local analysis. Full project integration
is separate from those local modes. See [native-linter.md](native-linter.md) for
actual APIs, scope, options and qualification. The [website guide](website.md) owns the
published rule pages.

To add a rule, establish its exact Lean predicate and coverage-map entry first.
Add its constructor, stable spelling/parser branch, exhaustive descriptor and
appropriate dependent payload. Add the actual detector and its invoking adapter
before enabling its modes. Update the closed inventory and its proofs. Preserve
existing qualification controls; qualify the changed admission and output paths.
Metadata text, a nonempty mode list and a green build are not proofs of detector
adequacy.

Never reuse an ID for incompatible semantics. `Lifecycle.active` records its
introduction. `Lifecycle.retired` retains the descriptor as a tombstone and
records introduction, retirement and optional replacement; a replacement carries
proof that it is a different ID. The current registry contains only active,
unreleased IDs. `parseDescriptor` compares against canonical metadata, rejecting
unknown/missing fields, changed routes and stale lifecycle data. A lifecycle or
predicate change still requires semantic review.

## Typed findings and coordinates

`Diagnostic id` contains `Payload id`, a location, related locations, evidence
mode, claim context, strict impact and display severity. Declaration rules take
structural declaration names; execution rules take structural root names;
context rules take context arguments. Runtime collections use the dependent pair
`Finding`. `supportedMode` proves membership in the descriptor's mode list, and
`makeDiagnostic` checks that condition at construction.

Strict impact is `violation` or `incomplete`. Changing display severity cannot
change this impact or the existing checker's acceptance decision. The existing
profile and execution parsers remain the configuration authority; claim text in
a diagnostic describes that context and is not an independent policy decision.
The policy-domain refactor will replace the remaining legacy context and detail
strings with its finer typed categories.

`Location` distinguishes a source snapshot, a Lean module and a project/configuration
scope. A source location retains the exact text and byte offsets for both full
and selection ranges. `admitSource` checks bounds, character boundaries, ordering
and containment. `sourceFromReport` additionally requires the recorded codepoint
and UTF-16 coordinates to agree with that text. `admitSource` and the conversion live in
the claimed `RegulaCore.Source`; the UTF-16 column is Lean's `leanPosToLspPos`, supplied
by `Regula.Diagnostic`. Missing ranges have module
attribution; inconsistent supplied ranges fail instead of acquiring a fabricated
location.

Lean report lines are **one-based**, and their columns count **Unicode codepoints**.
The report's `startUtf16` and `endUtf16` fields are zero-based **columns within their
respective lines**, not absolute offsets. JSON source locations retain byte ranges
and derived zero-based LSP ranges. Native messages use Lean codepoint positions.
The same validated selection supplies both conversions. Text/native output also
retains ID, impact, mode, claim, scope and help URL.

Filesystem paths remain native diagnostic filenames. Fence declaration diagnostics
use explicitly labelled virtual snippet locations, with the exact verbatim snippet
as their snapshot; their coordinates are not misrepresented as Markdown coordinates.
Aggregate fence errors retain their document/fence origin in context attribution.
Project reports may retain disposable source-copy paths as evidence alongside the
actual source text. They are not assertions that those paths remain live after the
run. No textual path substitution is applied to the new transport.

Names use outermost-first tagged string/numeric components, preserving anonymous
roots and names whose printed forms are ambiguous. `Probe` retains Lean's actual `Name` throughout collection and policy admission. The operational name
codec is public `Regula.StructuralName`; `NameCodec` is a compatibility import.
Only the legacy output adapter renders the display `name` field. Old display-only
worker records cannot supply a new declaration diagnostic. JSON syntax parsing and the compiler's collection of
names, ranges and source identity remain trusted operational boundaries.

## Versioned output and compatibility

Commands:

```sh
lake exe axiomGate --registry-out tmp/registry.json
lake exe axiomGate --validate-registry tmp/registry.json
lake exe axiomGate --file Example.lean --claim standard-logical --json-out tmp/result.json
lake exe axiomGate --with-docs --json-out tmp/result.json
lake exe axiomGate --with-docs --legacy-json-out tmp/legacy-report.json
```

`--json-out` now writes **result schema 2**. `--legacy-json-out` preserves the
previous file/project report format, including its path-remapping behavior. The
two options are mutually exclusive. Internal worker transport remains separately
versioned by its existing protocol; the new structural-name field is internal
collection data and is removed from the legacy export. Manifest schema 2 is
unchanged. No repository check or CI step consumes legacy output; registry CLI
qualification exercises only its mutual exclusion with `--json-out`.

Result schema 2 keeps result size proportional to the audited project rather than to
its dependencies. Schema 1 serialized, inside `acceptance.snapshot.configuration.source`,
the captured text of every Lake dependency (for a one-theorem project requiring this
package: all of Mathlib, about 110 MB of a 116 MB file) and listed every module of each
imported environment. Schema 2 renders the snapshot with `ResultProtocol.snapshotJson`:
the audited sources in full, the configuration by URI, and each dependency by package,
nominal revision and input-scoped `dirty` status. The project configuration files remain
in full in `scope.configuration` of axiomGate and ruleExamples results; the freshChecker
`serializedGraph` output has no `scope`, so it carries no configuration text, and no
consumer reads it there. It omits `acceptance.environments[*].importedModules` and
the report's `modules` and `moduleOrigins` import-closure lists (owned modules remain in
`census.modules`). The run still freezes and rechecks those exact bytes in memory before
any success; only their serialization changes. A clean dependency is identified by its
pinned revision. A dirty dependency, including any path dependency without its own Git
revision (which the checker records as dirty), is rendered only as
`{package, revision, dirty: true}`: it carries no content identity, and its frozen text is
not recorded. The size bound rests on `snapshotJson_configuration_independent`: the
snapshot rendering does not depend on `configuration.source`, which holds every
dependency's captured text. Kernel-checked `rfl` theorems
(`snapshotJson_configuration_independent`, `environmentJson_imports_independent`,
`Environment.resultJson_imports_independent`) state that the rendering does not depend
on those inputs. The remaining content is the project's own sources, configuration,
declarations, execution inventory from its owned roots, jobs and diagnostics, plus a
constant-size record per dependency; this is an argument from construction, not a
theorem about serialized byte counts.

Registry (schema 1) and result (schema 2) envelopes contain `schemaVersion`, `producerVersion`,
`toolchain` and `sourceRevision`. Registry output contains the canonical `rules`.
Result output contains `scope`, `mode`, `status`, `diagnostics` and `unresolved`.
The producer revision is captured when `ResultProtocol` is elaborated, with Git
anchored to that source file's checker package directory, rather than reading an
adopter's Git checkout. Unreleased working builds are explicitly
marked. This is build metadata, not a proof of compiler executable identity or
an authenticated source tree.

Result status is `completed`, `rejected`, `incomplete` or `classified`.
`completed` records completion of scoped mechanical checks; it is not a serialized
Lean proof or whole-standard semantic conformance. The
[acceptance guide](policy-acceptance.md#1-observed-call-flow-and-every-success-boundary)
owns the accepted-result boundary and its JSON metadata semantics. Since #42, a result envelope's
`completed` status is rendered only through `Account.Status`, whose `completed`
constructor requires an accepted report account (`RegulaCore.Account`), and the
`acceptance` object gains an additive `account` member (then within result schema 1):
`coverage` (only `freshWholeProject` is whole-project acceptance), `checked` (the
`theorem` `RegulaPolicy.accept_iff`, whose right side is the checked relation, and the job count), `contracts` (each RG1007
registration, its implementation and rendered requirement, with `unresolvedReview`
`R-INTENT`, `R-INVARIANT`), per-environment `execution` counts, `fences` by expectation,
`trusted` mechanisms and the run's `unresolvedReview` identifiers. No existing key changes;
the rule-example projection already excludes `acceptance`, and the other consumers test
only its presence. A completed envelope's `mode` is the account's. A listed identifier names an open review obligation, not a completed review. `classified`
distinguishes no-profile and compiler-teaching file runs from positive conformance. File scope retains its nullable foundation claim,
execution claim and exact source even when there are no findings. File `scope.report`
and project `scope.surfaces[*].report` retain the complete observed declaration and
execution inventories, including trusted boundaries and correspondence evidence.
Project scope also retains its source snapshots, Lake library inventory and
completed stage names. See the [producer account](engine-producers.md#source-and-configuration-binding)
for frozen configuration snapshots and source binding in file and project results. Combined
project/documentation output remains incomplete while its documentation stage is
pending. Configuration that has not been admitted has null scope/mode and an
incomplete status. Recognizable output destinations are invalidated before
argument parsing where their paths can be resolved; absolute destinations do not
require valid project configuration. Callers must require the current invocation's
successful completion, never reuse a previous report after a failed command.

Source compilation is distinguished from subsequent inspection. A normal pinned
compiler exit with a source-located error/warning can establish an emitted source
diagnostic. Crashes, termination and inspection exceptions are incomplete.
Existing flattened Lake build failures conservatively remain incomplete, with
the original compiler/build text retained, because that interface lacks a typed
completion account. Neither outcome permits acceptance.

`parseDiagnostic` reconstructs the indexed payload and admitted source location,
then compares the input against canonical re-encoding. This rejects unknown
fields, unsupported modes/IDs, invalid coordinates, and altered redundant text or
help URLs. The proved name/ID/mode codec laws below do not claim a universal proof
of Lean's JSON parser, FileMap implementation or complete diagnostic decoder.

## Website admission and links

Development help URLs are
`https://rbeauchamp.github.io/regula/dev/rules/<ID>/`; `Regula.Site.Build.helpUrl_dev`
proves each is the site's development page route of its rule. Released `/v/<package-version>/`
publication awaits a release; each published commit's `/rev/<commit>/` snapshot is published
with its deployment and kept by every later one ([website guide](website.md#retention)). This unreleased producer advertises
development links only.

The site builder (`lake exe site build`, run by `./scripts/verify.sh site`) generates every
page from the registry and, after assembling the artifact, invokes:

```sh
lake exe axiomGate --validate-site tmp/registry.json tmp/site-artifact.json
```

The artifact object has `required` and `emitted` ID arrays and a `pages` array.
Each page has `id`, `route`, `checkedExample` and `advertisedEnforced`. Admission
requires the expected producer/registry, unique and complete required pages,
canonical routes, checked examples, and an implementation for advertised enforced
rules. Every emitted ID must belong to the selected page scope. Unknown fields
fail. The builder supplies the observed artifact inventory and checked-example
evidence; the validator does not prove filesystem or compiler observations.
The site submits every registered rule as required, one page per rule, and every rule ID its
checked examples emitted.

`Website.ExampleExpectation` distinguishes positive, compiler rejection, policy
rejection and trusted teaching examples. A policy rejection may elaborate
successfully and must have the expected rule/subreason, a real primary source
range and no unexpected diagnostics. An incomplete collector result cannot
satisfy any intended rejection. The rule-example qualifier admits the completed jobs, and the site builder consumes only
its admitted exports.

## Evidence and limits

`RuleId.parse_spelling`, `spelling_injective`, `mem_all`, `all_nodup` and
`route_injective` establish the stated properties of the actual closed vocabulary
and route function. `RegistryCodec.mode_roundtrip`, `rule_roundtrip`,
`nameParts_roundtrip` and `name_roundtrip` establish round trips over their exact
Lean domains. Their transitive axiom sets are checked by `RegistryChecks` against
Standard-Logical. The empty-foundation results are `parse_spelling` and `all_nodup`;
`spelling_injective`, `mem_all` and `mode_roundtrip` use `propext`;
`route_injective` uses `propext` and `Quot.sound`; the remaining
listed results use `propext`, `Quot.sound` and `Classical.choice`. None uses a
project axiom, hole or compiler-trusting proof axiom.

`RegistryChecks` exhaustively checks the twenty-one canonical descriptors and exercises
malformed transport, missing/duplicate routes, unsupported modes, Unicode/CRLF
coordinate boundaries, native/text agreement and incomplete negative outcomes.
Those controls qualify operational boundaries; they are not sampled evidence for
the universal theorems. `scripts/verify.sh` includes these checks within its same
hard 420-second ordinary acceptance budget. The native-linter and lint-driver campaigns separately exercise actual native diagnostics and
Lake dispatch; the site build checks the generated pages.

## Attribution and pinned interfaces

Canonical representation and complete indexed metadata credit con-leche's
[PropWhen](https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Kernel/PropWhen.lean)
and [Installed](https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean),
Joachim Breitner and contributors at Lean FRO. No con-leche code or proof is copied
or imported as a proof of Regula's predicates.

The source and native-message adapters use Lean 4.34.0, commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`:
[FileMap](https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Lean/Data/Position.lean),
[UTF-16 conversion](https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Lean/Data/Lsp/Utf16.lean),
and [command linter hooks](https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Lean/Elab/Command.lean).
Credit Lean's authors for these APIs. The rule-reference site credits Verso
and the [Microsoft CA1416](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/ca1416)
illustrative presentation reference. The [ecosystem study](ecosystem-design.md) broadens
the comparison; none of these examples prescribes an exact UX or supplies Lean policy
semantics or suppression permission. The root Mathlib revision is locked in the
[root manifest](../../lake-manifest.json).

The shared registry attribution describes a metadata design influence, not authorship of every
rule or a runtime dependency. See [attribution scope](design-influences.md).
