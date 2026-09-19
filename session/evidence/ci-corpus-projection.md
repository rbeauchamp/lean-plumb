# PR #33 corpus representation repair

Assigned CI phase at HEAD `e19018e47b73ac732853ad90297bcc94d15854b3`.
The outer executor owns publication, hosted exact-head CI, merge and issue handoffs.
This receipt does not close issue #7 or replace the required hosted corpus result.

## Retained evidence and bounded change

The retained-role repair and its exact role-family equality are unchanged. Its
producer318.96, history295.60, site67.66 and cold ordinary217.86 results remain
historical scoped evidence in [ci-role-retention.md](ci-role-retention.md).
The two failed full corpus attempts remain FAIL, with their logs and multi-GB
partial receipts preserved under the original `tmp/ci-roles-*` paths. Their macOS
time wrappers exited1 without a usable child status; no child exit137 is inferred.
The removed compact-only experiment is not retried unchanged.

The corpus adapter now constructs a qualification-only result view, replacing the
values of top-level `acceptance` and `documentationAcceptance` with null. It keeps
every key and the original raw-tree shape; all required nested values are unchanged.
Full-result source-alias, configuration and selector extraction still precedes
projection. Raw detector output is written directly to durable attempt/rule/phase
sidecars before parsing. Original bytes, command/request/pre-source state, partial
stream files, terminal exit/streams/post-source state and canonical compact records
are retained. Synthetic mutations identify their original observation honestly.

The unchanged qualifier still decides every record, internal mutation, ordered
sixty-phase scan and terminal corpus check. Explicit wrong-claim, classification,
demonstration, displayed-source/binding and missing-source-account controls and
restorations remain. No partition, deadline, runner, cache or policy change is made.
The CLI body moved unchanged to `RuleExampleQualificationMain.lean` so the adapter
can import the pure qualifier without importing a competing global `main`.

Progress receipts remain INCOMPLETE. Terminal PASS additionally requires readable,
matching canonical records, registrations, terminal metadata, raw SHA256/length,
streams and final checker-source equality. Canonical corpus construction avoids
the former final whole-artifact rereads. The standalone wrapper invalidates stale
PASS before timer setup; the verification Lean driver invalidates before its
check/build setup. Failure of the outer shell's prerequisite timeout discovery
occurs before that Lean driver and is not covered by its receipt invalidation.

## Machine-checked execution correspondence

`JsonProjectionTree.map_insert` and `get_map` preserve exact raw-tree operations
without ordering/balance assumptions. `RuleExampleProjection.qualify_record`,
`qualifyMutations_record` and the checker-source injection variants quantify every
canonical metadata list and every producer Json. Their conclusion is exact
`Except String Unit` equality, including first refusals, malformed values and
missing-versus-null distinctions. `withoutSourceAccount_view` covers the existing
control's getObj/toList/filter/mkObj reconstruction, including its error outcome.

`RuleExampleCorpusProjection.qualifyCorpus_records` quantifies arbitrary corpus
metadata and an array of arbitrary record metadata/result pairs. Its private
decomposition is definitionally equal (`rfl`) to the actual unchanged
`qualifyCorpus`. Filter transport retains errors and array order. Schema, selected
uniqueness/completeness, source equality/nonemptiness, phase counts and ordered
rule/phase traversal all remain, including failures before record admission.
The adapter calls the proved `record`, `resultView` and `corpus` constructors.

Builds passed in `tmp/ci-corpus-tree-build.log`,
`tmp/ci-corpus-correspondence-build.log` and
`tmp/ci-corpus-adapter-final-build.log`. Exact signatures and axioms are in
`tmp/corpus-projection-axioms.log` and `tmp/ci-corpus-full-axioms.log`:
the audited capstones use exactly `{propext, Classical.choice, Quot.sound}`.
Lean4.34.0/compiler293d5d0c0c3f3dded4688b3ccd6a33939ac5102b and Mathlib
5ed2965256430c3649e86755f9576b54eca72435 remain pinned.

Fresh independent proof reviewer `/root/projection_review` returned CLEAN for the
structural, projection and corpus claims and actual constructor linkage. Fresh
independent adapter reviewer `/root/adapter_final_review` returned CLEAN for
source custody, control preservation and success ordering; that ordering verdict
was superseded by the two concrete findings below. It also identified that the
first sidecar control receipt lacked intended-reason assertions and a killed
stream control. The focused follow-up below closes those evidence gaps. Frozen
source bindings are `tmp/ci-corpus-reviewed-inputs.sha256`.

These are supplied-data proofs and scoped source reviews, not proofs of the
parser/duplicate-key semantics, serializers, SHA256 tool, filesystem/process IO,
compiled runtime, scheduling or future deadline compliance. No pure theorem
authenticates the raw observations. No full repository conformance is inferred.

## Focused custody and process qualification

`tmp/ci-corpus-sidecar-controls.log` records seven intended-reason refusals and
eight restored/original admissions through the actual `validateRaw`: missing raw,
same-length changed bytes, changed stdout, wrong canonical slot, missing terminal,
unreadable raw directory and stale attempt. Malformed retained JSON refuses with
its parser reason while original bytes remain intact. The real public invalid
selection command replaces a seeded PASS with INCOMPLETE before refusing.
The first insufficient control log and intermediate failed assertions are retained.

The killed-observer control exposed a real initial drain defect: after the child
flushed stdout/stderr and wrote a separate ready marker, a 65,536-byte pipe read
had left both durable files empty. `ci-corpus-kill-control-blocked-read.log`
preserves that failure; earlier startup-ambiguous attempts are also retained.
The repaired drain uses getLine/putStr/flush. The same marker-confirmed control
now passes (`ci-corpus-kill-control.log`): actual GNU-timeout process exit137,
retained completed-line markers, no fabricated terminal result, and the initial
INCOMPLETE receipt unchanged. Its restored normal observer preserves multibyte
UTF-8, CRLF and a final unterminated line exactly. Sources are
`tmp/CorpusSidecarControls.lean`, `CorpusKillControl.lean`,
`CorpusObserveControl.lean` and `CorpusStreamWorker.lean`.

This control exercises the actual observe function and receipt initializer, not
a killed full corpus. A pending unterminated line can remain buffered on kill;
only a terminal observation claims complete streams. Raw detector-result bytes
are written independently and are never reencoded. The targeted repaired module
build passed in `tmp/ci-corpus-line-drain-build.log`.

## Required full runtime results

The prior projection attempt also failed at 420.15 seconds after 56/60 phases;
`tmp/ci-corpus-projection420.log` and the preserved
`tmp/ci-corpus-projection420-incomplete.json` retain this third failed attempt.
It does not supersede or erase either earlier corpus timeout.

### Ordering and redundant-prefix repair

Independent review in `/private/tmp/issue7-corpus-adapter-review.md` found PASS
saved before scratch cleanup and derived controls submitted before durable
retention. Both findings were confirmed and repaired. `admitRecord` now saves
the exact submitted mutation, origin record path and mutation label before its
scratch write or qualifier invocation. `check` returns its completed JSON from
`withScratch`; only after `finally` cleanup succeeds does the caller save PASS.

The repeated growing-prefix aggregate save was removed: each producer already
retains its canonical record and raw observation before returning. The initial
INCOMPLETE receipt points to the unique raw attempt; the complete aggregate is
saved before terminal qualification. Per-record fresh checker snapshots,
admission, all sixty phases, special controls, restorations, terminal qualifier,
raw validation and final source equality remain unchanged.

Fresh reviewer `/root/ordering_review` checked actual `Support.withScratch`
ordering and both repairs, then separately checked prefix-removal preservation:
CLEAN. Prefix-removal adapter SHA256
`72ea170dac7ef92d7118157a79036df5308b61b15470f02b8507e7cb45e64ca8`;
Support SHA256 `25dc899028d1bb16778b9b3c3a35f277d2744910624a59e0cc3ef0d5e785c886`.
Targeted builds passed (`ci-corpus-ordering-build.log`, `ci-corpus-prefix-build.log`).
`tmp/ci-corpus-ordering-sidecar-controls.log` rechecks all existing intended
refusals/restored positives and public stale-PASS invalidation. The executable
`tmp/CorpusDerivedRetention.lean` invokes the actual adapter admission with each
of the three mutation labels, observes unexpected qualification refusal and
completed scratch cleanup, then compares retained record/origin/label exactly.
All three pass in `tmp/ci-corpus-derived-retention.log`. These are observed
filesystem/process outcomes, not universal IO authentication proofs.

The prefix-only repair also failed at 420.12 seconds after 56/60 phases:
`tmp/ci-corpus-prefix420.log` and `tmp/ci-corpus-prefix420-incomplete.json`.
Removing prefix writes did not establish sufficient runtime improvement.

Inspection then identified another retained pretty-print boundary: the large
temporary `current.json` passed to per-record admission still used `writeJson`.
That one call now uses the existing compact `save`, preserving the exact supplied
JSON, before/after snapshots and external qualifier invocation. Independent
`/root/ordering_review` follow-up is CLEAN at adapter SHA256
`2b2c38f49a5bcdbc7178f8d236454c5c5b46a4c083e738cc7b84ea57ad329bdd`.
`tmp/ci-corpus-admission-build.log` passes. The actual retained admission input
was checked under both parsers and both encodings through the real external
consumer, including intended changed-source refusal and positive restoration:
`tmp/ci-corpus-admission-encoding.log` PASS. The probe's initial compile error
is retained separately; it was a missing BEq instance for Except in the probe,
repaired by comparing the successfully decoded Json values.

The compact-admission attempt failed at 420.10 seconds after 56/60 phases:
`tmp/ci-corpus-compact-admission420.log` and
`tmp/ci-corpus-compact-admission420-incomplete.json`. No running child remained
after either new deadline failure. The macOS time wrapper returned 1 with its
abnormal-command/signal diagnostic; no direct child exit code is invented.
No new corpus attempt passed its special controls or terminal qualifier. The
whole-campaign runtime hypothesis is therefore falsified; neither removal nor
compact formatting establishes the required runtime margin.

Read-only causal review of retained detector timings found 56 completed calls
totalling 754,299 milliseconds of overlapping elapsed time in the prefix-only
attempt. This is not summed CPU time. A sampled SL1001/Fixed detector spent
2,531 + 3,108 ms in dependency snapshots, 1,066 ms in terminal Lake inventory,
1,232 ms in imports/kernel admission and 0 ms in result acceptance. These required
boundaries were preserved. No further checker optimization or scheduling change
was inferred from that sample. Early queue refill was considered but not applied:
it could launch/drain an additional producer after an admission refusal and alter
failure reporting near the deadline.

The eleven exact compiler-emitted signatures and axiom closures are now retained
in [ci-corpus-signatures.txt](ci-corpus-signatures.txt), generated by
[ci-corpus-signatures.lean](ci-corpus-signatures.lean), exit 0. Every listed axiom
set is exactly `{propext, Classical.choice, Quot.sound}`. Earlier logs remain.

Final cold ordinary420 passed in **224.40 seconds**, exit 0, with the root build directory moved to
`tmp/ci-corpus-before-cold-build`; dependencies alone remain provisioned. Its
source inputs are frozen in `tmp/ci-corpus-cold-inputs.sha256`, including all new
modules and changed Lake/verification roots. The complete command is
`./scripts/verify.sh`, without partition or root-output reuse. The retained full
log is `tmp/ci-corpus-cold420.log`; post-run input hashes all match. It accepted
7,278 project and 97 documentation jobs, with 70/70 positive fences, 23/23
negative fences and 1/1 teaching classifications, zero failures.

[Current exact coverage](ci-corpus-coverage.json) records all 40 modules and
5,238 declarations with their individual axiom arrays: StrictLeanPolicy 17/4,180;
StrictLeanVerification 1/106; StrictLeanQualification 10/443; Audit 7/313;
AuditApp including Main 5/196. The five libraries and one executable keep their
standard-logical/execution-report claims. Fixtures remains excluded at 60 modules;
StrictLean now has 71 excluded modules, including the four new operational/proof
modules. Their selected projection proofs are separately checked above. Earlier
`ci-role-coverage.json` remains historical, not overwritten.

[Current input hashes](ci-corpus-inputs.sha256) bind all source/configuration,
guide, fixture and workflow files selected for this run, including new modules.
Raw current report: `tmp/ci-corpus-cold-report.json`, SHA256
`647e042f31c6985c3d822843312bdb5699c070c8c710e54ea6d077c5f99a5f6b`;
coverage SHA256 `e4924e8d1e093815f0651d9b3744bd52106e6f74617796bf4491ecd327268141`;
input-list SHA256 `68aaad039fbb5378cade1fbf599d9cc45766a38c4a0a984ce39f503a85a06a1c`.
Evidence-only updates after this gate do not change its Lean/docs inputs.

The final adapter's actual success path was separately exercised with
`lake exe qualify rule-examples --evidence tmp/ci-corpus-ordering-scoped.json --rules SL2005`.
It passed all three phases, the relabel/stale-source/missing-sourceAccount
controls and restorations, and its scoped terminal qualifier. This invocation
retains its normal 420-second wrapper. `tmp/CorpusScopedCleanup.lean` reads the
emitted receipt: PASS is explicitly scoped (`completeCorpus=false`), all three
producer directories are absent, and all three exact derived submissions equal
their retained origin/label/record sidecars. It passed in
`tmp/ci-corpus-ordering-readback.log`; the command log is
`tmp/ci-corpus-ordering-scoped.log`. This observes cleanup at readback; independent
source review establishes that the actual PASS write follows cleanup. It is not
a partitioned replacement for the failed mandatory full-corpus command.

The required full corpus remains FAIL and the CI repair is INCOMPLETE.
Do not publish this checkpoint as a successful repair. The outer executor owns
hosted evidence and publication; no pipeline control or publication was performed.

### Same-run continuation checkpoint

HEAD remains `e19018e47b73ac732853ad90297bcc94d15854b3`; all inherited and new
changes remain uncommitted in this worktree. All failed logs/receipts and raw
attempt directories are preserved. No Lean/Lake/qualifier/timeout child remains.
Final source-input hash checks and `git diff --check` pass. Both concrete ordering
findings are closed; exact proof signatures/axioms, native sidecar controls,
scoped actual success/cleanup and current cold coverage are available above.
Independent `/root/ordering_review` final reconciliation is CLEAN for these
scoped evidence claims, including current artifact hashes and the explicit
full-corpus FAIL/CI INCOMPLETE disposition.
The still-open obligation is a contract-preserving repair that completes the
full sixty-phase corpus, all special/internal controls and terminal qualifier
inside the unchanged 420-second deadline. Do not retry unchanged passed gates
or the same failed corpus candidate. No claim of exact-head hosted CI, merged
delivery or issue closure is made.
