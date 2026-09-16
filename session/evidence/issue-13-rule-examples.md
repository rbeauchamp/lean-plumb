# Issue 13 rule corpus — work in progress

This is the examples worker's scoped evidence, not issue-13 completion. Engine producer
integration, final full-corpus qualification, ordinary420 acceptance, independent review,
exact-head CI and merge remain pending. Base: `b64747b7ce16d5850c11f9798d46dfa5fe5b9b17`.

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

## Observed independent qualification

The maintained runner passed all nineteen rules independent of the pending SL2005 repair:
SL1001–SL1007, SL2001–SL2004, SL3001–SL3002, SL4001–SL4004 and SL5001–SL5002.
Each had disjoint fixed, intended diagnostic and restored phases: 57 actual records.
The Lean qualifier also refused five single mutations of a real record (abnormal exit,
changed source/configuration, wrong mode, stale revision and a forbidden fifth accepted kind),
checking the intended reason and restoring the original between mutations.

Command (one bounded run, not a partition of ordinary acceptance):

```sh
gtimeout --signal=KILL 420s python3 scripts/rule_example_checks.py \
  --rules SL1001 SL1002 SL1003 SL1004 SL1005 SL1006 SL1007 \
  SL2001 SL2002 SL2003 SL2004 SL3001 SL3002 SL4001 SL4002 SL4003 SL4004 SL5001 SL5002 \
  --evidence tmp/issue13-examples/independent-corpus-v2.json
```

Exit 0; full log: `tmp/issue13-examples/independent-corpus-v2.log`.
The local export records `completeCorpus=false`, exact before/after source/configuration and
checker bytes, all canonical results, actual commands and original compiler output. Producer
identity was `b64747b7ce16d5850c11f9798d46dfa5fe5b9b17:unreleased-worktree` throughout. This
is working-tree evidence, not a clean exact-head claim. Later comment/prose edits do not
change checked semantics; final delivery must regenerate the complete exact-source export.

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

## Remaining engine dependency and delivery checks

The source-owned SL2005 pair is present. On the old base, malformed owned admission is
flattened to SL2001 instead of the required SL2005. The engine worker owns the typed public
admission result repair. This corpus deliberately retains SL2005 and cannot qualify that
rule until the authoritative repaired engine revision is integrated. No substitute diagnostic
is accepted, and no final all-rule PASS is claimed.

After integration, run `./scripts/verify.sh diagnostics rule-examples` for the entire closed
twenty-rule corpus and `./scripts/verify.sh` for separate unpartitioned ordinary420 acceptance,
under Firstmate's coordinated resource slot. Apply the repository review skill inside the
selected no-mistakes path, with distinct fresh semantic/proof and operational/metaprogramming
reviewers and focused verification after repair. No independent review or final CI is claimed
by the compiler/corpus observations above. Existing producer/history campaigns remain owned
by the engine worker and their prior evidence is not relabelled here.
