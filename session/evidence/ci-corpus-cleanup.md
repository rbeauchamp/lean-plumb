# Corpus recovery and cleanup repair, 2026-09-22

Delivery remains **INCOMPLETE**. Reviewed predecessor
`5d7b5fade002a783943474c5a74c691be66e39e8` failed full corpus qualification at
the unchanged 420-second limit. The repair below has a focused compiler result;
independent delta review, a newly authorized full corpus attempt, cold ordinary
acceptance and final-head hosted checks remain pending. Earlier
[projection/ordinary evidence](ci-corpus-projection.md) retains its own inputs.

## Recovery and failed replacement

The original run started at 2026-09-22 14:38:32Z. Host reboot at 14:41:38Z
interrupted it before 420 seconds; no completion receipt exists. The single
authorized replacement ran unchanged `./scripts/verify.sh diagnostics rule-examples`
at the clean predecessor from 15:45:48Z to 15:52:48Z, with all prerequisite build
and preparation inside the timer. The time wrapper reports 420.02 seconds,
abnormal command termination and wrapper exit 1; its macOS signal diagnostic
supplies no reliable direct-child exit code.

The full log has all 60 ordered primary phases. The retained aggregate has
`outcome=INCOMPLETE`, `completeCorpus=true`, 20 selected rules, 60 records and
12 controls. Its raw attempt has 65 registrations and 65 terminal observations.
The unchanged construction is **65 productions / 79 admissions / 72 terminal raw
validations**: five specials and seven mutations, each mutation with restoration.
Earlier 65/85/75 estimates were incorrect; no control was removed for these counts.

Flushed marks record run-start 3864903; aggregate-save 4240900–4241327;
qualifier-start and raw-validation-start 4241328; raw-validation-end and
consumer-observed qualifier join 4244852; terminal-equality 4244853–4244862
(monotonic milliseconds). Reaching terminal-equality/end in this source implies
that both task outcomes and equality succeeded. Marks alone do not authorize
acceptance. There is no pass-save mark or PASS receipt.

Remaining scratch contains slot-0/1 while slot-2/3/4 are deleted. Together with
source ordering this localizes the cutoff to parent scratch cleanup. Remaining
elapsed work is unknown. No Lean/Lake/qualifier/timeout process remained after the
run; process-group signal delivery remains OS trust, not a theorem.

Local artifacts remain intact:

- `tmp/corpus-replacement-5d7b5fa.receipt`: contemporaneous head, clean status,
  command, timestamps and matching start/end source hashes.
- `tmp/corpus-replacement-5d7b5fa.log` and
  `tmp/corpus-replacement-5d7b5fa-incomplete.json` (49,773,695 bytes).
- Raw attempt `tmp/rule-examples.json.raw/142-140-228-229-20-198-0-236-128-214-18-7-249-32-10-228-/`.
- Scratch `tmp/rule-examples-5-116-5-228-125-72-33-30-167-75-172-144-140-87-169-211-/`.
- Reboot-interrupted copies `tmp/corpus-reboot-5d7b5fa.log` and
  `tmp/corpus-reboot-5d7b5fa-incomplete.json`, with original raw evidence intact.

## Managed stream exits

Independent review found that `RuleExamples.observe` propagated a stdout drain
error before joining stderr; recoverable `child.wait` errors also skipped both
joins. The repair captures the child wait outcome, joins both launched stream
tasks, then consumes outcomes in the original order: child wait, stdout, stderr,
followed by the original sidecar reads. Error values remain verbatim. A failed
wait is not successful reaping. Return still requires successful child wait and
both drains. Handle-open/spawn failures before task launch owe no drain joins.

A stream failure can still require the external deadline to resolve blocked
process/pipe behavior. This is no liveness or detached-grandchild termination
theorem. SIGKILL cannot promise user-space finalizers. Stream encoding, output,
policy semantics and all admission predicates remain unchanged.

## Bounded deletion of owned slots

The successful corpus path removes only its five producer slots, three at a
time, before existing `withScratch` parent cleanup. The obligations are:

1. Cleanup begins after the producer pool's `finally` joins every producer,
   all admissions return, both terminal tasks join successfully and final source
   equality passes. No owned slot reader/writer remains. Consumers use captured
   values, retained sidecars and the real root, never slot paths.
2. Before any deletion, require exactly five slots. Each must equal its unique
   immediate child `realPath scratch / slot-<index>`, resolve to that same path,
   and have directory metadata rather than a symlink. Distinct canonical child
   paths exclude alias/ancestor overlap. External path replacement remains outside
   the stable-filesystem assumption, as for sequential removal.
3. Every task uses pinned `IO.FS.removeDirAll`. Lean 4.34.0's
   `Init/System/IO.lean` specifies unspecified deletion order and deletes symlinks
   without following them. Shared original dependencies and retained raw evidence
   are outside the roots. No source, provenance or byte guard is removed.
4. All five outcomes are collected and all launched tasks joined before the first
   slot-index error is rethrown verbatim. `withScratch` still removes the parent
   on success or failure; its cleanup error retains precedence over an action
   error. Early corpus failures retain the original sequential exceptional cleanup.
5. PASS stays after successful slot and parent cleanup, inside the unchanged420.
   Best-effort serialized phase marks expose these stages but grant no acceptance.

This is a composition argument for the actual IO calls under stated runtime
assumptions, not a proof of filesystem effects, scheduling or deadline compliance.
Con-leche remains the indexed accepted-result design influence, not the source of
an IO or cleanup theorem. No general cleanup framework or new process is introduced.

## Focused check and remaining gates

`lake build qualify` passed (169 jobs), including the changed module and native
qualifier, in `tmp/drain-cleanup-focused-build.log`. This checked the working-tree
repair over the predecessor, not final-head ordinary acceptance. Lean4.34.0,
compiler `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, arm64-apple-darwin24.6.0;
Mathlib remains pinned to `5ed2965256430c3649e86755f9576b54eca72435`.
Changed module SHA256:
`1d2b00746a4d540a14b8c3bfd73566ad7e532383797b09b87826e506824318e9`.
Build-log SHA256:
`0dd1d104cacb5d65c89376a48f239b5f7465c502be0ffbf4c1394a8c9ab2fbb1`.

No policy theorem, census, job inventory or example classification changes.
This compilation does not close independent delta review, full corpus, cold
ordinary420, separate producer420/history420, site or final-head hosted gates.
The old AXI run is terminal failed (`daemon shutting down`); live supported
custody reconciliation reports clean local-ahead with every pipeline commit
preserved. Full no-mistakes has not restarted. Firstmate owns review disposition,
full-run authorization, protected integration and successor publication.
