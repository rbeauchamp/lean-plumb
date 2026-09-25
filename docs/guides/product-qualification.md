# Product qualification

This is the integrated account of the Plumb for Lean linter and its rule-reference website
(issue #10). It records, per rule and per supported route, what is proved about the executed
code, what is checked by a command, what was observed, what is trusted and what remains
semantic review. It is repository practice, not part of the normative standard; the rule
predicates live in [`docs/standard/`](../standard/README.md) and the
[coverage map](rule-coverage.md). Observations, commands, timings and revisions of the
qualification run are recorded in
[issue-10 evidence](../../session/evidence/issue-10-qualification.md).

Evidence classes used below:

- **Proved**: a kernel-checked Lean theorem about the definition that callers execute, usually
  through an `ExecutableContract` registration whose `.run` the caller invokes.
- **Checked**: a command's own validation of its output or inputs (a build, a corpus admission, a
  site check); it establishes that property for the inputs it ran on.
- **Observed**: a bounded observation of a real run (adopter journeys, editor, browser, hosting).
- **Trusted**: Lean's elaborator, kernel and compiler, Lake loading, source and dependency
  acquisition, environment extraction, worker processes, JSON transport, the native runtime,
  VS Code and the Lean 4 extension, browsers and GitHub Pages.
- **Review**: the nine residual obligations (R-INTENT … R-GRAPH) of the
  [coverage map](rule-coverage.md#residual-semantic-and-research-accounts); no command
  discharges them.

## Scope

The registry has exactly twenty-one rules (`PlumbCore.RuleId`, `RuleId.all`); every one is
`existingChecker` and has an executed emission site. The supported toolchain is the pinned
[`lean-toolchain`](../../lean-toolchain) (Lean 4.34.0); the checker imports only Lean, Std and
Lake. The only supported editor client is VS Code with the `leanprover.lean4` extension.

Success comes from one place: an `AcceptedRun` built by `PlumbPolicy.accept`, whose
`accept_iff` states that acceptance holds exactly when the run is complete for its plan
(`CompleteFor`) and every stage observation meets its policy (`AllPolicyOK`). `lake lint`
exits 0 only through `Plumb.Checker.Lint.accepted_sound` (audit exit 0 and a recorded
`completed` status of the requested mode imply such a run); its exit classes are the claimed
`PlumbCore.Lint.checkedClassify`. Those theorems prove the success direction. They do not prove
which rule a failure receives; the per-rule linkage below says which rule mappings are proved.

## Per-rule capability and evidence

`D` is the shared declaration decision: `PlumbPolicy.declarationFailure` (the first failed
requirement of `DeclarationRequirements`, `declarationFailure_ordered`), mapped to a rule by the
injective `ruleForFailure`. Project, file and documentation paths run it through
`Policy.ruleForMember` (`checkedMemberRule.run`, equal to `ruleFor` by `ruleForMember_eq`);
the editor runs `checkedEditorDecision.run`, proved equal to the project decision on the
editor domain (`editor_request_sound`/`_complete`, `editor_decision_none_iff`/`_rule`/`_pending`
in `PlumbCore.Policy`). Its proofs take the observed declaration fields (`collectAxioms`
axioms, unsafe/partial flags, contract observations) and the recomputed generated-role
evidence as given. Modes are the rule's registry `evidenceModes`, which `makeDiagnostic`
enforces at construction (a finding in an unlisted mode is an error, never a silent pass); each
listed mode has an executed emission site. For PL5001–PL5003 the correspondence is proved:
`Plumb.Checker.Acceptance.documentationPresence_modes` states that their modes are exactly the
modes whose required stages (`PlumbPolicy.requiredStages`) include documentation presence. Stage
names are the required-stage slots of `PlumbPolicy.Stage` whose observation the rule reports.

| Rule | Normative obligation | Detector and adapter | Modes (routes) | Stage | Proved linkage | Qualification | Limits | Credit |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PL1001 | §8.5; FOUND-01 | D (`projectAxiom`); `Findings.declarationFinding` | editor, incremental, fresh, file, docs | declarationPolicy | D | corpus; native, lint-driver, build-policy, fixture controls | Native teaching axioms are PL1004 | Lean `ConstantInfo` |
| PL1002 | §8.5; FOUND-02 | D (`sorryAx` in axioms) | editor, incremental, fresh, file, docs | declarationPolicy | D | corpus (diagnostic inspection that keeps Lean's warning); native, fixture controls | Lean's `sorry` warning makes project and claimed-file audits stop at PL2003 first | Lean `collectAxioms` |
| PL1003 | §8.5; FOUND-03 | D (axiom outside the standard and compiler sets) | editor, incremental, fresh, file, docs | declarationPolicy | D | corpus (project, vendored dependency); native, fixture controls | Imported axioms are not exempt | Lean `collectAxioms` |
| PL1004 | §8.5; FOUND-05 | D (compiler-trusting or native-role axiom on a conforming claim) | editor, incremental, fresh, file, docs | declarationPolicy, transcript | D; role sets from `authorize` | corpus; native, fixture controls | Editor defers role authentication (PL2005) | Lean frontend transcripts |
| PL1005 | §8.5, §4.5; FOUND-03/04 | D (`ProfileOK` fails) | editor (with `plumb.localFoundation`), incremental, fresh, file | declarationPolicy | D | corpus plus wrong-claim refusal control; native, build-policy controls | Documentation fences use Standard-Logical or teaching requests, under neither of which it can fire | Lean `collectAxioms` |
| PL1006 | §8.4; COMP-02 | D (unsafe or partial, not an authenticated helper) | editor, incremental, fresh, file, docs | declarationPolicy, transcript | D; `authorizedUnsafeRecHelpers_iff` | corpus; native, fixture controls | Editor defers helper authentication (PL2005) | Lean frontend transcripts |
| PL1007 | §8.12, §8.5; BUILD-03, THEOREM-07 | D (contract observation has a failure) | editor, incremental, fresh, file, docs | declarationPolicy | D over the observation; `Collect.executableContract?` is operational | corpus; native, build-policy controls | Adequacy of `R` and caller linkage are R-INTENT, R-INVARIANT | Lean type checker |
| PL2001 | §8.1; DECL-01/04 | Setup failures and every escaped audit error not prefixed `manifest-` (`AxiomGate` catch-all) | incremental, fresh, file | setup, before any stage | None: classification by error prefix, fail-closed | corpus demonstration (INCOMPLETE by design) | Always INCOMPLETE; `docFenceAudit` setup failures print FAIL without a finding | Lake workspace loader |
| PL2002 | §8.2; DECL-04 | `Manifest.parse`/`load`, `checkClassification`; editor `Rules.request` | editor, incremental, fresh, file | configuration | `Manifest.parse_sound`, `parseValue_complete` (excluded library, kernel-checked); `checkedEditorRequest` | corpus; structural, build-policy, lint-driver (exit 2), native controls | Routing by `manifest-` prefix is unproved; editor never guesses scope | Lake elaborated package model |
| PL2003 | §8.3; DECL-01, BUILD-01 | `Lake.buildChecked` result lines; file compile via `SourceAudit` | incremental, fresh, file | build | Acceptance side only (`BuildOK`) | corpus; build-policy, lint-driver (exit 3), `sourceDiagnosticFailure` controls | Project runs: always INCOMPLETE. File runs reject warnings only with `--claim` | Lake build |
| PL2004 | §8.2; DECL-02/03 | Inline inventory checks in `AxiomGate` | incremental, fresh | discovery | Acceptance side only (`ScopeOK`, `checkedSurfaceAssignments`) | corpus; structural, environments controls | Violation for `unexpected-project-module`; INCOMPLETE for omission, not-fresh, attribution mismatch | Lake module arrays, `.olean` origin |
| PL2005 | §8.3; DECL-01/02 | `Admission.validate`, source freshness, authentication; editor pending | editor, incremental, fresh, file, docs | admission, transcript | Acceptance side (`AdmissionOK`); `editor_decision_pending` | corpus demonstration; fixture, history controls | Always INCOMPLETE; imported base trusted | Lean `Environment.replay` |
| PL3001 | §8.6; COMP-03 | `executionFailureRecords` → `RuleDiagnostics.executionFinding` | incremental, fresh, file | execution, history | `executionFailureRecords_empty_iff`, `checkedExecutionFailures`, `executionRule_injective` | corpus demonstration; policy-domain controls | Always INCOMPLETE; closure overapproximates runtime edges; not an editor rule | Lean compiler IR |
| PL3002 | §8.6; COMP-03/04 | Same, checked-mode branch | incremental, fresh, file | execution, origin (Init native-runtime exemption) | Same; `BoundaryOK` | corpus; fixture, build-policy controls | Native runtime stays trusted; external code unproved | Lean compiler IR |
| PL4001 | §8.7; DOC-03 | `Documentation.scan` | docs | documentScan | Acceptance side (`DocumentOK`); scanner unproved | corpus; fence corpus controls | Structure only | — |
| PL4002 | §8.7; DOC-04 | `assessPositive` (D plus warning check) | docs | example | D; `ExampleExpectationOK`; `incomplete_example_refused` | corpus; fence corpus controls | Standard-Logical only | Lean elaborator |
| PL4003 | §8.7; DOC-05 | `auditNegative` with `matchesPattern` | docs | example | `matchesPattern_iff` on the executed matcher | corpus; fence corpus controls | Worker non-completion is INCOMPLETE | — |
| PL4004 | §8.7; DOC-05 | `assessPositive` teaching branch | docs | example | `checkedMemberFoundation`, `labelOf_member` | corpus plus teaching refusal controls | Never a conforming positive | Lean frontend transcripts |
| PL5001 | §5.3; DOC-01 | `Linter.Documentation.modulePresent` | editor, incremental, fresh | documentationPresence | Acceptance side (`DocumentationPresenceOK`, `modulePresence_iff`); presence predicate unproved | corpus; native, producers controls | Presence only (R-DOC) | Lean module-doc APIs |
| PL5002 | §5.1; DOC-01 | `materialDocumentationFailure` on `findDocString?` of `@[plumb_material]` public declarations | editor, incremental, fresh | documentationPresence | `materialDocumentationFailure_eq_none_iff`/`_missingDocstring_iff`, `ruleForMaterialDocumentation_injective` | corpus; native, producers controls | Registration completeness is R-DOC | Lean `findDocString?` |
| PL5003 | §5.2; DOC-02 | Same, missing Intent section | editor, incremental, fresh | documentationPresence | `materialDocumentationFailure_eq_missingIntent_iff`, `hasIntentSection_iff` | corpus; native controls | Presence only; intent adequacy is R-INTENT | Lean `findDocString?` |

"Corpus" is the [rule-example campaign](rule-examples.md): one violating and one corrected
record per rule in fresh workspaces, admitted by the proved `ruleExampleQualification` relations
and rendered on the rule's page. It qualifies the detectors on those inputs; it does not prove
them correct for every input. The registry, complete acceptance and executed-form equality draw on
con-leche's designs (see [design influences](design-influences.md)); the credit column names the
Lean facility each detector observes.

**Foundations of the cited proofs.** Theorems in `PlumbPolicy` and `PlumbCore` belong to claimed
Standard-Logical surfaces: ordinary acceptance re-elaborates them from source and checks each
declaration's exact axiom set against that profile. Theorems in the excluded `Plumb` library
(`Manifest.parse_sound`, `parseValue_complete`, `Plumb.Site.Build.helpUrl_dev`) are
kernel-checked by the warning-as-error `lake build`; `foundation_manifest.json` records an
in-module `collectAxioms` Standard-Logical ceiling for that library's transport-admission
theorems. The acceptance audit does not inspect them. The hypotheses of
the `D` theorems are stated above; the others are the observations named in each row.

**Evidence commands.** Each "Qualification" entry names a campaign run by
`./scripts/verify.sh diagnostics <partition>` (fixtures, structural, cli, environments,
build-policy, lint-driver, producers, history, rule-examples 1/2 and 2/2) or inside ordinary
acceptance (registry, native and CLI qualification). The runs for this change, with exact
revision and timings, are listed in the [evidence record](../../session/evidence/issue-10-qualification.md#commands-and-results-for-the-10-change);
campaigns not listed there were not rerun and keep their earlier recorded evidence.

Every declaration, context and execution finding is a `Diagnostic id` whose `helpUrl id` is the
development route of `id` (`Plumb.Site.Build.helpUrl_dev`), and whose text is
`messageLine id …` (`PlumbCore.Rule`) followed by that URL: the same definition the registry and site publish as
the rule's message form.

## Supported routes

| Route | What runs | Result | Evidence |
| --- | --- | --- | --- |
| Editor, `import Plumb.Linter` | Command and module hooks over the current snapshot | `editorSnapshot` feedback: PL1001–PL1007, PL2002, PL2005, PL5001–PL5003 at their ranges; never project acceptance | Proved editor/project equality above; observed in VS Code ([#14 journeys](../../session/evidence/issue-14-editor-journeys.md), #10 journey) |
| `lake lint` | `plumb/lint` driver: builds the manifest's targets with the audit-build marker (local findings off whatever the source sets `linter.plumb` to), then the `axiomGate` project audit | `incrementalProject`; exit 0/1/2/3 | `accepted_sound`, `checkedClassify`; `liveFeedback_auditBuild`; lint-driver campaign (17 controls); #10 fresh-adopter journey |
| `lake lint -- --fresh` | Same audit in an isolated copy from empty build output | `freshProject`, the only fresh whole-project claim | Observed PASS in the fresh adopter |
| `lake lint -- --json-out PATH` | Same audit, result schema 2 | `status`, diagnostics with `helpUrl` and source ranges | Observed |
| `lake lint -- --explain-config`, `--help` | No audit | Exit 2; establish nothing | Observed (both); lint-driver campaign covers `--explain-config` |
| `lake exe lint` | Same driver without Lake dispatch | As `lake lint` | Observed PASS in the fresh adopter; for packages whose `lintDriver` is taken |
| Build-lint `policy` target | Sole default target runs `axiomGate --build-lint` | Incremental audit; failure fails `lake build` | build-policy campaign |
| `lake exe axiomGate` | Fresh project audit (default), `--incremental`, `--file F [--claim P]`, `--with-docs` | Accepted account and exit status | Ordinary acceptance dogfoods it on six claimed libraries |
| `docFenceAudit`, `./scripts/verify.sh docs` | Every Lean fence under `docs/` | `documentationExample` | Acceptance step 2 |
| Workers | `axiomGate` inspection and fence diagnostic workers, with indexed result admission (`checkedIndexedResults`) | A crashed, abnormally terminated or incomplete worker is INCOMPLETE, never a pass | Proved admission; fixtures and fence-corpus controls (abnormal termination) |
| `freshChecker` | Optional serialized-graph recheck (§8.9) | Emits no rule findings | Optional MUT-05 claim; not part of product acceptance |
| Direct `lean`, `lake build <other target>`, `lake lint --builtin-only`, TOML `lake build` | Nothing of Plumb's project audit | Not enforcement | Documented as such everywhere |

Incremental and cached paths re-evaluate current policy on every run: the driver and the
`policy` target have no cached verdict, and a configuration change reloads the manifest
(lint-driver repeated cached violation and build-policy cached-failure and
configuration-change controls). Local
options (`linter.plumb`, `plumb.localFoundation`, `warningAsError`) change only local feedback;
the project audit still rejects. A cancelled editor collection reports nothing for that declaration (observed in the
[#14 journeys](../../session/evidence/issue-14-editor-journeys.md#stale-and-cancelled-snapshots)),
and a failed one reports PL2005 (`Plumb.Linter` `unavailable`), never an invented rule or a PASS. Unknown rules cannot occur: the
registry is closed, and codecs refuse unknown IDs, fields and modes.

## Adopter journeys

On a new project that requires Plumb by Git revision `a52bf1f` (the published `main` before this
change) and follows the [adoption guide](adoption.md) (details in the evidence record). These
runs exercised the base revision; the #10 changes to evidence modes, message rendering,
explanations and credits are covered instead by ordinary acceptance, both corpus shards, the site
build and the lint-driver and producers campaigns at this change's revision:

- `lake lint` accepted the clean project (exit 0), and `lake lint -- --fresh` gave fresh
  whole-project acceptance.
- A project axiom gave PL1001 at its declaration with the rule URL (exit 1); a Choice-Free
  surface using `Classical.byCases` gave PL1005 (exit 1), and the documented fix (a proof with
  fewer axioms) returned exit 0; an unclassified library gave PL2002 (exit 2), fixed by an
  exclusion; a missing module docstring gave PL5001 (exit 1); an unused-variable warning gave
  PL2003 (exit 3); `set_option linter.plumb false` did not hide a PL1001 violation (exit 1).
- A second library importing `Mathlib.Algebra.Group.Basic` (Standard-Logical) was accepted by
  `lake lint` and `lake lint -- --fresh`.
- A `sorry` gave PL2003 (exit 3), not PL1002: Lean's own warning stops the audit first. The
  PL1002 page and the adoption guide now say so.
- In VS Code, the same `sorry` showed Lean's warning and PL1002 at the declaration with code
  `Plumb.PL1002`, the text URL and Lean's **View explanation** anchor (`target=_blank`,
  `rel="noreferrer noopener"`, no Lean-manual link). A trusted click reached the anchor, and the configured
  external browser started immediately afterwards; the URL it received and the page it showed
  were not observable from this environment. The same URL serves the matching PL1002 page of
  the deployed commit. The documented fix cleared the diagnostic, and `lake lint` accepted.

These are bounded observations of real runs, not theorems about the tools.

## Website

- **Proved** (claimed `PlumbCore.Site*` and `PlumbCore.Guide`, except `helpUrl_dev` in the excluded
  `Plumb.Site.Build`): one page route per rule per edition and none shared
  (`pageFiles_nodup`, `mem_pageFiles`), escaping (`escape_safe`, `htmlBlock_ok`), filter no-match
  set (`mem_emptySelections`), link-check soundness for scanned links (`linkErrors_nil_iff`), the
  nine sections (`ruleSections_headings`), nonempty explanations (`guide_wellFormed`), archive
  monotonicity (`artifactRevisions_mono`), and `helpUrl_dev` for every emitted help link.
- **Checked** by `./scripts/verify.sh site`: evidence identity and freshness, exact rule-route
  set, example text in pages, `axiomGate --validate-site`, byte-identical editions, size budget.
  CI's `verify-deployment` checks the live `build.json`, every rule page of every edition and
  the 404 route byte for byte against the validated artifact.
- **Observed** on the live site (deployed `a52bf1f`, before this change): all 21 `dev/` and `rev/` rule routes return their pages;
  unknown IDs, unreleased versions and unpublished revisions return the not-available page (HTTP
  404) without redirecting; search finds rules; keyboard traversal reaches the table of contents
  and rule index with visible focus; the index lists 21 rules. At 390 px every rule page scrolled
  horizontally because the attribution's commit hash did not wrap; #10 adds wrapping for inline code and
  links; its local build of this change showed no horizontal scroll at 390 px on any
  rule page or on the index, versions and credits pages (the credits page's long plain-text URL,
  also present on the live site, is covered by paragraph wrapping).
- **Hosting**: GitHub Pages project site from GitHub Actions, no custom domain, no release, no
  paid hosting. The site lags `main` while checks run; each page names its commit. Operator
  settings not configured: `site` and the corpus shards are not required status checks, and
  `site-archive` has no force-push/deletion protection ([website guide](website.md)).

## Changes made by this qualification

Review of the delivered product found and fixed:

- Registry evidence modes that no path emits: PL1005 and PL2001–PL2003 no longer list
  documentation examples, PL2004 lists only project modes, PL5001–PL5003 list editor and
  project modes. The site's evidence-mode filters and each page follow.
- PL1007 cited §8.6; its predicate is stated in §8.12 and §8.5.
- The published message form (`PL1001:{subject}:{detail}`) was not what the checker prints; it
  is now derived from the same `messageLine` the checker renders, and the account text names
  PL1007 through the registry.
- Explanations: the `sorry` route (PL1002), the editor's actual scope (PL2005, PL3001, PL5001),
  PL2004's two impact classes, PL2001's catch-all role, PL2003's file-mode `--claim` condition,
  INCOMPLETE fence outcomes (PL4002–PL4004), complete checklist rows, and a rule-specific
  strict-impact row with `lake lint` exit classes.
- Credits: the adapted Lean JSON parser (Apache 2.0) now has its verbatim notice, the Apache
  text in `LICENSES/`, and a credits entry; Verso's license is linked; the CDN-loaded marked
  library, Batteries and the vscode-lean4 infoview are credited; no endorsement is implied.
- Narrow-screen layout: long inline code, links and paragraph text now wrap.
- A theorem (`documentationPresence_modes`) now fixes the documentation-presence rules' modes to
  the stage structure at build time.
- Stale documentation: two-command acceptance, twenty-one rules, delivered integration, the
  docs index.

## Remaining limits

- The human transcript names the file and declaration of a finding; exact ranges are in
  `--json-out` and the editor.
- PL2001/PL2002 routing of escaped errors is by error-message prefix, and PL1007 contract
  extraction, PL2004 inventory checks, the fence scanner and PL5001 presence are operational
  code in the excluded `Plumb` library; the acceptance theorems cover their observations, not
  their extraction.
- Editor: only VS Code with the Lean 4 extension; no latency claim; the browser-side page view
  after the external hand-off is not observable from this environment beyond the process
  hand-off and the live route.
- A small Mathlib-importing library was accepted incrementally and fresh; there is no
  Mathlib-scale adopter, Mathlib-driver coexistence run (`lake exe lint` beside `runLinter`) or
  other-editor claim, and no released versions (`/v/` pages need a separately authorized
  release).
- Diagnostic help links target the moving `/dev/` route, so an adopter pinned at an older
  revision reads the latest deployed explanation there; the unchanged text of any published
  revision stays at `/rev/<commit>/rules/<ID>/`, and versioned `/v/` links await a release.
- Native blocker [#43](https://github.com/rbeauchamp/lean-plumb/issues/43): its delivery (PR 64)
  is merged, but the issue was still open when this qualification ran.
- All nine residual obligations stay open; every accepted account lists them.

## Optional external checking

[#8](https://github.com/rbeauchamp/lean-plumb/issues/8) (con-leche export research) is pending
with no go/no-go decision, and [#9](https://github.com/rbeauchamp/lean-plumb/issues/9) (adapter)
is conditional on a go decision from #8. Neither is part of or blocks core delivery, and neither
is complete. Con-ron is excluded.
