# Issue7: separate required diagnostic deadlines

## Decision and preserved baseline

The approved decision is **“Separate diagnostic gates (recommended)”**: producer and
history qualification each receive an independent hard420-second gate. Every existing
control remains required and sequential; ordinary complete cold-root verification keeps
its original hard420 deadline. The two diagnostic gates together allow up to840 seconds.
This is an explicit resource-contract change, not a performance proof or a pass under
the old combined420 contract.

Baseline: `0d2d6142192967f4873305cbf1ec5d8227607a36`, tree
`149ffee91a062bf716e399227073549c44fa27cc`, signed commit on
`codex/strict-lean-7-integration`, [delivery](https://github.com/rbeauchamp/strict-lean/pull/33).
Historical baseline local cold acceptance passed in225.263557834s; hosted ordinary
acceptance passed (approximately394.392s logged interval). The subsequent combined420
diagnostic failed: all21 producer public invocations completed, but only2/17 history
invocations completed. These observations retain their original request/platform identity;
neither they nor the completed producer sub-suite establish final-head CI readiness.

The previous no-mistakes run `01M2PHB688THDTPP3K7MQHJG3A` terminated with
`daemon shutting down` during restart. Read-only supported `axi sync --check` found
caller, recorded current/pushed pipeline head and live remote equal to the baseline,
with a clean caller and no synchronization needed. Its old pipeline worktree was absent.
All existing branch commits and available scoped evidence were preserved. A fresh full
validation run, not a response to the terminal gate, owns the next delivery checks.

## Executed change and coverage argument

- `./scripts/verify.sh diagnostics producers` builds `axiomGate` and the producer
  qualifier module, then runs the unchanged `scripts/producer_checks.py`.
- `./scripts/verify.sh diagnostics history` builds `axiomGate` and the history qualifier
  module, then runs the unchanged `scripts/history_checks.py`.
- `.github/workflows/ci.yml` requires those commands in that order in the same job,
  after ordinary cold acceptance and before corpus/site qualification. Each command
  retains the existing outer GNU timeout `--signal=KILL 420s`; there is no concurrency,
  timeout override, coverage skip or runner replacement.

The scripts' control inventories and within-suite order are unchanged:21+17 actual
public invocations and8+17 transport controls. The old aggregate executed producer
then history; the new required composition executes the same programs in the same order,
with an explicit history prerequisite build at its own entrypoint. Pure Lean definitions,
proofs, producer/decoder predicates, fixture bytes, source/admission/ownership semantics,
warning/refusal expectations and positive restorations are unchanged by this follow-up.
Ordinary verification still builds both qualification modules and performs its complete
original command sequence. This source-level preservation argument is not proof of
shell, Lake, OS or compiled process semantics.

## Verification and remaining gates

Pre-commit shell syntax, ShellCheck, whitespace checks and the system skill-creator
validator passed. Parsing the workflow confirmed all four verification commands occur
once in the intended order as unconditional required steps on the unchanged runner.
These checks establish neither Lean acceptance nor hosted readiness.

The delivery pipeline must record final signed-head local complete cold420 evidence,
independent delta review, and required exact-head hosted ordinary/producer/history/corpus/
site and other registered checks before readiness. Earlier proof/integration and focused
qualification evidence may be reused only for unchanged relevant inputs and claims.
No unrun or incomplete diagnostic is PASS. Historical failed attempts remain in
[issue7 verification](issue-7-verification.md); the successor contract is in
[the handoff](issue-7-successor-handoff.md). Issue7 remains open until protected integration
and reconciliation by its owner. No issue14/15/10 implementation is part of this change.

The con-leche-inspired complete request-indexed assembly retains its stated guarantees
and attribution. Its machine-checked proofs do not authenticate IO extraction, filesystem
freshness, JSON provenance, compiler/native code or process scheduling. Before/after
source equality does not exclude transient change-and-restore. The diagnostic deadline
is enforced by GNU timeout/OS process-group signaling, not a hard real-time theorem.
