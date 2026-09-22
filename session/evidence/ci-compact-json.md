# CI repair: compact initial result serialization

Subject: HEAD `7aab68f1ba099dc951a5b658cfeca513dadc94a3`, dirty implementation
qualification. Only two executable lines change, in
`StrictLean.Checker.ResultProtocol.write` and `writeAccepted`: use pinned
`Json.compress` instead of `Json.pretty`. No caller or normative rule changes.
The original hosted history420 failure and all prior receipts remain intact.

## Preservation argument and authority

The argument supplied to serialization is definitionally the same constructed
`Json`: every request/claim/snapshot/source field and ordered array is unchanged.
Parent-directory creation, newline, write operation, and exception propagation
remain at the original locations. Both source-account and request/effective
terminal read/parse/rewrite operations remain; no write fusion or observation reuse
was introduced. Invalidation before parsing, `finally` retention, failure precedence,
and source/configuration/dependency comparisons are unchanged.

The con-leche-inspired accepted-evidence boundary remains `AcceptedRun.report`;
compact JSON is transport, not deserializable proof or a new source of authority.
Combined acceptance and internal incomplete production retain their meanings.
The pinned Lean serializer/parser, operational strict parser, IO and compiled runtime
remain trusted. Identical JSON construction is a source/definitional argument;
sampled parsing qualification is not a universal serializer correctness theorem.
No timing cause, savings, runtime bound or full CI readiness is claimed.

## Allocation, build and review

Firstmate095 granted exclusive local compiler allocation contingent on a fresh
process-only scan. The scan immediately preceding the targeted build was empty.
`lake build axiomGate +StrictLean.Checker.HistoryQualification:olean
+StrictLean.Checker.ProducerQualification:olean` passed (104 jobs), on Lean 4.33.1.
This was incremental dirty implementation compilation, not cold acceptance.
No Mathlib input changed; no new mathematical theorem or axiom-coverage claim is made.

Fresh-context integration reviewer `compact_review` was explicitly configured with
`gpt-6-astra` / `medium`; source review was CLEAN. It traced the JSON arguments,
Accepted.report authority, pinned string/array rendering, project/file/combined/docs
and rule-example callers, and unchanged terminal freshness/error boundaries.
No compiler work was delegated. Scope is the two substitutions, not full conformance;
operational MUT qualification remains incomplete. The observed parent launch argv
(PID 25958) contains `-m gpt-6-astra` and
`model_reasoning_effort=medium`, executable `codex`; the child configuration is
recorded by the agent invocation, not independently observed child argv. Launch
arguments do not authenticate backend model execution.

## Qualification stopped: fixture expectation failure

An attempted public rejected-envelope preparation invoked the changed binary with
`--project <this-worktree> --manifest tmp/ci-compact-json/invalid-manifest.json
--json-out <absolute tmp/ci-compact-json/rejected.json>`; the manifest was `{}`.
Exit 1 was expected, but the actual status was **incomplete**, with SL2001 and
`property not found: schema-version`, rather than the driver's expected rejected.
This is an incorrect fixture expectation, not evidence of a renderer defect.
The command output and actual envelope are preserved; the latter's filename does
not classify its status.

The preparation command yielded a running session; the equivalence command was
launched before its completion was collected. This sequencing error is recorded,
not represented as successful ordered qualification. The second compiler-only
scan was empty at its launch. Under a 60-second bound, the Lean equivalence driver
passed both retained actual accepted and incomplete envelopes: pretty and compact
output each parsed equal to the original complete Json value through both
`Lean.Json.parse` and `StrictLean.Checker.PolicyCodec.parse`. It then failed on the
incorrect rejected-status expectation. There was no timeout. Its subsequent escaped
source-byte/structural Name/array/null/Unicode/number controls and direct write
controls were **not reached**. The rejected envelope comparison is also incomplete.
No isolated timing comparison was performed.

The first collected failure ended validation: no correction/retry, CLI controls,
producer/history decoder controls, history420 or ordinary cold420 followed.
Both launched sessions exited. Final process-only scan found no Lean/Lake/leanc/
leanmake processes; the owned compiler allocation is released.

The emitted producer identity was
`b424d47c9477df2868c08504987e692b5ef19e8c:unreleased-worktree`, producer version
`unreleased`, toolchain `4.33.1`: the incremental build reused the elaboration-captured
Producer identity. It is not a clean or exact published-head receipt for 7aab68f.
The changed binary and ResultProtocol olean/source hashes are retained separately.
Historical ordinary399.689s/producer418.028s do not validate these changed inputs.

## Evidence and next disposition

Raw evidence: `tmp/ci-compact-json/` contains build/equivalence logs, temporary Lean
qualification driver, actual incomplete envelope and command output, normalized
fixture failure, retained input/output SHA256 identities, both pretty/compact
outputs for completed comparisons, producer identity, observed runner arguments,
and before/after process scans. Original retained inputs were read unchanged;
no other clone or caller evidence was accessed. `git diff --check` passed.

Return to the owning CI phase executor for renewed validation disposition after
this fixture failure. Pending work, only after authorization and fresh allocation:

1. Supply an actual rejected envelope and correct the temporary qualification input;
   execute the complete retained-envelope and exact-byte controls with
   `lake env lean --run tmp/ci-compact-json/SerializationQualification.lean`.
2. Run `python3 scripts/registry_cli_checks.py` and the existing
   `lake env lean --run lean/StrictLean/Checker/ProducerQualification.lean <qualified-project-envelope>`
   and corresponding `HistoryQualification.lean` controls. These are scoped controls,
   not complete producer/history campaigns.
3. Only after targeted qualification succeeds, one complete
   `./scripts/verify.sh diagnostics history` attempt under its unchanged420 limit.
4. Only if history passes, one separately sequenced complete cold-root
   `./scripts/verify.sh`, with pinned dependencies provisioned and root artifacts
   absent; do not substitute separately executed inner checks.
5. Required complete producer420, remaining corpus/site checks, exact published-head
   validation and hosted CI remain with the outer executor. No old receipt substitutes.

No pipeline control, push, PR update, merge, runner/deadline/coverage change, or
other optimization was performed. CI and delivery remain unresolved.
