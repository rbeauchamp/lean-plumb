# Corpus checkpoint writer — CI/ci-1

Subject: parent `81e8b01ab80369ad310afb66a527d6673871cc47`, changed working tree.
Only `scripts/rule_example_checks.py` production behavior changes. This is a
serialization repair, not a Snapshot optimization or a normative-rule change.
The con-leche-inspired accepted-evidence boundary remains the existing Lean
consumer; Python IO is not kernel verified.

## Value and failure argument

The fixed header is encoded once with Python JSON. The writer's byte offset is
immediately after the last encoded record (initially after the opening array).
Appending the next encoded record with a comma exactly when nonempty, followed
by a freshly encoded footer, gives the old object with the next ordered record.
Truncation removes the previous footer remainder. Both new values are encoded
before mutation. Finalization replaces only the footer, adding the original
controls and independently sampled final checkerAfter. All original snapshot
calls and their order, admissions, subprocesses, controls, and final consumer
reread remain. Whitespace/object member order are not observation identity.

Startup removes previous evidence before corpus loading or snapshot acquisition.
The initial empty checkpoint uses checkerBefore as checkerAfter without another
snapshot call. Encoding failure retains the current last successful checkpoint;
write failure or interruption may leave invalid/incomplete JSON. No atomicity or
crash-durability claim is made. A full-record checkpoint can precede controls;
`completeCorpus` denotes requested scope, not campaign completion. The consumer
already does not inspect admissionControls. Only the terminal successful command
establishes campaign completion; parsing a checkpoint does not. No Accepted claim
is created by this diagnostic artifact.

For 60 records, old prefixes encode 1830 record occurrences, then another 60 at
finalization. New checkpoints encode each original record once. This structural
work reduction proves neither elapsed savings nor a 420-second pass.

## Qualification and ownership

Raw evidence and one-off executable drivers are in `tmp/ci-corpus-writer/`.
`equality.log`: PASS for parsed empty/prefix/final objects, actual large retained
producer envelope, Unicode/escaped source, ordered arrays/nulls, controls,
shorter-footer truncation, encoding failure and injected partial-write failure.
These are serialization qualifications, not universal proofs of Python IO.
Fresh producer rebuild invalidated only the local Producer olean (previous file
retained) because its elaboration embeds Git revision/dirty state. Build passed
on Lean 4.33.1. No toolchain/package installation or external project writes.

Independent fresh-context source review: CLEAN, writer SHA256
`795f389c719635e426e7feeae788454b7c2409c681989386bab8c5f646e901a5`.
Reviewer configured through collaboration as gpt-6-astra/medium; actual model
argv was not independently observable. Fixer model/effort requested by outer
executor as Codex/gpt-6-astra/medium; runtime argv not independently verified.

Final execution outcomes are recorded below. Producer/history/site and hosted
checks remain outer-executor requirements; old-head passes do not cover changed
inputs automatically. No pipeline control, push, PR mutation or merge performed.

Targeted actual-envelope qualification passed: fresh SL1001 Fixed/Violation/
Restored at each checkpoint and final object equal the old constructor, followed
by actual Lean `qualifyCorpus` (including its seven mutations/restorations).
Additional actual-envelope `--record` controls refused missing and changed
source accounts for the intended reasons and accepted restoration. Compiled
producer reports `81e8b01ab80369ad310afb66a527d6673871cc47:unreleased-worktree`,
Lean 4.33.1. This is changed-working-tree evidence, not a signed final-head pass.
The fresh pre-corpus process-only scan was empty.

## Terminal disposition: acceptance failure — stop, no retry

The sole changed-input `./scripts/verify.sh diagnostics rule-examples` attempt
was killed at the hard 420-second deadline: subprocess return `-9` (SIGKILL;
shell convention 137), observed parent duration 420.3514307500009 seconds.
`corpus.log` records 41/60 qualified primary cases, ending at SL3002/Violation.
The five extra public controls and terminal controls/corpus validation did not
complete. Retained `corpus-partial.json` is partial evidence, never a corpus PASS.
`corpus-outcome.json` records the exit and duration. Prior failure artifacts were
preserved. No inference of runtime savings from the old hosted run is justified.

Per Firstmate100 stop-on-first-acceptance-failure allocation, ordinary cold420
was NOT STARTED; there was no retry, budget/concurrency change, producer/history/
site campaign or hosted execution. The final process-only scan is empty for
Lean/Lake/compiler and owned checker executables. Owned command descendants
have exited; compiler allocation released. CI remains unresolved and requires
Firstmate disposition. This writer repair is locally qualified but insufficient
to close the complete-corpus deadline failure. No further optimization is
implicitly authorized.
