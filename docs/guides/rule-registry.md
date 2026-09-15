# Rule registry and diagnostic interface

The implementation lives in `StrictLean.RuleId`, `StrictLean.Rule`,
`StrictLean.Diagnostic`, `StrictLean.NameCodec`, `StrictLean.RegistryCodec`,
`StrictLean.DiagnosticCodec` and `StrictLean.Website`. These modules supply one
vocabulary to the existing checker, its native diagnostic prototype and the
prototype website. The [coverage map](rule-coverage.md) defines the twenty
reserved predicates and their residual semantic obligations.

## Identity and authoring

`RuleId` is a closed inductive type. `RuleId.spelling`, `parse?`, `all` and
`route` are the executing definitions. A route is `rules/<ID>/`; it cannot be
independently changed in a descriptor. `descriptor : (id : RuleId) →
RuleDescriptor id` is exhaustive. There is no runtime registration table whose
missing entries silently disappear.

A descriptor supplies title, category, scope, evidence kind, normative clauses, applicability and
message-template identifiers, strict default, supported evidence modes,
implementation availability, lifecycle and attribution. `existingChecker`
means the named existing predicate has a checker implementation; it does not
mean that every planned live editor or production website adapter is complete.
SL5001 and SL5002 now have native metadata-presence observers. SL1001–SL1007
have partial command feedback; SL2002 covers invalid local foundation requests,
and SL2005 covers unavailable or pending local analysis. Full project integration
is separate from those local modes. See [native-linter.md](native-linter.md) for
actual APIs, scope, options and qualification. Production pages remain #15.

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
and UTF-16 coordinates to agree with that text. Missing ranges have module
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
codec is public `StrictLean.StructuralName`; `NameCodec` is a compatibility import.
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

`--json-out` now writes **result schema 1**. `--legacy-json-out` preserves the
previous file/project report format, including its path-remapping behavior. The
two options are mutually exclusive. Internal worker transport remains separately
versioned by its existing protocol; the new structural-name field is internal
collection data and is removed from the legacy export. Manifest schema 2 is
unchanged. The ordinary verification command deliberately requests legacy output
for its existing archived report consumer.

Registry and result envelopes contain `schemaVersion`, `producerVersion`,
`toolchain` and `sourceRevision`. Registry output contains the canonical `rules`.
Result output contains `scope`, `mode`, `status`, `diagnostics` and `unresolved`.
The producer revision is captured when `ResultProtocol` is elaborated, with Git
anchored to that source file's checker package directory, rather than reading an
adopter's Git checkout. Unreleased working builds are explicitly
marked. This is build metadata, not a proof of compiler executable identity or
an authenticated source tree.

Result status is `completed`, `rejected`, `incomplete` or `classified`.
`completed` records completion of the existing scoped mechanical checks; it is
not the future proof-bearing `Accepted` value and is not whole-standard semantic
conformance. `classified` distinguishes no-profile and compiler-teaching file
runs from positive conformance. File scope retains its nullable foundation claim,
execution claim and exact source even when there are no findings. File `scope.report`
and project `scope.surfaces[*].report` retain the complete observed declaration and
execution inventories, including trusted boundaries and correspondence evidence.
Project scope also retains its source snapshots, Lake library inventory and
completed stage names. Combined
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
`https://rbeauchamp.github.io/strict-lean/dev/rules/<ID>/`. They describe the
selected development route, not a claim that a public page has been deployed.
Released `/v/<package-version>/` and immutable `/rev/<commit>/` publication remain
subject to the architecture's publication contract; this unreleased producer
advertises development links only.

The prototype now exports the complete registry and selects its page from that
export. After building the actual artifact, it invokes:

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
The prototype explicitly selects one page; it does not manufacture nineteen
placeholder pages or satisfy production WEBSITE-01.

`Website.ExampleExpectation` distinguishes positive, compiler rejection, policy
rejection and trusted teaching examples. A policy rejection may elaborate
successfully and must have the expected rule/subreason, a real primary source
range and no unexpected diagnostics. An incomplete collector result cannot
satisfy any intended rejection. Production collection and example publication
must connect this interface to their actual completed jobs.

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

`RegistryChecks` exhaustively checks the twenty canonical descriptors and exercises
malformed transport, missing/duplicate routes, unsupported modes, Unicode/CRLF
coordinate boundaries, native/text agreement and incomplete negative outcomes.
Those controls qualify operational boundaries; they are not sampled evidence for
the universal theorems. `scripts/verify.sh` includes these checks within its same
hard 420-second ordinary acceptance budget. The prototype separately exercises
actual native diagnostics, Lake dispatch and deterministic Verso output.

## Attribution and pinned interfaces

Canonical representation and complete indexed metadata credit con-leche's
[PropWhen](https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Kernel/PropWhen.lean)
and [Installed](https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean),
Joachim Breitner and contributors at Lean FRO. No con-leche code or proof is copied
or imported as a proof of Strict Lean's predicates.

The source and native-message adapters use Lean 4.33.1, commit
`819816b2e0a3bf405af45ae5c7af2491d8f5bee6`:
[FileMap](https://github.com/leanprover/lean4/blob/819816b2e0a3bf405af45ae5c7af2491d8f5bee6/src/Lean/Data/Position.lean),
[UTF-16 conversion](https://github.com/leanprover/lean4/blob/819816b2e0a3bf405af45ae5c7af2491d8f5bee6/src/Lean/Data/Lsp/Utf16.lean),
and [command linter hooks](https://github.com/leanprover/lean4/blob/819816b2e0a3bf405af45ae5c7af2491d8f5bee6/src/Lean/Elab/Command.lean).
Credit Lean's authors for these APIs. The existing prototype retains Verso credit
and the [Microsoft CA1416](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/ca1416)
illustrative presentation reference. The [ecosystem study](ecosystem-design.md) broadens
the comparison; none of these examples prescribes an exact UX or supplies Lean policy
semantics or suppression permission. Root Mathlib remains pinned to
`0df444a360eaa60ab8c11dca51a86af692955474`.

The shared registry attribution describes a metadata design influence, not authorship of every
rule or a runtime dependency. See [attribution scope](design-influences.md).
