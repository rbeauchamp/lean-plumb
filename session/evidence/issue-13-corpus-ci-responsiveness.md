# Issue 13 corpus: CI repairs and bounded responsiveness

This supplements the historical [corpus record](issue-13-rule-examples.md), not a
declaration that issue 13 or Project 8 is complete. Engine integration is
[the engine change](https://github.com/rbeauchamp/strict-lean/pull/30), merge
`0df758a92856b6a268882eada641773af5684d80`. The corpus delivery is
https://github.com/rbeauchamp/strict-lean/pull/31. Firstmate owns whole-issue reconciliation,
successor-body publication, protected integration and cleanup.

## Exact checked candidate

Signed `117ec9fe0b77aea9bd1bb5ae011b3719217f1193` completed
`./scripts/verify.sh` locally with empty root build output in **254.812s**, exit 0.
It retained 29 owned modules and 4,177 declarations: Audit 7/313, AuditApp 5/197,
StrictLeanPolicy 17/3,667. The exact declaration/axiom report is retained in the task's
`tmp/cold420-20260916-117ec9fe/axiom-report.json`, alongside metadata and the complete log.
All 94 documentation fences completed: 70 positives, 23 intended negatives and one
classified compiler-teaching example. Root Lake inventory reconciled the added qualifier
executable as tooling; no claimed library was excluded.

[Hosted run 35113512538](https://github.com/rbeauchamp/strict-lean/actions/runs/35113512538)
passed at the same head. Job metadata records ordinary verification 15:12:34–15:19:18 UTC
(404s), producer qualification 15:19:18–15:26:14 (416s), corpus qualification
15:26:14–15:32:58 (404s), and the separate one-rule linter/Verso prototype
15:33:18–15:36:05 (167s), on 2026-09-16. All four PR checks passed. The pipeline returned
`checks-passed` for run `01M2N4A63CSQQ23NARC7CV7PHT`. These stage durations are rounded
observations, not a guaranteed margin; diagnostic stages do not partition or replace
ordinary acceptance. A later documentation/skill follow-up requires its own final-head
review/check attribution. No production website or deployed identity is established here.

Pins: Lean 4.33.1 / `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`, Mathlib
`0df444a360eaa60ab8c11dca51a86af692955474`. Local machine: Apple M4 Pro, 14 logical CPUs,
24 GiB RAM, macOS 27.0 build 26A428. Hosted snapshots report Ubuntu 24.04 x86_64,
four CPUs and 15 GiB total memory. Preflight resource snapshots do not establish peak
runtime memory, utilization or the absence of scheduling contention.

## Failed attempts and repairs

- `ef5ca2e5056f51a46e2eb1aed81deba430750f01`: local cold ordinary PASS216.521s;
  [hosted 35102091879](https://github.com/rbeauchamp/strict-lean/actions/runs/35102091879)
  failed137 at420s during fence inspection, group32/38.
- `d53a7d9b7c7aef02d3e42b41647a9fae53924113`: equivalent canonical-set decisions;
  local cold PASS217.737s;
  [hosted 35107667667](https://github.com/rbeauchamp/strict-lean/actions/runs/35107667667)
  still failed137 at420s during group32/38. The observed declaration phase decreased
  183.325s to171.391s, but these are not a controlled speedup estimate.
- `47ab5adc184f16faae96be7284966bc2c87c73c2`: removed the extra two-worker inspection
  cap while retaining ordinary `jobs=4`, isolated children/scratch and fixed result slots.
  Local cold PASS221.240s;
  [hosted 35109885992](https://github.com/rbeauchamp/strict-lean/actions/runs/35109885992)
  passed ordinary and producer checks, then failed the separate corpus420 deadline after
  its sixtieth phase line, before full control/final qualification completion. Site checks
  were skipped. Sixty lines did not establish a complete corpus result.
- `117ec9fe`: built the unchanged `RuleExampleQualification.main` as a native executable,
  classified the target, and synchronized the diagnostic runner and guide. The local full
  diagnostic campaign completed 60 phases and 12 admission controls in approximately
  394.64s, including its build/housekeeping. The same complete export passed the old
  `lean --run` and native invocations with identical output, observed17.18s versus1.22s.
  An auxiliary interpreted Lake-inventory probe hit a Lean interpreter assertion and was
  not counted as PASS; the subsequent full ordinary run reconciled the actual root scope.

The canonical repair's `adjacentOrdered_iff` and `orderedDecision` use exactly
`propext` and `Quot.sound`. `normalized_iff_ordered`, `normalizedDecision` and the concrete
name/edge decision instances additionally use `Classical.choice`. They decide the existing
normalization-equality propositions; no policy predicate changed. Compiled admission-call
inspection and isolated duplicate/order/restored controls qualify the executed path.
At most `max(n-1,0)` adjacent comparisons does not bound name comparison cost or prove
machine-code correctness. Initial duplicate controls also introduced descending pairs;
independent review identified that masking, and final controls used adjacent duplicates
without a descending pair. The incomplete initial controls remain nonqualifying.

All repairs received fresh-context focused review inside no-mistakes, with actual
Codex/gpt-6-astra/medium launches checked. Canonical proof and operational risks had separate
reviewers; the scheduling and native-invocation changes had focused independent repair
review. The latter caught the stale direct build command before final review. Original
source-binding/terminal-capture repairs and semantic reviews remain in the pipeline and
the linked corpus evidence. Compiler/runtime, subprocesses, filesystem observations and
serialization authenticity remain trusted; these checks do not prove them.

## What the detector timer includes

At the failing47ab revision, `scripts/rule_example_checks.py` brackets `run(command,cwd=project)`
with monotonic time. The reported `detectorSeconds` includes the fresh checker subprocess
and nested work through its exit. For SL4001's documentation fixture, `RuleExamples.documentation`
copies the project, discovers Lake scope, fresh-builds the claimed target and audits the
valid Lean fence before reporting the orphan marker. Fence compilation, imports, kernel
admission, source/configuration guards and result serialization are inside that interval.
The structural scanner alone is not being timed.

Python fixture setup, before/after snapshots, export, and subsequent receipt qualification
are outside it. The old per-record `lake env lean --run` qualifier overhead was therefore
outside the displayed detector time. Results print in fixed order after qualification,
with two producers overlapping; gaps between lines are not isolated detector durations.
No per-operation dominance or universal latency claim follows from these logs.

## Bounded native responsiveness at47ab

The approved protocol used one small Core application and one Mathlib library, separately
provisioned and compiled before measurement. It used the actual pinned `lake env lean --server`,
not another server or an installed-VSCode claim. Core's proposition was
`reflexive (n : Nat) : n = n`; Mathlib's was `twoPrime : Nat.Prime 2`.
Only the proofs changed between `rfl`/`Nat.prime_two` and `by sorry`; all corrections
restored exact bytes under the same Standard-Logical local maximum.

| Workload | Fresh-server positive | Warm unchanged | Three violating edits | Three restorations |
| --- | ---: | ---: | --- | --- |
| Core | 1.244s | 0.206s | 0.207,0.204,0.206s | 0.205,0.206,0.205s |
| Mathlib | 1.580s | 0.297s | 0.206,0.202,0.206s | 0.206,0.203,0.204s |

Each ordinary observation had one in-flight document version and required an exact URI/version
diagnostic publication followed by `textDocument/waitForDiagnostics`. The barrier alone allows
a later version, so it was not treated as identity evidence. All six violations retained the
original sorry warning plus `StrictLean.SL1002` at zero-based line4 and the actual theorem-name
range (Core8–17, Mathlib8–16); all restorations completed cleanly. Timing includes native
debounce and local hooks, not a full fresh project audit. Filesystem caches were not flushed.

Each workload also sent an immediate violating-to-corrected supersession and cancelled its
obsolete wait request. Both old requests returned `-32800`; corrected version10 completed
cleanly (about0.205s/0.206s). This is request-cancellation evidence, not proof that elaboration
was cancelled or its resource use bounded. No older-version result was accepted as current.
All18 observations finished, without retry, inside the900s total/45s per-wait bounds; combined
native traces were under8s. Three samples do not support a p95 or general workload guarantee.

Core setup took7.409s, Mathlib4.975s. Separate fresh `axiomGate --project` checks of both
corrected libraries completed with zero diagnostics. The Core IO entry was built but excluded
from the library foundation claim. Full Mathlib, arbitrary files/machines and actual VSCode
interaction remain outside this observation. Raw exact sources, configurations, identities,
JSON-RPC traces, stderr, driver and all samples remain in the owned task's
`tmp/latency-47ab5adc-20260916/`. This evidence is attributed to47ab, not silently renamed117;
117 changes corpus invocation/configuration only, leaving the measured native observer Lean
sources unchanged. Any later relevant input change requires renewed qualification.

## Remaining delivery boundaries

Four accepted-example kinds remain unchanged. SL2001/SL2005/SL3001 demonstrations are
incomplete analysis with completed diagnostic production, never positive acceptance.
Whole-set expected findings, source/config/toolchain/mode and authentic attribution remain
required. The corpus qualifies interfaces, not every possible detector execution or R-* adequacy.
Global Accepted composition remains issue7; actual editor journeys14; full site15; final
workflow/residual reconciliation10. Optional8/9 and historical3 do not become core gates.

The requested Lean CI skill and coverage-guide synchronization follow this green candidate.
Their signed follow-up, independent review and exact-head CI remain required before final
readiness. Successor drafts carry substantive APIs, modes, commands and page inputs; Firstmate
must publish final evidence and reconcile all issue13 criteria before unblocking7. No release,
visibility change, new public repository or Lean fork is authorized by this record.
