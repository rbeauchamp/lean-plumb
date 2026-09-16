# Issue 13 review-phase repairs

Starting HEAD: `d5a6c8ca92ebd44079d7c21a2550c675d84ad330`.
Branch comparison base: `b64747b7ce16d5850c11f9798d46dfa5fe5b9b17`.
This record covers the uncommitted R1–R3 repair in the active no-mistakes review phase.
The outer executor owns signed fix commits and all subsequent pipeline phases.
Issue #13 remains partial and open; this is neither delivery nor global Accepted.

## Repairs and claims

- R1 was a snapshot-lifetime defect. Both public documentation paths now freeze the
  Lake-resolved project sources and configuration before dependency building. The same
  snapshots cross fence compilation and grouped inspection and are checked before success.
  Group requests bind both original project sources and exact compiled snippet text.
  Missing reads and observed changes refuse success. This does not detect transient
  change-and-restore or prove compiler/IO/source-to-olean correspondence.
- R2 was redundant ownership of the worker source map. `GroupRequest` and
  `ReportWorkerRequest` now carry only `sourceBindings`; loader module/path arrays derive
  from those records. Existing strict decoding and report/request equality remain.
- R3 removes only the newly introduced `CLAUDE.md` alias. `AGENTS.md` is unchanged by
  this repair.

## Historical focused evidence

The missing-source SL2001 assertion below was incorrect under the registry contract.
R4 supersedes that classification; this historical run does not qualify the required
missing-source SL2005 behavior. The other observed paths retain their recorded scope.

Pinned Lean: `4.33.1` / `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`.
Mathlib lock: `0df444a360eaa60ab8c11dca51a86af692955474`.
The previously empty local `.lake` was provisioned by Lake within this worktree.
No system packages or tool configuration were changed.

`lake build axiomGate docFenceAudit +StrictLean.Checker.CheckerSelftest:olean`
completed successfully: 97 jobs. See [build output](issue-13-review-repair-build.txt).
This compiles the affected `Documentation`, `DocFenceAudit`, `AxiomGate`, `SourceAudit`
and `CheckerSelftest` modules and dependencies. No pure theorem statements or admission
proof definitions changed. This compilation is not a new full declaration/axiom audit.

`python3 scripts/documentation_source_checks.py` completed with exit zero:
18 public invocations, nine each through `docFenceAudit` and `axiomGate --with-docs`.
Each path has an initial positive, four single-fault mutations during fence compilation
(source text change, source removal, manifest text change, manifest removal), and a
fresh restored positive after each mutation. The source is imported before mutation;
all positives retain the same proposition and proof. Each refusal requires its intended
reason. The combined path additionally requires exactly SL2001/incomplete for missing
source, SL2005/incomplete for the other mutations, and completed/no diagnostics for
positives. See [final qualification output](issue-13-review-repair-qualification.txt).

The first attempted control failed its baseline because its theorem used reserved
identifier `example`. Renaming that fixture identifier to `fenceClaim` repaired the
precondition; no checker definition changed. All 18 controls then passed. Independent
review tightened missing-file reason and diagnostic-ID assertions; the final rerun above
passed all 18 strengthened controls. No failure is counted as qualifying negative evidence.

## Independent review

Two separate fresh-context Codex `gpt-6-astra` reviewers, both at supported `high` effort,
reviewed the frozen core repair without editing or running builds/tests:

- `/root/repair_semantics`: semantic/source lifetime lenses; CLEAN for R1/R3,
  covering DOC-04/DOC-05, DECL-01 and DOGFOOD-03 aspects.
- `/root/repair_transport`: Lean/compiler/transport lenses 3–5; CLEAN for R1/R2,
  including both strict decoders, loader projections, report reconciliation and explicit
  empty snapshots in diagnostic-only callers. Its focused qualification follow-up found
  two precision improvements, now independently confirmed repaired: exact missing-file
  reason assertions and the SL2001 versus SL2005 documentation distinction.

These are focused repair reviews, not fresh full-branch conformance reviews. They retain
compiler/imported-library/filesystem trust and the change-and-restore limitation.
Qualification observes the changed public paths under MUT-02–MUT-04; it does not prove
universal IO correctness or separately exercise every initial-build/inspection mutation
and every worker-decoder refusal.

## Remaining outer-pipeline obligations

Full ordinary420, authoritative test/lint phases, any outstanding full-branch independent
reviews, signed fix commits, exact reviewed-head CI, protected integration and owned cleanup
remain with the outer executor. None was executed or claimed in this review phase.
The source-owned twenty-rule corpus and global jobs/Accepted work retain their existing
issue boundaries; this repair does not complete #13 or Project 8.
