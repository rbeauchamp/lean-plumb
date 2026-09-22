# Corpus recovery and cleanup repair, 2026-09-22

Delivery remains **INCOMPLETE**. The reviewed repair at signed clean
`1c7304b40267e2343d65b3b94251b6e9424548f1` passed complete corpus qualification
in 391.55 seconds and cold ordinary acceptance in 237.84 seconds, each under its
unchanged 420-second limit. Full no-mistakes and final-head hosted checks remain
pending. Reviewed predecessor `5d7b5fade002a783943474c5a74c691be66e39e8`
failed its full corpus limit; that evidence remains below. Earlier
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

## Focused check

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
This focused compilation alone established none of the complete gates below.

## Reviewed full corpus and cold ordinary results

Firstmate's independent source-review disposition cleared immutable signed
`1c7304b40267e2343d65b3b94251b6e9424548f1`, including the managed stream joins,
bounded cleanup and successor-routing correction. One new full corpus run was
authorized because cleanup commit `31ad6f52f08fd4669a0490ccabb98d7255167bba`
materially changes the diagnosed tail. This was not a retry of unchanged failed
inputs. Under the sole local compiler allocation, the complete command
`./scripts/verify.sh diagnostics rule-examples` passed from 16:22:47Z to
16:29:18Z on 2026-09-22: **391.55 seconds, exit 0**. Prerequisite builds and
preparation remained inside the wrapper's hard420.

The final receipt is `PASS`, `completeCorpus=true`, 20 selected rules, 60 primary
records and 12 controls. All **65 productions / 79 admissions / 72 terminal raw
validations** remain required. The raw attempt contains 65 registrations and
65 terminal sidecars. After successful terminal qualification, raw validation
and source equality, slot cleanup took 22,560 ms and parent cleanup 75 ms.
Both ended before pass-save, which took 517 ms. Readback confirms the successful
attempt's parent scratch is absent. This is one observed completion, not a
runtime or scheduling guarantee; the earlier failed receipt is unchanged.

Retained local artifacts:

- `tmp/corpus-cleanup-1c7304b.receipt` binds command, clean head, timestamps,
  unchanged source hashes and exit status.
- `tmp/corpus-cleanup-1c7304b.log`, SHA256
  `666ed9eb51b4972d0465f502c1e85bb4aef1ea9411bd7dbbde93f49a2aab56c7`.
- `tmp/corpus-cleanup-1c7304b-pass.json`, SHA256
  `6e2359c9ebe989c409dc552966d2ebc9c94df6790e63303be94d6bfe6333379c`.
- Raw attempt `tmp/rule-examples.json.raw/203-66-231-157-198-60-144-124-189-22-42-108-169-30-86-88-/`,
  including flushed `phase-marks.txt`; these marks supplement, never replace,
  the executable finalizer and successful command receipt.

Next, the complete `./scripts/verify.sh` passed on the same unchanged signed
head from 16:29:52Z to 16:33:50Z: **237.84 seconds, exit 0**. The entire root
`.lake/build` was moved to `tmp/cold-1c7304b-root-build-preserved` before the
command; only pinned dependency artifacts remained provisioned. All recorded
[source/configuration inputs](ci-corpus-cleanup-inputs.sha256) still matched
afterward. No inner check was substituted for cold ordinary acceptance.

The combined audit accepted 7,278 project jobs and 97 documentation jobs,
70/70 positive fences, 23/23 negative fences and 1/1 teaching classification,
zero failures. [Exact coverage](ci-corpus-cleanup-coverage.json) retains all
40 modules and 5,238 declarations with their individual axiom arrays:
StrictLeanPolicy 17/4,180; StrictLeanVerification 1/106;
StrictLeanQualification 10/443; Audit 7/313; AuditApp including Main 5/196.
These are the standard-logical/execution-report claims, not a whole-checker
formal-verification claim. Lean, compiler, Mathlib and host pins are those above.

The cold receipt/log/report are `tmp/cold-1c7304b.receipt`,
`tmp/cold-1c7304b.log` and `tmp/cold-1c7304b-report.json`. Their log/report SHA256s
are `3ecae929c38cb7b10d8858f5db45c3ddc6cd067c14ebab58fd6d8168cf3f011f`
and `2692bc382554c7b2d6f28220edf55f0380996bb3b99848ce6d737eb9ecf50915`.
Coverage SHA256 is `36e9c1f4946427eb7ff9bb6c9785db139db89d22c12e833262b4dfb722da6a5b`;
input-list SHA256 is `3f35293e7efd0d889b5f60030397f7b01d96217c59b62a3afb8f501dda60e1ee`.

## Remaining delivery gates

These receipts establish their exact local requests only. Subsequent evidence-only
commits preserve checked Lean/docs inputs; they do not change the recorded head or
make an old Accepted artifact evidence for a new request. Separate required
producer420/history420, site, full no-mistakes and final-head hosted outcomes must
be reconciled through delivery. The old AXI run is terminal failed (`daemon
shutting down`); supported custody reconciliation reports clean local-ahead with
every pipeline commit preserved and `run_pipeline` as the next action. Firstmate
authorized continuing full no-mistakes after these passes and retains protected
integration and successor publication. No merge or issue closure is claimed here.
