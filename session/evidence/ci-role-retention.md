# PR #33 retained-role CI repair

Assigned CI phase, starting clean at `e19018e47b73ac732853ad90297bcc94d15854b3`.
The outer executor owns publication, exact-head hosted CI, issue updates, merge
and cleanup. This receipt does not approve CI or close issue #7.

## Failure and diagnosis

Hosted run `35413603172`, job `105817828895`, reached the unchanged ordinary
420-second deadline during parent result acceptance. Worker acceptance took
40.155 seconds; documentation was unrun. This is a performance failure, not the
historical invalid-inventory refusal. The supplied hosted timings do not isolate
CPU, memory or output causality.

The first candidate reused admitted plan/table facts to avoid redundant claim,
snapshot and environment-key decisions. Its proofs and two independent reviews
passed; cold ordinary acceptance passed in 260.58 seconds, and environment
qualification passed. Worker/parent acceptance remained 18.095/12.344 seconds,
versus historical local 17.854/12.242 seconds. This supplied no material timing
benefit. The candidate was removed from the working sources, with its patch,
build attempts, signatures, cold report and qualification preserved under
`tmp/ci-policy-*`. No predicate change from that experiment remains.

Two bounded stack samples were taken during the required environment campaign.
The first caught report validation, not acceptance. The second,
`tmp/ci-policy-control-sample.txt`, caught actual `finalize` / `accept` calling
the role function from `Acceptance.freeze`, repeatedly entering `authorize` and
`authorizedUnsafeRecHelpers`. That sample includes the subsequently removed
decision candidate; it is predecessor diagnostic evidence, not a measurement of
the final repair or a universal runtime claim.

## Final change and proof linkage

`freezeEnvironment` already receives `scope.roles` from actual
`Policy.admitScope`. `FrozenEnvironment.roles` now retains that receipt with
type `Roles census.policy`. `freeze` supplies `frozenEnvironmentRoles`, which
selects the stored receipt at the same array position. The prior function called
`authorize` afresh for every local job.

`Roles.eq_authorize` proves, for every inventory and every receipt indexed by
it, exact equality to recomputation. `frozenEnvironmentRoles_eq` lifts this to
equality of the entire dependent role family. Equality includes ordered native
and helper arrays, not just membership. Substitution preserves the existing
acceptance/finalization outcomes, including all refusal cases. The actual caller
uses this helper. No worker proof flag, accepted verdict, or changed census is
reused; each independently reconstructed worker/parent environment still passes
its existing admission and authorization.

`CompleteFor`, `AllPolicyOK`, `PolicyOK`, `EnvironmentStageOK`, collection,
admission checks, required jobs, modes, sources, runner, caches and deadlines
are unchanged. Generated C shows the helper only indexing the environment array
and projecting its stored roles field; the former authorization thunk is absent.
This is compiler inspection, not proof of native runtime or external IO.

The final code patch is `tmp/ci-roles-repair.patch`, SHA256
`3f80456213d375402bf1d50bef91f414a8e11740355393cffc719f2604fedd1d`.
Source hashes are `tmp/ci-roles-reviewed-sources.sha256`. The focused build
`ci-roles-proof-build4.log` and full adapter build `ci-roles-adapters-build.log`
passed. Earlier elaboration failures are retained, not relabeled successes.
`tmp/ci-roles-signatures.txt` records the exact types and transitive axiom set
`{propext, Classical.choice, Quot.sound}` for all three new declarations.

Independent reviewers `/root/policy_proof_review` and `/root/policy_call_review`
returned CLEAN for this exact final patch and its generated execution linkage.
Their scope was the changed proof/implementation claims, not full conformance,
performance, hosted CI or delivery.

## Scoped qualification

`lake exe qualify environments --evidence tmp/ci-roles-environments.json`
exited 0 with a complete receipt and restored positive. Its controls retain the
real cross-environment collision, omitted/duplicate/rebound environments, source
binding omission, replay omission, cross-environment declaration/root/role
transcript, incompatible execution, wrong snapshot and incompatible request.
Timed acceptance calls were 2.491 and 2.484 seconds, versus 12.254 and 12.271
seconds in the predecessor campaign. These local observations support reduced
work; they do not predict hosted duration or prove the external mechanisms.

All commands use Lean 4.34.0, compiler
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, with pinned Mathlib
`5ed2965256430c3649e86755f9576b54eca72435`, on arm64 macOS.
Final ordinary acceptance and the remaining diagnostic/site results are recorded
below only after their actual completion. Until then, CI remains INCOMPLETE.

## Native diagnostic retirement

The fence transport campaign exited 0 with all seven phases completed in
`tmp/ci-roles-acceptance-fences.json` and its log/retained sidecars: initial
positive, missing/duplicate/misindexed mutations and each restored positive.
The real process-group control also exited 0; `tmp/ci-roles-timeout-control.log`
records live descendant start, exit137, drained inherited pipes, observed stopped
descendant and restored positive. The observed timeout interval was 6,505ms;
this is not an OS scheduling bound.

The four retired drivers are `acceptance_checks.py`,
`acceptance_snapshot_checks.py`, `documentation_dependency_checks.py` and
`input_inventory_checks.py`. They were not executed. Independent source review
mapped every finite mutation/assertion to the native ports. Prior complete
receipts are reused for unchanged surface/evidence/source/process transport,
dependency/history snapshots, both documentation-dependency routes and root/
Markdown inventory controls; their precise files and original identities remain
in `ci-environment-census.md`. Receipt initialization, sidecar retention, complete
commands and all native control implementations are unchanged in this repair.
Exact role-family equality preserves policy decisions, with new environment and
fence qualification above. This reuse is not a new run of those campaigns.

The prior Python timeout killed a coordinator group; native acceptance checks a
worker's timeout/refusal and incomplete result, while the separate retained
`TimeoutControl` checks group termination. The documented scope split is retained,
not represented as universal old/new IO equivalence. Deleting the historical
drivers removes no required gate or control. Git history and all failed receipts
remain available.

## Resumed local completion

The continuation rechecked HEAD `e19018e47b73ac732853ad90297bcc94d15854b3`
and both reviewed source hashes; the retained-role sources are unchanged.
The producer process had ended before continuation. Its retained
`tmp/ci-roles-producers420.log` reaches the verification driver's terminal PASS
(emitted only after successful child waits), with `real 318.96`: all 18
source-owned phases, eight transport refusal/restoration controls and three
standalone executable phases passed. This establishes successful completion of
that command, not success inferred from the enclosing agent's timeout.

The prior history command was still live (time/timeout/Lean/Lake/qualify chain,
PIDs 73335/73336/73339/73362/73381). It was observed to completion without
restart: `tmp/ci-roles-history420.log` ends in the driver's terminal PASS,
`real 295.60`, and the entire recorded process chain exited. All 17 public
project/incremental/file phases and the history/closure/source transport and
decoder refusal/restoration controls passed. This is scoped diagnostic evidence,
not ordinary acceptance. No heavyweight commands overlapped in this continuation.
The four legacy-driver deletions and guide updates were already preserved at entry.

Fresh-context reviewer `/root/final_docs_review` returned CLEAN for the guide
updates, retirement mapping and historical/current status framing, covering
DOC-02, DOGFOOD-03 and scoped MUT-02/03/04. It inspected retained native control
sources and receipts and reused unchanged proof review at the exact hashes above.
This review does not establish pending command outcomes or full conformance.

### Rule-example diagnostic failure

`/usr/bin/time -p ./scripts/verify.sh diagnostics rule-examples` reached the
unchanged 420-second process-group deadline (`real 420.13`). The enclosing
macOS `time` reported abnormal termination and itself exited 1; it did not
provide a usable child exit code. This is a failed campaign, not an assertion
of child exit 137 or a passing command. The log ends after 29 qualified phases,
through SL2003/Violation. No compiler descendants remained afterward.
`tmp/ci-roles-rule-examples420.log` and the approximately 2.1 GB partial receipt
`tmp/ci-roles-rule-examples420-incomplete.json` are preserved. The receipt is
not a completed corpus or authority for all sixty phases/admission controls.

Source inspection locates cumulative checkpoint serialization in
`Qualification.RuleExamples.check`; growing output was observed during this run.
This does not isolate physical runtime causality. The failure prompted the narrow
receipt-layout repair below; no unchanged retry or deadline change was performed.
This attempt remains FAIL regardless of subsequent results.

### Discarded corpus receipt experiment and site result

The corpus adapter uses the shared pretty-layout writer for every cumulative
checkpoint and per-record admission input. Its actual consumer parses JSON values;
pretty-layout bytes are not a contract. An experimental local `writeReceipt` used the pinned
`Json.compress` plus the existing newline at exactly those four receipt writes.
Every field, snapshot acquisition, checkpoint, admission control and failure path
remains; package configuration writes and the shared helper are unchanged. No pure
policy, runner, concurrency, cache scope or deadline changed.

`lake build qualify` passed (`tmp/ci-roles-corpus-writer-build.log`). A retained
actual per-record receipt parsed identically after compact serialization in both
Lean's JSON parser and `PolicyCodec.parse`; the real `ruleExampleQualification
--record` consumer exited 0 for both original and compact files. Logs are
`tmp/ci-roles-corpus-encoding.log`, `ci-roles-corpus-reader-before.log` and
`ci-roles-corpus-reader-after.log`. This is executable protocol qualification,
not a universal serializer proof. Fresh-context source review is CLEAN at
RuleExamples SHA256 `dcd7891ef267e19f721c08f6abfef2a6c0163d58f645ae53f37d5ffc80abfc22`.
The changed-input full campaign also failed at the 420-second deadline
(`real 420.15`, enclosing time exit 1), after 36 qualified phases through
SL2005/Restored. No compiler descendants remained. Its log and partial receipt
are `tmp/ci-roles-corpus-compact420.log` and
`tmp/ci-roles-corpus-compact420-incomplete.json`. This falsified the experiment's
whole-campaign success criterion. The experiment was removed; its exact patch is
`tmp/ci-roles-corpus-compact-experiment.patch`. The corpus source is restored to
HEAD, and no speculative writer change remains. Required corpus qualification
remains FAIL; no further optimization or unchanged retry is undertaken.

Pinned site setup `lake build verso/VersoManual` exited 0 (587 jobs), entirely
inside `examples/rule-reference-prototype/site`; log `tmp/ci-roles-site-setup.log`.
`lake env lean --run examples/rule-reference-prototype/Run.lean` exited 0 in
67.66 seconds under its existing 600-second wrapper; log `tmp/ci-roles-site600.log`.
It checked native diagnostics, actual policy, Lake dependency dispatch, corrected
fixture, Verso output and identical static bytes across two renders. Editor
interaction remains unverified. This predates the corpus-only writer change;
independent review confirmed the unchanged site/shared-writer paths do not consume
corpus receipts, so this scoped site evidence is reused. Restoring the corpus
source leaves the site run's original implementation inputs unchanged.

### Final cold acceptance source binding

All retained source and guide edits are complete before this run. The exact
tracked Lean/documentation/example/workflow/configuration input hashes are in
`tmp/ci-roles-final-inputs.sha256`; the full retained diff is in
`tmp/ci-roles-final-source.patch`. HEAD remains e19018e. Root build artifacts
are preserved at `tmp/ci-roles-before-final-cold-build`, with `.lake/build`
absent at gate entry; dependency setup is retained. Final evidence-only receipt
updates do not change those source inputs. The following result is recorded
only after the single unpartitioned `./scripts/verify.sh` actually finishes.

The final cold command exited 0 in **217.86 seconds**. Log:
`tmp/ci-roles-final-cold420.log`. Worker/parent result acceptance took
3.038/2.718 seconds. Combined acceptance consumed 7,273 project and 97 document
jobs; all 70 positives, 23 negatives and one teaching fence completed with zero
failures. This is observed local acceptance, not a hosted timing prediction.
Post-run input hash verification passed without changes. The signature/axiom
query was rerun and exactly matches `ci-role-signatures.txt`.

Current coverage is **40 modules / 5,238 declarations**, not the old 5,237:
StrictLeanPolicy 17/4,180; StrictLeanVerification 1/106;
StrictLeanQualification 10/443; Audit 7/313; AuditApp including Main 5/196.
The five libraries and one executable retain standard-logical/execution-report
claims. Fixtures (60 modules) and StrictLean (67 modules) remain excluded.
[Compact exact coverage](ci-role-coverage.json) retains every selected module,
declaration name and exact axiom array separately by surface, with Lake inventory
and pin metadata. `Roles.eq_authorize` is present with exactly
`{Classical.choice, propext, Quot.sound}`. The two adapter declarations remain
outside the claimed surfaces and have the separately checked signature receipt.

SHA256 bindings:
- final raw report `tmp/ci-roles-final-cold-report.json`:
  `9d96ed98854350f8ad9068cd25374610a97d7aa7dcd1a4f985b135b5a2a9151b`;
- source-input hash list: `ae728a8c1c7e874a7ca056a6666df1855d0b44a59ff37998e361426a972e9fb4`;
- compact coverage: `8a93306988d976b6afdd489b84ea9dd224d470587c948c088c0f09dcd0dcb62f`.

## Handoff: required corpus gate remains FAIL

Producer, history, site and final ordinary cold acceptance have completed.
The required sixty-phase corpus and its terminal admission controls have not:
both bounded attempts failed and the unsuccessful writer experiment is removed.
No completed CI repair or permission to publish these changes is implied.
Further corpus repair is the unresolved local phase; no deadline, runner,
cache-scope, policy or proved-core weakening is authorized. All retained source
changes, failed attempts and receipts are preserved. No pipeline controls,
publication, GitHub handoffs, merge or owned-branch cleanup were performed.
