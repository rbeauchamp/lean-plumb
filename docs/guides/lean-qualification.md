# Lean qualification tooling

Project-owned implementation follows the Lean 4 policy in `AGENTS.md`, not
in the universal standard. The sixteen former Python entrypoints listed below have Lean
replacements; ordinary acceptance, the producer/history/corpus CI campaigns, and the
prototype do not need a Python interpreter. The four remaining acceptance, snapshot,
documentation-dependency and input-inventory drivers were retired after their native
controls passed. The [earlier receipt](../../session/evidence/ci-environment-census.md)
and [completion receipt](../../session/evidence/ci-role-retention.md) retain the
control mapping, runtime results, failed attempts and evidence-reuse boundaries.
Historical implementations remain in Git history; use the Lean commands below.
The prototype's project-owned JavaScript widget was also removed. External Lean, Lake,
Verso, runtime libraries and generated browser assets remain external dependencies, not
claims of a wholly Lean or formally verified toolchain.

## Why retain these controls?

They are integration qualification, not alternative implementations of policy. A theorem
about a pure policy function cannot establish that the CLI called it, that warnings were
promoted, that the compiler supplied the right source range, or that a static renderer
produced a page. Deleting those observations would lose real coverage under standard §8.8.
Conversely, passing these controls never proves arbitrary compiler or OS behavior.

The converse also holds: a property of a pure Lean function the checker executes is
proved over every input, not sampled by mutating one real output. Producer and history
transport admission (`ProducerReport.validate_sound`) and the history oracle
(`History.validate_importedRootExecuted`, `validate_unsupported_unresolved`) replaced
their former mutation campaigns this way; the retained controls above are each kept for
the external process, compiler or filesystem boundary they observe.

| Former entrypoint | Lean replacement | Retained purpose |
| --- | --- | --- |
| `registry_cli_checks.py` | `lake exe qualify registry` | Seven malformed CLI invocations must invalidate seeded stale output. |
| `native_linter_checks.py` | `lake exe qualify native` | 36 real compiler controls: identity, multiplicity, severity, source ranges, documentation and metadata ownership. |
| `producer_checks.py` | `lake exe qualify producers` | Twelve source-owned documentation controls: for incremental and build-lint and each of SL5001/SL5002, one workspace runs Fixed, then Violation over that Fixed build (stale-artifact detection), then Fixed again from a cleared build. Also two standalone-executable controls, each in its own fresh workspace. The fresh-project SL5001/SL5002 observations are the rule-example corpus records, validated there by the same producer oracle. |
| `history_checks.py` | `lake exe qualify history` | Ten project/file invocations, each in its own fresh workspace: private/imported roots, reached-closure/source accounts, unsupported-evaluator refusal and source-snapshot changes. |
| `closure_evidence_checks.py` | `lake exe qualify closure-evidence` | Reflexive candidate versus active cycle, retained recursive IR edges, and range refusals through four invocation paths. |
| `configuration_capture_checks.py` | `lake exe qualify configuration-capture` | Initial configuration IO failure through project/file result protocols. |
| `documentation_source_checks.py` | `lake exe qualify documentation-source` | Frozen dependency/configuration changes through both documentation commands; `--source-read-only` adds file/build read-failure controls. |
| `fence_evidence_checks.py` | `lake exe qualify fence-evidence` | Independent range, admission, policy and compiler failures inside positive fences, plus restoration. |
| `frozen_exit_checks.py` | `lake exe qualify frozen-exits` | Frozen-input rechecks after imports and failed build/compilation operations. |
| `native_launcher_diagnostic.py` | `lake exe qualify native-launcher` | 36 paired baseline/cached-environment controls; exact source, argv, outputs and in-memory environment/executable equality. |
| `rule_example_checks.py` | `lake exe qualify rule-examples --evidence PATH` | Forty source-owned phases for twenty rules (Fixed and Violation, each in its own fresh workspace), plus admission mutations and authentic wrong-claim/classification refusal controls: 43 productions and 10 individual control admissions, then one corpus admission of every record. `--shard K/N` selects every Nth rule by corpus position, keeping SL5001 and SL5002 in one shard. |
| prototype `run.py` | `lake env lean --run examples/rule-reference-prototype/Run.lean` | Separately pinned Verso integration, native messages, Lake dependency dispatch and identical-output comparison. |
| `acceptance_checks.py` | `lake exe qualify acceptance GROUP --evidence PATH` | Fence-compilation packet mutations with positive restoration. Group: `fences`. The former `surface`, `evidence`, `sources` and `process` groups mutated the removed surface-worker packet; project and documentation acceptance now run in one process with nothing serialized between them. |
| `acceptance_snapshot_checks.py` | `lake exe qualify acceptance-snapshots dependencies`, `lake exe qualify acceptance-snapshots history` and `lake exe qualify acceptance-snapshots git-status` | Ignored Git/non-Git dependency input coverage and mutation; SL3001 fresh/incremental/build-lint history refusal and restoration; dependency dirty decision against the retired pathspec status across Git collapse, rename, nested-repository, symlinked-root and outside-root cases. `all` runs all three under one deadline. |
| `documentation_dependency_checks.py` | `lake exe qualify documentation-dependencies` | Both documentation commands retain pre-build dependency observations; combined project/documentation positive remains distinct. |
| `input_inventory_checks.py` | `lake exe qualify input-inventory` | Root additions and Markdown edit/removal during prerequisite build; actual new-module build and restored fresh controls. |

The producer command retains `--evidence PATH`. `scripts/verify.sh` runs registry and native
controls; `scripts/verify.sh diagnostics producers`, `scripts/verify.sh diagnostics history`
and the two `scripts/verify.sh diagnostics rule-examples K/2` shards run as parallel
capability-triggered CI jobs. Each invocation retains its own hard 420-second deadline. Direct `lake exe qualify`
campaigns have a single 420-second process-group deadline; the prototype has a single
600-second process-group deadline. These replace the old per-child timers, which cannot
safely enforce descendant termination while sharing acceptance's outer process group.
The prototype never substitutes for acceptance. `diagnostics rule-examples` retains the
upstream corpus selection; optional `--rules RULE ...` or `--shard K/N` follows
`--evidence PATH` on the standalone command and never claims full-corpus coverage; the two
CI shards together select every rule once. The corpus runner retains at most five
concurrent producer detector invocations, each in its own fresh workspace. Each invocation
may launch subprocesses. The runner prepares one private copy of the root package, shared
by every producer, which must not write it (no permission enforces this; `sharedIdentity`
checks it by content identity); its manifest names the captured original Lake dependency
roots, which are shared too. The runner records a content-level identity of every entry
under every shared root, including the root copy,
(path, `lstat` kind, exact length and a 64-bit native content hash; symlinks recorded by
resolution, never followed) before any producer starts, and requires an equal identity
after all producers have been joined. A difference refuses the run. This detects a write;
it does not prevent one. The runner never changes shared dependency permissions, so a
deadline SIGKILL cannot leave the dependency trees read-only.

Dependency snapshots are captured once per run. Before any producer starts, the runner
makes one complete `Snapshot.dependenciesCaptures` and exports only its Git facts
(revision and dirty bit), each keyed by the exact capture request: package, canonical root,
and ordered source and configuration paths. The facts file is retained with the attempt's
raw evidence as `injected-git-facts.json`, and every producer registration names that
retained path. Producers run through the internal
`ruleExamples --injected-git-facts FACTS [axiomGate] ARGS` entry. It runs the same
`axiomGate` or `ruleExamples` body, reads every source and configuration byte itself, and
uses an injected pair only for a request that matches exactly. The private
`strict_lean` copy and fixture dependencies are always observed fresh.
`Snapshot.assemble_facts_eq` shows that equal Git facts give an identical capture, and so
(`stateOfCore_congruence`) identical request and report bytes. That the facts are equal is
the no-writer premise. Producers do not recheck an injected dependency at their own end; the campaign
rechecks the shared trees once: at run end, `Snapshot.inputsUnchanged` rechecks the
once-captured value with fresh reads and fresh Git, and the content identity must be equal.
Every producer still rechecks each non-injected dependency and its own inputs. Results
produced with injected facts carry `"gitFacts": "injected"`; admission ignores the field. User-facing `axiomGate` rejects `--injected-git-facts`.
Root processes, other file owners, concurrent external writers, filesystem honesty and
non-cryptographic hash collisions remain trusted assumptions.
The runner consumes records in fixed order and drains launched tasks
before ordinary/exceptional scratch cleanup. Partial exports remain `INCOMPLETE`.
Corpus records use a qualification-only view: top-level `acceptance` and
`documentationAcceptance` payloads become null, while every key, required nested value
and raw-tree shape remains unchanged. Exact detector bytes remain in
`PATH.raw/ATTEMPT/RULE/PHASE/result.json`, with registered command/request/snapshots,
stream files, terminal metadata and the compact original record. Derived admission
mutations retain their exact submitted record, origin path and mutation label before
admission under the original phase's `controls/` directory. During production the
INCOMPLETE receipt points to these sidecars; the full aggregate is written once all
records and controls are ready, and one corpus admission then admits every record. The
runner does not re-read its own just-written sidecars; it requires unchanged terminal
checker sources before exporting PASS. Kill paths retain INCOMPLETE and partial files.
PASS is written only after successful scratch cleanup.
Stream retention on kill covers completed lines already read; an unterminated line
can remain buffered. Only terminal observations claim complete streams.
The former launcher's separate 180-second diagnostic timer is replaced by the same
single 420-second public qualification boundary; no timing result is a future bound.

## Organization

- `lean/StrictLeanQualification/`: a separate **positive Lake library**, discovered through
  its all-submodules glob. It contains pure observation requirements and checked contracts,
  not process launchers. Testing requirements are not production policy, so this library
  does not belong in `StrictLeanPolicy`, nor in the mathematical `Audit` examples.
- `lean/StrictLean/Qualification/`: operational drivers, the single `qualify` Lake executable,
  and shared process/scratch/adopter support. These remain in the existing operational
  `StrictLean` library, explicitly excluded from the positive proof surface. Calling a
  proved oracle does not prove the entire driver or its IO effects.
- `lean/StrictLeanVerification.lean`: a separately claimed cold-start runner importing only
  the pinned toolchain. It owns argument selection, command recipes, sequential execution
  and success reporting. `scripts/verify.sh` only selects the root/GNU timeout and starts
  this runner under the external deadline, including all root-package builds.
- `examples/rule-reference-prototype/Run.lean`: the experiment-specific driver. It remains
  with its fixtures and separately pinned Verso package rather than becoming a checker
  dependency. Production website delivery remains separate work.

This uses normal Lean module factoring and Lake targets. It does not impose a universal
`tests/` directory convention or rename scripts while hiding another interpreter inside Lean.
The helpers invoke external programs with argv arrays, never generated shell programs.

## Exact proved boundary

All quantifiers below range over supplied Lean values, not external executions.
The IO drivers call the relevant `ExecutableContract.run`, so the evidence is required
by their source-level linkage. The proof is erased at execution.

- `Checks.evaluate_success`: evaluation returns success **iff** every supplied assertion
  is true. `evaluate_error` identifies a satisfied prefix and its first false assertion;
  `evaluate_append` specifies success/error composition. `checkedEvaluation` requires all
  three properties. Empty conjunction is permitted; each protocol supplies its own
  nonempty, explicit requirements.
- `Registry.validate_exact`: for every exit code and JSON tree, success **iff** the exit
  is nonzero, the root is an object, status is explicitly `incomplete`, and the seeded
  `old` key is absent (present-null is not absent).
- `Native.validate_exact`: for every expected result and decoded message list, success
  **iff** compiler messages match in order and length, native identities match with
  multiplicity, exit outcome and stderr agree, native file/severity/help fields agree,
  and any requested detail is present. `nativeMatches_exact` and
  `compilerMatches_exact` establish the field and ordered-list relations separately.
- `Json.validateDecoded_exact`: a decoding error always refuses; success **iff** decoding
  yields an assertion list whose every assertion holds. `History.requirements` and
  `Producer.requirements` spell out mandatory fields and their exact comparisons.
  Their registered contracts apply this equivalence to the actual decoders; they do
  **not** prove that the observations were extracted truthfully or that Lean's JSON
  parser implements a separately formalized JSON specification.
- `Checker.ProducerReport.validate_sound`: every producer report that
  `Environment.validate` admits satisfies `Environment.Admissible`, which restates every
  executed guard: a nonempty, unique, loaded module census; a declaration census equal
  to the reported keys in order and duplicate-free; execution results exactly for the
  requested roots; `ExecutionValid` closures; unique located source bindings covering
  every claimed module and range; a replay receipt admitting exactly its unique
  requirements and requiring every safe, total declaration; documentation observations
  for exactly the claimed modules and unique material selection; unique history
  requests with exactly one history per requested module; completed histories that are
  located, source-stable, bound to the owned snapshot and free of anonymous edge
  endpoints; unavailable histories that leave every requested root unresolved;
  requested runtime replacements whose resolved edges appear in completed histories;
  root/boundary module attribution with exact replacement-edge channels; and, for every
  current replacement reference, a reached, attributed, requested and recorded module
  history, with the root's historical edges the canonical form of exactly those
  completed-history edges. `validate_eq_ok` decomposes the executed guard sequence
  exactly, `validate_nonvacuous` exhibits an admitted report by kernel reduction, and
  `fromJson_admissible` extends soundness to the transport decoder. Producers,
  documentation groups and acceptance call `checkedValidate.run`, so each call site
  requires this `ExecutableContract`. These replace the former 8 producer and 17
  history/closure/source transport mutations. They do not authenticate the observations.
- `History.validate_importedRootExecuted` and `validate_unsupported_unresolved`: every
  report the history oracle admits executes the imported registered root with a foreign
  module, and, for an unsupported evaluator, leaves every root requested from the
  audited module with nonempty unresolved evidence. These replace the former 7 oracle
  mutations.
- `Evidence.checkedValidation` and `checkedDocumentation`: exact conjunctions of decoded
  status/diagnostic/exit and transcript requirements, including distinct fence/project
  admission messages and the underlying IO reason. IO-only controls also consume the
  shared assertion contract for their observed source, closure and configuration fields.
- `Launcher.admit` returns a proof-bearing mapping with nonempty unique names and both
  required search paths; its completeness theorem admits every valid decoded mapping.
  `checkedEquivalence` requires exactly 36 observations and full ordered equality,
  including source, arguments, stdout/stderr, exit, environment and resolved executable.
  Lake's actual environment is cached only within one fixed parent/workspace invocation,
  separately for the imported-control search-path override. Neither observations nor
  compiled artifacts are reused. Environment values are not exported. Durations are
  observations, not a speed guarantee or compiler-equivalence theorem.
- `Template.instantiate` returns a required `Maps` proof for the actual recursive JSON
  transformation: ordered array entries, object keys and scalar kinds are preserved;
  only entire matching string values change. Unmatched strings stay unchanged. Depth
  exhaustion explicitly refuses; the corpus uses a 64-level budget. Semantic module
  discovery for checker snapshots uses Lake's elaborated inventory, not a source glob.
- `Checker.RuleExampleProjection.qualify_record` and its mutation/checker-source
  variants prove exact `Except String Unit` equality for arbitrary producer JSON at
  the adapter's canonical record constructor. `qualifyCorpus_records` extends this
  to the unchanged full corpus qualifier, including ordered scans, completeness and
  first refusals. `withoutSourceAccount_view` covers the existing missing-source
  control. Structural raw-tree laws avoid assuming parser well-formedness. These
  separately checked operational-module proofs do not authenticate parsing,
  duplicate-key handling, serialization, hashes, filesystem custody or subprocesses.
- `Website.hasFence_exact`: the fence guard detects exactly a contiguous triple backtick
  in the input character list. `checkedBlock` specifies refusal or exact LF-normalized
  text wrapping. `checkedPage` admits exactly fence-free SL1001 inputs and returns a
  proof-bearing `Page input`: its bytes equal the canonical `pageText input`, including
  the supplied metadata and exact LF-normalized violation/diagnostic/fixed sections.
  `checkedArtifact` proves field-level preservation of required IDs, emitted IDs (order
  and multiplicity), route and the conjunction of observed checked-example conditions.
  The driver consumes these contracts. They do not establish Verso/browser correctness.
- `StrictLeanVerification.parseMode_sound`, `parseMode_roundtrip`, and `select_exact`
  prove exact argument binding and acceptance of every documented invocation. The caller
  consumes the proof-bearing selection; recipes name the intended commands explicitly.
  `commands_nonempty` rules out a selected empty campaign. Process execution remains IO.

The positive library is audited as `standard-logical`, `execution: report`. The gate
reports each declaration's exact axiom set and each reached execution boundary;
that surface profile is an upper bound, not a claim that every proof uses choice.
No `sorry`, project axiom, native proof, authored partial or unsafe definition is permitted
on that surface. The supplied-observation contracts do not certify the entire operational
checker or all project-owned Lean code as formally verified.

## Operational assumptions and approved bootstrap

The supported compiler, filesystem, process runtime and GNU timeout are trusted mechanisms.
Unique scratch directories are removed on normal or exceptional return; a killed process
cannot promise to run its cleanup handler. Each supported public invocation has one
non-foreground GNU timeout owning the whole process group, including descendants with
inherited output handles. Acceptance passes an internal `--under-deadline` protocol flag
to `qualify` so it does not detach a nested timer/group. That private flag is not a bounded
standalone invocation or an alternative acceptance command. `TimeoutControl.lean` separately
exercises positive, descendant timeout, terminated-descendant and restored controls.
These observations are not an OS scheduling theorem.

`lake exe qualify receipt-boundaries` seeds completed evidence and exercises
actual missing/unusable timeout selection and selected-timer spawn failures for
both `acceptance` and `environments`. Each public invocation replaces the old
receipt with a fresh incomplete attempt before those fallible operations. The
timed child carries the same attempt, and adds no new deadline. Acceptance keeps
existing raw result/trace sidecars before parsing and records partial file
locations on the active case; completed command records contain executable plus
argv. These are diagnostic receipt guarantees under trusted filesystem/process IO.

The operator approved a narrow exception for the existing CI bootstrap to install pinned
Elan/Lean and required system tools before Lean is available, expose their paths, and
check availability/versions. `AGENTS.md` records its exact scope: no policy decisions,
validation logic, or test orchestration in that shell step; expansion requires explicit
approval. Installation and runtime mechanisms remain trusted, not proved by Lean.
The nonessential shell resource-reporting block has been removed. Direct commands
in CI and developer setup examples are invocation recipes, not a second implementation
language for qualification logic.

No CI, publication, merge, actual VS Code interaction, or full repository semantic
conformance is implied by local acceptance or these scoped integration results.
