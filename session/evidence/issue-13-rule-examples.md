# Issue 13 rule corpus — merged-engine qualification

This is the examples worker's scoped evidence, not issue-13 completion. The corpus is
rebased on reviewed main `0df758a92856b6a268882eada641773af5684d80`, integrated by
https://github.com/rbeauchamp/strict-lean/pull/30. The original signed checkpoint
`8453a8ec591807ecf4157924571aad1132cd058d` was preserved and safely rebased to signed
`4d1c08342e6ad4aa036b84ef05724baee2d9f7bd`. This report includes the subsequent adapter
integration working tree. Full cold ordinary420, independent review, exact-head CI and
corpus merge remain for Firstmate's no-mistakes invocation.

## Checked pure guarantees

`StrictLean.Website` preserves the four accepted-example classifications. Separate
`DemonstrationRequest` / `admitDemonstration` require bound, completed diagnostic production,
exact canonical findings and an incomplete finding in the actual observed list. The returned
subtype retains the supplied observation unchanged with its `DemonstrationOK` proof.
`demonstration_not_accepted` proves that the executed `validateBoundExample` refuses every
admitted demonstration for every accepted classification and every expected finding list.
`StrictLeanPolicy.incomplete_example_refused` preserves the pure fence refusal.

Compiler checks passed for these six new theorem declarations:

- `StrictLean.Website.admitDemonstration_complete`
- `StrictLean.Website.admitDemonstration_sound`
- `StrictLean.Website.demonstration_completed`
- `StrictLean.Website.demonstration_observed_incomplete`
- `StrictLean.Website.demonstration_not_accepted`
- `StrictLeanPolicy.incomplete_example_refused`

Each exact transitive axiom set was `[propext, Classical.choice, Quot.sound]` on Lean 4.33.1
(`819816b2e0a3bf405af45ae5c7af2491d8f5bee6`). The qualifier contains a compiler-time ceiling
check for the same named theorems. This proves relations over the actual pure definitions;
it does not authenticate IO, subprocesses, Lean metaprogramming observations or binaries.
No JSON-renderer injectivity premise is needed for the incomplete/accepted separation.

## Complete corpus qualification on the merged engine

`./scripts/verify.sh diagnostics rule-examples` passed, exit 0, in **227.61 seconds**
under its unmodified 420-second process-group deadline. This is a separate diagnostic
campaign, not ordinary acceptance. It built its executables/modules and qualified all
twenty registry rules in disjoint fixed, intended diagnostic and restored phases:
**60 actual records**. The exact transcript is
[issue-13-rule-examples-qualification.txt](issue-13-rule-examples-qualification.txt).

The Lean qualifier also refused five single mutations of a real production record
(abnormal exit, changed source/configuration, wrong mode, stale revision and a forbidden
fifth accepted kind), checking the intended reason and restoring the original between
mutations. These qualify the operational adapter; the six general pure guarantees above
are not inferred from those observations.

The canonical local export is `tmp/rule-examples.json`, with `completeCorpus=true`, exact
before/after source/configuration and checker bytes, every result, original compiler output
and command. All sixty producer identities were
`4d1c08342e6ad4aa036b84ef05724baee2d9f7bd:unreleased-worktree`; their checker snapshots were
unchanged. This is exact-source working-tree evidence, not authenticated binary provenance
or a clean reviewed-head claim. CI regenerates the artifact at its own head.

Previously, nineteen independent rules passed 57 records before engine integration. That
scoped evidence never claimed SL2005 or the complete corpus; the current complete run
supersedes it for integrated behavior. A focused SL2005 fixed/violation/restored run also
passed through the merged public project path before the complete run. Its malformed
owned proof now produces exactly SL2005/admission/incomplete with kernel-admission detail
and honest project attribution, rather than the old base's unrelated SL2001.

The first maintained attempt exposed a missing dependency-build directory in the hole-only
adapter. The adapter now builds its actual declared dependency targets. File fixtures live
outside the positive library used for dependency preparation. The negative hole path retains
its compiler warning and runs real SourceAudit admission and Policy detection; its correction
uses the ordinary warning-rejecting gate under the same Standard-Logical maximum. Focused
SL1002 and SL1003 fixed/violation/restored controls passed before the nineteen-rule run.

SL2001 and SL3001 observations remain INCOMPLETE diagnostic demonstrations. They do not count
as accepted rejection or positive program evidence. SL1004 retains both generated axiom and
parent findings; SL4002 retains its wrapper and underlying SL1001 finding. No location or
finding was discarded to make qualification pass.

## Operational adapter integration and trust

`Checker.RuleExamples` uses the merged `SourceAudit.compile` and `inspectOutcome` typed
results. Its negative-hole route freezes original source, dependencies and configuration
before building. It reuses `SourceBinding.withUnchanged` around discovery and the entire
build/compile/inspect/result-construction operation. A typed refusal or IO exception emits
no qualifying success record. Final serialization follows the successful guard.

The documentation route freezes the copied project's source/configuration before its
build and passes those same snapshots into `Documentation.auditBuiltProject`. It freezes
Markdown separately (documents are not invented Lean module identities), checks the exact
text on successful and exceptional returns, and serializes only after all guards complete.
These are small adapters over the reviewed engine owner, not copied detector semantics.
Before/after equality does not rule out transient change-and-restore; compiler, process,
filesystem and extraction authenticity remain trusted as documented by the engine.

## Live contracts and remaining delivery gates

Issues 13, 7, 14, 15 and 10 now contain the approved example/demonstration distinction;
exact body readback was verified. The amendment retains all four accepted kinds, exact
completed production/source/configuration/mode/diagnostic binding, positive corrections,
multiple findings and honest module/project attribution. Historical numerical summaries
were compacted to their maintained evidence pointers to fit GitHub's issue-body limit;
requirements and acceptance checkboxes were preserved. No issue state, native blocker or
project status was changed. #13 remains open and blocks #7.

The complete all-twenty diagnostic above does not discharge the unpartitioned cold-root
`./scripts/verify.sh` gate. That run, fresh independent semantic/proof and operational/
metaprogramming reviews, focused repair review, exact-head CI and merge remain mandatory
inside the selected no-mistakes delivery path. Existing engine producer/history campaigns
retain their own evidence; none is relabelled PASS by this corpus run. The older structural
campaign remains unrun. Global Accepted is #7; actual editor/site integration is #14/#15.
