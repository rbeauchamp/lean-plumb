# Session context: Strict Lean Project 8

**Date:** 2026-09-16
**Current corpus branch:** `fm/strict-lean-13-examples`.
**Verified code/evidence checkpoint:** `117ec9fe0b77aea9bd1bb5ae011b3719217f1193`.
The engine change [is merged](https://github.com/rbeauchamp/strict-lean/pull/30) at
`0df758a92856b6a268882eada641773af5684d80`; refresh live `origin/main` before resuming.
**Working checkout:** a disposable task worktree; read these files from your own checkout.
**Current delivery state:** the [corpus change](https://github.com/rbeauchamp/strict-lean/pull/31)
passed local cold ordinary420 and all hosted checks at the checkpoint above. The branch now
also contains the Lean CI skill, documentation follow-up and subsequent
[R7 configuration-capture repair](evidence/issue-13-configuration-capture-repair.md).
That record owns the repair's focused evidence and remaining gates; the checkpoint results
do not validate the later operational change. Final-head delivery checks remain pending.
Firstmate still owns protected integration, whole-issue reconciliation and successor updates.
**Active focus:** issue #13 only. No merge, issue completion, global Accepted or successor
unblocking follows from the green candidate. Preserve all pipeline repairs and unrelated work;
inspect current no-mistakes custody before editing. Coordinate expensive verification with Firstmate.

## Active plan and resume point

[Project 8's overview and execution plan](https://github.com/users/rbeauchamp/projects/8),
the [full live #13](https://github.com/rbeauchamp/strict-lean/issues/13) and native dependencies
are authoritative. There is no separate local `plans/` system. The overview now includes
an **Immediate execution plan**; use it rather than resurrecting the old #5 handoff.

#13 remains **In Progress**; prerequisites #5/#12/#25 were verified closed. The concrete
resume point is completing the follow-up and R7 repair through the active no-mistakes run,
then Firstmate's integration and acceptance-criterion reconciliation. Read the
[corpus CI and responsiveness record](evidence/issue-13-corpus-ci-responsiveness.md)
for exact checked revisions, failed attempts, proof/runtime limits and bounded native-server
observations. Refresh live issue bodies, comments, blockers and pipeline state before acting.
The producer guide retains the engine's precise proof and trust boundaries. Do not advance
to #7 because a partial #13 change passed or merged.

## Accomplished and reusable evidence

The engine repair entries below are historical checkpoints, including their then-pending
gates. Current corpus evidence at `117ec9fe` is local cold ordinary **PASS254.812s**,
29 owned modules / 4,177 declarations, all 94 fences, and
[all hosted stages passing](https://github.com/rbeauchamp/strict-lean/actions/runs/35113512538).
The linked current record distinguishes ordinary acceptance, separate producer/corpus
qualification and the one-rule site prototype; none establishes full Project 8 completion.

- R8/R9 against `94070754107360f414392f4744be38a119e4d584` make frozen-input
  rechecks structural across normal, typed-error and IO-exception exits. Import-time
  fence changes and failed dependency builds retain typed SL2005; unchanged failures
  retain their original classification. Focused build, 44 new controls and 18 affected
  fence controls passed. Both independent final branch/inventory re-reviews are CLEAN.
  See [frozen-exit repair](evidence/issue-13-frozen-exit-repair.md). Earlier broad consumer
  completeness claims are superseded by its explicit owner/exit inventory. Ordinary420,
  signed pipeline commits and exact-head CI remain outer-executor gates.

- R7 against `f8b383ff34b82aa678372b0be047c4a9696dbcaa` closes the grouped-fence
  typed admission consumer: SL2005 retains original detail alongside SL4002.
  Focused build and 18 fence-local public controls passed; independent semantic and
  transport follow-ups are CLEAN. See [fence repair evidence](evidence/issue-13-fence-evidence-repair.md).
  The R6 combined tests below failed on project source before fence inspection and
  did not establish fence-local propagation. Ordinary420 and delivery remain pending.

- R5/R6 repairs against `e58c783be00134d88ec192b575316cf7873b9887` retain reflexive
  candidates without weakening active-cycle refusal and carry malformed source-range
  refusal through the existing typed worker outcome. Focused build and 18 public controls
  passed; independent semantic and compiler/transport repair follow-ups are CLEAN.
  See [current closure/evidence repair](evidence/issue-13-closure-evidence-repair.md).
  No pure proofs changed; earlier review claims invalidated by these findings are
  superseded, not silently reused. Ordinary420 and delivery remain pending.
- R4 and related frozen-evidence read paths are repaired against
  `f7dfff2531fc0076d2558242dffcd46018c81455`: missing/unreadable captured source or
  configuration is SL2005/incomplete with IO detail; initial setup remains SL2001.
  Focused build and 28 public controls passed. Two distinct fresh full-branch reviews
  and their focused repair follow-ups are recorded in the
  [current repair evidence](evidence/issue-13-source-read-repair.md).
  The earlier missing-source SL2001 assertion is withdrawn as contract qualification.
- R1–R3 review-phase repairs against `d5a6c8ca92ebd44079d7c21a2550c675d84ad330`: frozen
  documentation project inputs, sole worker source maps and removal of the new Claude alias.
  Focused build and 18 public documentation controls passed; two fresh-context risk-specific
  repair reviews are CLEAN. See [repair evidence](evidence/issue-13-review-repair.md).
  These scoped repairs do not discharge ordinary420, full-branch review or delivery gates.
- Current closure/source scoped qualification: **PASS, 291.27s** under a 420s timeout;
  17 actual fresh/incremental/file invocations and 17 decoder mutation/restoration controls.
  Pure/compiler checks and three exact theorem axiom sets passed. The unchanged producer
  controls passed within earlier combined attempts that **failed overall** on subsequently
  repaired history-fixture preconditions. See the [current verification record](evidence/issue-13-closure-verification.md)
  and its transcript; no ordinary acceptance or independent review is claimed for this head.
- Product/design/registry #11/#4/#12/#20, domain #5, policy proofs #6 and native feedback #25
  are delivered. The implemented contracts are in the guides below; their live issue/PR state
  takes precedence over historical session text.
- [PR #27](https://github.com/rbeauchamp/strict-lean/pull/27) adds declaration/execution census,
  completed replay receipts and mandatory project SL5001/SL5002 documentation observations.
- [PR #28](https://github.com/rbeauchamp/strict-lean/pull/28) adds root/module history requests
  recorded before lookup, exact source-bound overwritten replacement histories or explicit
  unavailability, and producer/decoder reconciliation. Source `785eea7232487233dda60bf984daad7c496c9bbb`;
  its signed merge is an ancestor of the current engine basis. [Exact-head CI](https://github.com/rbeauchamp/strict-lean/actions/runs/35018300753)
  passed. Local acceptance: **241.00s**; combined producer qualification: **187.02s**.
- The historical PR #28 acceptance used Lean **4.33.1**, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`,
  Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`: **29 modules / 4041 declarations**, all
  94 documentation fences, registry/CLI and 36 native controls. Exact lists/counts/axiom unions,
  input hashes, qualification and scope limits are in the [history verification record](evidence/issue-13-history-verification.md).
- Fresh independent production and evidence reviews were clean after repairing the new
  mutation assertions to require each exact diagnostic. That delivery's local/remote branch and
  owned scratch were removed. The original ignored `tmp/axiom-report.json` was restored.
- #7/#10/#13/#14/#15 contain verified producer handoffs and remain open. #7 retains global
  jobs/Accepted; #14 actual Lake/editor journeys; #15 the complete website. The plan specifies
  serial delivery and disposition of optional #8/#9 under their existing criteria.

## Decisions, rejected approaches and unresolved limits

The [engine producer guide](../docs/guides/engine-producers.md) owns the settled APIs and
remaining producer work. Reuse `Report.Collected`, `Checker.ProducerReport.Environment`,
`Admission.validate`, shared `Collect`, native documentation observers and the typed policy core.
Pure policy proofs establish properties of admitted observations; they do not authenticate
external extraction, serialized source claims, runtime behavior or complete operational assembly.

- New transport validators initially placed in force-loaded `Report` caused PR #27's first
  ordinary run to hit 420s. Moving them to `Checker.ProducerReport` preserved the guards and
  allowed a complete passing run. Keep operational validation outside repeated reporter replay;
  never relax the deadline or use separately run inner checks as acceptance.
- Preserve unique result paths and exact source checks. Prior harness output reuse could admit
  stale results; mutation checks accepting any history error could accept the wrong reason.
  Both are repaired. Negative controls need the intended reason and a fresh restored positive.
- Older structural-campaign manifests omit classification of the newer `StrictLeanPolicy`
  root. Simply excluding it conflicts with forced policy imports. This setup needs reconciliation;
  the broad structural campaign is **unrun/not PASS**. Neutral docs were restored around older
  axiom controls so missing documentation does not become a second defect.
- The closure increment adds an actual reached-node/edge census, checked first-visit witnesses,
  exact source/configuration guards and typed owned-admission failures. Before/after equality
  still does not establish absence of transient source changes or truthful compiler extraction.
  The checker Producer revision identifies its last elaboration, not authenticated whole-binary
  source identity. #7 still owns claim-indexed global jobs and Accepted construction.
- The corpus branch now has all twenty source-owned rule pairs under `examples/rules/`
  and exact policy-example outcome qualification at the checkpoint above. Integration and
  whole-issue reconciliation remain pending; refresh main before claiming delivery. The user chose
  separate diagnostic demonstrations for intentional INCOMPLETE rules SL2001/SL2005/SL3001.
  Keep all four accepted-example kinds. Match the complete expected finding set (possibly
  multiple findings), exact ID/subreason, real location, source/configuration/toolchain/mode
  and terminal diagnostic production. Crashes/staleness/missing/unrelated failures satisfy
  neither demonstrations nor accepted examples; corrections require positive checks.
- Lean native hooks/current-module collection are implemented (#25); the old imported-only
  prototype limitation is superseded. Full editor journeys still require actual supported
  VS Code/infoview evidence (#14). Browser evidence does not establish editor behavior.
- Con-ron remains excluded. Con-leche informs canonical/indexed design, with no imported
  code/proofs or checker invocation. No universal con-leche branding. Ruff, Pyrefly and CA1416
  are illustrative design references, not exact-copy instructions.
- Pinned Verso/GitHub Pages remains selected; no Wiki or Docusaurus replacement is needed.
  Docs Lean 4.33.0/Verso and checker/examples Lean 4.33.1 stay separate. The full public rule
  website is still #15; the one-rule prototype is not its completion.

## Standing user directives and preservation

- “we will work each issue, one by one, until the project is complete.” Complete the current
  issue's ACs, verification, review, integration and live reconciliation before selecting the next.
  The save/merge request ends after persistence; the next work session resumes the execution plan.
- “leverage and re-use as much as we practically can and should rather than re-build it ourselves”;
  distinguish intended reusable APIs from specialized internal implementations.
- “An ounce of math is worth a pound of computation.” Preserve exact quantifiers, foundation
  sets, implementation linkage and trust boundaries. Follow AGENTS.md for proof-first choices.
- “Preserve public repository’s 420 seconds.” Ordinary `./scripts/verify.sh` has no override,
  partition or grace period. Focused diagnostics remain separate; never label an unrun campaign PASS.
- Keep all standard obligations accounted for: mechanically enforced predicates, required proof
  evidence or explicit residual semantic review. Natural-language MUST/SHOULD is not automatically
  an implemented detector. Registration completeness and specification adequacy remain review.
- Use closing syntax only for a genuinely completing PR. A negated closing phrase previously
  auto-closed #4; use `References #13` for partials and verify `closingIssuesReferences`.
- Standing PR/push/merge authorization applies with checks, independent review and protections.
  No release, visibility change, paid hosting, custom domain or Lean fork is authorized here.
- Preserve unrelated ignored reports, `.lake/packages`, `.lavish/`, `.local-state/` and archive
  branches. The old preparation repository is not the push target. Historical preparation data
  may exist in `.local-state/session-2026-09-14/`; it is not needed to resume and is not publication
  input. Do not delete or publish it. No other task owns these session files at save time.

## Key files and immediate action

1. Refresh the resulting main and read AGENTS.md, Project 8's **Immediate execution plan**, full
   #13 and its live blockers. Inspect `lean/StrictLean/Probe.lean` (`executionWalk`),
   `lean/StrictLean/Checker/{Environment,ProducerReport}.lean`, and
   `lean/StrictLeanPolicy/{Plan,Observation,Execution}.lean` against that plan.
2. Read the [producer contract](../docs/guides/engine-producers.md),
   [policy acceptance](../docs/guides/policy-acceptance.md),
   [policy proofs](../docs/guides/policy-proofs.md), [coverage map](../docs/guides/rule-coverage.md)
   and complete affected normative modules before implementation. Architecture, ecosystem-design,
   developer-experience and design-influences guides retain settled product decisions.
3. Complete the skill/documentation follow-up through no-mistakes with the repository
   [review skill](../.agents/skills/pr-review-toolkit/SKILL.md)'s independent semantic and
   implementation lenses, ordinary420 and exact-head CI. Firstmate owns integration.
   Reconcile the corpus increment and copy the settled interface and final evidence
   record into successor issues before declaring #13 complete; then follow the serial plan.

**Mission-leverage card / active goal object:** N/A; neither is used by this project.
