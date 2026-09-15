# ENGINE-01 producer increment: scoped verification

This increment references issue #13; it does not complete it. Baseline:
`c966cc36ecad3a591ea9742804494fb38752d32f`. The implementation contract and remaining work
are in `docs/guides/engine-producers.md`. PR/merge and exact-head CI identity are recorded
in GitHub at publication; this pre-commit record does not predict those identities.

## Inputs and scope

- Lean `4.33.1`, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`.
- Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`.
- `issue-13-producer-inputs.json` records 177 repository input hashes and exact module lists.
  Hashes identify source bytes; they are not correctness or runtime-authentication proofs.
- Pure policy/theorem definitions are unchanged. Existing policy proof guarantees and their
  assumptions remain those in `docs/guides/policy-proofs.md`; this change adds operational
  observations, not a universal proof of collection or an `Accepted` constructor.
- Exact source-owned corrections for SL5001/SL5002 retain `∀ n : Nat, n = n`, the same `rfl`
  proof, and empty axiom sets. Documentation alone changes.

## Machine and operational checks

`./scripts/verify.sh`: **PASS, 244.07 seconds**, below the unmodified 420-second deadline.
It compiled the required tools/qualification modules, passed registry and CLI checks and
36 native bridge controls, freshly built and admitted every claimed declaration, and checked
70 positive, 23 negative and one authenticated teaching fence (94 total).

| Surface | Modules | Declarations | Exact union of transitive axiom names |
| --- | ---: | ---: | --- |
| Audit | 7 | 313 | propext, Quot.sound, Classical.choice |
| AuditApp, including standalone Main | 5 | 197 | propext, Quot.sound, Classical.choice |
| StrictLeanPolicy | 17 | 3531 | propext, Quot.sound, Classical.choice |
| Total | 29 | 4041 | No other axiom names |

All three surfaces select Standard-Logical and execution report mode. These counts and
per-declaration checks establish the actual audited scope, not arbitrary theorem adequacy
or checked execution correspondence for every reported trusted boundary.

`./scripts/verify.sh diagnostics producers`: **PASS, 93.48 seconds**. The retained transcript
is `issue-13-producer-qualification.txt`. It establishes:

- 18 actual project invocations: two doc rules × fixed/violation/restored × fresh/incremental/
  direct build-lint entrypoints. Unique output files, exact embedded sources, complete expected
  census and doc observations, unchanged elaborated types/empty axioms, replay membership,
  exact diagnostic IDs/details/primary locations/related lists/modes/status are checked.
- Three actual fresh standalone-executable controls: documented positive, one owned-axiom
  defect, fresh restored positive. Its module and execution root remain inventoried.
- Eight independent mutations of an actual returned report through the real Lean decoder,
  with intended refusal and re-admission of the original after each mutation.

These are operational qualification observations, not universal proofs about IO, Lean,
serialization or all possible projects. The direct build-lint entrypoint controls do not
claim a new ordinary `lake build` driver-integration campaign.

## Repair history and review

The first ordinary run was killed at its 420-second deadline during fence inspection:
**FAIL**, never treated as partial acceptance. New transport validators were then moved
from the force-loaded `Report` into `Checker.ProducerReport`, preserving the guards while
removing their implementation from repeated reporter replay. The full command above passed
afterward. Its measured duration is one observation, not a universal timing guarantee or an
isolated estimate of that refactor's performance effect.

Two fresh-context independent reviews covered production/replay/ownership and source/evidence/
invocation risks. They found stale-output reuse in the new harness, missing module docs in
an older standalone positive, and now-compound axiom fixtures. Repairs require unique output
and exact source binding, and preserve neutral module docs around the intended axiom defect.
Both focused independent repair reviews returned CLEAN on the final implementation.

Reviewed rows: DECL-01–04, affected COMP-03, DOC-01/02/04, BUILD-01/03, MUT-02–04 and
DOGFOOD-03. This is a scoped delivery review, not a complete chapter 9 conformance claim.

## Remaining evidence and work

- Exact-head hosted CI remains a publication/merge gate, verified separately before merge.
- #13 retains complete closure/source producer linkage, full policy-example matching and
  the remaining eighteen rule source pairs. #7 retains fixed jobs and global Accepted;
  #14 actual adoption/editor journeys; #15 the complete generated website.
- Older structural-campaign manifests predate the StrictLeanPolicy root and require
  reconciliation before that broader campaign can pass. Their changed doc sources are
  repaired, but that old campaign is not reported as executed or PASS here.
- Cached Producer metadata describes its last elaboration, not authenticated whole-binary
  source identity. Producer was rebuilt for the final local command; exact input hashes and
  hosted CI on the immutable PR head supply the stated delivery provenance. Complete source
  binding remains part of #13/#7, not authority obtained from a serialized revision string.
