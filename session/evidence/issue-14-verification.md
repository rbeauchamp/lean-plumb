# Issue 14 verification record

Branch `fm/strict-lean-14-adopt` rebuilt on `origin/main` `39fc631` (the Plumb rename,
after #43 and PR #60). Lean `v4.34.0`, Mathlib `5ed2965256430c3649e86755f9576b54eca72435`,
macOS arm64. Labels: **proved** (machine-checked), **observed** (a run), **assumed** (a
trusted boundary). The earlier parked commit `73c0ecf` was rebuilt by applying the PR #66
rename mapping (plus the captain's `plumb/lint` driver name) to both its base and its diff,
then reconciling with main; it was not force-applied.

## Delivered

- `lint` (`lean/Plumb/Checker/Lint.lean`, root `LintMain`), the Lake lint driver
  (`lintDriver = "plumb/lint"`). It calls the unchanged `AxiomGate.entry` project audit
  (`--incremental`, or fresh with `--fresh`) and classifies the exit from the audit's own
  recorded status. Its success line is `Account.pass "plumb lint"` of the account the audit
  recorded, so it names the coverage (incremental never reads as fresh whole-project).
- `AxiomGate.terminalObservation` records the `Account.Status` at the points where the project
  and combined audits decide the result `status`, including runs without `--json-out`.
  `completed` carries the accepted account.
- `PlumbCore.Lint` (claimed): `Outcome`, `Observation`, `ClassifyContract`, the registration
  `checkedClassify`, `accepted_sound`, and the `--explain-config` stage list.
- `PlumbCore.EditorPolicy` (claimed `module`): `checkedEditorRequest` and
  `checkedEditorDecision`, which `Linter.Rules.request`/`declarations` now run. `PlumbCore.Policy`
  proves their correspondence with `checkedRequest`/`checkedMemberRule` (the #43 handoff item).
- `--explain-config` reuses `Manifest.load`, `Lake.surfaceInventory`, the extracted
  `AxiomGate.checkClassification` and `Acceptance.surfaceAssignments`, and runs no audit.
- Editor links: `Plumb.Linter` attaches Lean's builtin `errorDescriptionWidget` pointed at the
  registry `helpUrl`; the text URL fallback is unchanged; PL2005 pending feedback names
  `lake lint`.
- Fixtures: `examples/build-lint` gains `lintDriver`; new `examples/lake-lint-toml`
  (`lakefile.toml`, imports `Plumb.Linter`).
- Qualification: the `lint-driver` build-bound partition (`LintQualification`),
  `scripts/verify.sh diagnostics lint-driver`.
- Docs: adoption guide §6–7, standard 8 §8.12 and 9 `BUILD-01`, architecture, native linter,
  policy acceptance, foundation status (editor-linter gap closed), design influences (Lean/Lake
  interface credit), review skill, and the issue 13 status correction in `engine-producers.md`.

## Proved (axioms from `#print axioms`; all within the claimed Standard-Logical profile)

| Declaration | Statement | Axioms |
| --- | --- | --- |
| `Lint.checkedClassify` | `ClassifyContract classifyImpl`: accepted ↔ exit 0 ∧ recorded `completed a` with `a.val.mode` the requested mode; violation/configuration ↔ nonzero exit after a recorded rejection with non-configuration/only-configuration findings; everything else incomplete | `propext`, `Classical.choice`, `Quot.sound` |
| `Lint.accepted_sound` | driver exit code 0 → audit exit 0 ∧ ∃ `c` and `run : AcceptedRun c` with `c.val.mode` the requested mode, `CompleteFor` and `AllPolicyOK` | same |
| `Lint.Outcome.exitCode_injective` | distinct exit classes have distinct codes | `propext` |
| `Lint.projectStages_required` | `--explain-config`'s stage list equals `requiredStages c` for either project mode | `propext` |
| `checkedEditorRequest` | `EditorRequestContract`: `classification-only` ↦ classification, conforming spellings ↦ that profile, all else refused | `propext`, `Quot.sound` |
| `checkedEditorDecision` | `EditorDecisionContract`: none ↔ `policyFor` passes; pending ↔ its failure needs role evidence; `rule id` ↔ otherwise, `id = ruleForFailure f` | `propext`, `Classical.choice`, `Quot.sound` |
| `Policy.editor_request_sound` / `_complete` | the editor request domain is exactly `request claim` for claims other than compiler-trusting | same |
| `Policy.editor_decision_none_iff` / `_rule` / `_pending` | for the same member and request: editor passes ↔ `ruleForMember` selects none; a rendered rule is `ruleForMember`'s; pending withholds a rule `ruleForMember` selects | same |

**Assumed / checked by inspection:** that the recorded observation is this invocation's
audit (the driver resets and reads the same process-global reference around one
`AxiomGate.entry` call); that the editor's loop renders each `EditorDecision` as its finding;
process exit, IO and Lake's lint dispatch.

## Observed

Current head: macOS arm64, `ad05fef` plus the `Frontend.buildCore` change from
`linter.plumb` to `weak.linter.plumb`. The operator ran each command in a disposable
checkout, under the hard 420 s deadline:

- `./scripts/verify.sh diagnostics lint-driver`: PASS, 14 controls in two disposable
  adopters, 113 s wall. Lean format: positive, explain-config (exit 2), violation, cached
  violation, builtin-only (exit 0 with a violation present, no driver output), builtin plus
  driver (exit 1), configuration (exit 2), invalid argument (exit 2), incomplete (exit 3),
  fresh restored. TOML format: positive, editor opt-out still rejected (exit 1), live
  finding (exit 1, `VIOLATION`, from the audit's own PL1001 after an ordinary `lake build`
  cached the module with the live warning; no `build-failed` or `editorSnapshot` in the
  driver's output), fresh restored with `--fresh` (`plumb lint: PASS — fresh whole-project
  acceptance`). The TOML live-finding control runs the in-process driver build
  (`Lake.buildAuditTargets`).
- Cold `./scripts/verify.sh` (root `.lake/build` removed first): PASS in 147 s (6 claimed
  libraries, 52 owned modules, 7055 owned declarations, 9786 policy jobs for
  `freshProject`). Then cold `./scripts/verify.sh docs`: PASS in 85 s (inputs equal the
  accepted ordinary inputs).
- Warm `./scripts/verify.sh`: PASS in 126 s. Then warm `./scripts/verify.sh docs`: PASS in
  116 s.
- Defect fixed by that change: at `ad05fef` without it, `./scripts/verify.sh` failed (exit 1
  after 129 s). The failure was "fresh frontend elaboration failed for
  PlumbQualification.Template … invalid -D parameter, unknown configuration option
  'linter.plumb'", repeated for other modules whose imports do not register the option.

Decision: the weak `linter.plumb` override applies only in the `lake lint` driver's claimed
build (`AxiomGate.claimedBuild`, set by `Lint`). Lake scopes Lean options by package and
library, not by module, so the override changes the trace of every root-package module.
`axiomGate` audits, the build-lint target and `./scripts/verify.sh` therefore keep ordinary
options. A source `set_option linter.plumb true` still re-enables live warnings in the
driver's build; follow-up is
[#69](https://github.com/rbeauchamp/lean-plumb/issues/69).

Observed at `1153e48` and superseded: `lint-driver` PASS with 14 controls in 93 s. In that
run, explain-config exited 0 and the TOML live finding exited 3 with the original
`PL1001 … editorSnapshot` warning. The ordinary acceptance runs at `1153e48` took 141 s and
111 s.

Observed at `1153e48`, and still current:

- `lake exe qualify native`: PASS, 36 actual Lean source controls, after routing the editor
  linter through `PlumbCore.EditorPolicy`.
- VS Code journeys: [issue-14-editor-journeys.md](issue-14-editor-journeys.md). The adopter's
  `lake lint -- --json-out` result is 14 KB (result schema 2).

## Not established

- The published rule site. The development route returns GitHub Pages' 404 until #15
  deploys it; #10 verifies the live route.
- A concise human renderer (DESIGN-01's preferred presentation). The canonical text is
  unchanged.
- `lint-driver` in the hosted diagnostics matrix. Like `build-policy`, it stays a local,
  capability-triggered campaign under the verification-slimming decision; the driver's
  classification is proved, and the campaign qualifies only Lake dispatch and the adopter
  boundaries.
- PL2002 local-configuration refusals repeat on every following command snapshot, as
  documented. Deduplicating them is not implemented.
- Mathlib adopters, other editors, latency.
