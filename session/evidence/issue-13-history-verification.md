# ENGINE-01 history producer: scoped verification

Baseline `1bc12e62422a4b687876af93e222cffc847fd4c1`. This partial #13 increment
retains source-bound replacement-history observations for future acceptance composition.
The exact interface and remaining obligations are in `docs/guides/engine-producers.md`.
Publication records the immutable PR head, CI run and signed merge separately.

## Inputs and claim

Lean 4.33.1, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`; Mathlib
`0df444a360eaa60ab8c11dca51a86af692955474`. `issue-13-history-inputs.json` records
179 source input hashes and the exact checked module lists, declaration counts and per-surface axiom unions.
Hashes identify bytes, not correctness or runtime authentication. Pure policy definitions
and their theorems are unchanged; no new universal collection or source-authentication
proof is claimed.

The walk registers root/module history requests before lookup. Per-report caching retains
both success and unavailability. Completed receipts retain the Lean-resolved source path,
exact before/after bytes and ordered replacement edges, including overwritten choices.
The existing worker request binding and evaluator restrictions remain in force. Shared
producer/decoder guards reconcile requests and receipts, source equality and runtime
replacement edges; unavailable history cannot accompany completed requesting roots.

These guarantees are operational under the pinned process/imported-library boundary.
They do not prove complete closure acquisition, absence of transient source changes between
observations, arbitrary serialized-source authenticity, global Accepted or full conformance.
Legacy JSON still omits the added producer records.

## Acceptance

`./scripts/verify.sh`: **PASS, 241.00 seconds**, under the unchanged 420-second limit.
Registry/CLI and 36 native controls passed; every claimed declaration was freshly built
and admitted; 70 positive, 23 negative and one authenticated teaching fence passed (94/94).

| Surface | Modules | Declarations | Exact transitive axiom union |
| --- | ---: | ---: | --- |
| Audit | 7 | 313 | propext, Quot.sound, Classical.choice |
| AuditApp, including Main | 5 | 197 | propext, Quot.sound, Classical.choice |
| StrictLeanPolicy | 17 | 3531 | propext, Quot.sound, Classical.choice |
| Total | 29 | 4041 | No other axiom names |

All surfaces select Standard-Logical and execution report mode. Counts describe the
actual checked domain, not theorem adequacy or runtime correspondence for all boundaries.
Producer was rebuilt for this run; its embedded revision still identifies its elaboration,
not authenticated whole-binary source identity.

## Qualification and review

`./scripts/verify.sh diagnostics producers`: **PASS, 187.02 seconds**. The retained
transcript is `issue-13-history-qualification.txt`. The campaign includes the existing
18 documentation invocations, three standalone controls and eight producer-report mutations;
it adds nine fresh/incremental/file history invocations and eight history-report mutations.
Each new mutation requires its exact expected decoder error, with original-record re-admission
afterward. The public controls preserve the identity computation, expose both overwritten
choices, and add only a no-op source evaluator for the unsupported-history case. Every
restored public control starts with cleared root build output and a unique result path.
These are scoped operational observations, not universal correctness proofs.

Two fresh-context independent reviews covered production/source/transport and qualification
risks. Production review was CLEAN. The qualification review required full exact error equality
for each decoder mutation instead of accepting any history-related error. That repair received
a focused independent CLEAN review. No other findings remained.

Applied rows: SCOPE-02/03, DECL-03/04, COMP-03/04, BUILD-03/04, DOC-01/02,
DOGFOOD-03 and MUT-02/03/04 for the changed claims. This is scoped evidence; no full chapter9
conformance claim is made. Hosted CI remains required on the exact reviewed PR head.

## Remaining work

#13 retains complete reached-node/edge and source linkage, policy-example integration and
the remaining eighteen source-owned rule pairs. The older structural campaign's Policy-root
manifest setup remains unresolved; this increment does not execute or claim that campaign.
#7 owns fixed jobs/global Accepted; #14 adoption/editor journeys; #15 the complete website.
